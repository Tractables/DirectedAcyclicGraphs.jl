using Test
using DirectedAcyclicGraphs

@testset "Helper Functions" begin

    d = Dict("a" => 1, "b" => 3)
    @test map_values(x -> x+1, d, Int)["b"] == 4
    
    @test groupby(isodd, [1,2,3,4,5])[true] == [1,3,5]
    
end

