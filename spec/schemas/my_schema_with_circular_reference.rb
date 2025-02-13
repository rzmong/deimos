# frozen_string_literal: true

# This file is autogenerated by Deimos, Do NOT modify
module Schemas
  ### Primary Schema Class ###
  # Autogenerated Schema for Record at com.my-namespace.MySchemaWithCircularReference
  class MySchemaWithCircularReference < Deimos::SchemaClass::Record

    ### Secondary Schema Classes ###
    # Autogenerated Schema for Record at com.my-namespace.Property
    class Property < Deimos::SchemaClass::Record

      ### Attribute Accessors ###
      # @param value [Boolean, Integer, Integer, Float, Float, String, Array<Property>, Hash<String, Property>]
      attr_accessor :property

      # @override
      def initialize(property: nil)
        super
        self.property = property
      end

      # @override
      def schema
        'Property'
      end

      # @override
      def namespace
        'com.my-namespace'
      end

      # @override
      def to_h
        {
          'property' => @property
        }
      end
    end


    ### Attribute Readers ###
    # @return [Hash<String, Property>]
    attr_reader :properties

    ### Attribute Writers ###
    # @param values [Hash<String, Property>]
    def properties=(values)
      @properties = values.transform_values do |value|
        Property.initialize_from_value(value)
      end
    end

    # @override
    def initialize(properties: {})
      super
      self.properties = properties
    end

    # @override
    def schema
      'MySchemaWithCircularReference'
    end

    # @override
    def namespace
      'com.my-namespace'
    end

    # @override
    def to_h
      {
        'properties' => @properties.transform_values { |v| v&.to_h }
      }
    end
  end
end
