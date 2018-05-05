# frozen_string_literal: true

module Clarke
  class Transformer
    def visit_assignment(expr)
      Clarke::AST::Assignment.new(
        var_name: expr.var_name,
        expr:     visit_expr(expr.expr),
        context:  expr.context,
      )
    end

    def visit_var_def(expr)
      Clarke::AST::VarDef.new(
        var_name: expr.var_name,
        expr:     visit_expr(expr.expr),
        context:  expr.context,
      )
    end

    def visit_false_lit(expr)
      expr
    end

    def visit_fun_call(expr)
      Clarke::AST::FunCall.new(
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

    def visit_integer_lit(expr)
      expr
    end

    def visit_lambda_def(expr)
      Clarke::AST::LambdaDef.new(
        params: expr.params,
        body:       visit_expr(expr.body),
        context:    expr.context,
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

    def visit_string_lit(expr)
      expr
    end

    def visit_true_lit(expr)
      expr
    end

    def visit_ref(expr)
      expr
    end

    def visit_class_def(expr)
      Clarke::AST::ClassDef.new(
        name:    expr.name,
        members: expr.members.map { |e| visit_expr(e) },
        context: expr.context,
      )
    end

    def visit_fun_def(expr)
      Clarke::AST::FunDef.new(
        name:       expr.name,
        params: expr.params,
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

    def visit_op_add(expr)
      Clarke::AST::OpAdd.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_subtract(expr)
      Clarke::AST::OpSubtract.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_multiply(expr)
      Clarke::AST::OpMultiply.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_divide(expr)
      Clarke::AST::OpDivide.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_exponentiate(expr)
      Clarke::AST::OpExponentiate.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_eq(expr)
      Clarke::AST::OpEq.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_gt(expr)
      Clarke::AST::OpGt.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_lt(expr)
      Clarke::AST::OpLt.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_gte(expr)
      Clarke::AST::OpGte.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_lte(expr)
      Clarke::AST::OpLte.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_and(expr)
      Clarke::AST::OpAnd.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_op_or(expr)
      Clarke::AST::OpOr.new(
        lhs:     visit_expr(expr.lhs),
        rhs:     visit_expr(expr.rhs),
        context: expr.context,
      )
    end

    def visit_prop_decl(expr)
      expr
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
