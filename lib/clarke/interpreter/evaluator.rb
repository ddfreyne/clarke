# frozen_string_literal: true

module Clarke
  module Interpreter
    class Evaluator < Clarke::Visitor
      def initialize(global_scope)
        @global_scope = global_scope
      end

      def check_argument_count(function, arguments)
        if arguments.count != function.parameters.size
          raise Clarke::Language::ArgumentCountError.new(
            expected: function.parameters.size,
            actual: arguments.count,
          )
        end
      end

      def visit_function_call(expr, env)
        base = visit_expr(expr.base, env)
        values = expr.arguments.map { |e| visit_expr(e, env) }

        if base.is_a?(Clarke::Interpreter::Runtime::Fun)
          check_argument_count(base, values)
          base.call(values, self)
        elsif base.is_a?(Clarke::Interpreter::Runtime::Class)
          instance = Clarke::Interpreter::Runtime::Instance.new(props: {}, klass: base)

          init = base.functions[:init]
          if init
            check_argument_count(init, values)
            init.bind(instance).call(values, self)
          end

          instance
        else
          raise Clarke::Language::TypeError.new(base, [Clarke::Interpreter::Runtime::Fun, Clarke::Interpreter::Runtime::Class], expr.base)
        end
      end

      def visit_get_prop(expr, env)
        base_value = visit_expr(expr.base, env)
        name = expr.name.to_sym

        unless base_value.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Language::NameError.new(name)
        end

        if base_value.props.key?(name)
          base_value.props.fetch(name)
        elsif base_value.klass&.functions&.key?(name)
          base_value.klass.functions.fetch(name).bind(base_value)
        else
          raise Clarke::Language::NameError.new(name)
        end
      end

      def visit_var(expr, env)
        sym = expr.scope.resolve(expr.name)
        env.fetch(sym)
      end

      def visit_var_def(expr, env)
        value = visit_expr(expr.expr, env)
        sym = expr.scope.resolve(expr.variable_name)
        env[sym] = value
        value
      end

      def visit_assignment(expr, env)
        sym = expr.scope.resolve(expr.variable_name)

        value = visit_expr(expr.expr, env)
        env.containing(sym)[sym] = value
        value
      end

      def visit_block(expr, env)
        multi_visit(expr.exprs, env.push)
      end

      def visit_if(expr, env)
        res = check_type(visit_expr(expr.cond, env), Clarke::Interpreter::Runtime::Boolean, expr)

        if res.value
          visit_expr(expr.body_true, env)
        else
          visit_expr(expr.body_false, env)
        end
      end

      def visit_op_add(expr, env)
        visit_expr(expr.lhs, env).add(visit_expr(expr.rhs, env))
      end

      def visit_op_subtract(expr, env)
        visit_expr(expr.lhs, env).subtract(visit_expr(expr.rhs, env))
      end

      def visit_op_multiply(expr, env)
        visit_expr(expr.lhs, env).multiply(visit_expr(expr.rhs, env))
      end

      def visit_op_divide(expr, env)
        visit_expr(expr.lhs, env).divide(visit_expr(expr.rhs, env))
      end

      def visit_op_exponentiate(expr, env)
        visit_expr(expr.lhs, env).exponentiate(visit_expr(expr.rhs, env))
      end

      def visit_op_eq(expr, env)
        visit_expr(expr.lhs, env).eq(visit_expr(expr.rhs, env))
      end

      def visit_op_gt(expr, env)
        visit_expr(expr.lhs, env).gt(visit_expr(expr.rhs, env))
      end

      def visit_op_lt(expr, env)
        visit_expr(expr.lhs, env).lt(visit_expr(expr.rhs, env))
      end

      def visit_op_gte(expr, env)
        visit_expr(expr.lhs, env).gte(visit_expr(expr.rhs, env))
      end

      def visit_op_lte(expr, env)
        visit_expr(expr.lhs, env).lte(visit_expr(expr.rhs, env))
      end

      def visit_op_and(expr, env)
        visit_expr(expr.lhs, env).and(visit_expr(expr.rhs, env))
      end

      def visit_op_or(expr, env)
        visit_expr(expr.lhs, env).or(visit_expr(expr.rhs, env))
      end

      def visit_lambda_def(expr, env)
        Clarke::Interpreter::Runtime::Fun.new(
          parameters: expr.parameters,
          body: expr.body,
          env: env,
          scope: expr.scope,
        )
      end

      def visit_class_def(expr, env)
        functions = {}
        expr.functions.each { |e| functions[e.name.to_sym] = visit_expr(e, env) }
        sym = expr.scope.resolve(expr.name)
        env[sym] = Clarke::Interpreter::Runtime::Class.new(name: expr.name, functions: functions)
      end

      def visit_fun_def(expr, env)
        Clarke::Interpreter::Runtime::Fun.new(
          parameters: expr.parameters,
          body: expr.body,
          env: env,
          scope: expr.body.scope,
        )
      end

      def visit_set_prop(expr, env)
        base_value = visit_expr(expr.base, env)

        unless base_value.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Language::NameError.new(expr.name)
        end

        base_value.props[expr.name.to_sym] = visit_expr(expr.value, env)
      end

      # TODO: turn this into a visitor
      def visit_expr(expr, env)
        case expr
        when Clarke::AST::IntegerLit
          Clarke::Interpreter::Runtime::Integer.new(value: expr.value)
        when Clarke::AST::TrueLit
          Clarke::Interpreter::Runtime::True
        when Clarke::AST::FalseLit
          Clarke::Interpreter::Runtime::False
        when Clarke::AST::StringLit
          Clarke::Interpreter::Runtime::String.new(value: expr.value)
        when Clarke::AST::FunCall
          visit_function_call(expr, env)
        when Clarke::AST::GetProp
          visit_get_prop(expr, env)
        when Clarke::AST::Var
          visit_var(expr, env)
        when Clarke::AST::VarDef
          visit_var_def(expr, env)
        when Clarke::AST::Assignment
          visit_assignment(expr, env)
        when Clarke::AST::Block
          visit_block(expr, env)
        when Clarke::AST::If
          visit_if(expr, env)
        when Clarke::AST::OpAdd
          visit_op_add(expr, env)
        when Clarke::AST::OpSubtract
          visit_op_subtract(expr, env)
        when Clarke::AST::OpMultiply
          visit_op_multiply(expr, env)
        when Clarke::AST::OpDivide
          visit_op_divide(expr, env)
        when Clarke::AST::OpExponentiate
          visit_op_exponentiate(expr, env)
        when Clarke::AST::OpEq
          visit_op_eq(expr, env)
        when Clarke::AST::OpGt
          visit_op_gt(expr, env)
        when Clarke::AST::OpLt
          visit_op_lt(expr, env)
        when Clarke::AST::OpGte
          visit_op_gte(expr, env)
        when Clarke::AST::OpLte
          visit_op_lte(expr, env)
        when Clarke::AST::OpAnd
          visit_op_and(expr, env)
        when Clarke::AST::OpOr
          visit_op_or(expr, env)
        when Clarke::AST::LambdaDef
          visit_lambda_def(expr, env)
        when Clarke::AST::ClassDef
          visit_class_def(expr, env)
        when Clarke::AST::FunDef
          visit_fun_def(expr, env)
        when Clarke::AST::SetProp
          visit_set_prop(expr, env)
        else
          raise ArgumentError, "don’t know how to handle #{expr.inspect}"
        end
      rescue Clarke::Language::Error => e
        e.expr = expr unless e.expr
        raise e
      end

      def visit_exprs(exprs)
        env = Clarke::Util::Env.new

        Clarke::Interpreter::Init::CONTENTS.each_pair do |name, val|
          sym = @global_scope.resolve(name)
          env[sym] = val
        end

        env = env.push
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
end
