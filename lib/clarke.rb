# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'
require 'singleton'

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

    # Determine lookup depths
    global_names = Clarke::Interpreter::Evaluator::INITIAL_ENV.keys
    local_depths = {}
    Clarke::Passes::BuildScopes.new(global_names, local_depths).visit_exprs(exprs)

    # Debug
    exprs.each { |e| p e } if verbose

    # Run
    evaluator = Clarke::Interpreter::Evaluator.new(local_depths)
    evaluator.visit_exprs(exprs)
  end
end

require_relative 'clarke/grammar'
require_relative 'clarke/ast'
require_relative 'clarke/language'
require_relative 'clarke/util'

require_relative 'clarke/visitor'
require_relative 'clarke/transformer'

module Clarke
  module Passes
  end
end

require_relative 'clarke/passes/build_scopes'
require_relative 'clarke/passes/simplify_op_seq'

module Clarke
  module Interpreter
  end
end

require_relative 'clarke/interpreter/runtime'
require_relative 'clarke/interpreter/evaluator'
