# frozen_string_literal: true

module Clarke
  module Errors
    class Error < StandardError
      attr_accessor :expr

      def initialize(expr = nil)
        @expr = expr
      end

      def fancy_message
        return message if @expr.nil?

        ctx = @expr.context

        lines = []
        lines << "line #{ctx.from.line + 1}: #{message}"
        lines << ''
        lines << (ctx.input.lines[ctx.from.line] || '').rstrip
        lines << "\e[31m" + ' ' * ctx.from.column + ('〰' * ((ctx.to.column - ctx.from.column + 1) / 2)) + "\e[0m"
        lines.join("\n")
      end
    end

    class SyntaxError < StandardError
    end

    class GenericError < Error
      attr_reader :message

      def initialize(message, expr: nil)
        super(expr)

        @message = message
      end
    end

    class NotCallable < GenericError
      def initialize(expr: nil)
        super(message, expr: expr)
      end

      def message
        'Can only call functions and classes; this thing is neither'
      end
    end

    class NotGettable < GenericError
      def initialize(expr: nil)
        super(message, expr: expr)
      end

      def message
        'Can only get properties from instances; this thing isn’t one'
      end
    end

    class UntypedArguments < GenericError
      def initialize(missing)
        @missing = missing

        super(message)
      end

      def message
        "The argument(s) #{@missing.map(&:name).join(', ')} have no types"
      end
    end

    class BinOpTypeMismatch < GenericError
      def initialize(expr)
        @expr = expr
        super(message, expr: expr)
      end

      def message
        "Left-hand side and right-hand side have distinct types (“#{@expr.lhs.type}” and “#{@expr.rhs.type}”, respectively)"
      end
    end

    class IfTypeMismatch < GenericError
      def initialize(expr)
        @expr = expr
        super(message, expr: expr)
      end

      def message
        "True and false bodies have distinct types (“#{@expr.body_true.type}” and “#{@expr.body_false.type}”, respectively)"
      end
    end

    class ArgumentTypeMismatch < GenericError
      def initialize(param_type, arg_type)
        @param_type = param_type
        @arg_type = arg_type

        super(message)
      end

      def message
        "Argument has type #{@arg_type.inspect}, which is incompatible with parameter type #{@param_type.inspect}"
      end
    end

    class NameError < Error
      attr_reader :name

      def initialize(name)
        super(nil)

        @name = name
      end

      def message
        "#{@name}: no such name"
      end
    end

    class DoubleNameError < Error
      attr_reader :name

      def initialize(name)
        super(nil)

        @name = name
      end

      def message
        "#{@name}: already defined"
      end
    end

    class TypeError < Error
      attr_reader :val, :klass

      def initialize(val, classes, expr)
        super(expr)

        @val = val
        @classes = classes
      end

      def message
        "expected #{@classes.map(&:inspect).join(' or ')}, but got #{@val.inspect}"
      end
    end

    class ArgumentCountError < Error
      attr_reader :actual
      attr_reader :expected

      def initialize(actual:, expected:)
        super(nil)

        @actual = actual
        @expected = expected
      end

      def message
        "wrong number of arguments: expected #{@expected}, but got #{@actual}"
      end
    end
  end
end
