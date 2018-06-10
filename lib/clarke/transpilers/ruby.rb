# frozen_string_literal: true

module Clarke
  module Transpilers
    class Ruby
      def initialize(exprs, global_scope)
        @exprs = exprs
        @global_scope = global_scope
      end

      def run
        visitor = MyVisitor.new

        puts 'print = ->(a) { puts a }'
        puts
        puts @exprs.map { |e| visitor.visit_expr(e) }.join("\n")
      end

      class MyVisitor < Clarke::Visitor
        def indent(lines)
          lines.each_line.map { |l| '  ' + l.rstrip }.join("\n")
        end

        def visit_assignment(expr)
          name_for(expr.var_name_sym) + ' = ' + visit_expr(expr.expr)
        end

        def visit_block(expr)
          expr.exprs.map { |e| visit_expr(e) }.join("\n")
        end

        def visit_class_def(expr)
          (+'').tap do |res|
            res << "class #{expr.name}\n"
            res << expr.members
                       .map { |m| indent(visit_expr(m)) + "\n" }
                       .reject { |m| m.strip.empty? }
                       .join("\n")
            res << "end\n"
          end
        end

        def visit_false_lit(_expr)
          'false'
        end

        def visit_fun_call(expr)
          args = expr.arguments.map { |a| visit_expr(a) }.join(', ')

          case expr.base.type
          when Clarke::Sym::Class
            visit_expr(expr.base) + '.new(' + args + ')'
          when Clarke::Sym::Fun
            visit_expr(expr.base) + '.(' + args + ')'
          end
        end

        def visit_fun_def(expr)
          params = '(' + expr.params.map { |pa| visit_expr(pa) }.join(', ') + ')'

          (+'').tap do |res|
            res << "def #{name_for(expr.name_sym)}#{params}" << "\n"
            res << indent(visit_expr(expr.body)) << "\n"
            res << 'end'
          end
        end

        def visit_getter(expr)
          visit_expr(expr.base) + '.' + name_for(expr.name_sym)
        end

        def visit_if(expr)
          (+'').tap do |res|
            res << 'if (' << visit_expr(expr.cond) << ')' << "\n"
            res << indent(visit_expr(expr.body_true)) << "\n"
            res << 'else' << "\n"
            res << indent(visit_expr(expr.body_false)) << "\n"
            res << 'end'
          end
        end

        def visit_integer_lit(expr)
          expr.value.to_s
        end

        def visit_ivar_decl(_expr)
          ''
        end

        def visit_lambda_def(expr)
          params = expr.params.any? ? ' |' + expr.params.map(&:name).join(', ') + '|' : ''
          "lambda do#{params}\n#{indent visit_expr(expr.body)}\nend"
        end

        def visit_op(expr)
          expr.name
        end

        def visit_op_add(expr)
          [expr.lhs, expr.rhs].map { |e| visit_expr(e) }.join(' + ')
        end

        def visit_op_gt(expr)
          [expr.lhs, expr.rhs].map { |e| visit_expr(e) }.join(' > ')
        end

        def visit_op_subtract(expr)
          [expr.lhs, expr.rhs].map { |e| visit_expr(e) }.join(' - ')
        end

        # TODO: visit_op*

        def visit_param(expr)
          name_for(expr.name_sym)
        end

        def visit_ref(expr)
          sym = expr.scope.resolve(expr.name)
          name_for(sym)
        end

        def visit_setter(expr)
          visit_expr(expr.base) + ' = ' + visit_expr(expr.value)
        end

        def visit_string_lit(expr)
          expr.value.inspect
        end

        def visit_true_lit(_expr)
          'true'
        end

        def visit_var_def(expr)
          sym = expr.scope.resolve(expr.var_name)
          "#{name_for(sym)} = #{visit_expr(expr.expr)}"
        end

        def name_for(sym)
          # TODO: make this depend on scope

          @name_to_sym ||= {}
          @sym_to_name ||= {}

          @sym_to_name.fetch(sym) do
            candidate = sym.name

            if candidate == 'init'
              candidate = 'initialize'
            end

            loop do
              if @name_to_sym.key?(candidate)
                candidate += '_'
              else
                @sym_to_name[sym] = candidate
                @name_to_sym[candidate] = sym
                break candidate
              end
            end
          end
        end
      end
    end
  end
end
