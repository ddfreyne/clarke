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

      def hash
        self.class.hash ^ @name.hash
      end

      def ==(other)
        other.is_a?(self.class) && @name == other.name
      end

      def eql?(other)
        other.is_a?(self.class) && @name == other.name
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

      def auto?
        false
      end

      def any?
        false
      end

      # FIXME: #void?

      def concrete?
        true
      end

      def match?(other_type)
        self == other_type || other_type.any?
      end
    end

    module HasType
      attr_accessor :type
    end

    class BuiltinType < Base
      include Type

      def auto?
        name == 'auto'
      end

      def any?
        name == 'any'
      end

      def void?
        name == 'void'
      end

      def concrete?
        !auto? && !void?
      end
    end

    class InstanceType
      include Type

      attr_accessor :klass

      def initialize(klass)
        @klass = klass
      end

      def inspect
        "<InstanceType klass=#{klass.inspect}>"
      end

      def hash
        self.class.hash ^ klass.hash
      end

      def ==(other)
        other.is_a?(self.class) && other.klass == klass
      end
    end

    class Var < Base
      include HasType

      def inspect_hash
        super.merge(type: type || '?')
      end
    end

    class Class < Base
      include Type

      attr_accessor :scope
      attr_reader :ivar_syms

      def initialize(*)
        super

        @ivar_syms = []
      end
    end

    class Fun < Base
      include Type

      attr_reader :params
      attr_reader :ret_type

      def initialize(name, params, ret_type)
        super(name)

        @params = params
        @ret_type = ret_type
      end

      def param_count
        @params.size
      end

      def inspect_hash
        super.merge('#params': param_count, ret_type: ret_type.inspect || '?')
      end

      def ret_type=(ret_type)
        raise ArgumentError unless ret_type
        @ret_type = ret_type
      end
    end

    class Ivar < Base
      include HasType
    end
  end
end
