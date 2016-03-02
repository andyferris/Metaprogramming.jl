@testset "Vals" begin

    @test Vals() == Vals{Void}
    @test Vals(Int64) == Vals{MetaPair{Int64,Void}}
    @test Vals(Int64,Float64,Bool) == Vals{MetaPair{Int64,MetaPair{Float64,MetaPair{Bool,Void}}}}

    @test (v = Vals(); v = push!(v, Int64); v == Vals(Int64))
    @test (v = Vals(Int64); v = push!(v, Float64); v == Vals(Int64,Float64))

    @test (v = Vals(Int64); (p,v) = pop!(v); v == Vals() && p == Int64)
    @test (v = Vals(Int64,Float64); (p,v) = pop!(v); v == Vals(Int64) && p == Float64)
    @test (v = Vals(Int64,Float64,Bool); (p,v) = pop!(v); v == Vals(Int64,Float64) && p == Bool)

end
