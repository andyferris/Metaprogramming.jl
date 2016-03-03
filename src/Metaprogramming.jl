module Metaprogramming

import Base.+, Base.-

export True, False, TrueOrFalse
export VoidTuple, MInt, MetaPair, Vals

# Make bools a bit easier to deal with
typealias True Val{true}
typealias False Val{false}
typealias TrueOrFalse Union{Type{Val{true}},Type{Val{false}}}

typealias VoidTuple{N} NTuple{N,Void}

# Stolen from @mbauman but doesn't work in-general
#check_Tuple(T) = (T===Tuple || T===NTuple) && throw(ArgumentError("parameters of $T are undefined"))
function concatenate{T<:Tuple, S<:Tuple}(::Type{T}, ::Type{S})
    Base.@_pure_meta
    Tuple{T.parameters..., S.parameters...}
end


# Some instantiators - people can define a "default" instantiator for a type which won't require too much computation for Julia
instantiate{T}(::Type{T}) = T()
instantiate{T<:Number}(::Type{T}) = zero(T)
instantiate{T<:AbstractString}(::Type{T}) = T(fieldtype(T,1)[])
instantiate(::Type{Symbol}) = symbol("")
instantiate{T}(::Type{Type{T}}) = T # ?

#"""
#By default, Julia provides limited constructors for `Tuple`-types. This function
#provides
#"""
#function instantiate{T<:Tuple}(::Type{T})

"""
A meta-integer `MInt{N}` is a special Julia type that naturally represents
unsigned integers `N` and can be added, multiplied, etc. Internally it is
manipulated using a tuple of `N` `nothing` values in order to make all
operations type-safe and have zero run-time penalty.

NOTE: Current Julia limitations mean this approach only works until N=8
"""
immutable MInt{N}; end

MInt_from_VoidTuple{N}(::VoidTuple{N}) = MInt{N}
MInt_from_VoidTuple(x::Void...) = MInt_from_VoidTuple(x)
VoidTuple_from_MInt{N}(::Type{MInt{N}}) = _voidtuple(Val{N},())

 _voidtuple{N}(::Type{Val{N}},x::VoidTuple{N}) = x
 _voidtuple{N,M}(::Type{Val{N}},x::VoidTuple{M}) = _voidtuple(Val{N},(nothing,x...))

Base.convert{N}(::Type{Val},::Type{MInt{N}}) = Val{N}
Base.convert{N}(::Type{Val{N}},::Type{MInt{N}}) = Val{N}
Base.convert{N}(::Type{MInt},::Type{Val{N}}) = MInt{N}
Base.convert{N}(::Type{MInt{N}},::Type{Val{N}}) = MInt{N}

# Base.promote_type(::Type{Val},::Type{MInt}) = ?

# Generated version.
#@generated +{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = :(MInt{$(N+M)})
#@generated -{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = :(MInt{$(N-M)})

# Pure version for Julia 0.5 (not working yet as of 3/3/2016)
function +{N,M}(x::Type{MInt{N}},y::Type{MInt{M}})
    Base.@_pure_meta
    MInt{N+M}
end
function -{N,M}(x::Type{MInt{N}},y::Type{MInt{M}})
    Base.@_pure_meta
    MInt{N-M}
end

# Hacky method making use of NTuple{N,Void}, Brittle and
#+{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = MInt_from_VoidTuple(VoidTuple_from_MInt(x)...,VoidTuple_from_MInt(y)...)
#-{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = MInt_from_VoidTuple(_subtract(Val{M},(),VoidTuple_from_MInt(x)...))


_subtract{N}(::Type{Val{N}},::VoidTuple{N},nothing,out::Void...) = (nothing, out...)
_subtract{N,M}(::Type{Val{N}},in::VoidTuple{M},nothing,out::Void...) = _subtract(Val{N},(nothing,in...),out...)
_subtract{N}(::Type{Val{N}},in::VoidTuple{N}) = ()
_subtract{N,M}(::Type{Val{N}},in::VoidTuple{M}) = error("Subtraction error: MInt must be positive")



"""
The `MetaPair` type is used for recursive-tree representation of one-or-more
type parameters, particularly used internally in `Vals`
"""
immutable MetaPair{T,M}; end
MetaPair() = Void
MetaPair{T}(::Type{T}) = MetaPair{T,Void}
MetaPair{T}(::Type{T},x::Type...) = MetaPair{T,MetaPair(x...)}

Base.show{T}(io::IO,::Type{MetaPair{T,Void}}) = show(io::IO,T)
function Base.show{T1,T2}(io::IO,::Type{MetaPair{T1,T2}})
    show(io::IO,T1)
    print(io::IO,",")
    show(io::IO,T2)
end

# The above was a little sneaky, so perhaps the user should be able to see the "real" thing when necessary
Base.showall{T}(io::IO,::Type{MetaPair{T,Void}}) = print(io,"MetaPair{$T,Void}")
function Base.showall{T1,T2}(io::IO,::Type{MetaPair{T1,T2}})
    print(io,"MetaPair{")
    showall(io,T1)
    print(io,",")
    showall(io,T2)
    print(io,"}")
end

_length{T,N}(::Type{MetaPair{T,Void}}, ::Type{MInt{N}}) = MInt{N} + MInt{1}
_length{T1,T2,N}(::Type{MetaPair{T1,T2}}, ::Type{MInt{N}}) = _length(T2, MInt{N} + MInt{1})

