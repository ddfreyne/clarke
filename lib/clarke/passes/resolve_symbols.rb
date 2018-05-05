# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveSymbols < Clarke::Visitor
      def visit_ref(expr)
        expr.name_sym = expr.scope.resolve(expr.name)
        super
      end

      def visit_var_def(expr)
        expr.variable_name_sym = expr.scope.resolve(expr.variable_name)
        super
      end

      def visit_assignment(expr)
        expr.variable_name_sym = expr.scope.resolve(expr.variable_name)
        super
      end
    end
  end
end
