# Clarke

This is an interpreted programming language made for fun. Not even close to finished.

```
let multiply = (a, b) =>
  if (b > 0) {
    a + multiply(a, b - 1)
  } else {
    0
  }

print(multiply(2, 3))
```

## Requirements

* Ruby 2.5+
* Bundler

## Set up

```
bundle
```

## Run

Call `bin/clarke` with `interpret` and the name of the file to run, e.g.

```
bin/clarke interpret samples/lambda.cke
```

## Syntax

Values:

```
3
"string"
true
false
```

Declaration and assignment:

```
let factor = 3
```

```
let factor = 3
factor = 4
```

Functions:

```
let double = (a) => 2 * a
```

```
let double = fun (a) { 2 * a }
```

Function calls:

```
print(123)
```

Conditionals:

```
if (b > 0) {
  print("Bigger!")
} else {
  print("Smaller!)
}
```

## Naming

* `fun`: function
* `var`: variable
* `def`: definition
* `lit`: literal
* `ref`: reference
* `param`: parameter

## To do

* Allow mutually recursive functions

## Ideas

In no particular order:

* Comments
* Isolated scoping
  * e.g. `iso fun a() { … }` which cannot access outer env
* More primitive types
  * Chars
  * Floats
  * Null
* Compound types
  * Arrays
  * Structs
  * Maps
  * Ranges
  * Sets
  * Enumerable mixin
* Iterators
* Classes (without inheritance)
* If without else
* Static types
  * In arguments (x int, y int ; x, y int)
  * In return value
  * In let
* Modules
