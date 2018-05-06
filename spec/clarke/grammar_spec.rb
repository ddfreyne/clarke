# frozen_string_literal: true

describe 'Clarke' do
  it 'handles expressions with any kind of indentation/line breaking' do
    expect('true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect(' true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect(' true ').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect(" true\t").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("\ttrue\t").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("\ntrue").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("\rtrue").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("\r\ntrue").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("true\r\n").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("true\r").to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect("true\n").to evaluate_to(Clarke::Interpreter::Runtime::True)
  end

  it 'handles valid identifiers' do
    expect("let a = 1\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let ab = 1\nab").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let a1 = 1\na1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
  end

  it 'handles booleans' do
    expect('true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('false').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles integers' do
    expect('0').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 0))
    expect('123').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 123))
    expect('234').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 234))
  end

  it 'handles strings' do
    expect('"hi"').to evaluate_to(Clarke::Interpreter::Runtime::String.new(value: 'hi'))
    expect { run('print("hi")') }.to output("hi\n").to_stdout
  end

  it 'handles operator sequences' do
    expect('1+2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect('1+ 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect('1 +2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect('1 + 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
  end

  it 'handles addition' do
    expect('0 + 1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('1 + 0').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('1 + 1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
  end

  it 'handles subtraction' do
    expect('10 - 5').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect('5 - 10').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: -5))
    expect('10 - 10').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 0))
  end

  it 'handles multiplication' do
    expect('2 * 1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect('1 * 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect('2 * 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 4))
  end

  it 'handles division' do
    expect('2 / 1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect('1 / 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 0))
    expect('2 / 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
  end

  it 'handles exponentiation' do
    expect('2 ^ 1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect('1 ^ 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('2 ^ 2').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 4))
  end

  it 'handles eq' do
    expect('1 == 2').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('1 == 1').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('2 == 1').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles lt' do
    expect('1 < 2').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('1 < 1').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('2 < 1').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles lte' do
    expect('1 <= 2').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('1 <= 1').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('2 <= 1').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles gt' do
    expect('1 > 2').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('1 > 1').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('2 > 1').to evaluate_to(Clarke::Interpreter::Runtime::True)
  end

  it 'handles gte' do
    expect('1 >= 2').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('1 >= 1').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('2 >= 1').to evaluate_to(Clarke::Interpreter::Runtime::True)
  end

  it 'handles andand' do
    expect('true && false').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('true && true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('false && true').to evaluate_to(Clarke::Interpreter::Runtime::False)
    expect('false && false').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles oror' do
    expect('true || false').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('true || true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('false || true').to evaluate_to(Clarke::Interpreter::Runtime::True)
    expect('false || false').to evaluate_to(Clarke::Interpreter::Runtime::False)
  end

  it 'handles function definitions and function calls' do
    expect("let x = fun (a,b) { a + b }\nx(2, 3)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect("let x = fun (a: int) { a + 3 }\nx(2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect("let x = fun () { 5 }\nx()").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
  end

  it 'handles arrow function definitions and function calls' do
    expect("let x = (a, b) => a + b\nx(2, 3)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect("let x = (a: int) => a + 3\nx(2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect("let x = () => 5\nx()").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
  end

  it 'handles closures' do
    expect("let a = 1\nlet x = fun () { a }\n{ let a = 3\nx() }").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
  end

  it 'handles parens' do
    expect('1').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('(1)').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('((1))').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('(((1)))').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
  end

  it 'handles props with class type' do
    expect(<<~CODE).to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 123))
      class Oink {
        prop a: int
        fun init() { this.a = 123 }
      }

      class Squeal {
        prop a: Oink
        fun init() { this.a = Oink() }
      }

      Squeal().a.a
    CODE
  end

  it 'errors on wrong argument counts' do
    expect("let x = fun () { 5 }\nx(1)").to fail_with(Clarke::Errors::ArgumentCountError)
    expect("let x = fun (a) { 5 }\nx()").to fail_with(Clarke::Errors::ArgumentCountError)
    expect("let x = fun (a) { 5 }\nx(1, 2)").to fail_with(Clarke::Errors::ArgumentCountError)
    expect("let x = fun (a, b) { 5 }\nx(1)").to fail_with(Clarke::Errors::ArgumentCountError)
    expect("let x = fun (a, b) { 5 }\nx(1, 2, 3)").to fail_with(Clarke::Errors::ArgumentCountError)
    expect('Array(1)').to fail_with(Clarke::Errors::ArgumentCountError)
    expect('Array(1, 2)').to fail_with(Clarke::Errors::ArgumentCountError)
  end

  it 'handles non-anonymous function definitions' do
    expect("fun sum(a, b) { a + b }\nsum(1, 2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
  end

  it 'handles complex function calls' do
    expect("let sum = fun (a) { fun (b) { a + b } }\nsum(1)(2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect("let sum = (a) => (b) => a + b\nsum(1)(2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect { run('print(((a) => (b) => a + b)(1)(2))') }.to output("3\n").to_stdout
  end

  it 'handles if' do
    expect('if (true) { 1 } else { 2 }').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect('if (false) { 1 } else { 2 }').to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
  end

  it 'handles variable assignment and variable reference' do
    expect("let a = 6\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 6))
  end

  it 'handles reassignment' do
    expect("let a = 6\na = 7\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 7))
  end

  it 'handles reassignment at correct level' do
    expect("let a = 6\n{ a = 7 }\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 7))
  end

  it 'can shadow' do
    expect("let a = 6\n{ let a = 7 }\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 6))
  end

  it 'stringifies things nicely' do
    expect { run("class Person {\n}\nprint(Person)") }.to output("<Class Person>\n").to_stdout
    expect { run("class Person {\n}\nprint(Person())") }.to output("<Instance class=Person>\n").to_stdout
  end

  it 'can shadow recursively' do
    expect("let sum = (a: int, b: int): int => {\n  if (a > 0) { sum(a - 1, b + 1) } else { b }\n}\nsum(2, 3)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(0)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 0))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(1)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(2)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(3)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(4)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 3))
    expect("let fib = (a: int): int => {\n  if (a > 1) { fib(a - 1) + fib(a - 2) } else { a }\n}\nfib(5)").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 5))
  end

  it 'forbids reassigment of non-declared vars' do
    expect('a = 4').to fail_with(Clarke::Errors::NameError)
  end

  it 'handles block' do
    expect("let a = 1\n{let a = 2}").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 2))
    expect("let a = 1\n{let a = 2}\na").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("{let a = 2}\na").to fail_with(Clarke::Errors::NameError)
  end

  it 'handles empty blocks' do
    expect("let a = {}\na").to evaluate_to(Clarke::Interpreter::Runtime::Null.instance)
  end

  it 'handles empty functions' do
    expect("let a = fun () {}\na()").to evaluate_to(Clarke::Interpreter::Runtime::Null.instance)
  end

  it 'handles classes without initializer' do
    expect("class Foo {\n  fun oink() { \"stuff\" }\n}\nFoo().oink()").to evaluate_to(Clarke::Interpreter::Runtime::String.new(value: 'stuff'))
  end

  it 'handles classes with initializer' do
    expect(<<~CODE).to evaluate_to(Clarke::Interpreter::Runtime::String.new(value: 'stuff'))
      class Foo {
        prop a: string
        fun init(a) { this.a = a }
        fun oink() { this.a }
      }
      Foo("stuff").oink()
    CODE
  end

  it 'handles empty classes' do
    expect('class Foo {}').to evaluate_to(instance_of(Clarke::Interpreter::Runtime::Class))
  end

  it 'does not allow multiple functions of the same name' do
    expect(<<~CODE).to fail_with(Clarke::Errors::DoubleNameError)
      class Foo {
        fun a() {
          1
        }
        fun a() {
          2
        }
      }
    CODE
  end

  it 'can set defined props' do
    expect(<<~CODE).to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 123))
      class Foo {
        prop a: int
      }
      let f = Foo()
      f.a = 123
      f.a
    CODE
  end

  it 'cannot set defined props' do
    expect(<<~CODE).to fail_with(Clarke::Errors::NameError)
      class Foo {
      }
      let f = Foo()
      f.a = 123
      f.a
    CODE
  end

  it 'handles getters for props' do
    expect { run("class Foo {\n  prop a: int\n  fun init() { this.a = 123 }\n}\nprint(Foo().a)") }
      .to output("123\n").to_stdout
  end

  it 'handles getters for functions' do
    expect { run("class Foo {\n  prop a: int\n  fun init() { this.a = 123 }\n}\nprint(Foo().init)") }
      .to output("<function>\n").to_stdout
  end

  it 'prevents prop getters from returning non-member data' do
    expect("let a = 1\nclass Foo {}\nFoo().a").to fail_with(Clarke::Errors::NameError)
  end

  it 'prints things properly' do
    expect { run('print(1)') }.to output("1\n").to_stdout
    expect { run('print(true)') }.to output("true\n").to_stdout
    expect { run('print(false)') }.to output("false\n").to_stdout
    expect { run("let a = () => 1\nprint(a)") }.to output("<function>\n").to_stdout
    expect('print("hi")').to evaluate_to(Clarke::Interpreter::Runtime::Null.instance)
  end

  it 'raises NameError when appropriate' do
    expect('x()').to fail_with(Clarke::Errors::NameError)
    expect('a').to fail_with(Clarke::Errors::NameError)
  end

  it 'can’t create functions with uppercase name' do
    expect("class A {\n  fun b() { true }\n}").not_to fail_with(Clarke::Errors::SyntaxError)
    expect("class A {\n  fun B() { true }\n}").to fail_with(Clarke::Errors::SyntaxError)
  end

  it 'raises TypeError when appropriate' do
    expect("let x = 1\nx()").to fail_with(Clarke::Errors::NotCallable)
    expect("let x = true\nx()").to fail_with(Clarke::Errors::NotCallable)
    expect("let x = false\nx()").to fail_with(Clarke::Errors::NotCallable)

    expect('if (0) { 1 } else { 2 }').to fail_with(Clarke::Errors::TypeError)
    expect("let x = fun () { 5 }\nif (x) { 1 } else { 2 }").to fail_with(Clarke::Errors::TypeError)
  end

  it 'does not allow reserved words for variables' do
    expect('let else = 1').to fail_with(Clarke::Errors::SyntaxError)
    expect('let false = 1').to fail_with(Clarke::Errors::SyntaxError)
    expect('let fun = 1').to fail_with(Clarke::Errors::SyntaxError)
    expect('let if = 1').to fail_with(Clarke::Errors::SyntaxError)
    expect('let let = 1').to fail_with(Clarke::Errors::SyntaxError)
    expect('let true = 1').to fail_with(Clarke::Errors::SyntaxError)
  end

  it 'accepts type annotations' do
    expect("fun stuff(a) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("fun stuff(a: Array) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("fun stuff(a: any) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))

    expect("let stuff = fun (a) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let stuff = fun (a: Array) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let stuff = fun (a: any) { 1 }\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))

    expect("let stuff = (a) => 1\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let stuff = (a: Array) => 1\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
    expect("let stuff = (a: any) => 1\n1").to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))
  end

  it 'handles arrays' do
    init = Clarke::Interpreter::Init.instance
    array_sym = init.scope.resolve('Array')
    array_class = init.envish.fetch(array_sym)

    expect('Array()')
      .to evaluate_to(a_clarke_instance_of(array_class))

    expect("let x = Array()\nx.add(1)")
      .to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))

    expect('let x = Array()')
      .to evaluate_to(a_clarke_array_containing([]))

    expect("let x = Array()\nx.add(1)")
      .to evaluate_to(Clarke::Interpreter::Runtime::Integer.new(value: 1))

    expect("let x = Array()\nx.add(1)\nx")
      .to evaluate_to(a_clarke_array_containing([Clarke::Interpreter::Runtime::Integer.new(value: 1)]))

    expect("let x = Array()\nx.add(1)\nx.each((a) => print(a))")
      .to evaluate_to(Clarke::Interpreter::Runtime::Null.instance)

    expect { run("let x = Array()\nx.add(1)\nx.each((a) => print(a))") }
      .to output("1\n").to_stdout
  end
end
