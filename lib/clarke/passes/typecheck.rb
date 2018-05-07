# frozen_string_literal: true

module Clarke
  module Passes
    class Typecheck < Clarke::Visitor
      def visit_expr(expr)
        super
        assert_typed(expr)
      end

      def assert_typed(thing, expr: thing)
        if thing.type.nil?
          raise Clarke::Errors::GenericError.new("could not type #{thing.inspect}", expr: expr)
        elsif thing.type.auto?
          raise Clarke::Errors::GenericError.new("still auto-typed #{thing.inspect}", expr: expr)
        elsif !thing.type.is_a?(Clarke::Sym::Type)
          raise Clarke::Errors::GenericError.new("type is not a type #{thing.type.inspect}", expr: expr)
        end
      end
    end
  end
end
