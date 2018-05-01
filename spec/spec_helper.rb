# frozen_string_literal: true

require 'rspec'
require 'coveralls'
require 'fuubar'

Coveralls.wear!

require 'clarke'

module Helpers
  def run(string)
    Clarke.run(string, verbose: false)
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
    res = error_for(input)
    @actual = res
    res.is_a?(expected)
  end

  def error_for(input)
    run(input)
    nil
  rescue StandardError => e
    e
  end

  failure_message do |input|
    if @actual
      "expected #{input.inspect} to fail, but with #{expected} rather than #{@actual.inspect}"
    else
      "expected #{input.inspect} to fail with #{expected}, but it didn’t"
    end
  end

  failure_message_when_negated do |input|
    if @actual
      "expected #{input.inspect} not to fail with #{expected}, but it did"
    else
      "expected #{input.inspect} not to fail, but with #{expected} rather than #{@actual.inspect}"
    end
  end
end
