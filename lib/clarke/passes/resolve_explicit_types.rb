# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveExplicitTypes < Clarke::Visitor
      def initialize(global_scope)
        @global_scope = global_scope
      end

      def visit_class_def(expr)
        expr.type = @global_scope.resolve('void')
        super
      end

      def visit_false_lit(expr)
        expr.type = @global_scope.resolve('bool')
        super
      end

      def visit_fun_def(expr)
        expr.type = @global_scope.resolve('void')
        super
      end

      def visit_integer_lit(expr)
        expr.type = @global_scope.resolve('int')
        super
      end

      def visit_param(expr)
        super

        sym = expr.scope.resolve(expr.name)
        sym.type = expr.scope.resolve(expr.type_name)
        expr.type = sym.type
      end

      def visit_ivar_decl(expr)
        type = expr.scope.resolve(expr.type_name)
        type = Clarke::Sym::InstanceType.new(type) if type.is_a?(Clarke::Sym::Class)

        sym = expr.scope.resolve(expr.name)
        sym.type = type

        expr.type = @global_scope.resolve('void')

        super
      end

      def visit_setter(expr)
        expr.type = @global_scope.resolve('void')
        super
      end

      def visit_string_lit(expr)
        expr.type = @global_scope.resolve('string')
        super
      end

      def visit_true_lit(expr)
        expr.type = @global_scope.resolve('bool')
        super
      end
    end
  end
end
