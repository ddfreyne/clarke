# frozen_string_literal: true

module Clarke
  class Visitor
    def visit_assignment(expr)
      visit_expr(expr.expr)
      nil
    end

    def visit_var_decl(expr)
      visit_expr(expr.expr)
      nil
    end

    def visit_false(_expr)
      nil
    end

    def visit_function_call(expr)
      expr.arguments.map { |a| visit_expr(a) }
      visit_expr(expr.base)
      nil
    end

    def visit_get_prop(expr)
      visit_expr(expr.base)
      nil
    end

    def visit_if(expr)
      visit_expr(expr.cond)
      visit_expr(expr.body_true)
      visit_expr(expr.body_false)
      nil
    end

    def visit_integer_literal(_expr)
      nil
    end

    def visit_lambda_def(expr)
      visit_expr(expr.body)
      nil
    end

    def visit_op(_expr)
      nil
    end

    def visit_op_seq(expr)
      expr.seq.map { |e| visit_expr(e) }
      nil
    end

    def visit_block(expr)
      expr.exprs.map { |e| visit_expr(e) }
      nil
    end

    def visit_string(_expr)
      nil
    end

    def visit_true(_expr)
      nil
    end

    def visit_var(_expr)
      nil
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
      else
        raise ArgumentError, "don’t know how to handle #{expr.inspect}"
      end
    end

    def visit_exprs(exprs)
      exprs.map { |e| visit_expr(e) }
    end
  end
end
