# frozen_string_literal: true

module Clarke
  def self.run(exprs, verbose:)
    # Transform
    local_depths = {}
    stack = Clarke::TransformerStack.new([
      Clarke::Transformers::SimplifyOpSeq.new,
      Clarke::Transformers::BuildScopes.new(local_depths),
    ],)
    transformed_exprs = stack.transform_exprs(exprs)

    # Debug
    transformed_exprs.each { |e| p e } if verbose

    # Run
    evaluator = Clarke::Evaluator.new(local_depths)
    evaluator.eval_exprs(transformed_exprs)
  end
end

require_relative 'clarke/grammar'
require_relative 'clarke/ast'
require_relative 'clarke/language'
require_relative 'clarke/runtime'
require_relative 'clarke/evaluator'
require_relative 'clarke/transformer'
require_relative 'clarke/transformer_stack'
require_relative 'clarke/transformers'
require_relative 'clarke/util'
