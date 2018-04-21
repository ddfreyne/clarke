# frozen_string_literal: true

module Clarke
  class TransformerStack
    def initialize(transformers)
      @transformers = transformers
    end

    def transform_exprs(exprs)
      @transformers.reduce(exprs) { |a, e| e.transform_exprs(a) }
    end
  end
end
