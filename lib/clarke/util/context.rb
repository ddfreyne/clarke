# frozen_string_literal: true

module Clarke
  module Util
    class Context
      attr_reader :input
      attr_reader :from
      attr_reader :to

      def initialize(input:, from:, to:)
        @input = input
        @from = from
        @to = to
      end
    end
  end
end
