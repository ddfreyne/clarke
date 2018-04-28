# frozen_string_literal: true

module Clarke
  module Passes
    class SimplifyOpSeq < Clarke::Transformer
      def visit_op_seq(expr)
        if expr.seq.size == 1
          visit_expr(expr.seq.first)
        else
          super
        end
      end
    end
  end
end
