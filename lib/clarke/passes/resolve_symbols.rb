# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveSymbols < Clarke::Visitor
      def visit_ref(expr)
        expr.name_sym = expr.scope.resolve(expr.name)
        super
      end

      def visit_var_def(expr)
        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        super
      end

      def visit_assignment(expr)
        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        super
      end
    end
  end
end
