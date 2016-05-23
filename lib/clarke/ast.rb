module Clarke
  module AST
    def self.Node(*args)
      Class.new do
        args.each { |a| attr_reader a }

        define_method(:initialize) do |hash|
          args.each do |a|
            instance_variable_set('@' + a.to_s, hash.fetch(a))
          end
        end
      end
    end

    class Def < Node(:name, :args, :body)
      def pretty_print(pp)
        pp.text('AST:Def(')
        pp.nest(1) do
          pp.text(@name)
          pp.comma_breakable
          pp.pp(@args)
          pp.comma_breakable
          pp.pp(@body)
        end
        pp.text(')')
      end
    end

    class If < Node(:cond, :body_true, :body_false)
      def pretty_print(pp)
        pp.text('AST:If(')
        pp.pp(@cond)
        pp.comma_breakable
        pp.pp(@body_true)
        pp.comma_breakable
        pp.pp(@body_false)
        pp.text(')')
      end
    end

    class Var < Node(:name)
      def pretty_print(pp)
        pp.text('AST:Var(')
        pp.text(@name)
        pp.text(')')
      end
    end

    class Int < Node(:value)
      def pretty_print(pp)
        pp.text('AST:Int(')
        pp.text(@value.to_s)
        pp.text(')')
      end
    end

    class Call < Node(:name, :args)
      def pretty_print(pp)
        pp.text('AST:Call(')
          pp.nest(1) do
          pp.text(@name)
          pp.comma_breakable
          pp.pp(@args)
        end
        pp.text(')')
      end
    end

    class Assign < Node(:var, :value)
      def pretty_print(pp)
        pp.text('AST:Assign(')
          pp.nest(1) do
          pp.pp(@var)
          pp.comma_breakable
          pp.pp(@value)
        end
        pp.text(')')
      end
    end
  end
end
