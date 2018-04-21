# frozen_string_literal: true

module Clarke
  module Util
    class Env
      def initialize(parent: nil, contents: {})
        @parent = parent
        @contents = contents
      end

      def key?(key)
        @contents.key?(key) || (@parent&.key?(key))
      end

      def fetch(key, depth: nil, expr: nil)
        if depth&.positive?
          @parent.fetch(key, depth: depth - 1, expr: expr)
        elsif depth&.zero?
          @contents.fetch(key) { raise Clarke::Language::NameError.new(key, expr) }
        elsif @parent
          # TODO: remove
          @contents.fetch(key) { @parent.fetch(key, expr: expr) }
        else
          # TODO: remove
          @contents.fetch(key) { raise Clarke::Language::NameError.new(key, expr) }
        end
      end

      def []=(key, value)
        @contents[key] = value
      end

      def merge(hash)
        pushed = push
        hash.each { |k, v| pushed[k] = v }
        pushed
      end

      def push
        self.class.new(parent: self)
      end

      def inspect
        "<Env keys=#{@contents.keys} parent=#{@parent.inspect}>"
      end
    end
  end
end
