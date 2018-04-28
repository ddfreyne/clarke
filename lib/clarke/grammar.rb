# frozen_string_literal: true

require 'd-parse'

module Clarke
  module Grammar
    extend DParse::DSL

    # Whitespace

    WS_CHAR =
      alt(
        char(' '),
        char("\t"),
        char("\n"),
        char("\r"),
      )

    SPACE_OR_TAB =
      alt(
        char(' '),
        char("\t"),
      )

    WS0 = repeat0(WS_CHAR)
    WS1 = repeat1(WS_CHAR)

    LINE_BREAK =
      seq(
        repeat(SPACE_OR_TAB),
        char("\n"),
        WS0,
      )

    # Basic components

    DIGIT = char_in('0'..'9')
    LETTER = alt(char_in('a'..'z'), char_in('A'..'Z'))
    UNDERSCORE = char('_')

    # Primitives

    NUMBER =
      repeat1(DIGIT)
      .capture
      .map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::IntegerLiteral.new(data.to_i, context)
      end

    TRUE =
      string('true').map do |_data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::TrueLiteral.new(context)
      end

    FALSE =
      string('false').map do |_data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::FalseLiteral.new(context)
      end

    STRING =
      seq(
        char('"').ignore,
        repeat(
          alt(
            string('\"').capture.map { |_| '"' },
            char_not('"').capture,
          ),
        ),
        char('"').ignore,
      ).compact.first.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::StringLiteral.new(data.join(''), context)
      end

    # … Other …

    RESERVED_WORD =
      describe(
        alt(
          string('else'),
          string('false'),
          string('fun'),
          string('if'),
          string('let'),
          string('true'),
        ),
        'reserved keyword',
      )

    IDENTIFIER =
      except(
        describe(
          seq(
            alt(
              LETTER,
              UNDERSCORE,
            ),
            repeat(
              alt(
                LETTER,
                UNDERSCORE,
                NUMBER,
              ),
            ),
          ).capture,
          'identifier',
        ),
        RESERVED_WORD,
      )

    VAR_NAME = IDENTIFIER

    VAR_REF =
      VAR_NAME.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Var.new(data, context)
      end

    ARG_LIST =
      seq(
        char('(').ignore,
        opt(
          intersperse(
            seq(
              WS0.ignore,
              lazy { EXPR },
              WS0.ignore,
            ).compact.first,
            char(',').ignore,
          ).select_even,
        ).map { |d| d || [] },
        char(')').ignore,
      ).compact.first

    EXT_BASE =
      alt(
        VAR_REF,
        lazy { GROUPED_EXPR },
      )

    CALL_EXT =
      ARG_LIST.map { |d| [:call, d] }

    GET_PROP_EXT =
      seq(
        char('.').ignore,
        IDENTIFIER,
      ).compact.first.map { |d| [:prop, d] }

    EXT_SEQ =
      seq(
        EXT_BASE,
        repeat1(
          alt(
            CALL_EXT,
            GET_PROP_EXT,
          ),
        ),
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        data[1].reduce(data[0]) do |base, ext|
          case ext[0]
          when :call
            Clarke::AST::FunctionCall.new(base, ext[1], context)
          when :prop
            Clarke::AST::GetProp.new(base, ext[1], context)
          end
        end
      end

    BLOCK =
      seq(
        char('{').ignore,
        WS0.ignore,
        intersperse(lazy { EXPR }, WS1).select_even,
        WS0.ignore,
        char('}').ignore,
      ).compact.first.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Block.new(data, context)
      end

    ASSIGNMENT =
      seq(
        VAR_NAME,
        WS0.ignore,
        char('=').ignore,
        WS0.ignore,
        lazy { EXPR },
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Assignment.new(data[0], data[1], context)
      end

    VAR_DECL =
      seq(
        string('let').ignore,
        WS1.ignore,
        VAR_NAME,
        WS0.ignore,
        char('=').ignore,
        WS0.ignore,
        lazy { EXPR },
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::VarDecl.new(data[0], data[1], context)
      end

    IF =
      seq(
        string('if').ignore,
        WS0.ignore,
        char('(').ignore,
        WS0.ignore,
        lazy { EXPR },
        WS0.ignore,
        char(')').ignore,
        WS0.ignore,
        BLOCK,
        WS0.ignore,
        string('else').ignore,
        WS0.ignore,
        BLOCK,
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::If.new(data[0], data[1], data[2], context)
      end

    PARAM_LIST =
      seq(
        char('(').ignore,
        opt(
          intersperse(
            seq(
              WS0.ignore,
              VAR_NAME,
              WS0.ignore,
            ).compact.first,
            char(',').ignore,
          ).select_even,
        ).map { |d| d || [] },
        char(')').ignore,
      ).compact.first

    FUN_LAMBDA_DEF =
      seq(
        string('fun').ignore,
        WS1.ignore,
        PARAM_LIST,
        WS0.ignore,
        BLOCK,
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::LambdaDef.new(data[0], data[1], context)
      end

    ARROW_LAMBDA_DEF =
      seq(
        PARAM_LIST,
        WS0.ignore,
        string('=>').ignore,
        WS0.ignore,
        lazy { EXPR },
      ).compact.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::LambdaDef.new(data[0], Clarke::AST::Block.new([data[1]]), context)
      end

    LAMBDA_DEF =
      alt(
        FUN_LAMBDA_DEF,
        ARROW_LAMBDA_DEF,
      )

    OPERATOR =
      alt(
        char('^'),
        char('*'),
        char('/'),
        char('+'),
        char('-'),
        string('=='),
        string('>='),
        string('>'),
        string('<='),
        string('<'),
        string('&&'),
        string('||'),
      ).capture.map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Op.new(data, context)
      end

    GROUPED_EXPR =
      seq(
        char('(').ignore,
        WS0.ignore,
        lazy { EXPR },
        WS0.ignore,
        char(')').ignore,
      ).compact.first

    OPERAND =
      alt(
        ASSIGNMENT,
        EXT_SEQ,
        FALSE,
        IF,
        LAMBDA_DEF,
        NUMBER,
        GROUPED_EXPR,
        BLOCK,
        STRING,
        TRUE,
        VAR_DECL,
        VAR_REF,
      )

    EXPR =
      intersperse(
        OPERAND,
        seq(
          WS0.ignore,
          OPERATOR,
          WS0.ignore,
        ).compact.first,
      ).map do |data, success, old_pos|
        context = Clarke::AST::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::OpSeq.new(data, context)
      end

    STATEMENTS =
      intersperse(
        EXPR,
        LINE_BREAK,
      ).select_even

    PROGRAM =
      seq(
        WS0.ignore,
        STATEMENTS,
        WS0.ignore,
        eof.ignore,
      ).compact.first
  end
end
