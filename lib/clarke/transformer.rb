# frozen_string_literal: true

module Clarke
  class Transformer
    def visit_assignment(expr)
      Clarke::AST::Assignment.new(
        variable_name: expr.variable_name,
        expr:          visit_expr(expr.expr),
        context:       expr.context,
      )
    end

    def visit_var_decl(expr)
      Clarke::AST::VarDecl.new(
        variable_name: expr.variable_name,
        expr:          visit_expr(expr.expr),
        context:       expr.context,
      )
    end

    def visit_false(expr)
      expr
    end

    def visit_function_call(expr)
      Clarke::AST::FunctionCall.new(
        base:      visit_expr(expr.base),
        arguments: expr.arguments.map { |a| visit_expr(a) },
        context:   expr.context,
      )
    end

    def visit_get_prop(expr)
      Clarke::AST::GetProp.new(
        base:    visit_expr(expr.base),
        name:    expr.name,
        context: expr.context,
      )
    end

    def visit_if(expr)
      Clarke::AST::If.new(
        cond:       visit_expr(expr.cond),
        body_true:  visit_expr(expr.body_true),
        body_false: visit_expr(expr.body_false),
        context:    expr.context,
      )
    end

    def visit_integer_literal(expr)
      expr
    end

    def visit_lambda_def(expr)
      Clarke::AST::LambdaDef.new(
        parameters: expr.parameters,
        body:           visit_expr(expr.body),
        context:        expr.context,
      )
    end

    def visit_op(expr)
      expr
    end

    def visit_op_seq(expr)
      Clarke::AST::OpSeq.new(
        seq:     expr.seq.map { |e| visit_expr(e) },
        context: expr.context,
      )
    end

    def visit_block(expr)
      Clarke::AST::Block.new(
        exprs:   expr.exprs.map { |e| visit_expr(e) },
        context: expr.context,
      )
    end

    def visit_string(expr)
      expr
    end

    def visit_true(expr)
      expr
    end

    def visit_var(expr)
      expr
    end

    def visit_class_def(expr)
      Clarke::AST::ClassDef.new(
        name:      expr.name,
        functions: expr.functions.map { |e| visit_expr(e) },
        context:   expr.context,
      )
    end

    def visit_fun_def(expr)
      Clarke::AST::FunDef.new(
        name:       expr.name,
        parameters: expr.parameters,
        body:       visit_expr(expr.body),
        context:    expr.context,
      )
    end

    def visit_set_prop(expr)
      Clarke::AST::SetProp.new(
        base:    visit_expr(expr.base),
        name:    expr.name,
        value:   visit_expr(expr.value),
        context: expr.context,
      )
    end

    def visit_expr(expr)
      case expr
      when Clarke::AST::VarDecl
        visit_var_decl(expr)
      when Clarke::AST::Assignment
        visit_assignment(expr)
      when Clarke::AST::FalseLiteral
        visit_false(expr)
      when Clarke::AST::FunctionCall
        visit_function_call(expr)
      when Clarke::AST::GetProp
        visit_get_prop(expr)
      when Clarke::AST::If
        visit_if(expr)
      when Clarke::AST::IntegerLiteral
        visit_integer_literal(expr)
      when Clarke::AST::LambdaDef
        visit_lambda_def(expr)
      when Clarke::AST::Op
        visit_op(expr)
      when Clarke::AST::OpSeq
        visit_op_seq(expr)
      when Clarke::AST::Block
        visit_block(expr)
      when Clarke::AST::StringLiteral
        visit_string(expr)
      when Clarke::AST::TrueLiteral
        visit_true(expr)
      when Clarke::AST::Var
        visit_var(expr)
      when Clarke::AST::ClassDef
        visit_class_def(expr)
      when Clarke::AST::FunDef
        visit_fun_def(expr)
      when Clarke::AST::SetProp
        visit_set_prop(expr)
      else
        raise ArgumentError, "don’t know how to handle #{expr.inspect}"
      end
    end

    def visit_exprs(exprs)
      exprs.map { |e| visit_expr(e) }
    end
  end
end
