# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveExplicitTypes < Clarke::Visitor
      def visit_fun_def(expr)
        expr.params.each do |param|
          sym = expr.scope.resolve(param.name)
          sym.type = expr.scope.resolve(param.type_name)
        end

        super
      end

      def visit_lambda_def(expr)
        expr.params.each do |param|
          sym = expr.scope.resolve(param.name)
          sym.type = expr.scope.resolve(param.type_name)
        end

        super
      end

      def visit_prop_decl(expr)
        type = expr.scope.resolve(expr.type_name)
        type = Clarke::Sym::InstanceType.new(type) if type.is_a?(Clarke::Sym::Class)

        sym = expr.scope.resolve(expr.name)
        sym.type = type

        super
      end
    end
  end
end
