# frozen_string_literal: true

describe 'Clarke' do
  it 'handles expressions with any kind of indentation/line breaking' do
    expect('true').to evaluate_to(Clarke::Evaluator::True)
    expect(' true').to evaluate_to(Clarke::Evaluator::True)
    expect(' true ').to evaluate_to(Clarke::Evaluator::True)
    expect(" true\t").to evaluate_to(Clarke::Evaluator::True)
    expect("\ttrue\t").to evaluate_to(Clarke::Evaluator::True)
    expect("\ntrue").to evaluate_to(Clarke::Evaluator::True)
    expect("\rtrue").to evaluate_to(Clarke::Evaluator::True)
    expect("\r\ntrue").to evaluate_to(Clarke::Evaluator::True)
    expect("true\r\n").to evaluate_to(Clarke::Evaluator::True)
    expect("true\r").to evaluate_to(Clarke::Evaluator::True)
    expect("true\n").to evaluate_to(Clarke::Evaluator::True)
  end

  it 'handles booleans' do
    expect('true').to evaluate_to(Clarke::Evaluator::True)
    expect('false').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles integers' do
    expect('0').to evaluate_to(Clarke::Evaluator::Integer.new(0))
    expect('123').to evaluate_to(Clarke::Evaluator::Integer.new(123))
    expect('234').to evaluate_to(Clarke::Evaluator::Integer.new(234))
  end

  it 'handles operator sequences' do
    expect('1+2').to evaluate_to(Clarke::Evaluator::Integer.new(3))
    expect('1+ 2').to evaluate_to(Clarke::Evaluator::Integer.new(3))
    expect('1 +2').to evaluate_to(Clarke::Evaluator::Integer.new(3))
    expect('1 + 2').to evaluate_to(Clarke::Evaluator::Integer.new(3))
  end

  it 'handles addition' do
    expect('0 + 1').to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect('1 + 0').to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect('1 + 1').to evaluate_to(Clarke::Evaluator::Integer.new(2))
  end

  it 'handles subtraction' do
    expect('10 - 5').to evaluate_to(Clarke::Evaluator::Integer.new(5))
    expect('5 - 10').to evaluate_to(Clarke::Evaluator::Integer.new(-5))
    expect('10 - 10').to evaluate_to(Clarke::Evaluator::Integer.new(0))
  end

  it 'handles multiplication' do
    expect('2 * 1').to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect('1 * 2').to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect('2 * 2').to evaluate_to(Clarke::Evaluator::Integer.new(4))
  end

  it 'handles division' do
    expect('2 / 1').to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect('1 / 2').to evaluate_to(Clarke::Evaluator::Integer.new(0))
    expect('2 / 2').to evaluate_to(Clarke::Evaluator::Integer.new(1))
  end

  it 'handles exponentiation' do
    expect('2 ^ 1').to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect('1 ^ 2').to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect('2 ^ 2').to evaluate_to(Clarke::Evaluator::Integer.new(4))
  end

  it 'handles eq' do
    expect('1 == 2').to evaluate_to(Clarke::Evaluator::False)
    expect('1 == 1').to evaluate_to(Clarke::Evaluator::True)
    expect('2 == 1').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles lt' do
    expect('1 < 2').to evaluate_to(Clarke::Evaluator::True)
    expect('1 < 1').to evaluate_to(Clarke::Evaluator::False)
    expect('2 < 1').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles lte' do
    expect('1 <= 2').to evaluate_to(Clarke::Evaluator::True)
    expect('1 <= 1').to evaluate_to(Clarke::Evaluator::True)
    expect('2 <= 1').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles gt' do
    expect('1 > 2').to evaluate_to(Clarke::Evaluator::False)
    expect('1 > 1').to evaluate_to(Clarke::Evaluator::False)
    expect('2 > 1').to evaluate_to(Clarke::Evaluator::True)
  end

  it 'handles gte' do
    expect('1 >= 2').to evaluate_to(Clarke::Evaluator::False)
    expect('1 >= 1').to evaluate_to(Clarke::Evaluator::True)
    expect('2 >= 1').to evaluate_to(Clarke::Evaluator::True)
  end

  it 'handles andand' do
    expect('true && false').to evaluate_to(Clarke::Evaluator::False)
    expect('true && true').to evaluate_to(Clarke::Evaluator::True)
    expect('false && true').to evaluate_to(Clarke::Evaluator::False)
    expect('false && false').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles oror' do
    expect('true || false').to evaluate_to(Clarke::Evaluator::True)
    expect('true || true').to evaluate_to(Clarke::Evaluator::True)
    expect('false || true').to evaluate_to(Clarke::Evaluator::True)
    expect('false || false').to evaluate_to(Clarke::Evaluator::False)
  end

  it 'handles function definitions and function calls' do
    expect("let x = fun (a,b) { a + b }\nx(2, 3)").to evaluate_to(Clarke::Evaluator::Integer.new(5))
    expect("let x = fun (a) { a + 3 }\nx(2)").to evaluate_to(Clarke::Evaluator::Integer.new(5))
    expect("let x = fun () { 5 }\nx()").to evaluate_to(Clarke::Evaluator::Integer.new(5))
  end

  it 'handles arrow function definitions and function calls' do
    expect("let x = (a, b) => a + b\nx(2, 3)").to evaluate_to(Clarke::Evaluator::Integer.new(5))
    expect("let x = (a) => a + 3\nx(2)").to evaluate_to(Clarke::Evaluator::Integer.new(5))
    expect("let x = () => 5\nx()").to evaluate_to(Clarke::Evaluator::Integer.new(5))
  end

  it 'handles closures' do
    expect("let a = 1\nlet x = fun () { a }\nlet a = 2 in { x() }").to evaluate_to(Clarke::Evaluator::Integer.new(1))
  end

  it 'errors on wrong function counts' do
    expect("let x = fun () { 5 }\nx(1)").to fail_with(Clarke::Language::ArgumentCountError)
    expect("let x = fun (a) { 5 }\nx()").to fail_with(Clarke::Language::ArgumentCountError)
    expect("let x = fun (a) { 5 }\nx(1, 2)").to fail_with(Clarke::Language::ArgumentCountError)
    expect("let x = fun (a, b) { 5 }\nx(1)").to fail_with(Clarke::Language::ArgumentCountError)
    expect("let x = fun (a, b) { 5 }\nx(1, 2, 3)").to fail_with(Clarke::Language::ArgumentCountError)
  end

  it 'handles if' do
    expect('if (true) { 1 } else { 2 }').to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect('if (false) { 1 } else { 2 }').to evaluate_to(Clarke::Evaluator::Integer.new(2))
  end

  it 'handles variable assignment and variable reference' do
    expect("let a = 6\na").to evaluate_to(Clarke::Evaluator::Integer.new(6))
  end

  it 'handles scoped let' do
    expect("let a = 1\nlet a = 2 in { a }").to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect("let a = 1\nlet a = 2 in { a }\na").to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect("let a = 2 in { a }\na").to fail_with(Clarke::Language::NameError)
  end

  it 'handles scoped let without curly braces' do
    expect("let a = 1\nlet a = 2 in a").to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect("let a = 1\nlet a = 2 in a\na").to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect("let a = 2 in a\na").to fail_with(Clarke::Language::NameError)
  end

  it 'handles scope' do
    expect("let a = 1\n{let a = 2}").to evaluate_to(Clarke::Evaluator::Integer.new(2))
    expect("let a = 1\n{let a = 2}\na").to evaluate_to(Clarke::Evaluator::Integer.new(1))
    expect("{let a = 2}\na").to fail_with(Clarke::Language::NameError)
  end

  it 'raises NameError when appropriate' do
    expect('x()').to fail_with(Clarke::Language::NameError)
    expect('a').to fail_with(Clarke::Language::NameError)
  end

  it 'raises TypeError when appropriate' do
    expect("let x = 1\nx()").to fail_with(Clarke::Language::TypeError)
    expect("let x = true\nx()").to fail_with(Clarke::Language::TypeError)
    expect("let x = false\nx()").to fail_with(Clarke::Language::TypeError)

    expect('if (0) { 1 } else { 2 }').to fail_with(Clarke::Language::TypeError)
    expect("let x = fun () { 5 }\nif (x) { 1 } else { 2 }").to fail_with(Clarke::Language::TypeError)
  end

  it 'does not allow reserved words for variables' do
    expect('let else = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let false = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let fun = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let if = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let in = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let let = 1').to fail_with('expected identifier, not reserved keyword')
    expect('let true = 1').to fail_with('expected identifier, not reserved keyword')
  end
end
