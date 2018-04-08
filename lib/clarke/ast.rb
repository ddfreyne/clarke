# frozen_string_literal: true

module Clarke
  module AST
    # TODO: add context everywhere

    FalseLiteral = Object.new
    TrueLiteral = Object.new

    Assignment = Struct.new(:variable_name, :expr) do
      def inspect
        to_s
      end

      def to_s
        "(Assignment #{variable_name} #{expr})"
      end
    end

    FunctionCall = Struct.new(:name, :arguments, :input, :old_pos, :new_pos) do
      def inspect
        to_s
      end

      def to_s
        "(FunctionCall #{name} #{arguments})"
      end
    end

    If = Struct.new(:cond, :body_true, :body_false) do
      def inspect
        to_s
      end

      def to_s
        "(If #{cond} #{body_true} #{body_false})"
      end
    end

    IntegerLiteral = Struct.new(:value) do
      def inspect
        to_s
      end

      def to_s
        "(IntegerLiteral #{value})"
      end
    end

    LambdaDef = Struct.new(:argument_names, :body) do
      def inspect
        to_s
      end

      def to_s
        "(LambdaDef #{argument_names} #{body})"
      end
    end

    Op = Struct.new(:name) do
      def inspect
        to_s
      end

      def to_s
      "(Op #{name})"
      end
    end

    OpSeq = Struct.new(:seq) do
      def inspect
        to_s
      end

      def to_s
        "(OpSeq #{seq})"
      end
    end

    Scope = Struct.new(:exprs) do
      def inspect
        to_s
      end

      def to_s
        "(Scope #{exprs})"
      end
    end

    ScopedLet = Struct.new(:variable_name, :expr, :body) do
      def inspect
        to_s
      end

      def to_s
        "(ScopedLet #{variable_name} #{expr} #{body})"
      end
    end

    Var = Struct.new(:name) do
      def inspect
        to_s
      end

      def to_s
       "(Var #{name})"
      end
    end
  end
end
