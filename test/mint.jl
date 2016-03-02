@testset "MInt" begin

@test Metaprogramming.MInt_from_VoidTuple(()) == MInt{0}
@test Metaprogramming.MInt_from_VoidTuple((nothing,)) == MInt{1}
@test Metaprogramming.MInt_from_VoidTuple((nothing,nothing,nothing)) == MInt{3}

@test Metaprogramming.VoidTuple_from_MInt(MInt{0}) == ()
@test Metaprogramming.VoidTuple_from_MInt(MInt{1}) == (nothing,)
@test Metaprogramming.VoidTuple_from_MInt(MInt{3}) == (nothing,nothing,nothing)

@test begin
    a = MInt{2}
    b = MInt{10}
    a+b == MInt{12}
end

@test begin
    a = MInt{0}
    b = MInt{0}
    a+b == MInt{0}
end

@test begin
    a = MInt{0}
    b = MInt{3}
    a+b == MInt{3}
end

@test begin
    a = MInt{10}
    b = MInt{2}
    a-b == MInt{8}
end

@test begin
    a = MInt{0}
    b = MInt{0}
    a-b == MInt{0}
end

@test begin
    a = MInt{4}
    b = MInt{0}
    a-b == MInt{4}
end

@test begin
    a = MInt{4}
    b = MInt{4}
    a-b == MInt{0}
end


end
