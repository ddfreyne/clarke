# frozen_string_literal: true

module Clarke
  module AST
    module Printable
      def inspect
        to_s
      end

      def to_s
        children_lines = ast_children.map(&:to_s).join("\n").lines

        res = +''
        res << '(' << ast_name
        if ast_children.empty?
        elsif ast_children.all? { |c| !c.respond_to?(:ast_children) || c.ast_children.empty? }
          res << ' '
          res << children_lines.first
        else
          res << "\n"
          res << children_lines.map { |l| '  ' + l }.join('')
        end
        res << ')'
        res
      end
    end

    class Context
      attr_reader :input
      attr_reader :from
      attr_reader :to

      def initialize(input:, from:, to:)
        @input = input
        @from = from
        @to = to
      end
    end

    FalseLiteral = Struct.new(:context) do
      include Printable

      def ast_name
        'FalseLiteral'
      end

      def ast_children
        []
      end
    end

    TrueLiteral = Struct.new(:context) do
      include Printable

      def ast_name
        'TrueLiteral'
      end

      def ast_children
        []
      end
    end

    Assignment = Struct.new(:variable_name, :expr, :context) do
      include Printable

      def ast_name
        'Assignment'
      end

      def ast_children
        [variable_name, expr]
      end
    end

    FunctionCall = Struct.new(:name, :arguments, :context) do
      include Printable

      def ast_name
        'FunctionCall'
      end

      def ast_children
        [name, *arguments]
      end
    end

    If = Struct.new(:cond, :body_true, :body_false, :context) do
      include Printable

      def ast_name
        'If'
      end

      def ast_children
        [cond, body_true, body_false]
      end
    end

    IntegerLiteral = Struct.new(:value, :context) do
      include Printable

      def ast_name
        'IntegerLiteral'
      end

      def ast_children
        [value]
      end
    end

    LambdaDef = Struct.new(:argument_names, :body, :context) do
      include Printable

      def ast_name
        'LambdaDef'
      end

      def ast_children
        [argument_names, body]
      end
    end

    Op = Struct.new(:name, :context) do
      include Printable

      def ast_name
        'Op'
      end

      def ast_children
        [name]
      end
    end

    OpSeq = Struct.new(:seq, :context) do
      include Printable

      def ast_name
        'OpSeq'
      end

      def ast_children
        [*seq]
      end
    end

    Scope = Struct.new(:exprs, :context) do
      include Printable

      def ast_name
        'Scope'
      end

      def ast_children
        [*exprs]
      end
    end

    ScopedLet = Struct.new(:variable_name, :expr, :body, :context) do
      include Printable

      def ast_name
        'ScopedLet'
      end

      def ast_children
        [variable_name, expr, body]
      end
    end

    Var = Struct.new(:name, :context) do
      include Printable

      def ast_name
        'Var'
      end

      def ast_children
        [name]
      end
    end
  end
end
