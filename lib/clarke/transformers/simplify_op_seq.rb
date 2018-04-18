# frozen_string_literal: true

module Clarke
  module Transformers
    class SimplifyOpSeq < Clarke::Transformer
      def transform_op_seq(expr)
        if expr.seq.size == 1
          transform_expr(expr.seq.first)
        else
          super
        end
      end
    end
  end
end
