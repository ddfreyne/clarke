# frozen_string_literal: true

module Clarke
  module Sym
    class Base
      attr_reader :name

      def initialize(name)
        @name = name.to_s
      end

      def inspect
        class_name = self.class.to_s.sub(/^.*::/, '')
        id = Clarke::Util::Num2String.call(object_id)

        extra = inspect_hash.map { |k, v| " #{k}=#{v}" }.join('')

        "<#{class_name} [#{id}] #{@name}#{extra}>"
      end

      def inspect_hash
        {}
      end

      def to_s
        @name
      end
    end

    module Type
      # Marker module

      def type
        self
      end
    end

    module HasType
      attr_accessor :type
    end

    class BuiltinType < Base
      include Type
    end

    class Var < Base
      include HasType

      def inspect_hash
        super.merge(type: type || '?')
      end
    end

    class Class < Base
      include Type
    end

    class Fun < Base
      include Type

      attr_reader :param_count
      attr_accessor :ret_type

      def initialize(name, param_count, ret_type)
        super(name)

        @param_count = param_count
        @ret_type = ret_type
      end
    end

    class Prop < Base
    end
  end
end
