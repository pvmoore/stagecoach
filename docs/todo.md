# Stagecoach ToDo List

## Unions

Implement unions

## Comparing Struct values

We can try using these functions to compare structs. Cast the struct to an int of the same number of bits
and then use LLVM's icmp eq:
  LLVMIntTypeInContext(context, numBits)
  LLVMConstIntOfArbitraryPrecision(context, numWords, words)

Alternatively we can iterate through the members and compare them one by one

## Imports

Currently we have imports at Module scope. We could allow these at any Statement scope but we would need
to change the way the scanner works. The Module properties would be affected:

  Module[string] importedModulesQualified;  
  Module[string] importedModulesUnqualified;

Resolving identifiers, calls and TYpes would need to be modified to walk backwards up the AST.  

## Public imports

Currently we only import symbols within the current Module. Any imports in external Modules are not included.
We could recursively import if the import is within a public attribute block.
We would need to account for circular imports.

## Null checks

Investigate the following functions for checking for null pointer dereferences:
```
  LLVMBuildIsNull
  LLVMBuildIsNotNull
```
Ideally we want to replace all pointer dereferances with a function call that checks the pointer is not null. 
If the pointer is null we can call another function eg:
```
  @nullPointerDeref(ptr, modulename, filename, line)  
```

There is already a config flag:
```
  enableNullChecks
```

## LLD Linker

Try using the LLVM linker (LLD). There is already a file created for this -> src\stagecoach\linking\lld_linker.d
At the moment I am not sure which files actually implement this. Could be one of:
```
  lld64.exe
  lld-link.exe
  lld.exe
```

## Debugging

Add debugging metadata

## Scope block expressions

Allow inner scope blocks to be used as expressions eg.
```      
  int a = { int b = 1; b + 1; }
```
This would yield the final expression as the result of the block.

## Select expression

Add a 'select' expression that can be used like a switch but with more flexibility eg.
```
  int a = select(t) { 
    1: 10
    2: 20
    3..5: 30
    else: 100
  }

  // evaluate from top down until a condition is true and the execute the associated block

  select {
    a < 3: doSomething()
    a < 5: doSomethingElse()
    true: doThisIfNothingElseIsTrue()
  }
```

## Optional

Add an Optional type eg. int? that can be null. This would be a struct under the hood but with
some syntactic sugar to make it easier to use.
```
  int? a = 10
  if(a?hasValue) {
    int b = a?value;
  }
```

## Auto type inference

Add auto type:
```
  auto a = 1
```

## Loop expression

```
  int a = for(int i = 0..10) {
    i + 1
  }
  assert(a is 10)

  int a = for(int i = 0..10) {
    if(i is 5) break i;
    i + 1
  }
  assert(a is 5)
```

## Defer statement

```
  defer {
    // This block is executed when the current scope exits
  }
```

## Vararg functions

We need to support functions with variable parameters for internal calls. We already support extern functions with varargs but we cannot call stagecoach functions in this way.
```
  fn foo(int a, ... args) {
    // args is a slice of Type (requires slices)
  }
```
  It might be better to use arrays or tuples for this eg.
```
  fn foo(int a, int[] args) {}

  fn foo(int a, struct (int, float, bool) args) {}
```
  This still doesn't solve the problem of variable arguments of different types.

## Slices

Add slices eg. int[] that can be used for non-owning array views.
```
  int[3] a = [1, 2, 3]
  int[] b = a[0..<2];   assert(b is [1, 2])
  int[] c = a[1..];     assert(c is [2, 3])
  int[] d = a[..1];     assert(d is [1, 2])
  int[] e = a[..];      assert(e is [1, 2, 3])
```

## Array length property

Add an array length property eg. a.length that returns an int. If the array length is greater than 2^31-1 then 
return a long.

Slices should also have the same property but we won't know at compile time whether it is > 2^31-1.

