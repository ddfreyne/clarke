# frozen_string_literal: true

module Clarke
  module Parser
    # Replaces OpSeq nodes with binary Op* nodes.
    class SimplifyOpSeq < Clarke::Transformer
      PRECEDENCES = {
        '^' => 3,
        '*' => 2,
        '/' => 2,
        '+' => 1,
        '-' => 1,
        '&&' => 0,
        '||' => 0,
        '==' => 0,
        '>'  => 0,
        '<'  => 0,
        '>=' => 0,
        '<=' => 0,
      }.freeze

      ASSOCIATIVITIES = {
        '^' => :right,
        '*' => :left,
        '/' => :left,
        '+' => :left,
        '-' => :left,
        '==' => :left,
        '>'  => :left,
        '<'  => :left,
        '>=' => :left,
        '<=' => :left,
        '&&' => :left,
        '||' => :left,
      }.freeze

      def visit_op_seq(expr)
        if expr.seq.size == 1
          visit_expr(expr.seq.first)
        else
          values =
            expr.seq.map do |e|
              case e
              when Clarke::AST::Op
                e
              else
                visit_expr(e)
              end
            end

          shunting_yard = Clarke::Util::ShuntingYard.new(
            PRECEDENCES,
            ASSOCIATIVITIES,
          )

          rpn_seq = shunting_yard.run(values)
          stack = []
          rpn_seq.each do |e|
            case e
            when Clarke::AST::Op
              operands = stack.pop(2)

              klass =
                case e.name
                when '+'
                  Clarke::AST::OpAdd
                when '-'
                  Clarke::AST::OpSubtract
                when '*'
                  Clarke::AST::OpMultiply
                when '/'
                  Clarke::AST::OpDivide
                when '^'
                  Clarke::AST::OpExponentiate
                when '=='
                  Clarke::AST::OpEq
                when '>'
                  Clarke::AST::OpGt
                when '<'
                  Clarke::AST::OpLt
                when '>='
                  Clarke::AST::OpGte
                when '<='
                  Clarke::AST::OpLte
                when '&&'
                  Clarke::AST::OpAnd
                when '||'
                  Clarke::AST::OpOr
                else
                  raise "unknown operator: #{e}"
                end

              # FIXME: context is not tight enough
              stack << klass.new(lhs: operands[0], rhs: operands[1], context: expr.context)
            else
              stack << e
            end
          end

          stack.first
        end
      end
    end
  end
end
