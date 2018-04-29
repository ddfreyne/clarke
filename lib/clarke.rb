# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'
require 'singleton'

module Clarke
  def self.run(code, mode: :eval, verbose:)
    # Parse
    res = Clarke::Parser::Grammar::PROGRAM.apply(code)
    if res.is_a?(DParse::Failure)
      raise Clarke::Errors::SyntaxError.new(res.pretty_message)
    end
    exprs = res.data

    # Simplify
    exprs = Clarke::Parser::SimplifyOpSeq.new.visit_exprs(exprs)
    exprs = Clarke::Parser::SimplifyOpSeq.new.visit_exprs(exprs)
    exprs = Clarke::Parser::LiftLetLambdas.new.visit_exprs(exprs)

    # Collect symbols
    init = Clarke::Interpreter::Init.instance
    pass = Clarke::Sema::CollectSymbols.new(init.scope)
    pass.visit_exprs(exprs)
    global_scope = pass.scope

    # Resolve explicit types
    pass = Clarke::Sema::ResolveExplicitTypes.new(global_scope)
    pass.visit_exprs(exprs)

    # Resolve implicit types
    pass = Clarke::Sema::ResolveImplicitTypes.new(global_scope)
    pass.visit_exprs(exprs)

    # Debug
    exprs.each { |e| p e } if verbose

    # Typecheck
    pass = Clarke::Sema::Typecheck.new
    pass.visit_exprs(exprs)

    # Generate initial env
    initial_env = Clarke::Util::Env.new
    init.envish.each_pair do |sym, val|
      initial_env[sym] = val
    end

    # Run
    case mode
    when :eval
      evaluator = Clarke::Interpreter::Evaluator.new(global_scope, initial_env)
      evaluator.visit_exprs(exprs)
    when :resolve
      exprs
    else
      raise ArgumentError, "Invalid mode: #{mode}"
    end
  end

  def self.transpile_to_ruby(code, verbose:)
    # Parse
    res = Clarke::Parser::Grammar::PROGRAM.apply(code)
    if res.is_a?(DParse::Failure)
      raise Clarke::Errors::SyntaxError.new(res.pretty_message)
    end
    exprs = res.data

    # Simplify
    exprs = Clarke::Parser::SimplifyOpSeq.new.visit_exprs(exprs)
    exprs = Clarke::Parser::SimplifyOpSeq.new.visit_exprs(exprs)
    exprs = Clarke::Parser::LiftLetLambdas.new.visit_exprs(exprs)

    # Collect symbols
    init = Clarke::Interpreter::Init.instance
    pass = Clarke::Sema::CollectSymbols.new(init.scope)
    pass.visit_exprs(exprs)
    global_scope = pass.scope

    # Resolve explicit types
    pass = Clarke::Sema::ResolveExplicitTypes.new(global_scope)
    pass.visit_exprs(exprs)

    # Resolve implicit types
    pass = Clarke::Sema::ResolveImplicitTypes.new(global_scope)
    pass.visit_exprs(exprs)

    # Typecheck
    pass = Clarke::Sema::Typecheck.new
    pass.visit_exprs(exprs)

    # Debug
    exprs.each { |e| p e } if verbose

    # Run
    Clarke::Transpilers::Ruby.new(exprs, global_scope).run
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

require_relative 'clarke/ast'
require_relative 'clarke/sym'
require_relative 'clarke/errors'
require_relative 'clarke/scope'

require_relative 'clarke/common/visitor'
require_relative 'clarke/common/transformer'

require_relative 'clarke/parser/grammar'
require_relative 'clarke/parser/simplify_op_seq'
require_relative 'clarke/parser/lift_let_lambdas'

require_relative 'clarke/sema/collect_symbols'
require_relative 'clarke/sema/resolve_explicit_types'
require_relative 'clarke/sema/resolve_implicit_types'
require_relative 'clarke/sema/typecheck'

module Clarke
  module Interpreter
  end
end

require_relative 'clarke/interpreter/runtime'
require_relative 'clarke/interpreter/init'
require_relative 'clarke/interpreter/evaluator'

module Clarke
  module Transpilers
  end
end

require_relative 'clarke/transpilers/ruby'
