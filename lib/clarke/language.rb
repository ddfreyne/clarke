# frozen_string_literal: true

module Clarke
  module Language
    class Sym
      attr_reader :name

      def initialize(name)
        @name = name.to_s
      end

      def inspect
        id = Clarke::Util::Num2String.call(object_id)
        "<#{self.class.to_s.sub(/^.*::/, '')} #{@name} #{id}>"
      end

      def to_s
        inspect
      end
    end

    class VarSym < Sym
    end

    class ClassSym < Sym
    end

    class FunSym < Sym
    end

    class PropSym < Sym
    end

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
        lines << "\e[31m" + ' ' * ctx.from.column + ('〰' * ((ctx.to.column - ctx.from.column) / 2)) + "\e[0m"
        lines.join("\n")
      end
    end

    class SyntaxError < StandardError
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

    class TypeError < Error
      attr_reader :val, :klass

      def initialize(val, classes, expr)
        super(expr)

        @val = val
        @classes = classes
      end

      def message
        "expected #{@classes.map(&:describe).join(' or ')}, but got #{@val.describe}"
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
