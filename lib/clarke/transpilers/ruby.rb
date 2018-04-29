# frozen_string_literal: true

module Clarke
  module Transpilers
    class Ruby
      def initialize(exprs, global_scope)
        @exprs = exprs
        @global_scope = global_scope
      end

      def run
        puts 'print = ->(a) { puts a }'
        puts
        puts @exprs.map { |e| MyVisitor.new.visit_expr(e) }.join("\n")
      end

      class MyVisitor
        def indent(lines)
          lines.each_line.map { |l| '  ' + l.rstrip }.join("\n")
        end

        def visit_block(expr)
          expr.exprs.map { |e| visit_expr(e) }.join("\n")
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

        def visit_integer_lit(expr)
          expr.value.to_s
        end

        def visit_false_lit(_expr)
          'false'
        end

        def visit_fun_call(expr)
          visit_expr(expr.base) + '.(' + expr.arguments.map { |a| visit_expr(a) }.join(', ') + ')'
        end

        def visit_fun_def(expr)
          params = expr.params.any? ? ' |' + expr.params.map(&:name).join(', ') + '|' : ''
          "#{name_for(expr.name_sym)} = lambda do#{params}\n#{indent visit_expr(expr.body)}\nend"
        end

        def visit_lambda_def(expr)
          params = expr.params.any? ? ' |' + expr.params.map(&:name).join(', ') + '|' : ''
          "lambda do#{params}\n#{indent visit_expr(expr.body)}\nend"
        end

        def visit_string_lit(expr)
          expr.value.inspect
        end

        def visit_true_lit(_expr)
          'true'
        end

        def visit_var(expr)
          sym = expr.scope.resolve(expr.name)
          name_for(sym)
        end

        def visit_var_decl(expr)
          sym = expr.scope.resolve(expr.var_name)
          "#{name_for(sym)} = #{visit_expr(expr.expr)}"
        end

        def visit_expr(expr)
          case expr
          when Clarke::AST::IntegerLit
            visit_integer_lit(expr)
          when Clarke::AST::TrueLit
            visit_true_lit(expr)
          when Clarke::AST::FalseLit
            visit_false_lit(expr)
          when Clarke::AST::StringLit
            visit_string_lit(expr)
          when Clarke::AST::FunCall
            visit_fun_call(expr)
          when Clarke::AST::FunDef
            visit_fun_def(expr)
          when Clarke::AST::Getter
            visit_get_prop(expr)
          when Clarke::AST::Ref
            visit_var(expr)
          when Clarke::AST::VarDef
            visit_var_decl(expr)
          when Clarke::AST::Assignment
            visit_assignment(expr)
          when Clarke::AST::Block
            visit_block(expr)
          when Clarke::AST::If
            visit_if(expr)
          when Clarke::AST::Op
            visit_op(expr)
          when Clarke::AST::OpAdd
            visit_op_add(expr)
          when Clarke::AST::OpGt
            visit_op_gt(expr)
          when Clarke::AST::OpSubtract
            visit_op_subtract(expr)
          when Clarke::AST::LambdaDef
            visit_lambda_def(expr)
          when Clarke::AST::ClassDef
            visit_class_def(expr)
          when Clarke::AST::Setter
            visit_set_prop(expr)
          else
            raise ArgumentError, "don’t know how to handle #{expr.inspect}"
          end
        end

        def name_for(sym)
          @name_to_sym ||= {}
          @sym_to_name ||= {}

          @sym_to_name.fetch(sym) do
            candidate = sym.name
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
