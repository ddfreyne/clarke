# frozen_string_literal: true

describe 'Clarke types' do
  let(:init_scope) { Clarke::Interpreter::Init.instance.scope }

  it 'resolves true' do
    expect('true').to have_type(init_scope.resolve('bool'))
  end

  it 'resolves false' do
    expect('false').to have_type(init_scope.resolve('bool'))
  end

  it 'resolves ints' do
    expect('0').to have_type(init_scope.resolve('int'))
    expect('1').to have_type(init_scope.resolve('int'))
    expect('12345').to have_type(init_scope.resolve('int'))
  end

  it 'resolves classes' do
    expect("class Oink {\n}\n").to have_type(init_scope.resolve('void'))
  end

  it 'resolves instances' do
    expect("class Oink {\n}\nOink()").to have_type(instance_type('Oink'))
  end

  it 'resolves anonymous function definitions' do
    expect('() => 1').to have_type(function_type('(anon)'))
  end

  it 'resolves named function definitions' do
    # FIXME: should this be void instead?
    expect('fun lol() { 1 }').to have_type(function_type('lol'))
  end

  it 'resolves function calls' do
    expect('(() => 1)()').to have_type(init_scope.resolve('int'))
  end
end
