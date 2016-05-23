module Clarke
  class Evaluator
    class Env
      def initialize(stack: [{}])
        @stack = stack
      end

      def merge(env)
        if block_given?
          yield(merge(env))
        else
          Env.new(stack: @stack + [env])
        end
      end

      def fetch(key)
        env = @stack.reverse_each.find { |env| env.key?(key) }
        env.fetch(key)
      end
    end

    class Result
      attr_reader :env
      attr_reader :value

      def initialize(env:, value:)
        @env = env
        @value = value
      end
    end

    def new_env
      Env.new(
        stack: [
          {
            'print'   => -> (a) { puts(a.to_s) },

            '_op_add' => -> (a, b) { a+b },
            '_op_sub' => -> (a, b) { a-b },
            '_op_mul' => -> (a, b) { a*b },

            '_op_gt'  => -> (a, b) { a > b  ? 1 : 0 },
            '_op_gte' => -> (a, b) { a >= b ? 1 : 0 },
            '_op_lt'  => -> (a, b) { a < b  ? 1 : 0 },
            '_op_lte' => -> (a, b) { a <= b ? 1 : 0 },
            '_op_eq'  => -> (a, b) { a == b ? 1 : 0 },
          },
        ],
      )
    end

    def evaluate_array(nodes, env: {})
      init = Result.new(env: env, value: 0)
      nodes.reduce(init) do |result, node|
        evaluate(node, env: result.env)
      end
    end

    def evaluate(node, env: {})
      case node
      when Clarke::AST::Def
        Result.new(
          env: env.merge(node.name => node),
          value: 0,
        )
      when Clarke::AST::If
        cond_value = evaluate(node.cond, env: env).value
        if cond_value != 0
          evaluate_array(node.body_true, env: env)
        elsif node.body_false
          evaluate_array(node.body_false, env: env)
        else
          Result.new(env: env, value: 0)
        end
      when Clarke::AST::Var
        Result.new(env: env, value: env.fetch(node.name))
      when Clarke::AST::Int
        Result.new(env: env, value: node.value)
      when Clarke::AST::Call
        arg_values = node.args.map { |n| evaluate(n, env: env).value }
        def_node = env.fetch(node.name)
        case def_node
        when Clarke::AST::Def
          arg_names = def_node.args.map { |a| a.name }
          result =
            env.merge(Hash[arg_names.zip(arg_values)]) do |new_env|
              evaluate_array(def_node.body, env: new_env)
            end
          Result.new(env: env, value: result.value)
        when Proc
          Result.new(env: env, value: def_node[*arg_values])
        end
      when Clarke::AST::Assign
        new_env = env.merge(node.var.name => evaluate(node.value, env: env).value)
        Result.new(env: new_env, value: 0)
      else
        raise ArgumentError, "Cannot evaluate #{node.inspect}"
      end
    end
  end
end
