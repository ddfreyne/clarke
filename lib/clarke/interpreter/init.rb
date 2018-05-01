# frozen_string_literal: true

module Clarke
  module Interpreter
    class Init
      def self.generate
        @generate ||= begin
          print = Clarke::Interpreter::Runtime::Fun.new(
            env: Clarke::Util::Env.new,
            scope: Clarke::Util::SymbolTable.new,
            parameters: %w[a],
            body: lambda do |_ev, _env, _scope, a|
              puts(a.clarke_to_string)
              Clarke::Interpreter::Runtime::Null.instance
            end,
          )

          array_init = Clarke::Interpreter::Runtime::Fun.new(
            env: Clarke::Util::Env.new,
            scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            parameters: %w[],
            body: lambda do |_ev, env, scope|
              this_sym = scope.resolve('this')
              this = env.fetch(this_sym)
              this.internal_state[:contents] = []
            end,
          )

          array_add = Clarke::Interpreter::Runtime::Fun.new(
            env: Clarke::Util::Env.new,
            scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            parameters: %w[elem],
            body: lambda do |_ev, env, scope, elem|
              this_sym = scope.resolve('this')
              this = env.fetch(this_sym)
              this.internal_state[:contents] << elem
              elem
            end,
          )

          array_each = Clarke::Interpreter::Runtime::Fun.new(
            env: Clarke::Util::Env.new,
            scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            parameters: %w[fn],
            body: lambda do |ev, env, scope, fn|
              this_sym = scope.resolve('this')
              this = env.fetch(this_sym)

              param_syms = fn.parameters.map do |e|
                fn.body.scope.resolve(e)
              end

              this.internal_state[:contents].each do |elem|
                new_env =
                  fn
                  .env
                  .merge(Hash[param_syms.zip([elem])])
                ev.visit_block(fn.body, new_env)
              end
              Clarke::Interpreter::Runtime::Null.instance
            end,
          )

          array_class_scope =
            Clarke::Util::SymbolTable
            .new
            .define(Clarke::Language::VarSym.new('this'))
            .define(Clarke::Language::VarSym.new('init'))
            .define(Clarke::Language::VarSym.new('add'))
            .define(Clarke::Language::VarSym.new('each'))

          array_class_env =
            Clarke::Util::Env.new.tap do |env|
              env[array_class_scope.resolve('init')] = array_init
              env[array_class_scope.resolve('add')] = array_add
              env[array_class_scope.resolve('each')] = array_each
            end

          array_class = Clarke::Interpreter::Runtime::Class.new(
            name: 'Array',
            env: array_class_env,
            scope: array_class_scope,
          )

          {
            'print' => print,
            'Array' => array_class,
          }
        end
      end
    end
  end
end
