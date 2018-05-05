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
    LOWERCASE_LETTER = char_in('a'..'z')
    UPPERCASE_LETTER = char_in('A'..'Z')
    LETTER = alt(LOWERCASE_LETTER, UPPERCASE_LETTER)
    UNDERSCORE = char('_')

    # Primitives

    NUMBER =
      repeat1(DIGIT)
      .capture
      .map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::IntegerLit.new(value: data.to_i, context: context)
      end

    TRUE =
      string('true').map do |_data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::TrueLit.new(context: context)
      end

    FALSE =
      string('false').map do |_data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::FalseLit.new(context: context)
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::StringLit.new(value: data.join(''), context: context)
      end

    # … Other …

    RESERVED_WORD =
      describe(
        alt(
          string('any'),
          string('class'),
          string('else'),
          string('false'),
          string('fun'),
          string('if'),
          string('let'),
          string('true'),
        ),
        'reserved keyword',
      )

    IDENTIFIER_TAIL =
      repeat0(
        alt(
          LETTER,
          UNDERSCORE,
          NUMBER,
        ),
      )

    NAME =
      except(
        describe(
          seq(
            alt(UNDERSCORE, LOWERCASE_LETTER, UPPERCASE_LETTER),
            IDENTIFIER_TAIL,
          ),
          'NAME',
        ),
        RESERVED_WORD,
      ).capture

    VAR_NAME =
      except(
        describe(
          seq(
            alt(UNDERSCORE, LOWERCASE_LETTER),
            IDENTIFIER_TAIL,
          ),
          'VAR_NAME',
        ),
        RESERVED_WORD,
      ).capture

    FUN_NAME =
      except(
        describe(
          seq(
            alt(UNDERSCORE, LOWERCASE_LETTER),
            IDENTIFIER_TAIL,
          ),
          'FUN_NAME',
        ),
        RESERVED_WORD,
      ).capture

    CLASS_NAME =
      except(
        describe(
          seq(
            alt(UNDERSCORE, UPPERCASE_LETTER),
            IDENTIFIER_TAIL,
          ),
          'CLASS_NAME',
        ),
        RESERVED_WORD,
      ).capture

    TYPE_NAME = alt(
      CLASS_NAME,
      string('any'),
    )

    REF =
      NAME.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Ref.new(name: data, context: context)
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
        REF,
        lazy { GROUPED_EXPR },
      )

    CALL_EXT =
      ARG_LIST.map { |d| [:call, d] }

    GET_PROP_EXT =
      seq(
        char('.').ignore,
        NAME,
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        data[1].reduce(data[0]) do |base, ext|
          case ext[0]
          when :call
            Clarke::AST::FunCall.new(base: base, arguments: ext[1], context: context)
          when :prop
            Clarke::AST::GetProp.new(base: base, name: ext[1], context: context)
          end
        end
      end

    BLOCK =
      seq(
        char('{').ignore,
        WS0.ignore,
        intersperse(lazy { STATEMENT }, WS1).select_even,
        WS0.ignore,
        char('}').ignore,
      ).compact.first.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Block.new(exprs: data, context: context)
      end

    ASSIGNMENT =
      seq(
        VAR_NAME,
        WS0.ignore,
        char('=').ignore,
        WS0.ignore,
        lazy { EXPR },
      ).compact.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Assignment.new(var_name: data[0], expr: data[1], context: context)
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::VarDef.new(var_name: data[0], expr: data[1], context: context)
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::If.new(cond: data[0], body_true: data[1], body_false: data[2], context: context)
      end

    PARAM_LIST =
      seq(
        char('(').ignore,
        opt(
          intersperse(
            seq(
              WS0.ignore,
              VAR_NAME,
              opt(
                seq(
                  char(':').ignore,
                  WS1.ignore,
                  TYPE_NAME,
                ),
              ),
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::LambdaDef.new(parameters: data[0], body: data[1], context: context)
      end

    ARROW_LAMBDA_DEF =
      seq(
        PARAM_LIST,
        WS0.ignore,
        string('=>').ignore,
        WS0.ignore,
        lazy { EXPR },
      ).compact.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::LambdaDef.new(
          parameters: data[0],
          body: Clarke::AST::Block.new(exprs: [data[1]], context: context),
          context: context,
        )
      end

    LAMBDA_DEF =
      alt(
        FUN_LAMBDA_DEF,
        ARROW_LAMBDA_DEF,
      )

    FUN_DEF =
      seq(
        string('fun').ignore,
        WS1.ignore,
        FUN_NAME,
        PARAM_LIST,
        WS0.ignore,
        BLOCK,
      ).compact.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::FunDef.new(name: data[0], parameters: data[1], body: data[2], context: context)
      end

    PROP_DECL =
      seq(
        string('prop').ignore,
        WS1.ignore,
        VAR_NAME,
      ).compact.first.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::PropDecl.new(name: data, context: context)
      end

    CLASS_BODY_STMT =
      alt(
        FUN_DEF,
        PROP_DECL,
      )

    CLASS_DEF =
      seq(
        string('class').ignore,
        WS1.ignore,
        CLASS_NAME,
        WS1.ignore,
        char('{').ignore,
        WS0.ignore,
        opt(
          intersperse(
            CLASS_BODY_STMT,
            WS0,
          ).select_even,
        ),
        WS0.ignore,
        char('}').ignore,
      ).compact.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::ClassDef.new(name: data[0], members: data[1] || [], context: context)
      end

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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::Op.new(name: data, context: context)
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
        REF,
        CLASS_DEF,
        FUN_DEF,
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
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::OpSeq.new(seq: data, context: context)
      end

    SET_PROP =
      seq(
        REF, # TODO: support more complex setters
        char('.').ignore,
        NAME,
        WS0.ignore,
        char('=').ignore,
        WS0.ignore,
        EXPR,
      ).compact.map do |data, success, old_pos|
        context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
        Clarke::AST::SetProp.new(base: data[0], name: data[1], value: data[2], context: context)
      end

    STATEMENT =
      alt(
        SET_PROP,
        EXPR,
      )

    STATEMENTS =
      intersperse(
        STATEMENT,
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
