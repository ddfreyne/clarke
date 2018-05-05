# frozen_string_literal: true

module Clarke
  module Sym
    class Base
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

    class BuiltinType < Base
    end

    class Var < Base
    end

    class Class < Base
    end

    class Fun < Base
    end

    class Prop < Base
    end
  end
end
