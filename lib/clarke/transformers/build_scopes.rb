# frozen_string_literal: true

module Clarke
  module Transformers
    class BuildScopes < Clarke::Transformer
      def initialize(local_depths)
        @local_depths = local_depths
        @scopes = [Set.new]
      end

      def transform_scope(expr)
        push do
          super
        end
      end

      def transform_scoped_let(expr)
        current_scope << expr.variable_name

        push do
          super
        end
      end

      def transform_assignment(expr)
        current_scope << expr.variable_name
        super
      end

      def transform_var(expr)
        @local_depths[expr] = scope_idx_containing(expr.name)
        super
      end

      def transform_lambda_def(expr)
        push do
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

      def scope_idx_containing(name)
        count = @scopes.size

        count.times do |i|
          return count - i - 1 if @scopes[i].include?(name)
        end

        nil
      end
    end
  end
end
