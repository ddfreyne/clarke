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
    exprs = Clarke::Passes::SimplifyOpSeq.new.visit_exprs(exprs)

    # Collect symbols
    initial_env = Clarke::Interpreter::Init.generate
    pass = Clarke::Passes::CollectSymbols.new(initial_env)
    pass.visit_exprs(exprs)
    global_scope = pass.scope

    # Resolve symbols
    pass = Clarke::Passes::ResolveSymbols.new
    pass.visit_exprs(exprs)

    # Debug
    exprs.each { |e| p e } if verbose

    # Run
    evaluator = Clarke::Interpreter::Evaluator.new(global_scope)
    evaluator.visit_exprs(exprs)
  end
end

module Clarke
  module Util
  end
end

require_relative 'clarke/util/env'
require_relative 'clarke/util/context'
require_relative 'clarke/util/num2string'
require_relative 'clarke/util/shunting_yard'
require_relative 'clarke/util/symbol_table'

require_relative 'clarke/grammar'
require_relative 'clarke/ast'
require_relative 'clarke/language'

require_relative 'clarke/visitor'
require_relative 'clarke/transformer'

module Clarke
  module Passes
  end
end

require_relative 'clarke/passes/collect_symbols'
require_relative 'clarke/passes/resolve_symbols'
require_relative 'clarke/passes/simplify_op_seq'

module Clarke
  module Interpreter
  end
end

require_relative 'clarke/interpreter/runtime'
require_relative 'clarke/interpreter/init'
require_relative 'clarke/interpreter/evaluator'
