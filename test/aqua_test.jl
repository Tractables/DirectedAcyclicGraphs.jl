using Aqua
using DirectedAcyclicGraphs
using Test

@testset "Aqua tests" begin
    Aqua.test_all(DirectedAcyclicGraphs, 
                    ambiguities = false)
end