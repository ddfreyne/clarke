# frozen_string_literal: true

module Clarke
  module Util
    class ShuntingYard
      def initialize(precedences, associativities)
        @precedences = precedences
        @associativities = associativities
      end

      def run(tokens)
        output = []
        stack = []

        tokens.each do |t|
          case t
          when Clarke::AST::Op
            loop do
              break if stack.empty?

              stack_left_associative = @associativities.fetch(stack.last.name) == :left
              stack_precedence = @precedences.fetch(stack.last.name)
              input_precedence = @precedences.fetch(t.name)

              break if stack_left_associative && input_precedence > stack_precedence
              break if !stack_left_associative && input_precedence >= stack_precedence

              output << stack.pop
            end
            stack << t
          else
            output << t
          end
        end

        stack.reverse_each do |t|
          output << t
        end

        output
      end
    end
  end
end
