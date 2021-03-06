# frozen_string_literal: true

require 'd-parse'

module Clarke
  module Parser
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
            string('auto'),
            string('bool'),
            string('class'),
            string('else'),
            string('false'),
            string('function'),
            string('fun'),
            string('if'),
            string('int'),
            string('let'),
            string('string'),
            string('true'),
            string('void'),
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
        string('any').capture,
        string('auto').capture,
        string('bool').capture,
        string('function').capture, # TODO: remove
        string('int').capture,
        string('string').capture,
        string('void').capture,
      )

      REF =
        seq(
          opt(char('@').capture),
          NAME,
        ).map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          name = data.take(2).join('') # prefix with sigil
          Clarke::AST::Ref.new(name: name, context: context)
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

      GET_IVAR_EXT =
        seq(
          char('.').ignore,
          NAME,
        ).compact.first.map { |d| [:ivar, d] }

      EXT_SEQ =
        seq(
          EXT_BASE,
          repeat1(
            alt(
              CALL_EXT,
              GET_IVAR_EXT,
            ),
          ),
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          data[1].reduce(data[0]) do |base, ext|
            case ext[0]
            when :call
              Clarke::AST::FunCall.new(base: base, arguments: ext[1], context: context)
            when :ivar
              Clarke::AST::Getter.new(base: base, name: ext[1], context: context)
            end
          end
        end

      BLOCK =
        seq(
          char('{').ignore,
          WS0.ignore,
          opt(
            intersperse(lazy { STATEMENT }, WS1).select_even,
          ).map { |d| d || [] },
          WS0.ignore,
          char('}').ignore,
        ).compact.first.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          Clarke::AST::Block.new(exprs: data, context: context)
        end

      ASSIGNMENT =
        seq(
          opt(char('@').capture).map { |d| d || '' },
          VAR_NAME,
          WS0.ignore,
          char('=').ignore,
          WS0.ignore,
          lazy { EXPR },
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          var_name = data.take(2).join('') # prefix with sigil
          Clarke::AST::Assignment.new(var_name: var_name, expr: data[2], context: context)
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

      TYPE_ANNOTATION =
        opt(
          seq(
            char(':').ignore,
            WS1.ignore,
            TYPE_NAME,
          ).compact.first,
        ).map do |data|
          data || 'auto'
        end

      PARAM_LIST =
        seq(
          char('(').ignore,
          opt(
            intersperse(
              seq(
                WS0.ignore,
                VAR_NAME,
                TYPE_ANNOTATION,
                WS0.ignore,
              ).compact.map do |data, success, old_pos|
                context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
                Clarke::AST::Param.new(name: data[0], type_name: data.fetch(1, 'any'), context: context)
              end,
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
          TYPE_ANNOTATION,
          WS0.ignore,
          BLOCK,
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          Clarke::AST::LambdaDef.new(
            params: data[0],
            ret_type_name: data[1],
            body: data[2],
            context: context,
          )
        end

      ARROW_LAMBDA_DEF =
        seq(
          PARAM_LIST,
          TYPE_ANNOTATION,
          WS0.ignore,
          string('=>').ignore,
          WS0.ignore,
          lazy { EXPR },
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          Clarke::AST::LambdaDef.new(
            params: data[0],
            ret_type_name: data[1],
            body: Clarke::AST::Block.new(exprs: [data[2]], context: context),
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
          TYPE_ANNOTATION,
          WS0.ignore,
          BLOCK,
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          Clarke::AST::FunDef.new(
            name: data[0],
            params: data[1],
            ret_type_name: data[2],
            body: data[3],
            context: context,
          )
        end

      IVAR_DECL =
        seq(
          string('ivar').ignore,
          WS1.ignore,
          VAR_NAME,
          TYPE_ANNOTATION,
        ).compact.map do |data, success, old_pos|
          context = Clarke::Util::Context.new(input: success.input, from: old_pos, to: success.pos)
          Clarke::AST::IvarDecl.new(name: '@' + data[0], type_name: data[1], context: context)
        end

      CLASS_BODY_STMT =
        alt(
          FUN_DEF,
          IVAR_DECL,
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
          Clarke::AST::Setter.new(base: data[0], name: data[1], value: data[2], context: context)
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
end
