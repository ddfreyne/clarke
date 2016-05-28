module Clarke
  module AST
    IntegerLiteral = Struct.new(:value) do
    end

    TrueLiteral = Object.new
    FalseLiteral = Object.new

    # TODO: add context everywhere
    FunctionCall = Struct.new(:name, :arguments, :input, :old_pos, :new_pos) do
    end

    FunctionDef = Struct.new(:name, :argument_names, :body) do
    end

    LambdaDef = Struct.new(:argument_names, :body) do
    end

    Var = Struct.new(:name) do
    end

    Assignment = Struct.new(:variable_name, :expr) do
    end

    ScopedLet = Struct.new(:variable_name, :expr, :body) do
    end

    Scope = Struct.new(:exprs) do
    end

    If = Struct.new(:cond, :body_true, :body_false) do
    end

    Op = Struct.new(:name) do
    end

    OpSeq = Struct.new(:seq) do
    end
  end
end
