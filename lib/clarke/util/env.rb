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
        if depth == 0
          self
        else
          @parent.at_depth(depth - 1)
        end
      end

      def fetch(key, depth:, expr:)
        if depth > 0
          @parent.fetch(key, depth: depth - 1, expr: expr)
        elsif depth == 0
          @contents.fetch(key) { raise Clarke::Language::NameError.new(key, expr) }
        elsif depth < 0 # special haxx
          if @contents.key?(key)
            @contents.fetch(key)
          elsif @parent
            @parent.fetch(key, depth: -1, expr: expr)
          else
            raise Clarke::Language::NameError.new(key, expr)
          end
        end
      end

      def []=(key, value)
        if key.is_a?(String) || key.is_a?(Symbol)
          @contents[key] = value
        elsif @parent
          # FIXME: haxx
          @parent[key] = value
        else
          @contents[key] = value
        end
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
        "<Env #{@contents.keys}\n#{_indent(@parent.inspect)}>"
      end

      def to_s
        inspect
      end

      def _indent(lines)
        lines.each_line.map { |l| '  ' + l }.join('')
      end
    end
  end
end
