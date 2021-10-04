# frozen_string_literal: true

# This file is autogenerated by Deimos, Do NOT modify
module Deimos
  # :nodoc:
  class Generated < SchemaClass::Record
    # Attribute Readers
    # @return [Deimos::AnEnum]
    attr_reader :an_enum
    # @return [Deimos::ARecord]
    attr_reader :a_record
    # Attribute Accessors
    # @param value [String]
    attr_accessor :a_string
    # @param value [Integer]
    attr_accessor :a_int
    # @param value [Integer]
    attr_accessor :a_long
    # @param value [Float]
    attr_accessor :a_float
    # @param value [Float]
    attr_accessor :a_double
    # @param value [nil, Integer]
    attr_accessor :an_optional_int
    # @param values [Array<Integer>]
    attr_accessor :an_array
    # @param values [Hash<String, String>]
    attr_accessor :a_map
    # @param value [String]
    attr_accessor :timestamp
    # @param value [String]
    attr_accessor :message_id
    # @return [Object] An optional payload key
    attr_accessor :payload_key
    # Attribute Writers
    # @param value [Deimos::AnEnum]
    def an_enum=(value)
      @an_enum = Deimos::AnEnum.initialize_from_value(value)
    end

    # @param value [Deimos::ARecord]
    def a_record=(value)
      @a_record = Deimos::ARecord.initialize_from_value(value)
    end


    # @override
    def initialize(a_string: nil,
                   a_int: nil,
                   a_long: nil,
                   a_float: nil,
                   a_double: nil,
                   an_optional_int: nil,
                   an_enum: nil,
                   an_array: nil,
                   a_map: nil,
                   timestamp: nil,
                   message_id: nil,
                   a_record: nil,
                   payload_key: nil)
      super()
      self.a_string = a_string
      self.a_int = a_int
      self.a_long = a_long
      self.a_float = a_float
      self.a_double = a_double
      self.an_optional_int = an_optional_int
      self.an_enum = an_enum
      self.an_array = an_array
      self.a_map = a_map
      self.timestamp = timestamp
      self.message_id = message_id
      self.a_record = a_record
      self.payload_key = payload_key
    end

    # @override
    def schema
      'Generated'
    end

    # @override
    def namespace
      'com.my-namespace'
    end

    # @override
    def to_h
      payload = {
        'a_string' => @a_string,
        'a_int' => @a_int,
        'a_long' => @a_long,
        'a_float' => @a_float,
        'a_double' => @a_double,
        'an_optional_int' => @an_optional_int,
        'an_enum' => @an_enum&.to_h,
        'an_array' => @an_array,
        'a_map' => @a_map,
        'timestamp' => @timestamp,
        'message_id' => @message_id,
        'a_record' => @a_record&.to_h
      }
      @payload_key.present? ? payload.merge('payload_key' => @payload_key) : payload
    end
  end
end
