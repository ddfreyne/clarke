# frozen_string_literal: true

module Clarke
  def self.run(code, verbose:)
    # Parse
    res = Clarke::Grammar::PROGRAM.apply(code)
    if res.is_a?(DParse::Failure)
      raise Clarke::Language::SyntaxError.new(res.pretty_message)
    end
    exprs = res.data

    # Simplify
    exprs = Clarke::Passes::SimplifyOpSeq.new.visit_exprs(exprs)

    # Transform
    global_names = Clarke::Evaluator::INITIAL_ENV.keys
    local_depths = {}
    Clarke::Passes::BuildScopes.new(global_names, local_depths).visit_exprs(exprs)

    # Debug
    exprs.each { |e| p e } if verbose

    # Run
    evaluator = Clarke::Evaluator.new(local_depths)
    evaluator.visit_exprs(exprs)
  end
end

require_relative 'clarke/grammar'
require_relative 'clarke/ast'
require_relative 'clarke/language'
require_relative 'clarke/runtime'
require_relative 'clarke/util'

require_relative 'clarke/visitor'
require_relative 'clarke/transformer'
require_relative 'clarke/evaluator'

require_relative 'clarke/passes'
