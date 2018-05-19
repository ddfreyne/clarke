# frozen_string_literal: true

module Clarke
  module Parser
    # Convert
    #
    #   let x = fun(…) { … }
    #
    # into
    #
    #   fun x(…) { … }
    #
    # so that it can be called recursively
    class LiftLetLambdas < Clarke::Transformer
      def visit_var_def(expr)
        if expr.expr.is_a?(Clarke::AST::LambdaDef)
          Clarke::AST::FunDef.new(
            name:          expr.var_name,
            params:        expr.expr.params,
            ret_type_name: expr.expr.ret_type_name,
            body:          visit_expr(expr.expr.body),
            context:       expr.context,
          )
        else
          super
        end
      end
    end
  end
end
