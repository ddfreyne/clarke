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

    ###

    class AbstractNode < Dry::Struct
      attribute :context, Dry::Types::Any
      attr_reader :type

      include Printable
      include WithScope

      def type=(type)
        unless type.is_a?(Clarke::Sym::Type) || type.nil?
          raise ArgumentError, "Expected Clarke::Sym::Type or nil, but got #{type.class.inspect}"
        end

        @type = type
      end
    end

    ###

    class Param < AbstractNode
      attribute :name, Types::Strict::String
      attribute :type_name, Types::Strict::String
      attr_accessor :type_sym

      def ast_name
        'Param'
      end

      def ast_children
        [name, type_name]
      end
    end

    ###

    class Assignment < AbstractNode
      attribute :var_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any
      attr_accessor :var_name_sym

      def ast_name
        'Assignment'
      end

      def ast_children
        [var_name, expr]
      end
    end

    class BinOp < AbstractNode
      attribute :lhs, Dry::Types::Any
      attribute :rhs, Dry::Types::Any

      def ast_name
        'BinOp'
      end

      def ast_children
        [lhs, rhs]
      end
    end

    class Block < AbstractNode
      attribute :exprs, Dry::Types::Any

      def ast_name
        'Block'
      end

      def ast_children
        [*exprs]
      end
    end

    class ClassDef < AbstractNode
      attribute :name, Dry::Types::Any
      attribute :members, Dry::Types::Any
      attr_accessor :name_sym

      def ast_name
        'ClassDef'
      end

      def ast_children
        [name, members]
      end
    end

    class FalseLit < AbstractNode
      def ast_name
        'FalseLit'
      end

      def ast_children
        []
      end
    end

    class FunCall < AbstractNode
      attribute :base, Dry::Types::Any
      attribute :arguments, Dry::Types::Any
      attr_accessor :base_sym

      def ast_name
        'FunCall'
      end

      def ast_children
        [base, *arguments]
      end
    end

    class FunDef < AbstractNode
      attribute :name, Dry::Types::Any
      attribute :params, Types::Strict::Array.of(Param)
      attribute :ret_type_name, Types::Strict::String
      attribute :body, Dry::Types::Any
      attr_accessor :name_sym
      attr_accessor :params_syms

      def ast_name
        'FunDef'
      end

      def ast_children
        [name, params, body]
      end
    end

    class GetProp < AbstractNode
      attribute :base, Dry::Types::Any
      attribute :name, Dry::Types::Any

      def ast_name
        'GetProp'
      end

      def ast_children
        [base, name]
      end
    end

    class If < AbstractNode
      attribute :cond, Dry::Types::Any
      attribute :body_true, Dry::Types::Any
      attribute :body_false, Dry::Types::Any

      def ast_name
        'If'
      end

      def ast_children
        [cond, body_true, body_false]
      end
    end

    class IntegerLit < AbstractNode
      attribute :value, Types::Strict::Integer

      def ast_name
        'IntegerLit'
      end

      def ast_children
        [value]
      end
    end

    class LambdaDef < AbstractNode
      attribute :params, Types::Strict::Array.of(Param)
      attribute :ret_type_name, Types::Strict::String
      attribute :body, Dry::Types::Any

      def ast_name
        'LambdaDef'
      end

      def ast_children
        [params, body]
      end
    end

    class SetProp < AbstractNode
      attribute :base, Dry::Types::Any
      attribute :name, Dry::Types::Any
      attribute :value, Dry::Types::Any

      def ast_name
        'SetProp'
      end

      def ast_children
        [base, name, value]
      end
    end

    class StringLit < AbstractNode
      attribute :value, Dry::Types::Any

      def ast_name
        'String'
      end

      def ast_children
        [value]
      end
    end

    class TrueLit < AbstractNode
      def ast_name
        'TrueLit'
      end

      def ast_children
        []
      end
    end

    class Op < AbstractNode
      attribute :name, Dry::Types::Any

      def ast_name
        'Op'
      end

      def ast_children
        [name]
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

    class OpSeq < AbstractNode
      attribute :seq, Dry::Types::Any

      def ast_name
        'OpSeq'
      end

      def ast_children
        [*seq]
      end
    end

    class PropDecl < AbstractNode
      attribute :name, Dry::Types::Any
      attribute :type_name, Dry::Types::Any

      def ast_name
        'PropDecl'
      end

      def ast_children
        [name]
      end
    end

    class Ref < AbstractNode
      attribute :name, Types::Strict::String
      attr_accessor :name_sym

      def ast_name
        'Ref'
      end

      def ast_children
        [name]
      end
    end

    class VarDef < AbstractNode
      attribute :var_name, Dry::Types::Any
      attribute :expr, Dry::Types::Any
      attr_accessor :var_name_sym

      def ast_name
        'VarDef'
      end

      def ast_children
        [var_name, expr]
      end
    end
  end
end