_getindex{T1,T2,N,M}(::Type{MetaPair{T1,T2}}, ::Type{Val{N}}, counter::Type{MInt{M}}) = _getindex(T2,Val{N},counter+MInt{1},X)
_getindex{T,N}(::Type{MetaPair{T,Void}}, ::Type{Val{N}}, counter::Type{MInt{N}}) = T
_getindex{T,N,M}(::Type{MetaPair{T,Void}}, ::Type{Val{N}}, counter::Type{MInt{M}}) = throw(BoundsError(X,N))

_getindex{T1,T2,N,X}(::Type{MetaPair{T1,T2}}, ::Type{Val{N}}, ::Type{MInt{N}},::Type{X}) = T1
_getindex{T1,T2,N,M,X}(::Type{MetaPair{T1,T2}}, ::Type{Val{N}}, counter::Type{MInt{M}},::Type{X}) = _getindex(T2,Val{N},counter+MInt{1},X)
_getindex{T,N,X}(::Type{MetaPair{T,Void}}, ::Type{Val{N}}, counter::Type{MInt{N}},::Type{X}) = T
_getindex{T,N,M,X}(::Type{MetaPair{T,Void}}, ::Type{Val{N}}, counter::Type{MInt{M}},::Type{X}) = throw(BoundsError(X,N))

_push!{T,X}(::Type{MetaPair{T,Void}},::Type{X}) = MetaPair{T,MetaPair{X,Void}}
_push!{T1,T2,X}(::Type{MetaPair{T1,T2}},::Type{X}) = MetaPair{T1,_push!(T2,X)}

_pop!{T}(::Type{MetaPair{T,Void}}) = (T,Void)
_pop!{T1,T2}(::Type{MetaPair{T1,T2}}) = _pop!(T2,MetaPair{T1,Void})
_pop!{T,Prev<:MetaPair}(::Type{MetaPair{T,Void}},::Type{Prev}) = (T,Prev)
_pop!{T1,T2,Prev<:MetaPair}(::Type{MetaPair{T1,T2}},::Type{Prev}) = _pop!(T2,_push!(Prev,T1))

_splat{T}(::Type{MetaPair{T,Void}}) = (T,)
_splat{T,M<:MetaPair}(::Type{MetaPair{T,M}}) = (T,_splat(M)...)

_splat_instances{T}(::Type{MetaPair{T,Void}}) = (instantiate(T),)
_splat_instances{T,M<:MetaPair}(::Type{MetaPair{T,M}}) = (instantiate(T),_splat_instances(M)...)


"""
`Vals` represents a meta-collection, with some similarities to `Tuple`, but
designed to represent a collection of `Val` or or other types. Convenience
functions for building, indexing, etc are provided.
"""
immutable Vals{T<:Union{MetaPair,Void}}; end
Vals() = Vals{Void}
Vals{T}(::Type{T}) = Vals{MetaPair{T,Void}}
Vals{T}(::Type{T},x::Type...) = Vals{MetaPair{T,MetaPair(x...)}}

function Base.showall{T}(io::IO,::Type{Vals{T}})
    print("Vals{")
    showall(T)
    print("}")
end


Base.getindex{N}(::Type{Vals{Void}},::Union{Type{Val{N}},Type{MInt{N}}}) = throw(BoundsError(Vals{Void},N))
Base.getindex{T,N}(x::Type{Vals{T}},::Union{Type{Val{N}},Type{MInt{N}}}) = _getindex(T,Val{N},MInt{1},Vals{T})

Base.endof(::Type{Vals{Void}}) = Val{0}
Base.endof{T}(::Type{Vals{T}}) = _length(T, MInt{0})

Base.push!{T}(::Type{Vals{Void}},::Type{T}) = Vals{MetaPair{T,Void}}
Base.push!{M,T}(::Type{Vals{M}},::Type{T}) = Vals{_push!(M,T)}

Base.pop!(::Type{Vals{Void}}) = throw(ArgumentError("Vals{Void} must be non-empty"))
function Base.pop!{M}(::Type{Vals{M}})
    v,m = _pop!(M)
    v,Vals{m}
end

Base.shift!(::Type{Vals{Void}}) = throw(ArgumentError("Vals{Void} must be non-empty"))
Base.shift!{T,M}(::Type{Vals{MetaPair{T,M}}}) = (T,Vals{M})

Base.unshift!{T,M}(::Type{Vals{M}},::Type{T}) = Vals{MetaPair{T,M}}


# These seem to have strange return type:: Tuple{DataType,DataType,...} and not Tuple{Type{Int64},...} or whatever...
# Also generate a LOT of code... (maybe that's splatting overhead that disappears in Julia 0.5?)
tuple_from_Vals(::Type{Vals{Void}}) = ()
tuple_from_Vals{M<:MetaPair}(::Type{Vals{M}}) = (_splat(M)...)

# OLD VERSION: It seemed to not be type-stable (possibly a Julia deficiency?)
#Tuple_from_Vals(::Type{Vals{Void}}) = Tuple{}
#Tuple_from_Vals{T}(::Type{Vals{MetaPair{T,Void}}}) = Tuple{T}
#Tuple_from_Vals{M<:MetaPair}(::Type{Vals{M}}) = Tuple{_splat(M)...}

# NEW VERSION: Is type-stable but only generates a no-op for isbits types excluding symbols (so symbols, arrays, strings, Ref{}, etc cause overhead)
# TODO: See if we can make this work through some C-calls or other hacking
Tuple_from_Vals(::Type{Vals{Void}}) = Tuple{}
Tuple_from_Vals{M<:MetaPair}(::Type{Vals{M}}) = typeof(_splat_instances(M))

end # module
