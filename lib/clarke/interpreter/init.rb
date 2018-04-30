# frozen_string_literal: true

module Clarke
  module Interpreter
    class Init
      CONTENTS = {
        'print' => Clarke::Interpreter::Runtime::Function.new(
          parameters: %w[a],
          body: lambda do |_ev, _env, _scope, _expr, a|
            puts(a.clarke_to_string)
            Clarke::Interpreter::Runtime::Null.instance
          end,
          env: Clarke::Util::Env.new,
          scope: Clarke::Util::SymbolTable.new,
        ),

        'Array' => Clarke::Interpreter::Runtime::Class.new(
          name: 'Array',
          functions: {
            init: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[],
              body: lambda do |_ev, env, scope, expr|
                this_sym = scope.resolve('this')
                this = env.fetch(this_sym, expr: expr)
                this.props[:contents] = []
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),

            add: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[elem],
              body: lambda do |_ev, env, scope, expr, elem|
                this_sym = scope.resolve('this')
                this = env.fetch(this_sym, expr: expr)
                this.props[:contents] << elem
                elem
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),

            each: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[fn],
              body: lambda do |ev, env, scope, expr, fn|
                this_sym = scope.resolve('this')
                this = env.fetch(this_sym, expr: expr)

                param_syms = fn.parameters.map do |e|
                  fn.body.scope.resolve(e)
                end

                this.props[:contents].each do |elem|
                  new_env =
                    fn
                    .env
                    .merge(Hash[param_syms.zip([elem])])
                  ev.visit_block(fn.body, new_env)
                end
                Clarke::Interpreter::Runtime::Null.instance
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),
          },
        ),
      }.freeze
    end
  end
end
