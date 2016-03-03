# Metaprogramming

[![Build Status](https://travis-ci.org/andyferris/Metaprogramming.jl.svg?branch=master)](https://travis-ci.org/andyferris/Metaprogramming.jl)

This is (at this stage) a test package to explore how far metaprogramming can
be taken in Julia. The motivating goal is to remove generated functions from
code like [Tables.jl](https://github,com/FugroRoames/Tables.jl). Each function
should be a meta-function, in the sense that it is type-stable and is a no-op
(or an error).

One primary feature is `Vals`, a new type that is the collection-variant of
Julia's built-in `Val`. We can create, push, pop, concatenate, index, search,
etc these collections. They are constructed via the slightly abusive syntax
`v = Vals(Type1,Type2,...)` which returns a type (not an instance). They
can then be indexed via `v[Val{1}]`, etc.

Another new type is `MInt` or meta-integer, where `MInt{2} + MInt{3} == MInt{5}`
can be computed at compile-time.

Attempts are being made to manipulate Tuple types, but for the moment, 
