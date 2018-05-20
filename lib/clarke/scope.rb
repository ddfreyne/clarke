# frozen_string_literal: true

module Clarke
  module Scope
    class Base
      attr_reader :symtab

      def initialize(symtab = nil)
        @symtab = symtab || Clarke::Util::SymbolTable.new
      end

      def define(sym)
        with_symtab(@symtab.define(sym))
      end

      def resolve(name, fallback = Clarke::Util::SymbolTable::UNDEFINED)
        @symtab.resolve(name, fallback)
      end

      def push_local
        Clarke::Scope::Local.new(@symtab.push)
      end

      def push_class(class_sym)
        Clarke::Scope::Class.new(class_sym, @symtab.push)
      end
    end

    class Local < Base
      def with_symtab(symtab)
        self.class.new(symtab)
      end
    end

    class Class < Base
      attr_reader :class_sym

      def initialize(class_sym, symtab = nil)
        super(symtab)
        @class_sym = class_sym
      end

      def with_symtab(symtab)
        self.class.new(@class_sym, symtab)
      end
    end
  end
end
