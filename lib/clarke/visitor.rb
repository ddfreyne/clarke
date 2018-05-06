# frozen_string_literal: true

module Clarke
  class Visitor
    def visit_assignment(expr)
      visit_expr(expr.expr)
      nil
    end

    def visit_block(expr)
      expr.exprs.map { |e| visit_expr(e) }
      nil
    end

    def visit_class_def(expr)
      expr.members.each { |e| visit_expr(e) }
      nil
    end

    def visit_false_lit(_expr)
      nil
    end

    def visit_fun_call(expr)
      expr.arguments.map { |a| visit_expr(a) }
      visit_expr(expr.base)
      nil
    end

    def visit_fun_def(expr)
      expr.params.each { |e| visit_expr(e) }
      visit_expr(expr.body)
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

    def visit_integer_lit(_expr)
      nil
    end

    def visit_lambda_def(expr)
      expr.params.each { |e| visit_expr(e) }
      visit_expr(expr.body)
      nil
    end

    def visit_op(_expr)
      nil
    end

    def visit_op_seq(expr)
      expr.seq.each { |e| visit_expr(e) }
      nil
    end

    def visit_op_add(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_subtract(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_multiply(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_divide(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_exponentiate(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_eq(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_gt(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_lt(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_gte(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_lte(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_and(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_op_or(expr)
      visit_expr(expr.lhs)
      visit_expr(expr.rhs)
      nil
    end

    def visit_param(_expr)
      nil
    end

    def visit_prop_decl(_expr)
      nil
    end

    def visit_ref(_expr)
      nil
    end

    def visit_set_prop(expr)
      visit_expr(expr.base)
      visit_expr(expr.value)
      nil
    end

    def visit_string_lit(_expr)
      nil
    end

    def visit_true_lit(_expr)
      nil
    end

    def visit_var_def(expr)
      visit_expr(expr.expr)
      nil
    end

    def visit_expr(expr)
      case expr
      when Clarke::AST::VarDef
        visit_var_def(expr)
      when Clarke::AST::Assignment
        visit_assignment(expr)
      when Clarke::AST::FalseLit
        visit_false_lit(expr)
      when Clarke::AST::FunCall
        visit_fun_call(expr)
      when Clarke::AST::GetProp
        visit_get_prop(expr)
      when Clarke::AST::If
        visit_if(expr)
      when Clarke::AST::IntegerLit
        visit_integer_lit(expr)
      when Clarke::AST::LambdaDef
        visit_lambda_def(expr)
      when Clarke::AST::Op
        visit_op(expr)
      when Clarke::AST::OpSeq
        visit_op_seq(expr)
      when Clarke::AST::OpAdd
        visit_op_add(expr)
      when Clarke::AST::OpSubtract
        visit_op_subtract(expr)
      when Clarke::AST::OpMultiply
        visit_op_multiply(expr)
      when Clarke::AST::OpDivide
        visit_op_divide(expr)
      when Clarke::AST::OpExponentiate
        visit_op_exponentiate(expr)
      when Clarke::AST::OpEq
        visit_op_eq(expr)
      when Clarke::AST::OpGt
        visit_op_gt(expr)
      when Clarke::AST::OpLt
        visit_op_lt(expr)
      when Clarke::AST::OpGte
        visit_op_gte(expr)
      when Clarke::AST::OpLte
        visit_op_lte(expr)
      when Clarke::AST::OpAnd
        visit_op_and(expr)
      when Clarke::AST::OpOr
        visit_op_or(expr)
      when Clarke::AST::Param
        visit_param(expr)
      when Clarke::AST::PropDecl
        visit_prop_decl(expr)
      when Clarke::AST::Block
        visit_block(expr)
      when Clarke::AST::StringLit
        visit_string_lit(expr)
      when Clarke::AST::TrueLit
        visit_true_lit(expr)
      when Clarke::AST::Ref
        visit_ref(expr)
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
