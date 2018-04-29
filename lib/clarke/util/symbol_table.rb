# frozen_string_literal: true

module Clarke
  module Util
    class SymbolTable
      def initialize(contents: {}, parent: nil)
        @contents = contents
        @parent = parent
      end

      def define(sym)
        self.class.new(
          parent: @parent,
          contents: @contents.merge(sym.name => sym),
        )
      end

      def resolve(name, expr)
        if @contents.key?(name)
          @contents.fetch(name)
        elsif @parent
          @parent.resolve(name, expr)
        else
          raise Clarke::Language::NameError.new(name, expr)
        end
      end

      def inspect
        "<SymbolTable #{@contents.values.inspect}\n#{_indent(@parent.inspect)}>"
      end

      def push
        self.class.new(parent: self)
      end

      def _indent(lines)
        lines.each_line.map { |l| '  ' + l }.join('')
      end
    end
  end
end
