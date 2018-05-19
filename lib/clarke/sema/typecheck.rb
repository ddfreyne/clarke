# frozen_string_literal: true

module Clarke
  module Sema
    class Typecheck < Clarke::Visitor
      def visit_expr(expr)
        super
        assert_typed(expr)
      end

      def visit_fun_call(expr)
        # Get param syms
        param_syms =
          case expr.base.type
          when Clarke::Sym::Class
            fun = expr.base.type.scope.resolve('init', nil)
            fun ? fun.params : []
          when Clarke::Sym::Fun
            expr.base.type.params
          else
            raise Clarke::Errors::NotCallable.new(expr: expr.base)
          end

        # Verify argument count
        if param_syms.size != expr.arguments.size
          raise Clarke::Errors::ArgumentCountError.new(
            actual: expr.arguments.size,
            expected: param_syms.size,
          )
        end

        # Verify argument type presence
        missing = param_syms.select { |e| e.type.nil? || !e.type.concrete? }
        if missing.any?
          raise Clarke::Errors::UntypedArguments.new(missing)
        end

        # Verify argument type
        pairs = param_syms.zip(expr.arguments.map)
        wrong_pairs = pairs.reject { |(param_sym, arg)| arg.type.match?(param_sym.type) }
        if wrong_pairs.any?
          raise Clarke::Errors::ArgumentTypeMismatch.new(
            wrong_pairs.first[0],
            wrong_pairs.first[1],
          )
        end

        super
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
