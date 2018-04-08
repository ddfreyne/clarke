# frozen_string_literal: true

module Clarke
  module Runtime
    Function = Struct.new(:argument_names, :body, :env) do
      def describe
        'function'
      end

      def self.describe
        'function'
      end

      def clarke_to_string
        '<function>'
      end
    end

    Integer = Struct.new(:value) do
      def describe
        'integer'
      end

      def self.describe
        'integer'
      end

      def clarke_to_string
        value.to_s
      end

      def add(other)
        Integer.new(value + other.value)
      end

      def subtract(other)
        Integer.new(value - other.value)
      end

      def multiply(other)
        Integer.new(value * other.value)
      end

      def divide(other)
        Integer.new(value / other.value)
      end

      def exponentiate(other)
        Integer.new(value**other.value)
      end

      def eq(other)
        Boolean.new(value == other.value)
      end

      def gt(other)
        Boolean.new(value > other.value)
      end

      def lt(other)
        Boolean.new(value < other.value)
      end

      def gte(other)
        Boolean.new(value >= other.value)
      end

      def lte(other)
        Boolean.new(value <= other.value)
      end
    end

    Boolean = Struct.new(:value) do
      def describe
        'boolean'
      end

      def self.describe
        'boolean'
      end

      def clarke_to_string
        value ? 'true' : 'false'
      end

      def eq(other)
        value == other.value ? True : False
      end

      def and(other)
        value && other.value ? True : False
      end

      def or(other)
        value || other.value ? True : False
      end
    end

    True = Boolean.new(true)
    False = Boolean.new(false)
  end
end
