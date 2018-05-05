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

      def visit_class_def(expr)
        expr.name_sym = expr.scope.resolve(expr.name)
        super
      end

      def visit_fun_def(expr)
        expr.name_sym = expr.scope.resolve(expr.name)
        expr.params.each do |param|
          param.type_sym = expr.scope.resolve(param.type_name)
        end
        super
      end
    end
  end
end
