# frozen_string_literal: true

module Clarke
  module Language
    class Sym
      attr_reader :name

      def initialize(name)
        @name = name.to_s
      end

      def inspect
        id = Clarke::Util::Num2String.call(object_id)
        "<#{self.class.to_s.sub(/^.*::/, '')} #{@name} #{id}>"
      end

      def to_s
        inspect
      end
    end

    class VarSym < Sym
    end

    class ClassSym < Sym
    end

    class FunSym < Sym
    end

    class PropSym < Sym
    end
  end
end
