# frozen_string_literal: true

module Clarke
  class TransformerStack
    def initialize(transformers)
      @transformers = transformers
    end

    def visit_exprs(exprs)
      @transformers.reduce(exprs) { |a, e| e.visit_exprs(a) }
    end
  end
end
