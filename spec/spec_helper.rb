# frozen_string_literal: true

require 'rspec'
require 'coveralls'

Coveralls.wear!

require 'clarke'

module Helpers
  def run(string)
    res = Clarke::Grammar::PROGRAM.apply(string)
    case res
    when DParse::Success
      evaluator = Clarke::Evaluator.new
      evaluator.eval_exprs(res.data)
    when DParse::Failure
      res
    end
  end
end

RSpec.configure do |c|
  c.include Helpers
end

RSpec::Matchers.define :evaluate_to do |expected|
  match do |input|
    run(input) == expected
  end

  failure_message do |input|
    "expected #{input.inspect} to evaluate to #{expected} (but was #{run(input).inspect})"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to evaluate to #{expected} (but was #{run(input).inspect})"
  end
end

RSpec::Matchers.define :fail_with do |expected|
  match do |input|
    res = error_for(input)

    case expected
    when String
      res.is_a?(DParse::Failure) && res.message == expected
    else
      res.is_a?(expected)
    end
  end

  def error_for(input)
    res = run(input)
    if res.is_a?(DParse::Failure)
      res
    else
      nil
    end
  rescue Clarke::Evaluator::Error => e
    e
  end

  failure_message do |input|
    actual = error_for(input)
    if actual
      "expected #{input.inspect} to fail, but with #{expected} rather than #{actual}"
    else
      "expected #{input.inspect} to fail with #{expected}, but it didn’t"
    end
  end

  failure_message_when_negated do |input|
    actual = error_for(input)
    if actual
      "expected #{input.inspect} not to fail with #{expected}, but it did"
    else
      "expected #{input.inspect} not to fail, but with #{expected} rather than #{actual}"
    end
  end
end
