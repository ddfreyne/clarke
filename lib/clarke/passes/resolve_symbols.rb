# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveSymbols < Clarke::Visitor
      def initialize(global_scope)
        @global_scope = global_scope
      end

      def visit_assignment(expr)
        super

        expr.type = expr.expr.type

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.type
      end

      def visit_block(expr)
        super

        # FIXME: handle empty block
        expr.type = expr.exprs.last.type
      end

      def visit_class_def(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)

        expr.type = @global_scope.resolve('void')
      end

      def visit_false_lit(expr)
        super

        expr.type = @global_scope.resolve('bool')
      end

      def visit_fun_call(expr)
        super

        # TODO: verify arg count
        # TODO: verify arg types

        case expr.base.type
        when Clarke::Sym::Class
          expr.type = Clarke::Sym::InstanceType.new(expr.base.type)
        when Clarke::Sym::Fun
          expr.type = expr.base.type.ret_type
        else
          raise Clarke::Errors::TypeError.new(expr.base.type, [Clarke::Sym::Class, Clarke::Sym::Fun], expr.base)
        end
      end

      def visit_fun_def(expr)
        expr.params.each do |param|
          param_sym = expr.scope.resolve(param.name)
          type_sym = expr.scope.resolve(param.type_name)
          param.type_sym = type_sym
          param_sym.type = type_sym
        end

        expr.name_sym = expr.scope.resolve(expr.name)

        expr.name_sym.ret_type = expr.scope.resolve(expr.ret_type_name)

        super

        expr.type = expr.name_sym

        # If the ret type is any, tighten it
        # TODO: maybe don’t
        ret_type = expr.name_sym.ret_type
        if ret_type.is_a?(Clarke::Sym::BuiltinType) && ret_type.name == 'any'
          expr.type.ret_type = expr.body.type
        end
      end

      def visit_get_prop(expr)
        super

        klass =
          case expr.base.type
          when Clarke::Sym::InstanceType
            expr.base.type.klass
          when Clarke::Sym::Class
            # FIXME: this is because expr.base.type.klass is erroneously set to Class rather than InstanceType
            expr.base.type
          else
            raise Clarke::Errors::GenericError.new("can only get props of instances (not #{expr.base.type.inspect})", expr: expr)
          end

        thing = klass.scope.resolve(expr.name)
        case thing
        when Clarke::Sym::Fun
          expr.type = thing
        when Clarke::Sym::Prop
          expr.type = thing.type
        else
          raise Clarke::Errors::NameError.new(expr.name)
        end
      end

      def visit_integer_lit(expr)
        super

        expr.type = @global_scope.resolve('int')
      end

      def visit_lambda_def(expr)
        expr.params.each do |param|
          param_sym = expr.scope.resolve(param.name)
          type_sym = expr.scope.resolve(param.type_name)
          param.type_sym = type_sym
          param_sym.type = type_sym
        end

        ret_type = expr.scope.resolve(expr.ret_type_name)
        expr.type = Clarke::Sym::Fun.new('(anon)', expr.params.count, ret_type)

        super

        # If the ret type is any, tighten it
        # TODO: maybe don’t
        if ret_type.is_a?(Clarke::Sym::BuiltinType) && ret_type.name == 'any'
          expr.type = Clarke::Sym::Fun.new(
            '(anon)', expr.params.count, expr.body.type,
          )
        end
      end

      def visit_op_add(expr)
        super

        types = [expr.lhs, expr.rhs].map(&:type).uniq
        if [expr.lhs, expr.rhs].map(&:type).uniq.size != 1
          # TODO: get a proper exception
          raise Clarke::Errors::GenericError.new("Left-hand side and right-hand side have distinct types (“#{expr.lhs.type}” and “#{expr.rhs.type}”, respectively)", expr: expr)
        end

        # TODO: verify that op exists for this type

        expr.type = types.first
      end

      def visit_op_multiply(expr)
        super

        types = [expr.lhs, expr.rhs].map(&:type).uniq
        if [expr.lhs, expr.rhs].map(&:type).uniq.size != 1
          # TODO: get a proper exception
          raise Clarke::Errors::GenericError.new("Left-hand side and right-hand side have distinct types (“#{expr.lhs.type}” and “#{expr.rhs.type}”, respectively)", expr: expr)
        end

        # TODO: verify that op exists for this type

        expr.type = types.first
      end

      # TODO: handle other op_

      def visit_ref(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
        expr.type = expr.name_sym.type
      end

      def visit_prop_decl(expr)
        super

        # FIXME: name_sym needed?
        expr.name_sym = expr.scope.resolve(expr.name)

        expr.type = @global_scope.resolve('void')
      end

      def visit_set_prop(expr)
        super

        # FIXME: name_sym needed?
        expr.name_sym = expr.base.type.klass.scope.resolve(expr.name)

        expr.type = @global_scope.resolve('void')
      end

      def visit_string_lit(expr)
        super

        expr.type = @global_scope.resolve('string')
      end

      def visit_true_lit(expr)
        super

        expr.type = @global_scope.resolve('bool')
      end

      def visit_var_def(expr)
        super

        expr.var_name_sym = expr.scope.resolve(expr.var_name)

        expr.var_name_sym.type = expr.expr.type

        expr.type = expr.expr.type
      end
    end
  end
end
