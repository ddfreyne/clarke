# frozen_string_literal: true

module Clarke
  module AST
    module Printable
      def inspect
        to_s
      end

      def to_s(short: false)
        children_lines = ast_children.map(&:to_s).join("\n").lines

        res = +''
        res << '(' << ast_name
        if ast_children.empty?
        elsif children_lines.size == 1 && !ast_children[0].respond_to?(:ast_children)
          res << ' '
          res << children_lines.first
        elsif short
          res << ' …'
        else
          res << "\n"
          res << children_lines.map { |l| '  ' + l }.join('')
        end
        res << ')'
        res
      end
    end

    module Types
      include Dry::Types.module
    end

    module WithScope
      attr_accessor :scope

      def replace_scope(scope)
        self.scope = scope
      end
    end

    class NameAndType < Dry::Struct
      attribute :name, Types::String
      attribute :type, Types::String
    end

    class FalseLit < Dry::Struct
      attribute :context, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'FalseLit'
      end

      def ast_children
        []
      end
    end

    class TrueLit < Dry::Struct
      attribute :context, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'TrueLit'
      end

      def ast_children
        []
      end
    end

    class StringLit < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :value, Dry::Types::Any

      include WithScope
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
      attribute :var_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any
      attr_accessor :var_name_sym

      include WithScope
      include Printable

      def ast_name
        'Assignment'
      end

      def ast_children
        [var_name, expr]
      end
    end

    class VarDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :var_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any
      attr_accessor :var_name_sym

      include WithScope
      include Printable

      def ast_name
        'VarDef'
      end

      def ast_children
        [var_name, expr]
      end
    end

    class GetProp < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :base, Dry::Types::Any
      attribute :name, Dry::Types::Any

      include WithScope
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

      include WithScope
      include Printable

      def ast_name
        'SetProp'
      end

      def ast_children
        [base, name, value]
      end
    end

    class FunCall < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :base, Dry::Types::Any
      attribute :arguments, Dry::Types::Any
      attr_accessor :base_sym

      include WithScope
      include Printable

      def ast_name
        'FunCall'
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

      include WithScope
      include Printable

      def ast_name
        'If'
      end

      def ast_children
        [cond, body_true, body_false]
      end
    end

    class IntegerLit < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :value, Types::Strict::Integer

      include WithScope
      include Printable

      def ast_name
        'IntegerLit'
      end

      def ast_children
        [value]
      end
    end

    class LambdaDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :params, Types::Strict::Array.of(NameAndType)
      attribute :body, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'LambdaDef'
      end

      def ast_children
        [params, body]
      end
    end

    class FunDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :params, Types::Strict::Array.of(NameAndType)
      attribute :body, Dry::Types::Any
      attr_accessor :name_sym

      include WithScope
      include Printable

      def ast_name
        'FunDef'
      end

      def ast_children
        [name, params, body]
      end
    end

    class ClassDef < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :members, Dry::Types::Any
      attr_accessor :name_sym

      include WithScope
      include Printable

      def ast_name
        'ClassDef'
      end

      def ast_children
        [name, members]
      end
    end

    class Op < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'Op'
      end

      def ast_children
        [name]
      end
    end

    class BinOp < ::Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :lhs, Dry::Types::Any
      attribute :rhs, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'BinOp'
      end

      def ast_children
        [lhs, rhs]
      end
    end

    class OpAdd < BinOp
      def ast_name
        'OpAdd'
      end
    end

    class OpSubtract < BinOp
      def ast_name
        'OpSubtract'
      end
    end

    class OpMultiply < BinOp
      def ast_name
        'OpMultiply'
      end
    end

    class OpDivide < BinOp
      def ast_name
        'OpDivide'
      end
    end

    class OpExponentiate < BinOp
      def ast_name
        'OpExponentiate'
      end
    end

    class OpEq < BinOp
      def ast_name
        'OpEq'
      end
    end

    class OpGt < BinOp
      def ast_name
        'OpGt'
      end
    end

    class OpLt < BinOp
      def ast_name
        'OpLt'
      end
    end

    class OpGte < BinOp
      def ast_name
        'OpGte'
      end
    end

    class OpLte < BinOp
      def ast_name
        'OpLte'
      end
    end

    class OpAnd < BinOp
      def ast_name
        'OpAnd'
      end
    end

    class OpOr < BinOp
      def ast_name
        'OpOr'
      end
    end

    class OpSeq < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :seq, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'OpSeq'
      end

      def ast_children
        [*seq]
      end
    end

    class PropDecl < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'PropDecl'
      end

      def ast_children
        [name]
      end
    end

    class Block < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :exprs, Dry::Types::Any

      include WithScope
      include Printable

      def ast_name
        'Block'
      end

      def ast_children
        [*exprs]
      end
    end

    class Ref < Dry::Struct
      attribute :context, Dry::Types::Any
      attribute :name, Types::Strict::String
      attr_accessor :name_sym

      include WithScope
      include Printable

      def ast_name
        'Ref'
      end

      def ast_children
        [name]
      end
    end
  end
end
