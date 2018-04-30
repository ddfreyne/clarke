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

      def fetch(key, expr:)
        if @contents.key?(key)
          @contents.fetch(key)
        elsif @parent
          @parent.fetch(key, expr: expr)
        else
          raise Clarke::Language::NameError.new(key, expr)
        end
      end

      def containing(key)
        if @contents.key?(key)
          self
        elsif @parent
          @parent.containing(key)
        else
          nil
        end
      end

      def force_set(key, value)
        @contents[key] = value
      end

      def []=(key, value)
        raise ArgumentError if key.is_a?(String) || key.is_a?(Symbol)

        containing_env = containing(key)
        if containing_env
          containing_env.force_set(key, value)
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
