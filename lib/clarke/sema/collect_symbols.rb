# frozen_string_literal: true

module Clarke
  module Sema
    # After this pass, each expression will have a `scope` (SymbolTable
    # instance).
    class CollectSymbols < Clarke::Visitor
      attr_reader :scope

      def initialize(global_scope)
        @scope = global_scope
      end

      def visit_block(expr)
        push_local do
          super
        end
      end

      def visit_class_def(expr)
        class_sym = Clarke::Sym::Class.new(expr.name)
        define(class_sym)

        push_class(class_sym) do
          this_sym = Clarke::Sym::Var.new('this')
          this_sym.type = Clarke::Sym::InstanceType.new(class_sym)
          define(this_sym)
          super
          update_scope(expr)
          update_scope(class_sym)
        end
      end

      def visit_fun_def(expr)
        param_syms = expr.params.map do |param|
          Clarke::Sym::Var.new(param.name)
        end

        define(Clarke::Sym::Fun.new(expr.name, param_syms, nil))

        push_local do
          param_syms.each { |ps| define(ps) }
          super
          update_scope(expr)
        end
      end

      def visit_lambda_def(expr)
        param_syms = expr.params.map do |param|
          Clarke::Sym::Var.new(param.name)
        end

        push_local do
          param_syms.each { |ps| define(ps) }
          super
          update_scope(expr)
        end
      end

      def visit_var_def(expr)
        define(Clarke::Sym::Var.new(expr.var_name))

        super
      end

      def visit_ivar_decl(expr)
        sym = Clarke::Sym::Ivar.new(expr.name)
        define(sym)

        class_sym = @scope.class_sym
        class_sym.ivar_syms << sym
      end

      def visit_expr(expr)
        super
        expr.scope ||= @scope
      end

      private

      def update_scope(thing)
        thing.scope = @scope
      end

      def define(sym)
        @scope = @scope.define(sym)
      end

      def push_local
        original_scope = @scope
        @scope = @scope.push_local
        res = yield
        @scope = original_scope
        res
      end

      def push_class(class_sym)
        original_scope = @scope
        @scope = @scope.push_class(class_sym)
        res = yield
        @scope = original_scope
        res
      end
    end
  end
end
