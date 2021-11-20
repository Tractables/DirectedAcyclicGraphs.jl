using Test
using DirectedAcyclicGraphs

module TestNodes

    using Test
    using ..DirectedAcyclicGraphs

    mutable struct TestINode <: Tree
        id::Int
        children::Vector{Tree}
        TestINode(i,c) = new(i,c)
    end

    mutable struct TestLNode <: Tree
        id::Int
        TestLNode(i) = new(i)
    end

    DirectedAcyclicGraphs.NodeType(::Type{<:TestINode}) = Inner()
    DirectedAcyclicGraphs.NodeType(::Type{<:TestLNode}) = Leaf()
    DirectedAcyclicGraphs.children(n::TestINode) = n.children

    @testset "Tree utils for TestNodes" begin

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

        l3 = TestLNode(4)
        l4 = TestLNode(5)

        i34 = TestINode(6,[l3,l4])

        r = TestINode(7,[i12,i34])

        @test has_children(r)
        @test num_children(r) == 2
        
        foreach(r) do n
            n.id += 1
        end
        @test l1.id == 2
        @test l2.id == 3
        @test i12.id == 4
        @test l3.id == 5
        @test l4.id == 6
        @test i34.id == 7
        @test r.id == 8
        @test i1.id == 1
        @test i2.id == 2

        foreach(r, l -> l.id += 1, i -> i.id -= 1)
        
        @test l1.id == 2 + 1
        @test l2.id == 3 + 1
        @test i12.id == 4 - 1
        @test l3.id == 5 + 1
        @test l4.id == 6 + 1
        @test i34.id == 7 - 1
        @test r.id == 8 - 1
        @test i1.id == 1 - 0
        @test i2.id == 2 - 0

        @test filter(n -> iseven(n.id), r) == [l2,l3,i34]

        lastvisited = nothing
        foreach(n -> lastvisited=n,r)
        @test lastvisited === r

        lastvisited = nothing
        foreach_down(n -> lastvisited=n, r)
        @assert isleaf(lastvisited) "$lastvisited"
        @test isleaf(lastvisited)

        @test num_nodes(r) == 7
        @test num_edges(r) == 6

        @test isempty(innernodes(l1))
        @test leafnodes(l1) == [l1]

        @test issetequal(innernodes(r), [i12,i34,r])
        @test issetequal(leafnodes(r), [l1,l2,l3,l4])
        
        @test tree_num_edges(r) == 6

        @test linearize(r)[end] == r
        @test isleaf(linearize(r)[1])
        @test linearize(l2) == [l2]
        @test length(linearize(i12)) == 3

        @test eltype(linearize(r)) == Tree
        @test eltype(linearize(l1)) == TestLNode
        @test eltype(linearize(r, Any)) == Any

        @test left_most_descendent(r) == l1
        @test right_most_descendent(r) == l4

        np = num_parents(r)
        @test np[r] == 0
        @test np[l1] == 1
        @test np[i34] == 1

        f_l(n) = 1
        f_i1(n,cs) = sum(cs) + 1
        f_i2(n,call) = mapreduce(call, +, children(n)) + 1

        @test foldup(r, f_l, f_i2, Int) == foldup_aggregate(r, f_l, f_i1, Int)

    end    

end