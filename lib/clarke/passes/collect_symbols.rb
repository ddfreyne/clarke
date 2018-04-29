# frozen_string_literal: true

module Clarke
  module Passes
    # Provides each expression with a Scope, containing zero or more Syms.
    #
    # To do afterwards: change any variable reference to use a Sym rather than
    # a string containing the variable name.
    class CollectSymbols < Clarke::Visitor
      # TODO: move out
      class Sym
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def inspect
          id = num_to_short_string(object_id).reverse.scan(/.{1,4}/).join('-').reverse
          "<#{self.class.to_s.sub(/^.*::/, '')} #{@name} #{id}>"
        end

        def to_s
          inspect
        end

        NUM_MAPPING = [
          ('0'..'9'),
          ('a'..'z'),
          ('A'..'Z'),
        ].map(&:to_a).flatten

        def num_to_short_string(num)
          q, r = num.divmod(NUM_MAPPING.size)
          (q > 0 ? num_to_short_string(q) : '') + NUM_MAPPING[r]
        end
      end

      # TODO: move out
      class VarSym < Sym
      end

      # TODO: move out
      class ClassSym < Sym
      end

      attr_reader :scope

      def initialize(initial_env)
        @scope = Clarke::Util::SymbolTable.new

        initial_env.each do |name, _thing|
          # TODO: use thing… but for what?
          define(VarSym.new(name))
        end
      end

      def visit_block(expr)
        push do
          super
        end
      end

      def visit_class_def(expr)
        define(ClassSym.new(expr.name))

        push do
          super
        end
      end

      def visit_fun_def(expr)
        push do
          expr.parameters.each do |param|
            define(VarSym.new(param))
          end

          define(VarSym.new('this'))

          super
        end
      end

      def visit_lambda_def(expr)
        push do
          expr.parameters.each do |param|
            define(VarSym.new(param))
          end

          super
        end
      end

      def visit_var_decl(expr)
        define(VarSym.new(expr.variable_name))

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
