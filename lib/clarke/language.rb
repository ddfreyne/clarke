# frozen_string_literal: true

module Clarke
  module Language
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
  end
end
