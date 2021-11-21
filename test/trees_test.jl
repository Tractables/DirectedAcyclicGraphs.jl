using Test
using DirectedAcyclicGraphs

module TestNodes

    using Test
    using ..DirectedAcyclicGraphs

    abstract type TestNode <: Tree end
    mutable struct TestINode <: TestNode
        id::Int
        children::Vector{Tree}
        parent
        TestINode(i,c) = begin
            x = new(i,c, nothing)
            for n in c
                n.parent = x
            end
            x
        end
    end

    mutable struct TestLNode <: TestNode
        id::Int
        parent
        TestLNode(i) = new(i, nothing)
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

        i12 = TestINode(3,[l1,l2])

        @test has_children(i12)

        @test num_children(i12) == 2

        l3 = TestLNode(4)
        l4 = TestLNode(5)

        i34 = TestINode(6,[l3,l4])

        r = TestINode(7,[i12,i34])

        @test has_children(r)
        @test num_children(r) == 2
        
        @test has_parent(l1)
        @test has_parent(i12)
        @test !has_parent(r)
        @test parent(l1) === i12
        @test parent(i12) === r

        @test isroot(r)
        @test !isroot(i12)
        @test root(l4) === r

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

        foreach(r, l -> l.id += 1, i -> i.id -= 1)
        
        @test l1.id == 2 + 1
        @test l2.id == 3 + 1
        @test i12.id == 4 - 1
        @test l3.id == 5 + 1
        @test l4.id == 6 + 1
        @test i34.id == 7 - 1
        @test r.id == 8 - 1

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

        @test eltype(linearize(r)) == TestNode
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

        function df(n,m)
            v = if m === i12
                n === l1 || n === l2
            elseif m === i34
                n === l3 || n === l4
            elseif m === r
                true
            else    
                @assert isleaf(m)
                false 
            end
            v || (n === m)
        end

        DirectedAcyclicGraphs.lca(x::TestNode, y::TestNode) =
            lca(x,y,df)

        @test lca(l1,l2) == i12
        @test lca(l1,l2,i34) == r
        @test lca(l1) == l1
        @test_throws ErrorException lca(l3, TestLNode(2)) 
        @test lca(nothing, l1, df) == l1
        @test lca(l1, nothing, df) == l1
        @test lca(nothing, nothing, df) === nothing

        @test find_inode(l1,l2,df) == i12
        @test find_inode(l3,l4,df) == i34
        @test find_inode(l1,l4,df) == r
        @test find_inode(l2,nothing,df) == r
        @test find_inode(nothing,l3,df) == r

        @test find_leaf(r, x -> true) == l1
        @test_throws ErrorException find_leaf(r, x -> false)

        @test depth(r, x -> true) == 2
        @test_throws ErrorException depth(r, x -> false)

        b = IOBuffer()
        print_tree(r,b)
        @test !isempty(String(take!(b)))

        DirectedAcyclicGraphs.isequal_local(x::TestNode,y::TestNode) = 
            x.id == y.id

        k1 = TestLNode(3)
        k2 = TestLNode(4)
        j12 = TestINode(3,[k1,k2])

        @test k1 != l2
        @test k1 == l1
        @test j12 != i34
        @test j12 == i12


    end    

end