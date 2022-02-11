using Test
using DirectedAcyclicGraphs

module TestDAGs

    using Test
    using ..DirectedAcyclicGraphs

    mutable struct TestINode <: DAG
        id::Int
        children::Vector{DAG}
        TestINode(i,c) = new(i,c)
    end

    mutable struct TestLNode <: DAG
        id::Int
        TestLNode(i) = new(i)
    end

    DirectedAcyclicGraphs.NodeType(::Type{<:TestINode}) = Inner()
    DirectedAcyclicGraphs.NodeType(::Type{<:TestLNode}) = Leaf()
    DirectedAcyclicGraphs.children(n::TestINode) = n.children

    @testset "DAG utils for TestNodes" begin

        l1 = TestLNode(1)
        l2 = TestLNode(2)

        @test !has_children(l1)
        @test num_children(l1) == 0
        @test isleaf(l1)
        @test !isinner(l1)

        i1 = TestINode(1,[l1])
        i2 = TestINode(2,[l2])
        i12 = TestINode(3,[l1,l2])

        @test has_children(i1)
        @test has_children(i12)

        @test num_children(i1) == 1
        @test num_children(i12) == 2

        j1 = TestINode(1,[i1,i12])
        j2 = TestINode(2,[i2])
        j12 = TestINode(3,[i1,i2])

        r = TestINode(5,[j1,j2,j12])

        @test has_children(r)
        @test num_children(r) == 3
        
        foreach(r) do n
            n.id += 1
        end
        @test l1.id == 2
        @test l2.id == 3
        @test i12.id == 4
        @test j2.id == 3
        @test r.id == 6

        foreach(r, l -> l.id += 1, i -> i.id -= 1)
        @test l1.id == 2+1
        @test l2.id == 3+1
        @test i12.id == 4-1
        @test j2.id == 3-1
        @test r.id == 6-1

        @test filter(n -> iseven(n.id), r) == [l2,i2,j2]

        lastvisited = nothing
        foreach(n -> lastvisited=n,r)
        @test lastvisited === r

        lastvisited = nothing
        foreach_down(n -> lastvisited=n,r)
        @test isleaf(lastvisited)

        @test num_nodes(r) == 9
        @test num_edges(r) == 12

        @test isempty(innernodes(l1))
        @test leafnodes(l1) == [l1]

        @test issetequal(innernodes(r), [i1,i2,i12,j1,j2,j12,r])
        @test issetequal(innernodes(r), [i1,i2,i12,j1,j2,j12,r])
        @test issetequal(leafnodes(r), [l1,l2])
        
        @test tree_num_edges(r) == 14 # unverified

        @test linearize(r)[end] == r
        @test linearize(r)[1] == l1 || linearize(r)[1] == l2
        @test linearize(l2) == [l2]
        @test length(linearize(i12)) == 3

        @test eltype(linearize(r)) == DAG
        @test eltype(linearize(l1)) == TestLNode
        @test eltype(linearize(r, Any)) == Any

        @test left_most_descendent(r) == l1
        @test right_most_descendent(r) == l2

        np = num_parents(r)
        @test np[r] == 0
        @test np[l1] == 2
        @test np[j1] == 1

        f_l(n) = 1
        f_i1(n,cs) = sum(cs) + 1
        f_i2(n,call) = mapreduce(call, +, children(n)) + 1

        @test foldup(r, f_l, f_i2, Int) == foldup_aggregate(r, f_l, f_i1, Int)

        @test tree_num_nodes(r) == 15
        @test tree_num_edges(r) == 14
        @test num_leafnodes(r) == 2
        @test num_innernodes(r) == 7

        @test j1 ∈ r
        @test TestLNode(24) ∉ r

        @test left_most_descendent(r) == l1
        @test right_most_descendent(r) == l2

        @test label_nodes(r)[r] == 9

        @test !isempty(node_stats(r))
        @test !isempty(parent_stats(r))

        layers, num_layers = @test_nowarn feedforward_layers(r)
        @test num_layers == 4
        @test layers[r] == 4
        @test layers[l2] == 1
        @test layers[i12] == 2
        @test layers[j1] == 3

        @test maximum(num_children, r) == 3
        @test minimum(num_children, r) == 0

    end    

end