# frozen_string_literal: true

module Clarke
  module Util
    class Env
      def initialize(parent: nil, contents: {})
        @parent = parent
        @contents = contents
      end

      def fetch(key)
        if @contents.key?(key)
          @contents.fetch(key)
        elsif @parent
          @parent.fetch(key)
        else
          raise Clarke::Errors::NameError.new(key)
        end
      end

      def fetch_member(key)
        if @contents.key?(key)
          @contents.fetch(key)
        else
          raise Clarke::Errors::NameError.new(key)
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

      def []=(key, value)
        @contents[key] = value
      end

      def merge(hash)
        push.tap do |new_env|
          hash.each { |k, v| new_env[k] = v }
        end
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
