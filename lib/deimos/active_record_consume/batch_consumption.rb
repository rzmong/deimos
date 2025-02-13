# frozen_string_literal: true

require 'deimos/active_record_consume/batch_slicer'
require 'deimos/utils/deadlock_retry'
require 'deimos/message'

module Deimos
  module ActiveRecordConsume
    # Methods for consuming batches of messages and saving them to the database
    # in bulk ActiveRecord operations.
    module BatchConsumption
      # Handle a batch of Kafka messages. Batches are split into "slices",
      # which are groups of independent messages that can be processed together
      # in a single database operation.
      # If two messages in a batch have the same key, we cannot process them
      # in the same operation as they would interfere with each other. Thus
      # they are split
      # @param payloads [Array<Hash|Deimos::SchemaClass::Record>] Decoded payloads
      # @param metadata [Hash] Information about batch, including keys.
      def consume_batch(payloads, metadata)
        messages = payloads.
          zip(metadata[:keys]).
          map { |p, k| Deimos::Message.new(p, nil, key: k) }

        tags = %W(topic:#{metadata[:topic]})

        Deimos.instrument('ar_consumer.consume_batch', tags) do
          # The entire batch should be treated as one transaction so that if
          # any message fails, the whole thing is rolled back or retried
          # if there is deadlock
          Deimos::Utils::DeadlockRetry.wrap(tags) do
            if @compacted || self.class.config[:no_keys]
              update_database(compact_messages(messages))
            else
              uncompacted_update(messages)
            end
          end
        end
      end

      # Get unique key for the ActiveRecord instance from the incoming key.
      # Override this method (with super) to customize the set of attributes that
      # uniquely identifies each record in the database.
      # @param key [String] The encoded key.
      # @return [Hash] The key attributes.
      def record_key(key)
        decoded_key = decode_key(key)

        if decoded_key.nil?
          {}
        elsif decoded_key.is_a?(Hash)
          @key_converter.convert(decoded_key)
        else
          { @klass.primary_key => decoded_key }
        end
      end

    protected

      # Perform database operations for a batch of messages without compaction.
      # All messages are split into slices containing only unique keys, and
      # each slice is handles as its own batch.
      # @param messages [Array<Message>] List of messages.
      def uncompacted_update(messages)
        BatchSlicer.
          slice(messages).
          each(&method(:update_database))
      end

      # Perform database operations for a group of messages.
      # All messages with payloads are passed to upsert_records.
      # All tombstones messages are passed to remove_records.
      # @param messages [Array<Message>] List of messages.
      def update_database(messages)
        # Find all upserted records (i.e. that have a payload) and all
        # deleted record (no payload)
        removed, upserted = messages.partition(&:tombstone?)

        upsert_records(upserted) if upserted.any?
        remove_records(removed) if removed.any?
      end

      # Upsert any non-deleted records
      # @param messages [Array<Message>] List of messages for a group of
      # records to either be updated or inserted.
      def upsert_records(messages)
        key_cols = key_columns(messages)

        # Create payloads with payload + key attributes
        upserts = messages.map do |m|
          attrs = if self.method(:record_attributes).parameters.size == 2
                    record_attributes(m.payload, m.key)
                  else
                    record_attributes(m.payload)
                  end

          attrs&.merge(record_key(m.key))
        end

        # If overridden record_attributes indicated no record, skip
        upserts.compact!

        options = if key_cols.empty?
                    {} # Can't upsert with no key, just do regular insert
                  else
                    {
                      on_duplicate_key_update: {
                        # conflict_target must explicitly list the columns for
                        # Postgres and SQLite. Not required for MySQL, but this
                        # ensures consistent behaviour.
                        conflict_target: key_cols,
                        columns: :all
                      }
                    }
                  end

        @klass.import!(upserts, options)
      end

      # Delete any records with a tombstone.
      # @param messages [Array<Message>] List of messages for a group of
      # deleted records.
      def remove_records(messages)
        clause = deleted_query(messages)

        clause.delete_all
      end

      # Create an ActiveRecord relation that matches all of the passed
      # records. Used for bulk deletion.
      # @param records [Array<Message>] List of messages.
      # @return ActiveRecord::Relation Matching relation.
      def deleted_query(records)
        keys = records.
          map { |m| record_key(m.key)[@klass.primary_key] }.
          reject(&:nil?)

        @klass.unscoped.where(@klass.primary_key => keys)
      end

      # Get the set of attribute names that uniquely identify messages in the
      # batch. Requires at least one record.
      # @param records [Array<Message>] Non-empty list of messages.
      # @return [Array<String>] List of attribute names.
      # @raise If records is empty.
      def key_columns(records)
        raise 'Cannot determine key from empty batch' if records.empty?

        first_key = records.first.key
        record_key(first_key).keys
      end

      # Compact a batch of messages, taking only the last message for each
      # unique key.
      # @param batch [Array<Message>] Batch of messages.
      # @return [Array<Message>] Compacted batch.
      def compact_messages(batch)
        return batch unless batch.first&.key.present?

        batch.reverse.uniq(&:key).reverse!
      end
    end
  end
end
