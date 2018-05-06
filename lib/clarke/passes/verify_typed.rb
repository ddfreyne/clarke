# frozen_string_literal: true

module Clarke
  module Passes
    class VerifyTyped < Clarke::Visitor
      def visit_expr(expr)
        super
        assert_typed(expr)
      end

      def assert_typed(expr)
        if expr.type.nil?
          raise Clarke::Errors::GenericError.new("could not type #{expr.inspect}", expr: expr)
        elsif expr.type.auto?
          raise Clarke::Errors::GenericError.new("still auto-typed #{expr.inspect}", expr: expr)
        elsif !expr.type.is_a?(Clarke::Sym::Type)
          raise Clarke::Errors::GenericError.new("type is not a type #{expr.type.inspect} -- for #{expr.inspect}", expr: expr)
        end
      end
    end
  end
end
