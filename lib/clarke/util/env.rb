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

      def at_depth(depth)
        if depth.zero?
          self
        else
          @parent.at_depth(depth - 1)
        end
      end

      def fetch(key, depth: nil, expr: nil)
        unless depth
          raise "Missing depth when fetching #{key.inspect} (env: #{inspect})"
        end

        if depth.positive?
          @parent.fetch(key, depth: depth - 1, expr: expr)
        elsif depth.zero?
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

      def to_s
        inspect
      end
    end
  end
end
