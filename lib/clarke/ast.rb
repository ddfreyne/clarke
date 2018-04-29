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
        elsif children_lines.size == 1 && !ast_children[0].respond_to?(:ast_children)
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

    module Types
      include Dry::Types.module
    end

    class FalseLiteral < Dry::Struct
      attribute :context, Dry::Types::Any

      include Printable

      def ast_name
        'FalseLiteral'
      end

      def ast_children
        []
      end
    end

    class TrueLiteral < Dry::Struct
      attribute :context, Dry::Types::Any

      include Printable

      def ast_name
        'TrueLiteral'
      end

      def ast_children
        []
      end
    end

    class StringLiteral < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :value, Dry::Types::Any

      include Printable

      def ast_name
        'String'
      end

      def ast_children
        [value]
      end
    end

    class Assignment < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :variable_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any

      include Printable

      def ast_name
        'Assignment'
      end

      def ast_children
        [variable_name, expr]
      end
    end

    class VarDecl < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :variable_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any

      include Printable

      def ast_name
        'VarDecl'
      end

      def ast_children
        [variable_name, expr]
      end
    end

    class GetProp < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :base, Dry::Types::Any
      attribute :name, Dry::Types::Any

      include Printable

      def ast_name
        'GetProp'
      end

      def ast_children
        [base, name]
      end
    end

    class SetProp < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :base, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :value, Dry::Types::Any

      include Printable

      def ast_name
        'SetProp'
      end

      def ast_children
        [base, name, value]
      end
    end

    class FunctionCall < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :base, Dry::Types::Any
      attribute :arguments, Dry::Types::Any

      include Printable

      def ast_name
        'FunctionCall'
      end

      def ast_children
        [base, *arguments]
      end
    end

    class If < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :cond, Dry::Types::Any
      attribute :body_true, Dry::Types::Any
      attribute :body_false, Dry::Types::Any

      include Printable

      def ast_name
        'If'
      end

      def ast_children
        [cond, body_true, body_false]
      end
    end

    class IntegerLiteral < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :value, Types::Strict::Int

      include Printable

      def ast_name
        'IntegerLiteral'
      end

      def ast_children
        [value]
      end
    end

    class LambdaDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :parameters, Types::Strict::Array.of(String)
      attribute :body, Dry::Types::Any

      include Printable

      def ast_name
        'LambdaDef'
      end

      def ast_children
        [parameters, body]
      end
    end

    class FunDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :parameters, Dry::Types::Any
      attribute :body, Dry::Types::Any

      include Printable

      def ast_name
        'FunDef'
      end

      def ast_children
        [name, parameters, body]
      end
    end

    class ClassDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :functions, Dry::Types::Any

      include Printable

      def ast_name
        'ClassDef'
      end

      def ast_children
        [name, functions]
      end
    end

    class Op < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any

      include Printable

      def ast_name
        'Op'
      end

      def ast_children
        [name]
      end
    end

    class OpSeq < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :seq, Dry::Types::Any

      include Printable

      def ast_name
        'OpSeq'
      end

      def ast_children
        [*seq]
      end
    end

    class Block < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :exprs, Dry::Types::Any

      include Printable

      def ast_name
        'Block'
      end

      def ast_children
        [*exprs]
      end
    end

    class Var < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Types::Strict::String

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
