# frozen_string_literal: true

require 'rspec'
require 'coveralls'
require 'fuubar'

Coveralls.wear!

require 'clarke'

module Helpers
  def run(string)
    error = nil
    ret = Clarke.run(string, verbose: false) { |e| error = e }
    error || ret
  end
end

RSpec.configure do |c|
  c.include Helpers

  c.fuubar_progress_bar_options = {
    format: '%c/%C |<%b>%i| %p%%',
  }
end

RSpec::Matchers.define :evaluate_to do |expected|
  match do |input|
    @actual = run(input)
    @actual == expected
  end

  failure_message do |input|
    "expected #{input.inspect} to evaluate to #{expected} (but was #{@actual.inspect})"
  end

  failure_message_when_negated do |input|
    "expected #{input.inspect} not to evaluate to #{expected} (but was #{@actual.inspect})"
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
    if actual
      "expected #{input.inspect} to fail, but with #{expected} rather than #{@actual_class}"
    else
      "expected #{input.inspect} to fail with #{expected}, but it didn’t"
    end
  end

  failure_message_when_negated do |input|
    if actual
      "expected #{input.inspect} not to fail with #{expected}, but it did"
    else
      "expected #{input.inspect} not to fail, but with #{expected} rather than #{@actual_class}"
    end
  end
end
