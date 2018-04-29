# frozen_string_literal: true

module Clarke
  module Passes
    # Provides each expression with a Scope, containing zero or more Syms.
    #
    # To do afterwards: change any variable reference to use a Sym rather than
    # a string containing the variable name.
    class CollectSymbols < Clarke::Visitor
      attr_reader :scope

      def initialize(initial_env)
        @scope = Clarke::Util::SymbolTable.new

        initial_env.each do |name, _thing|
          define(Clarke::Language::VarSym.new(name))
        end
      end

      def visit_block(expr)
        push do
          super
        end
      end

      def visit_class_def(expr)
        define(Clarke::Language::ClassSym.new(expr.name))

        push do
          super
        end
      end

      def visit_fun_def(expr)
        push do
          expr.parameters.each do |param|
            define(Clarke::Language::VarSym.new(param))
          end

          define(Clarke::Language::VarSym.new('this'))

          super
        end
      end

      def visit_lambda_def(expr)
        push do
          expr.parameters.each do |param|
            define(Clarke::Language::VarSym.new(param))
          end

          super
        end
      end

      def visit_var_decl(expr)
        define(Clarke::Language::VarSym.new(expr.variable_name))

        super
      end

      def visit_expr(expr)
        super
        expr.scope = @scope
      end

      private

      def define(sym)
        @scope = @scope.define(sym)
      end

      def push
        original_scope = @scope
        @scope = @scope.push
        res = yield
        @scope = original_scope
        res
      end
    end
  end
end
