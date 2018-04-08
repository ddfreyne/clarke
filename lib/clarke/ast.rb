# frozen_string_literal: true

module Clarke
  module AST
    # TODO: add context everywhere

    FalseLiteral = Object.new
    TrueLiteral = Object.new

    Assignment = Struct.new(:variable_name, :expr)
    FunctionCall = Struct.new(:name, :arguments, :input, :old_pos, :new_pos)
    FunctionDef = Struct.new(:name, :argument_names, :body)
    If = Struct.new(:cond, :body_true, :body_false)
    IntegerLiteral = Struct.new(:value)
    LambdaDef = Struct.new(:argument_names, :body)
    Op = Struct.new(:name)
    OpSeq = Struct.new(:seq)
    Scope = Struct.new(:exprs)
    ScopedLet = Struct.new(:variable_name, :expr, :body)
    Var = Struct.new(:name)
  end
end
