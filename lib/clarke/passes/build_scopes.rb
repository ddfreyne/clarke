# frozen_string_literal: true

module Clarke
  module Passes
    # Sets the lookup depth for Var and Assignment expressions.
    class BuildScopes < Clarke::Visitor
      def initialize(global_names, local_depths)
        @local_depths = local_depths
        @scopes = [Set.new(global_names), Set.new]
      end

      def visit_block(expr)
        push do
          super
        end
      end

      def visit_var_decl(expr)
        current_scope << expr.variable_name
        super
      end

      def visit_assignment(expr)
        @local_depths[expr] = scope_idx_containing(expr.variable_name, expr)
        super
      end

      def visit_var(expr)
        @local_depths[expr] = scope_idx_containing(expr.name, expr)
        super
      end

      def visit_lambda_def(expr)
        push do
          expr.parameters.each { |n| current_scope << n }
          super
        end
      end

      def visit_class_def(expr)
        current_scope << expr.name

        push do
          current_scope << 'this'
          super
        end
      end

      def visit_fun_def(expr)
        current_scope << expr.name

        push do
          expr.parameters.each { |n| current_scope << n }
          super
        end
      end

      private

      def push
        @scopes << Set.new
        res = yield
        @scopes.pop
        res
      end

      def current_scope
        @scopes.last
      end

      def scope_idx_containing(name, expr)
        x = @scopes.reverse_each.find_index { |s| s.include?(name) }
        raise Clarke::Language::NameError.new(name, expr) unless x
        x
      end
    end
  end
end
