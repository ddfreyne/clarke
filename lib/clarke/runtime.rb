# frozen_string_literal: true

module Clarke
  module Runtime
    class Function < Dry::Struct
      attribute :parameters, Dry::Types::Any
      attribute :body, Dry::Types::Any
      attribute :env, Dry::Types::Any

      def describe
        'function'
      end

      def self.describe
        'function'
      end

      def clarke_to_string
        '<function>'
      end

      def bind(instance)
        new_env = env.push
        new_env['this'] = instance
        Function.new(
          parameters: parameters,
          body:       body,
          env:        new_env,
        )
      end

      def call(arguments, evaluator)
        case body
        when Clarke::AST::Block
          new_env =
            env.merge(Hash[parameters.zip(arguments)])
          evaluator.visit_block(body, new_env)
        when Proc
          body.call(evaluator, env, *arguments)
        end
      end
    end

    Null = Object.new
    def Null.describe
      'null'
    end

    def Null.clarke_to_string
      'null'
    end

    def Null.inspect
      '<Null>'
    end

    Class = Struct.new(:name, :functions) do
      def describe
        'class'
      end

      def self.describe
        'class'
      end

      def clarke_to_string
        '<Class>'
      end
    end

    # TODO: remove props?
    Instance = Struct.new(:props, :klass) do
      def describe
        'instance'
      end

      def self.describe
        'instance'
      end

      def clarke_to_string
        '<Instance>'
      end
    end

    String = Struct.new(:value) do
      def describe
        'string'
      end

      def self.describe
        'string'
      end

      def clarke_to_string
        value
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

    Array = Struct.new(:values) do
      def describe
        'array'
      end

      def self.describe
        'array'
      end

      def clarke_to_string
        '[' + values.map(&:clarke_to_string).join(',') + ']'
      end

      def add(value)
        values << value
      end

      def each
        values.each { |e| yield(e) }
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
