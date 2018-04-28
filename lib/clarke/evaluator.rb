# frozen_string_literal: true

module Clarke
  class Evaluator < Clarke::Visitor
    INITIAL_ENV = {
      'print' => Clarke::Runtime::Function.new(
        %w[a],
        lambda do |_ev, a|
          puts(a.clarke_to_string)
          Clarke::Runtime::Null
        end,
      ),
      'Array' => Clarke::Runtime::Instance.new(
        new: Clarke::Runtime::Function.new(
          %w[],
          ->(_ev) { Clarke::Runtime::Array.new([]) },
        ),
      ),
      'array_new' => Clarke::Runtime::Function.new(
        %w[],
        ->(_ev) { Clarke::Runtime::Array.new([]) },
      ),
      'array_add' => Clarke::Runtime::Function.new(
        %w[a e],
        lambda do |_ev, a, e|
          a.add(e)
          a
        end,
      ),
      'array_each' => Clarke::Runtime::Function.new(
        %w[a fn],
        lambda do |ev, array, fn|
          array.each do |elem|
            new_env =
              fn.env.merge(Hash[fn.argument_names.zip([elem])])
            ev.visit_block(fn.body, new_env)
          end
          Clarke::Runtime::Null
        end,
      ),
    }.freeze

    def initialize(local_depths)
      @local_depths = local_depths
    end

    def visit_function_call(expr, env)
      base = visit_expr(expr.base, env)

      if base.is_a?(Clarke::Runtime::Function)
        function = base
        if expr.arguments.count != function.argument_names.size
          raise Clarke::Language::ArgumentCountError.new(
            expected: function.argument_names.size,
            actual: expr.arguments.count,
            expr: expr,
          )
        end

        values = expr.arguments.map { |e| visit_expr(e, env) }

        case function.body
        when Clarke::AST::Block
          new_env =
            function.env.merge(Hash[function.argument_names.zip(values)])
          visit_block(function.body, new_env)
        when Proc
          function.body.call(self, *values)
        end
      elsif base.is_a?(Clarke::Runtime::Class)
        Clarke::Runtime::Instance.new({}, base)
      else
        raise Clarke::Language::TypeError.new(base, [Clarke::Runtime::Function, Clarke::Runtime::Class], expr)
      end
    end

    def visit_get_prop(expr, env)
      base_value = visit_expr(expr.base, env)
      name = expr.name.to_sym

      unless base_value.is_a?(Clarke::Runtime::Instance)
        raise Clarke::Language::NameError.new(name, expr)
      end

      if base_value.props.key?(name)
        base_value.props.fetch(name)
      elsif base_value.klass&.functions&.key?(name)
        base_value.klass.functions.fetch(name)
      else
        raise Clarke::Language::NameError.new(name, expr)
      end
    end

    def visit_var(expr, env)
      depth = @local_depths.fetch(expr)
      env.fetch(expr.name, depth: depth, expr: expr)
    end

    def visit_var_decl(expr, env)
      value = visit_expr(expr.expr, env)
      env[expr.variable_name] = value
      value
    end

    def visit_assignment(expr, env)
      if @local_depths.key?(expr)
        value = visit_expr(expr.expr, env)
        env.at_depth(@local_depths.fetch(expr))[expr.variable_name] = value
        value
      else
        raise Clarke::Language::NameError.new(expr.variable_name, expr)
      end
    end

    def visit_block(expr, env)
      multi_visit(expr.exprs, env.push)
    end

    def visit_if(expr, env)
      res = check_type(visit_expr(expr.cond, env), Clarke::Runtime::Boolean, expr)

      if res.value
        visit_expr(expr.body_true, env)
      else
        visit_expr(expr.body_false, env)
      end
    end

    def visit_op_seq(expr, env)
      values =
        expr.seq.map do |e|
          case e
          when Clarke::AST::Op
            e
          else
            visit_expr(e, env)
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

    def visit_lambda_def(expr, env)
      Clarke::Runtime::Function.new(expr.argument_names, expr.body, env)
    end

    def visit_class_def(expr, env)
      functions = {}
      expr.functions.each { |e| functions[e.name.to_sym] = visit_expr(e, env) }
      env[expr.name] = Clarke::Runtime::Class.new(expr.name, functions)
    end

    def visit_fun_def(expr, env)
      Clarke::Runtime::Function.new(expr.argument_names, expr.body, env)
    end

    # TODO: turn this into a visitor
    def visit_expr(expr, env)
      case expr
      when Clarke::AST::IntegerLiteral
        Clarke::Runtime::Integer.new(expr.value)
      when Clarke::AST::TrueLiteral
        Clarke::Runtime::True
      when Clarke::AST::FalseLiteral
        Clarke::Runtime::False
      when Clarke::AST::StringLiteral
        Clarke::Runtime::String.new(expr.value)
      when Clarke::AST::FunctionCall
        visit_function_call(expr, env)
      when Clarke::AST::GetProp
        visit_get_prop(expr, env)
      when Clarke::AST::Var
        visit_var(expr, env)
      when Clarke::AST::VarDecl
        visit_var_decl(expr, env)
      when Clarke::AST::Assignment
        visit_assignment(expr, env)
      when Clarke::AST::Block
        visit_block(expr, env)
      when Clarke::AST::If
        visit_if(expr, env)
      when Clarke::AST::OpSeq
        visit_op_seq(expr, env)
      when Clarke::AST::LambdaDef
        visit_lambda_def(expr, env)
      when Clarke::AST::ClassDef
        visit_class_def(expr, env)
      when Clarke::AST::FunDef
        visit_fun_def(expr, env)
      else
        raise ArgumentError, "don’t know how to handle #{expr.inspect}"
      end
    end

    def visit_exprs(exprs)
      env = Clarke::Util::Env.new(contents: INITIAL_ENV).push
      multi_visit(exprs, env)
    end

    private

    def check_type(val, klass, expr)
      if val.is_a?(klass)
        val
      else
        raise Clarke::Language::TypeError.new(val, [klass], expr)
      end
    end

    def multi_visit(exprs, env)
      exprs.reduce(0) do |_, expr|
        visit_expr(expr, env)
      end
    end
  end
end
