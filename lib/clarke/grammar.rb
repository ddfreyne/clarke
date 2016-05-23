require 'd-parse'

module Clarke
  module Grammar
    extend DParse::DSL

    # primitives

    DIGIT = char_in('0'..'9')
    LETTER = char_in('a'..'z')
    UNDERSCORE = char('_')
    LPAREN = char('(')
    RPAREN = char(')')
    COMMA = char(',')
    SEMICOLON = char(';')
    LBRACE = char('{')
    RBRACE = char('}')

    # basic

    IDENTIFIER_CHAR =
      alt(
        LETTER,
        UNDERSCORE,
      )

    IDENTIFIER =
      describe(
        seq(
          IDENTIFIER_CHAR,
          repeat(IDENTIFIER_CHAR),
        ).capture,
        'identifier',
      )

    INTEGER =
      seq(
        DIGIT,
        repeat(DIGIT),
      ).capture.map { |d| Clarke::AST::Int.new(value: d.to_i(10)) }

    VAR =
      IDENTIFIER.map { |d| Clarke::AST::Var.new(name: d) }

    EOF =
      seq(
        opt(char("\n")),
        eof,
      )

    WHITESPACE_CHAR =
      alt(
        char(' '),
        char("\t"),
        char("\n"),
        char("\r"),
      )

    WHITESPACE0 =
      repeat(WHITESPACE_CHAR)

    WHITESPACE1 =
      seq(WHITESPACE_CHAR, WHITESPACE0)

    # complex

    FUNDEF_ARGLIST =
      opt(
        intersperse(
          VAR,
          seq(
            COMMA,
            WHITESPACE0,
          ),
        ).select_even,
      ).map { |d| d || [] }

    FUNDEF =
      seq(
        string('def').ignore,
        WHITESPACE1.ignore,
        IDENTIFIER,
        LPAREN.ignore,
        FUNDEF_ARGLIST,
        RPAREN.ignore,
        WHITESPACE1.ignore,
        LBRACE.ignore,
        WHITESPACE0.ignore,
        repeat(lazy { STATEMENT }),
        WHITESPACE0.ignore,
        RBRACE.ignore,
      ).compact.map do |d|
        Clarke::AST::Def.new(
          name: d[0],
          args: d[1],
          body: d[2],
        )
      end

    OPERAND_BASIC =
      alt(
        lazy { FUNCALL },
        INTEGER,
        VAR,
      )

    OPERATOR =
      alt(
        string('>'),
        string('>='),
        string('<'),
        string('<='),
        string('=='),
        string('+'),
        string('*'),
        string('-'),
      ).capture

    OPERATOR_EXPRESSION =
      seq(
        OPERAND_BASIC,
        WHITESPACE0.ignore,
        OPERATOR,
        WHITESPACE0.ignore,
        lazy { EXPRESSION },
      ).compact.map do |d|
        fname =
          case d[1]
          when '>'
            '_op_gt'
          when '>='
            '_op_gte'
          when '<'
            '_op_lt'
          when '<='
            '_op_lte'
          when '=='
            '_op_eq'
          when '+'
            '_op_add'
          when '*'
            '_op_mul'
          when '-'
            '_op_sub'
          end

        Clarke::AST::Call.new(
          name: fname,
          args: [d[0], d[2]],
        )
      end

    EXPRESSION =
      alt(
        lazy { FUNCALL },
        OPERATOR_EXPRESSION,
        INTEGER,
        VAR,
      )

    FUNCALL_ARGLIST =
      opt(
        intersperse(
          EXPRESSION,
          seq(
            COMMA,
            WHITESPACE0,
          ),
        ).select_even,
      ).map { |d| d || [] }

    FUNCALL =
      seq(
        IDENTIFIER,
        LPAREN.ignore,
        FUNCALL_ARGLIST,
        RPAREN.ignore,
      ).compact.map do |d|
        Clarke::AST::Call.new(
          name: d[0],
          args: d[1],
        )
      end

    IF =
      seq(
        string('if').ignore,
        WHITESPACE1.ignore,
        LPAREN.ignore,
        EXPRESSION,
        RPAREN.ignore,
        WHITESPACE0.ignore,
        LBRACE.ignore,
        WHITESPACE0.ignore,
        intersperse(
          lazy { STATEMENT },
          WHITESPACE0.ignore,
        ).compact,
        RBRACE.ignore,
        opt(
          seq(
            WHITESPACE0.ignore,
            string('else').ignore,
            WHITESPACE0.ignore,
            LBRACE.ignore,
            WHITESPACE0.ignore,
            intersperse(
              lazy { STATEMENT },
              WHITESPACE0.ignore,
            ).compact,
            RBRACE.ignore,
          ).compact.first,
        )
      ).compact.map do |d|
        Clarke::AST::If.new(
          cond: d[0],
          body_true: d[1],
          body_false: d[2],
        )
      end

    ASSIGN =
      seq(
        VAR,
        WHITESPACE0.ignore,
        string('=').ignore,
        WHITESPACE0.ignore,
        EXPRESSION,
        SEMICOLON.ignore,
      ).compact.map do |d|
        Clarke::AST::Assign.new(
          var: d[0],
          value: d[1],
        )
      end

    STATEMENT =
      alt(
        FUNDEF,
        IF,
        ASSIGN,
        seq(
          EXPRESSION,
          SEMICOLON.ignore,
          WHITESPACE0.ignore,
        ).compact.first,
      )

    PROGRAM =
      seq(
        intersperse(
          STATEMENT,
          WHITESPACE0.ignore,
        ).compact,
        EOF.ignore,
      ).compact.first
  end
end
