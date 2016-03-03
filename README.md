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
can be computed at compile-time. Internally, mathematics on this type are performed
by splatting and slurping tuples of `nothing` (e.g. `( (nothing,nothing)..., (nothing,nothing,nothing)... ) == NTuple{5,Void}`).

Attempts are being made to manipulate Tuple types, but for the moment, progress
is limited. For an approach that is type-safe up until a finite tuple-size, see
[Tuples.jl](https://github.com/mbauman/Tuples.jl) by @mbauman.

In general, generated functions may still be necessary for generic manipulations
of `Tuple`-types and checking conformance of type-parameters with zero run-time
overhead.

NOTE: Major caveats to all of the above: Julia gives up with strong type following
after tuple length 8 and Vals of length 5. I assume this has been implemented to
avoid slow compilation, at the risk of a slower run-time when it gets sufficiently complex.
This may make the entire approach more difficult.
