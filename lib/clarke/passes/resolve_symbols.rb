# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveSymbols < Clarke::Visitor
      def initialize(global_scope)
        @global_scope = global_scope
      end

      def visit_assignment(expr)
        super

        expr.type = expr.expr.type
        assert_typed(expr)

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.type
      end

      def visit_block(expr)
        super

        # FIXME: handle empty block
        expr.type = expr.exprs.last.type
        assert_typed(expr)
      end

      def visit_class_def(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
      end

      def visit_false_lit(expr)
        super

        expr.type = @global_scope.resolve('bool')
        assert_typed(expr)
      end

      def visit_fun_call(expr)
        super

        # TODO: verify callable
        # TODO: verify arg count
        # TODO: handle klass

        expr.type = expr.base.type.ret_type
        assert_typed(expr)
      end

      def visit_fun_def(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
        expr.params.each do |param|
          param.type_sym = expr.scope.resolve(param.type_name)
        end
      end

      def visit_integer_lit(expr)
        super

        expr.type = @global_scope.resolve('int')
        assert_typed(expr)
      end

      def visit_lambda_def(expr)
        expr.params.each do |param|
          param_sym = expr.scope.resolve(param.name)
          type_sym = expr.scope.resolve(param.type_name)
          param.type_sym = type_sym
          param_sym.type = type_sym
        end

        super

        expr.type = Clarke::Sym::Fun.new(
          '(anon)', expr.params.count, expr.body.type)
        assert_typed(expr)
      end

      def visit_op_add(expr)
        super

        types = [expr.lhs, expr.rhs].map(&:type).uniq
        if [expr.lhs, expr.rhs].map(&:type).uniq.size != 1
          # TODO get a proper exception
          raise Clarke::Errors::GenericError.new("Left-hand side and right-hand side have distinct types (“#{expr.lhs.type}” and “#{expr.rhs.type}”, respectively)", expr: expr)
        end

        expr.type = types.first
        assert_typed(expr)
      end

      def visit_ref(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
        expr.type = expr.name_sym.type
        assert_typed(expr)
      end

      def visit_true_lit(expr)
        super

        expr.type = @global_scope.resolve('bool')
        assert_typed(expr)
      end

      def visit_var_def(expr)
        super

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.expr.type

        expr.type = expr.expr.type
        assert_typed(expr)
      end

      def assert_typed(expr)
        return if expr.type

        raise Clarke::Errors::GenericError.new("could not type #{expr.inspect}", expr: expr)
      end
    end
  end
end
