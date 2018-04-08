# Clarke

This is an interpreted programming language made for fun. Not even close to finished.

```
let factor = 3
let a = () => 4 * factor in print(a())
```

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

## To do

* [ ] Static types
  * [ ] In arguments (x int, y int ; x, y int)
  * [ ] In return value
  * [ ] In let
* [ ] Comments
* [ ] Other types
  * [ ] Strings
  * [ ] Chars
  * [ ] Floats
  * [ ] Unit
* [ ] Let -> var and const/val
* [ ] If without else
* [ ] Pattern matching
* [ ] Structs
* [ ] Tuples/records
* [ ] Loops
* [ ] Ranges
* [ ] Classes
* [ ] Collections
  * [ ] Array
  * [ ] Set
  * [ ] List
  * [ ] Map
* [ ] Iterators
* [ ] Objects
* [ ] Interfaces
* [ ] Modules
