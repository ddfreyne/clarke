# frozen_string_literal: true

module Clarke
  class Evaluator
    INITIAL_ENV = {
      'print' => Clarke::Runtime::Function.new(
        ['a'],
        ->(a) { puts(a.clarke_to_string) },
      ),
    }.freeze

    def eval_function_call(expr, env)
      function = check_type(env.fetch(expr.name, expr: expr), Clarke::Runtime::Function, expr)

      if expr.arguments.count != function.argument_names.size
        raise Clarke::Language::ArgumentCountError.new(
          expected: function.argument_names.size,
          actual: expr.arguments.count,
          expr: expr,
        )
      end

      values = expr.arguments.map { |e| eval_expr(e, env) }

      case function.body
      when Clarke::AST::Scope
        new_env =
          function.env.merge(Hash[function.argument_names.zip(values)])
        eval_scope(function.body, new_env)
      when Proc
        function.body.call(*values)
      end
    end

    def eval_var(expr, env)
      env.fetch(expr.name, expr: expr)
    end

    def eval_assignment(assignment, env)
      value = eval_expr(assignment.expr, env)
      env[assignment.variable_name] = value
      value
    end

    def eval_scoped_let(expr, env)
      new_env = env.push
      new_env[expr.variable_name] = eval_expr(expr.expr, env)
      eval_expr(expr.body, new_env)
    end

    def eval_scope(expr, env)
      new_env = env.push
      expr.exprs.reduce(0) do |_, e|
        eval_expr(e, new_env)
      end
    end

    def eval_if(expr, env)
      res = check_type(eval_expr(expr.cond, env), Clarke::Runtime::Boolean, expr)

      if res.value
        eval_expr(expr.body_true, env)
      else
        eval_expr(expr.body_false, env)
      end
    end

    def eval_op_seq(expr, env)
      values =
        expr.seq.map do |e|
          case e
          when Clarke::AST::Op
            e
          else
            eval_expr(e, env)
          end
        end

      shunting_yard = Clarke::Util::ShuntingYard.new(
        Clarke::Language::PRECEDENCES,
        Clarke::Language::ASSOCIATIVITIES,
      )
      rpn_seq = shunting_yard.run(values)
      stack = []
      rpn_seq.each do |e|
        case e
        when Clarke::AST::Op
          operands = stack.pop(2)

          stack <<
            case e.name
            when '+'
              operands.reduce(:add)
            when '-'
              operands.reduce(:subtract)
            when '*'
              operands.reduce(:multiply)
            when '/'
              operands.reduce(:divide)
            when '^'
              operands.reduce(:exponentiate)
            when '=='
              operands.reduce(:eq)
            when '>'
              operands.reduce(:gt)
            when '<'
              operands.reduce(:lt)
            when '>='
              operands.reduce(:gte)
            when '<='
              operands.reduce(:lte)
            when '&&'
              operands[0].and(operands[1])
            when '||'
              operands[0].or(operands[1])
            else
              raise "unknown operator: #{e}"
            end
        else
          stack << e
        end
      end

      stack.first
    end

    def eval_lambda_def(expr, env)
      Clarke::Runtime::Function.new(expr.argument_names, expr.body, env)
    end

    def eval_expr(expr, env)
      case expr
      when Clarke::AST::IntegerLiteral
        Clarke::Runtime::Integer.new(expr.value)
      when Clarke::AST::TrueLiteral
        Clarke::Runtime::True
      when Clarke::AST::FalseLiteral
        Clarke::Runtime::False
      when Clarke::AST::FunctionCall
        eval_function_call(expr, env)
      when Clarke::AST::Var
        eval_var(expr, env)
      when Clarke::AST::Assignment
        eval_assignment(expr, env)
      when Clarke::AST::ScopedLet
        eval_scoped_let(expr, env)
      when Clarke::AST::Scope
        eval_scope(expr, env)
      when Clarke::AST::If
        eval_if(expr, env)
      when Clarke::AST::OpSeq
        eval_op_seq(expr, env)
      when Clarke::AST::LambdaDef
        eval_lambda_def(expr, env)
      else
        raise ArgumentError, "don’t know how to handle #{expr.inspect}"
      end
    end

    def eval_exprs(exprs)
      env = Clarke::Util::Env.new(contents: INITIAL_ENV).push
      exprs.reduce(0) do |_, expr|
        # FIXME: almost the same as #eval_scope
        eval_expr(expr, env)
      end
    end

    private

    def check_type(val, klass, expr)
      if val.is_a?(klass)
        val
      else
        raise Clarke::Language::TypeError.new(val, klass, expr)
      end
    end
  end
end
