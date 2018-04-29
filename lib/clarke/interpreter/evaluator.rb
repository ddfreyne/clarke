# frozen_string_literal: true

module Clarke
  module Interpreter
    class Evaluator < Clarke::Visitor
      INITIAL_ENV = {
        'print' => Clarke::Interpreter::Runtime::Function.new(
          parameters: %w[a],
          body: lambda do |_ev, _env, _scope, _expr, a|
            puts(a.clarke_to_string)
            Clarke::Interpreter::Runtime::Null.instance
          end,
          env: Clarke::Util::Env.new,
          scope: Clarke::Util::SymbolTable.new,
        ),
        'Array' => Clarke::Interpreter::Runtime::Class.new(
          name: 'Array',
          functions: {
            init: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[],
              body: lambda do |_ev, env, scope, expr|
                this_sym = scope.resolve('this', expr)
                this = env.fetch(this_sym, expr: expr)
                this.props[:contents] = []
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),
            add: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[elem],
              body: lambda do |_ev, env, scope, expr, elem|
                this_sym = scope.resolve('this', expr)
                this = env.fetch(this_sym, expr: expr)
                this.props[:contents] << elem
                elem
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),
            each: Clarke::Interpreter::Runtime::Function.new(
              parameters: %w[fn],
              body: lambda do |ev, env, scope, expr, fn|
                this_sym = scope.resolve('this', expr)
                this = env.fetch(this_sym, expr: expr)

                param_syms = fn.parameters.map do |e|
                  fn.body.scope.resolve(e, fn.body)
                end

                this.props[:contents].each do |elem|
                  new_env =
                    fn
                    .env
                    .merge(Hash[param_syms.zip([elem])])
                  ev.visit_block(fn.body, new_env)
                end
                Clarke::Interpreter::Runtime::Null.instance
              end,
              env: Clarke::Util::Env.new,
              scope: Clarke::Util::SymbolTable.new.define(Clarke::Language::VarSym.new('this')),
            ),
          },
        ),
      }.freeze

      def initialize(global_scope)
        @global_scope = global_scope
      end

      def visit_function_call(expr, env)
        base = visit_expr(expr.base, env)
        values = expr.arguments.map { |e| visit_expr(e, env) }

        if base.is_a?(Clarke::Interpreter::Runtime::Function)
          function = base

          if expr.arguments.count != function.parameters.size
            raise Clarke::Language::ArgumentCountError.new(
              expected: function.parameters.size,
              actual: expr.arguments.count,
              expr: expr,
            )
          end

          function.call(values, self, expr)
        elsif base.is_a?(Clarke::Interpreter::Runtime::Class)
          instance = Clarke::Interpreter::Runtime::Instance.new(props: {}, klass: base)

          # TODO: verify arg count

          init = base.functions[:init]
          if init
            function = init.bind(instance)
            function.call(values, self, expr)
          end

          instance
        else
          raise Clarke::Language::TypeError.new(base, [Clarke::Interpreter::Runtime::Function, Clarke::Interpreter::Runtime::Class], expr.base)
        end
      end

      def visit_get_prop(expr, env)
        base_value = visit_expr(expr.base, env)
        name = expr.name.to_sym

        unless base_value.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Language::NameError.new(name, expr)
        end

        if base_value.props.key?(name)
          base_value.props.fetch(name)
        elsif base_value.klass&.functions&.key?(name)
          base_value.klass.functions.fetch(name).bind(base_value)
        else
          raise Clarke::Language::NameError.new(name, expr)
        end
      end

      def visit_var(expr, env)
        sym = expr.scope.resolve(expr.name, expr)
        env.fetch(sym, expr: expr)
      end

      def visit_var_decl(expr, env)
        value = visit_expr(expr.expr, env)
        sym = expr.scope.resolve(expr.variable_name, expr)
        env[sym] = value
        value
      end

      def visit_assignment(expr, env)
        sym = expr.scope.resolve(expr.variable_name, expr)

        value = visit_expr(expr.expr, env)
        env[sym] = value
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
        Clarke::Interpreter::Runtime::Function.new(
          parameters: expr.parameters,
          body: expr.body,
          env: env,
          scope: expr.scope,
        )
      end

      def visit_class_def(expr, env)
        functions = {}
        expr.functions.each { |e| functions[e.name.to_sym] = visit_expr(e, env) }
        sym = expr.scope.resolve(expr.name, expr)
        env[sym] = Clarke::Interpreter::Runtime::Class.new(name: expr.name, functions: functions)
      end

      def visit_fun_def(expr, env)
        Clarke::Interpreter::Runtime::Function.new(
          parameters: expr.parameters,
          body: expr.body,
          env: env,
          scope: expr.body.scope,
        )
      end

      def visit_set_prop(expr, env)
        base_value = visit_expr(expr.base, env)

        unless base_value.is_a?(Clarke::Interpreter::Runtime::Instance)
          raise Clarke::Language::NameError.new(expr.name, expr)
        end

        base_value.props[expr.name.to_sym] = visit_expr(expr.value, env)
      end

      # TODO: turn this into a visitor
      def visit_expr(expr, env)
        case expr
        when Clarke::AST::IntegerLiteral
          Clarke::Interpreter::Runtime::Integer.new(value: expr.value)
        when Clarke::AST::TrueLiteral
          Clarke::Interpreter::Runtime::True
        when Clarke::AST::FalseLiteral
          Clarke::Interpreter::Runtime::False
        when Clarke::AST::StringLiteral
          Clarke::Interpreter::Runtime::String.new(value: expr.value)
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
        when Clarke::AST::SetProp
          visit_set_prop(expr, env)
        else
          raise ArgumentError, "don’t know how to handle #{expr.inspect}"
        end
      end

      def visit_exprs(exprs)
        env = Clarke::Util::Env.new

        INITIAL_ENV.each_pair do |name, val|
          sym = @global_scope.resolve(name, nil)
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
