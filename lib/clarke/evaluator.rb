# frozen_string_literal: true

module Clarke
  class Evaluator
    class Error < StandardError
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def fancy_message
        fancy_message_for(@expr.input, @expr.old_pos, @expr.new_pos)
      end

      def fancy_message_for(input, old_pos, new_pos)
        lines = []
        lines << "line #{old_pos.line + 1}: #{message}"
        lines << ''
        lines << (input.lines[old_pos.line] || '').rstrip
        lines << "\e[31m" + ' ' * old_pos.column + ('~' * (new_pos.column - old_pos.column)) + "\e[0m"
        lines.join("\n")
      end
    end

    class NameError < Error
      attr_reader :name

      def initialize(name, expr)
        super(expr)

        @name = name
      end

      def message
        "#{@name}: no such name"
      end
    end

    class TypeError < Error
      attr_reader :val, :klass

      def initialize(val, klass, expr)
        super(expr)

        @val = val
        @klass = klass
      end

      def message
        "expected #{@klass.describe}, but got #{@val.describe}"
      end
    end

    class ArgumentCountError < Error
      attr_reader :actual
      attr_reader :expected

      def initialize(actual:, expected:, expr:)
        super(expr)

        @actual = actual
        @expected = expected
      end

      def message
        "wrong number of arguments: expected #{@expected}, but got #{@actual}"
      end
    end

    Function = Struct.new(:argument_names, :body, :env) do
      def describe
        'function'
      end

      def self.describe
        'function'
      end
    end

    Integer = Struct.new(:value) do
      def describe
        'integer'
      end

      def self.describe
        'integer'
      end

      def add(other)
        Integer.new(value + other.value)
      end

      def subtract(other)
        Integer.new(value - other.value)
      end

      def multiply(other)
        Integer.new(value * other.value)
      end

      def divide(other)
        Integer.new(value / other.value)
      end

      def exponentiate(other)
        Integer.new(value**other.value)
      end

      def eq(other)
        Boolean.new(value == other.value)
      end

      def gt(other)
        Boolean.new(value > other.value)
      end

      def lt(other)
        Boolean.new(value < other.value)
      end

      def gte(other)
        Boolean.new(value >= other.value)
      end

      def lte(other)
        Boolean.new(value <= other.value)
      end
    end

    Boolean = Struct.new(:value) do
      def describe
        'boolean'
      end

      def self.describe
        'boolean'
      end

      def eq(other)
        value == other.value ? True : False
      end

      def and(other)
        value && other.value ? True : False
      end

      def or(other)
        value || other.value ? True : False
      end
    end

    True = Boolean.new(true)
    False = Boolean.new(false)

    class Env
      def initialize(parent: nil, contents: {})
        @parent = parent
        @contents = contents
      end

      def key?(key)
        @contents.key?(key) || (@parent&.key?(key))
      end

      def fetch(key, expr: nil)
        if @parent
          @contents.fetch(key) { @parent.fetch(key, expr: expr) }
        else
          @contents.fetch(key) { raise NameError.new(key, expr) }
        end
      end

      def []=(key, value)
        @contents[key] = value
      end

      def merge(hash)
        pushed = push
        hash.each { |k, v| pushed[k] = v }
        pushed
      end

      def push
        self.class.new(parent: self)
      end
    end

    INITIAL_ENV = {
      'print' => Function.new(['a'], ->(a) { puts(a.value.inspect) }),
    }.freeze

    def eval_function_call(expr, env)
      function = check_type(env.fetch(expr.name, expr: expr), Function, expr)

      if expr.arguments.count != function.argument_names.size
        raise ArgumentCountError.new(expected: function.argument_names.size, actual: expr.arguments.count, expr: expr)
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
      res = check_type(eval_expr(expr.cond, env), Boolean, expr)

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

      rpn_seq = shunting_yard(
        values,
        Clarke::Language::PRECEDENCES,
        Clarke::Language::ASSOCIATIVITIES,
      )
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
      Function.new(expr.argument_names, expr.body, env)
    end

    def eval_expr(expr, env)
      case expr
      when Clarke::AST::IntegerLiteral
        Integer.new(expr.value)
      when Clarke::AST::TrueLiteral
        True
      when Clarke::AST::FalseLiteral
        False
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
        raise ArgumentError
      end
    end

    def eval_exprs(exprs)
      env = Env.new(contents: INITIAL_ENV).push
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
        raise TypeError.new(val, klass, expr)
      end
    end
  end
end
