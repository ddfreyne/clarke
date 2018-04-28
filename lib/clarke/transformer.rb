# frozen_string_literal: true

module Clarke
  class Transformer
    def visit_assignment(expr)
      Clarke::AST::Assignment.new(
        expr.variable_name,
        visit_expr(expr.expr),
        expr.context,
      )
    end

    def visit_var_decl(expr)
      Clarke::AST::VarDecl.new(
        expr.variable_name,
        visit_expr(expr.expr),
        expr.context,
      )
    end

    def visit_false(expr)
      expr
    end

    def visit_function_call(expr)
      Clarke::AST::FunctionCall.new(
        visit_expr(expr.base),
        expr.arguments.map { |a| visit_expr(a) },
        expr.context,
      )
    end

    def visit_get_prop(expr)
      Clarke::AST::GetProp.new(
        visit_expr(expr.base),
        expr.name,
        expr.context,
      )
    end

    def visit_if(expr)
      Clarke::AST::If.new(
        visit_expr(expr.cond),
        visit_expr(expr.body_true),
        visit_expr(expr.body_false),
        expr.context,
      )
    end

    def visit_integer_literal(expr)
      expr
    end

    def visit_lambda_def(expr)
      Clarke::AST::LambdaDef.new(
        expr.argument_names,
        visit_expr(expr.body),
        expr.context,
      )
    end

    def visit_op(expr)
      expr
    end

    def visit_op_seq(expr)
      Clarke::AST::OpSeq.new(
        expr.seq.map { |e| visit_expr(e) },
        expr.context,
      )
    end

    def visit_block(expr)
      Clarke::AST::Block.new(
        expr.exprs.map { |e| visit_expr(e) },
        expr.context,
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
        expr.name,
        expr.functions.map { |e| visit_expr(e) },
      )
    end

    def visit_fun_def(expr)
      Clarke::AST::FunDef.new(
        expr.name,
        expr.argument_names,
        visit_expr(expr.body),
      )
    end

    def visit_set_prop(expr)
      Clarke::AST::SetProp.new(
        visit_expr(expr.base),
        expr.name,
        visit_expr(expr.value),
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
