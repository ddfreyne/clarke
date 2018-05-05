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

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.type
      end

      def visit_class_def(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
      end

      def visit_fun_call(expr)
        super

        # TODO: verify callable
        # TODO: verify arg count
        # TODO: handle klass

        expr.type = expr.base.type.ret_type
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
      end

      def visit_lambda_def(expr)
        super

        expr.params.each do |param|
          param.type_sym = expr.scope.resolve(param.type_name)
        end

        expr.type = Clarke::Sym::Fun.new('(anon)', expr.params.count)
      end

      def visit_op_add(expr)
        super

        types = [expr.lhs, expr.rhs].map(&:type).uniq
        if [expr.lhs, expr.rhs].map(&:type).uniq.size != 1
          # TODO get a proper exception
          raise "lhs and rhs have distinct types #{types.inspect}"
        end

        expr.type = types.first
      end

      def visit_ref(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
        expr.type = expr.name_sym.type
      end

      def visit_var_def(expr)
        super

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.expr.type

        expr.type = expr.expr.type
      end
    end
  end
end
