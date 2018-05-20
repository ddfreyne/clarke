# frozen_string_literal: true

module Clarke
  module Interpreter
    class Init
      include Singleton

      attr_reader :envish
      attr_reader :scope

      def initialize
        any_type = Clarke::Sym::BuiltinType.new('any')
        auto_type = Clarke::Sym::BuiltinType.new('auto')
        bool_type = Clarke::Sym::BuiltinType.new('bool')
        int_type = Clarke::Sym::BuiltinType.new('int')
        string_type = Clarke::Sym::BuiltinType.new('string')
        void_type = Clarke::Sym::BuiltinType.new('void')

        print = Clarke::Interpreter::Runtime::Fun.new(
          env: Clarke::Util::Env.new,
          scope: Clarke::Scope::Local.new,
          params: %w[a],
          body: lambda do |_ev, _env, _scope, a|
            puts(a.clarke_to_string)
            Clarke::Interpreter::Runtime::Null.instance
          end,
        )

        array_init = Clarke::Interpreter::Runtime::Fun.new(
          env: Clarke::Util::Env.new,
          scope: Clarke::Scope::Local.new.define(Clarke::Sym::Var.new('this')),
          params: %w[],
          body: lambda do |_ev, env, scope|
            this_sym = scope.resolve('this')
            this = env.fetch(this_sym)
            this.internal_state[:contents] = []
          end,
        )

        array_add = Clarke::Interpreter::Runtime::Fun.new(
          env: Clarke::Util::Env.new,
          scope: Clarke::Scope::Local.new.define(Clarke::Sym::Var.new('this')),
          params: %w[elem],
          body: lambda do |_ev, env, scope, elem|
            this_sym = scope.resolve('this')
            this = env.fetch(this_sym)
            this.internal_state[:contents] << elem
            elem
          end,
        )

        array_each = Clarke::Interpreter::Runtime::Fun.new(
          env: Clarke::Util::Env.new,
          scope: Clarke::Scope::Local.new.define(Clarke::Sym::Var.new('this')),
          params: %w[fn],
          body: lambda do |ev, env, scope, fn|
            this_sym = scope.resolve('this')
            this = env.fetch(this_sym)

            param_syms = fn.params.map do |e|
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

        array_class_symtab =
          Clarke::Util::SymbolTable
          .new
          .define(Clarke::Sym::Var.new('this'))
          .define(Clarke::Sym::Fun.new('init', [], void_type))
          .define(
            Clarke::Sym::Fun.new(
              'add',
              [Clarke::Sym::Var.new('elem').tap { |s| s.type = any_type }],
              void_type,
            ),
          )
          .define(
            Clarke::Sym::Fun.new(
              'each',
              [Clarke::Sym::Var.new('fn').tap { |s| s.type = any_type }],
              void_type,
            ),
          )

        array_class_sym = Clarke::Sym::Class.new('Array')

        array_class_scope =
          Clarke::Scope::Class.new(array_class_sym, array_class_symtab)

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

        array_class_sym.scope = array_class_scope

        print_sym = Clarke::Sym::Fun.new(
          'print',
          [Clarke::Sym::Var.new('e').tap { |s| s.type = any_type }],
          void_type,
        )

        symtab =
          Clarke::Util::SymbolTable
          .new
          .define(any_type)
          .define(auto_type)
          .define(bool_type)
          .define(int_type)
          .define(string_type)
          .define(void_type)
          .define(print_sym)
          .define(array_class_sym)

        @scope = Clarke::Scope::Global.new(symtab)

        @envish = {
          @scope.resolve('print') => print,
          @scope.resolve('Array') => array_class,
        }
      end
    end
  end
end
