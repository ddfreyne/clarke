# frozen_string_literal: true

module Clarke
  class Transformer
    def transform_assignment(expr)
      Clarke::AST::Assignment.new(
        expr.variable_name,
        transform_expr(expr.expr),
        expr.context,
      )
    end

    def transform_false(expr)
      expr
    end

    def transform_function_call(expr)
      Clarke::AST::FunctionCall.new(
        expr.name,
        expr.arguments.map { |a| transform_expr(a) },
        expr.context,
      )
    end

    def transform_if(expr)
      Clarke::AST::If.new(
        transform_expr(expr.cond),
        transform_expr(expr.body_true),
        transform_expr(expr.body_false),
        expr.context,
      )
    end

    def transform_integer_literal(expr)
      expr
    end

    def transform_lambda_def(expr)
      Clarke::AST::LambdaDef.new(
        expr.argument_names,
        transform_expr(expr.body),
        expr.context,
      )
    end

    def transform_op(expr)
      expr
    end

    def transform_op_seq(expr)
      Clarke::AST::OpSeq.new(
        expr.seq.map { |e| transform_expr(e) },
        expr.context,
      )
    end

    def transform_scope(expr)
      Clarke::AST::Scope.new(
        expr.exprs.map { |e| transform_expr(e) },
        expr.context,
      )
    end

    def transform_scoped_let(expr)
      Clarke::AST::ScopedLet.new(
        expr.variable_name,
        transform_expr(expr.expr),
        transform_expr(expr.body),
        expr.context,
      )
    end

    def transform_string(expr)
      expr
    end

    def transform_true(expr)
      expr
    end

    def transform_var(expr)
      expr
    end

    def transform_expr(expr)
      case expr
      when Clarke::AST::Assignment
        transform_assignment(expr)
      when Clarke::AST::FalseLiteral
        transform_false(expr)
      when Clarke::AST::FunctionCall
        transform_function_call(expr)
      when Clarke::AST::If
        transform_if(expr)
      when Clarke::AST::IntegerLiteral
        transform_integer_literal(expr)
      when Clarke::AST::LambdaDef
        transform_lambda_def(expr)
      when Clarke::AST::Op
        transform_op(expr)
      when Clarke::AST::OpSeq
        transform_op_seq(expr)
      when Clarke::AST::Scope
        transform_scope(expr)
      when Clarke::AST::ScopedLet
        transform_scoped_let(expr)
      when Clarke::AST::StringLiteral
        transform_string(expr)
      when Clarke::AST::TrueLiteral
        transform_true(expr)
      when Clarke::AST::Var
        transform_var(expr)
      else
        raise ArgumentError, "don’t know how to handle #{expr.inspect}"
      end
    end

    def transform_exprs(exprs)
      exprs.map { |e| transform_expr(e) }
    end
  end
end
