# frozen_string_literal: true

module Clarke
  module Transformers
    class BuildScopes < Clarke::Transformer
      def initialize(global_names, local_depths)
        @local_depths = local_depths
        @scopes = [Set.new(global_names), Set.new]
      end

      def transform_scope(expr)
        push do
          super
        end
      end

      def transform_scoped_var_decl(expr)
        push do
          current_scope << expr.variable_name
          super
        end
      end

      def transform_var_decl(expr)
        current_scope << expr.variable_name
        super
      end

      def transform_assignment(expr)
        @local_depths[expr] = scope_idx_containing(expr.variable_name, expr)
        super
      end

      def transform_var(expr)
        @local_depths[expr] = scope_idx_containing(expr.name, expr)
        super
      end

      def transform_lambda_def(expr)
        push do
          expr.argument_names.each { |n| current_scope << n }
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
