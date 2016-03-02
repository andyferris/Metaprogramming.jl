module Metaprogramming

import Base.+, Base.-

export True, False, TrueOrFalse
export VoidTuple, MInt, MetaPair, Vals

# Make bools a bit easier to deal with
typealias True Val{true}
typealias False Val{false}
typealias TrueOrFalse Union{Type{Val{true}},Type{Val{false}}}

typealias VoidTuple{N} NTuple{N,Void}

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

+{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = MInt_from_VoidTuple(VoidTuple_from_MInt(x)...,VoidTuple_from_MInt(y)...)
-{N,M}(x::Type{MInt{N}},y::Type{MInt{M}}) = MInt_from_VoidTuple(_subtract(Val{M},(),VoidTuple_from_MInt(x)...))

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

_getindex{T1,T2,N,X}(::Type{MetaPair{T1,T2}}, ::Type{Val{N}}, ::MInt{N},::Type{X}) = T1
_getindex{T1,T2,N,M,X}(::Type{MetaPair{T1,T2}}, ::Type{Val{N}}, counter::MInt{M},::Type{X}) = _getindex(T2,Val{N},(nothing,counter...),X)
_getindex{T,N,M,X}(::Type{MetaPair{T,Void}}, ::Type{Val{N}}, counter::MInt{M},::Type{X}) = throw(BoundsError(X,N))

_push!{T,X}(::Type{MetaPair{T,Void}},::Type{X}) = MetaPair{T,MetaPair{X,Void}}
_push!{T1,T2,X}(::Type{MetaPair{T1,T2}},::Type{X}) = MetaPair{T1,_push!(T2,X)}

_pop!{T}(::Type{MetaPair{T,Void}}) = (T,Void)
_pop!{T1,T2}(::Type{MetaPair{T1,T2}}) = _pop!(T2,MetaPair{T1,Void})
_pop!{T,Prev<:MetaPair}(::Type{MetaPair{T,Void}},::Type{Prev}) = (T,Prev)
_pop!{T1,T2,Prev<:MetaPair}(::Type{MetaPair{T1,T2}},::Type{Prev}) = _pop!(T2,_push!(Prev,T1))

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


Base.getindex{N}(::Type{Vals{Void}},::Type{Val{N}}) = throw(BoundsError(Vals{Void},N))
Base.getindex{T,N}(x::Type{Vals{T}},::Type{Val{N}}) = _getindex(T,Val{N},(nothing,),Vals{T})

Base.endof(::Type{Vals{Void}}) = Val{0}
Base.endof{T}(::Type{Vals{T}}) = Val{0}

Base.push!{T}(::Type{Vals{Void}},::Type{T}) = Vals{MetaPair{T,Void}}
Base.push!{M,T}(::Type{Vals{M}},::Type{T}) = Vals{_push!(M,T)}

Base.pop!(::Type{Vals{Void}}) = throw(ArgumentError("Vals{Void} must be non-empty"))
function Base.pop!{M}(::Type{Vals{M}})
    v,m = _pop!(M)
    v,Vals{m}
end



end # module
