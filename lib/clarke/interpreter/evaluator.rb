# frozen_string_literal: true

module Clarke
  module Interpreter
    class Evaluator < Clarke::Visitor
      def initialize(global_scope, initial_env)
        @global_scope = global_scope
        @initial_env = initial_env
      end

      def check_argument_count(function, arguments)
        if arguments.count != function.params.size
          raise Clarke::Errors::ArgumentCountError.new(
            expected: function.params.size,
            actual: arguments.count,
          )
        end
      end

      def visit_fun_call(expr, env)
        base = visit_expr(expr.base, env)
        values = expr.arguments.map { |e| visit_expr(e, env) }

        if base.is_a?(Clarke::Interpreter::Runtime::Fun)
          check_argument_count(base, values)
          base.call(values, self)
        elsif base.is_a?(Clarke::Interpreter::Runtime::Class)
          instance = Clarke::Interpreter::Runtime::Instance.new(internal_state: {}, env: Clarke::Util::Env.new, klass: base)

          init_sym = base.scope.resolve('init', nil)
          init_fun = init_sym && base.env.fetch(init_sym)
          if init_fun
            check_argument_count(init_fun, values)
            init_fun.bind(instance).call(values, self)
          end

          instance
        else
          raise Clarke::Errors::GenericError.new(
            'Can only call functions and classes; this thing is neither',
            expr: expr.base,
          )
        end
      end

      def visit_get_prop(expr, env)
        base = visit_expr(expr.base, env)
        name = expr.name.to_sym

        unless base.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Errors::NameError.new(name)
        end

        prop_sym = base.klass.scope.resolve(name)
        instance_env = base.env.containing(prop_sym)
        if instance_env
          instance_env.fetch(prop_sym)
        else
          base.klass.env.fetch_member(prop_sym).bind(base)
        end
      end

      def visit_ref(expr, env)
        env.fetch(expr.name_sym)
      end

      def visit_var_def(expr, env)
        env[expr.var_name_sym] = visit_expr(expr.expr, env)
      end

      def visit_assignment(expr, env)
        sym = expr.var_name_sym
        env.containing(sym)[sym] = visit_expr(expr.expr, env)
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
          params: expr.params.map(&:name),
          body: expr.body,
          env: env,
          scope: expr.scope,
        )
      end

      def visit_class_def(expr, env)
        this_sym = expr.scope.resolve('this')

        inner_env = env.push
        klass = Clarke::Interpreter::Runtime::Class.new(name: expr.name, env: inner_env, scope: expr.scope)
        inner_env[this_sym] = klass

        expr.members.each { |e| visit_expr(e, inner_env) }

        env[expr.name_sym] = klass
      end

      def visit_fun_def(expr, env)
        fun =
          Clarke::Interpreter::Runtime::Fun.new(
            params: expr.params.map(&:name),
            body: expr.body,
            env: env,
            scope: expr.scope,
          )

        env[expr.name_sym] = fun
      end

      def visit_prop_decl(_expr, _env); end

      def visit_set_prop(expr, env)
        base_value = visit_expr(expr.base, env)

        unless base_value.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Errors::NameError.new(expr.name)
        end

        instance = base_value
        klass = instance.klass

        value = visit_expr(expr.value, env)

        sym = klass.scope.resolve(expr.name)
        instance.env[sym] = value
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
          visit_fun_call(expr, env)
        when Clarke::AST::GetProp
          visit_get_prop(expr, env)
        when Clarke::AST::Ref
          visit_ref(expr, env)
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
        when Clarke::AST::PropDecl
          visit_prop_decl(expr, env)
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
      rescue Clarke::Errors::Error => e
        e.expr = expr unless e.expr
        raise e
      end

      def visit_exprs(exprs)
        env = @initial_env.push
        multi_visit(exprs, env)
      end

      private

      def check_type(val, klass, expr)
        if val.is_a?(klass)
          val
        else
          raise Clarke::Errors::TypeError.new(val, [klass], expr)
        end
      end

      def multi_visit(exprs, env)
        exprs.reduce(Clarke::Interpreter::Runtime::Null.instance) do |_, expr|
          visit_expr(expr, env)
        end
      end
    end
  end
end
