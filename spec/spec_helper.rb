# frozen_string_literal: true

require 'rspec'
require 'coveralls'
require 'fuubar'

Coveralls.wear!

require 'clarke'

module Helpers
  def run(string, mode: :eval)
    Clarke.run(string, mode: mode, verbose: false)
  end
end

RSpec.configure do |c|
  c.include Helpers

  c.fuubar_progress_bar_options = {
    format: '%c/%C |<%b>%i| %p%%',
  }
end

RSpec::Matchers.define :evaluate_to do |expected|
  include RSpec::Matchers::Composable

  match do |input|
    old_stdout = $stdout
    $stdout = StringIO.new
    @actual = run(input)
    $stdout = old_stdout

    values_match?(expected, @actual)
  end

  failure_message do |input|
    "expected #{input.inspect} to evaluate to #{expected}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to evaluate to #{expected}"
  end
end

RSpec::Matchers.define :have_type do |expected|
  include RSpec::Matchers::Composable

  match do |input|
    old_stdout = $stdout
    $stdout = StringIO.new
    @exprs = run(input, mode: :resolve)
    $stdout = old_stdout

    values_match?(expected, @exprs.last.type)
  end

  failure_message do |input|
    "expected #{input.inspect} to have type #{expected}, but was #{@exprs.last.type.inspect}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to have type #{expected}"
  end
end

RSpec::Matchers.define :instance_type do |expected|
  match do |input|
    input.is_a?(Clarke::Sym::InstanceType) && input.klass.name == expected
  end

  failure_message do |input|
    "expected #{input.inspect} to be an instance of #{expected}, but was #{input.klass.name}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to be an instance of #{expected}"
  end
end

RSpec::Matchers.define :function_type do |expected_name, expected_ret_type = nil|
  match do |input|
    input.is_a?(Clarke::Sym::Fun) &&
      input.name == expected_name &&
      (expected_ret_type.nil? || input.ret_type == expected_ret_type)
  end

  failure_message do |input|
    "expected #{input.inspect} to be a function named #{expected}, but was #{input.name}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to be a function named #{expected}"
  end
end

RSpec::Matchers.define :a_clarke_instance_of do |expected|
  match do |input|
    input.is_a?(Clarke::Interpreter::Runtime::Instance) && input.klass == expected
  end

  failure_message do |input|
    "expected #{input.inspect} to be a Clarke instance of #{expected}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to be a Clarke instance of #{expected}"
  end
end

RSpec::Matchers.define :a_clarke_array_containing do |expected|
  match do |input|
    input.is_a?(Clarke::Interpreter::Runtime::Instance) && input.klass.name == 'Array' && input.internal_state.fetch(:contents) == expected
  end

  failure_message do |input|
    "expected #{input.inspect} to be a Clarke array containing #{expected.inspect}"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to be a Clarke array containing #{expected.inspect}"
  end
end

RSpec::Matchers.define :fail_with do |expected|
  match do |input|
    @actual = error_for(input)
    @actual.is_a?(expected)
  end

  def error_for(input)
    run(input)
    nil
  rescue StandardError => e
    e
  end

  failure_message do |input|
    if @actual
      "expected #{input.inspect} to fail, but with #{expected} rather than #{@actual.class} (“#{@actual.message}”)"
    else
      "expected #{input.inspect} to fail with #{expected}, but it didn’t"
    end
  end

  failure_message_when_negated do |input|
    if @actual
      "expected #{input.inspect} not to fail with #{expected}, but it did"
    else
      "expected #{input.inspect} not to fail, but with #{expected} rather than #{@actual.class} (“#{@actual.message}”)"
    end
  end
end
