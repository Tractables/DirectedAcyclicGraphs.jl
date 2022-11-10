export DAG, NodeType, Leaf, Inner,
       children, has_children, num_children, isleaf, isinner,
       foreach, foreach_down, filter, foldup, foldup_aggregate, 
       num_nodes, num_edges, tree_num_nodes, tree_num_edges, in,
       innernodes, leafnodes, num_innernodes, num_leafnodes, linearize,
       left_most_descendent, right_most_descendent,
       num_parents, label_nodes, feedforward_layers,
       node_stats, innernode_stats, leaf_stats,
       parent_stats


#####################
# types and traits
#####################

"A directed acyclic graph as defined by its root node. This container exists to dispatch on."
struct DAG 
    root
end

"""
A trait hierarchy denoting types of `DAG` nodes
`NodeType` defines an orthogonal type hierarchy of node types, so we can dispatch on node type regardless of the graph type.
See @ref{https://docs.julialang.org/en/v1/manual/methods/#Trait-based-dispatch-1}
"""
abstract type NodeType end

"The trait of leaf nodes (nodes without children)"
struct Leaf <: NodeType end

"The trait of inner nodes (nodes that have children)"
struct Inner <: NodeType end

#####################
# basic fields and methods
#####################

# Each `DAG` is required to provide a specialized method for the following functions.

"Get the node type trait of the given `Node`"
@inline NodeType(node) = NodeType(typeof(node))

"Get the children of a given inner node"
function children end


#####################
# derived node functions
#####################

"Does the DAG node have children?"
@inline has_children(n)::Bool = has_children(NodeType(n), n)
@inline has_children(::Inner, n)::Bool = true
@inline has_children(::Leaf, n)::Bool = false

"Get the number of children of a given inner DAG node"
@inline num_children(n)::Int = num_children(NodeType(n), n)
@inline num_children(::Inner, n)::Int = length(children(n))
@inline num_children(::Leaf, n)::Int = 0

"Is the DAG node a leaf node?"
@inline isleaf(n) = NodeType(n) isa Leaf

"Is the DAG node an inner node?"
@inline isinner(n) = NodeType(n) isa Inner

#####################
# traversal
#####################

import Base.foreach #extend

foreach(f::Function, dag::DAG, ::Nothing=nothing) =
    foreach_node(f, dag.root)

"Apply a function to each node in a graph, bottom up"
foreach_node(f::Function, node::DAG, ::Nothing=nothing) =
    foreach_node(f, node, Dict{DAG,Nothing}())

function foreach_node(f::Function, node, seen)
    get!(seen, node) do
        if isinner(node)
            for c in children(node)
                foreach(f, c, seen)
            end
        end
        f(node)
        nothing
    end
    nothing
end

function foreach_node(node, f_leaf::Function, f_inner::Function, seen=nothing)
    foreach_node(node, seen) do n
        isinner(n) ? f_inner(n) : f_leaf(n)
    end
    nothing
end

"Apply a function to each node in a graph, top down"
function foreach_down(f::Function, node::DAG)
    # naive implementation
    lin = linearize(node)
    foreach(f, Iterators.reverse(lin))
end

import Base.filter #extend

filter(p::Function, dag::DAG, seen=nothing, ::Type{T} = Union{}) where T =
    filter_nodes(p, dag.root, seen, T)

"""Retrieve list of nodes in DAG matching predicate `p`"""
function filter_nodes(p::Function, root, seen=nothing, ::Type{T} = Union{})::Vector where T
    results = Vector{T}()
    foreach_node(root, seen) do n
        if p(n)
            if !(n isa eltype(results))
                results = collect(typejoin(eltype(results), typeof(n)), results)
            end
            push!(results, n)
        end
    end
    results
end

"""
    foldup(node, 
        f_leaf::Function, 
        f_inner::Function, 
        ::Type{T})::T where {T}

Compute a function bottom-up on the graph. 
`f_leaf` is called on leaf nodes, and `f_inner` is called on inner nodes.
Values of type `T` are passed up the circuit and given to `f_inner` as a function on the children.
"""
function foldup(node, f_leaf::Function, f_inner::Function, ::Type{T}, ::Nothing=nothing) where {T}
    foldup(node, f_leaf, f_inner, T, Dict{DAG,T}())
end

function foldup(node, f_leaf::Function, f_inner::Function, ::Type{T}, cache) where {T}
    get!(cache, node) do 
        if isinner(node)
            callback(c) = foldup(c, f_leaf, f_inner, T, cache)::T
            f_inner(node, callback)::T
        else
            f_leaf(node)::T
        end
    end
end

"""
Compute a function bottom-up on the circuit. 
`f_leaf` is called on leaf nodes, and `f_inner` is called on inner nodes.
Values of type `T` are passed up the circuit and given to `f_inner` in aggregate 
as a vector from the children.
"""
function foldup_aggregate(node::DAG, f_leaf::Function, f_inner::Function, ::Type{T}, ::Nothing=nothing) where {T}
    foldup_aggregate(node, f_leaf, f_inner, T, Dict{DAG,T}())
end

function foldup_aggregate(node::DAG, f_leaf::Function, f_inner::Function, ::Type{T}, cache) where {T}
    get!(cache, node) do 
        if isinner(node)
            child_values = Vector{T}(undef, num_children(node))
            map!(c -> foldup_aggregate(c, f_leaf, f_inner, T, cache)::T, 
                                        child_values, children(node))
            f_inner(node, child_values)::T
        else
            f_leaf(node)::T
        end
    end
end

#####################
# methods using circuit traversal
#####################

import Base.iterate #extend

iterate(dag::DAG, state=nothing) =
    iterate_nodes(dag.root, state)

function iterate_nodes(node, state=nothing)
    if isnothing(state)
        lin = linearize(node)
        liniter = iterate(lin) 
    else
        lin = first(state)
        liniter = iterate(lin, last(state))
    end
    if isnothing(liniter)
        nothing
    else
        el, outstate = liniter
        el, (lin, outstate)
    end
end
    

"""
    num_nodes(node)

Count the number of nodes in the `DAG`
"""
function num_nodes(node, seen=nothing)
    count::Int = 0
    foreach_node(node, seen) do _
        count += 1
    end
    count
end

"Number of edges in the `DAG`"
function num_edges(node, seen=nothing)
    count::Int = 0
    foreach_node(node, seen) do n
        count += num_children(n)
    end
    count
end

"""
    tree_num_nodes(node)::BigInt

Compute the number of nodes in of a tree-unfolding of the `DAG`. 
"""
function tree_num_nodes(node, cache=nothing)
    @inline f_leaf(n) = one(BigInt)
    @inline f_inner(n, call) = (1 + mapreduce(call, +, children(n)))
    foldup(node, f_leaf, f_inner, BigInt, cache)
end

"""
    tree_num_edges(node::DAG)::BigInt
    
Compute the number of edges in the tree-unfolding of the `DAG`. 
"""
function tree_num_edges(node::DAG, cache=nothing)::BigInt
    @inline f_leaf(n) = zero(BigInt)
    @inline f_inner(n, call) = (num_children(n) + mapreduce(c -> call(c), +, children(n)))
    foldup(node, f_leaf, f_inner, BigInt, cache)
end

"Is the node contained in the `DAG`?"
function Base.in(needle::DAG, root::DAG, seen=nothing)
    contained::Bool = false
    foreach(root, seen) do n
        contained |= (n == needle)
    end
    contained
end

"Get the list of inner nodes in a given graph"
innernodes(c::DAG) = 
    filter(isinner, c)

"Get the list of leaf nodes in a given graph"
leafnodes(c::DAG) = 
    filter(isleaf, c)

"Count the number of leaf nodes in a given graph"
num_leafnodes(c::DAG) = 
    length(leafnodes(c))

"Count the number of inner nodes in a given graph"
num_innernodes(c::DAG) = 
    length(innernodes(c))

"Order the `DAG`'s nodes bottom-up in a list (with optional element type)"
@inline linearize(r::DAG, ::Type{T} = Union{}) where T = 
    filter(x -> true, r, nothing, typejoin(T, typeof(r)))

"""
    left_most_descendent(root::DAG)::DAG    

Return the left-most descendent.
"""
function left_most_descendent(root::DAG)::DAG
    while isinner(root)
        root = children(root)[1]
    end
    root
end

"""
    right_most_descendent(root::DAG)::DAG    

Return the right-most descendent.
"""
function right_most_descendent(root::DAG)::DAG
    while isinner(root)
        root = children(root)[end]
    end
    root
end

"""
Assign an integer label to each circuit node, bottom up, starting at `1`
"""
function label_nodes(root::DAG)
    labeling = Dict{DAG,Int}()
    i = 0
    f_inner(n, call) = begin 
        foreach(call, children(n))
        (i += 1)
    end 
    f_leaf(n) = (i += 1)
    foldup(root, f_leaf, f_inner, Int, labeling)
    labeling
end

"""
    num_parents(root::DAG)

Count the number of parents for each node in `DAG` under `root`
"""
function num_parents(root::DAG)
    count = Dict{DAG,Int}()
    count[root] = 0
    foreach(root) do n
        if isinner(n)
            for c in children(n)
                count[c] = get(count, c, 0) + 1
            end
        end
    end
    count
end

"""
    feedforward_layers(root::DAG)

Assign a layer id with each node, starting from leafs to root
"""
function feedforward_layers(root::DAG)
    node2layer = Dict{DAG, Int}()
    f_inner(n, call) = 
        1 + mapreduce(call, max, children(n)) 
    f_leaf(n) = 1
    num_layers = foldup(root, f_leaf, f_inner, Int, node2layer)
    node2layer, num_layers
end

#####################
# debugging methods (not performance critical)
#####################

# When you suspect there is a bug but execution halts, it may be because of 
# pretty printing a huge recursive graph structure. 
# To safeguard against that case, we set a default show:
Base.show(io::IO, c::DAG) = print(io, "$(typeof(c))($(hash(c)))")

"""
    node_stats(c::DAG)    

Give count of types and fan-ins of all nodes in the graph
"""
node_stats(c::DAG) = merge(leaf_stats(c), innernode_stats(c))

"""
    innernode_stats(c::DAG)

Give count of types and fan-ins of inner nodes in the graph
"""
function innernode_stats(c::DAG)
    groups = groupby(e -> (typeof(e), num_children(e)), innernodes(c))
    map_values(v -> length(v), groups, Int)
end

"""
    leaf_stats(c::DAG)

Give count of types of leaf nodes in the graph
"""
function leaf_stats(c::DAG)
    groups = groupby(e -> typeof(e), leafnodes(c))
    map_values(v -> length(v), groups, Int)
end

"Group the elements of `list` by their values according to function `f`"
function groupby(f::Function, list::Union{Vector{E},Set{E}})::Dict{Any,Vector{E}} where E
    groups = Dict{Any,Vector{E}}()
    for v in list
        push!(get!(groups, f(v), []), v)
    end
    groups
end

"Map the values in the dictionary, retaining the same keys"
function map_values(f::Function, dict::AbstractDict{K}, vtype::Type)::AbstractDict{K,vtype} where K
    mapped_dict = Dict{K,vtype}()
    for key in keys(dict)
        mapped_dict[key] = f(dict[key])
    end
    mapped_dict
end

"""
    parent_stats(c::DAG)

Give number of nodes grouped by (type, parent_count)
"""
function parent_stats(c::DAG)
    par_count = num_parents(c)
    groups = groupby(e -> (typeof(e[1]), e[2]), collect(par_count));
    map_values(v->length(v), groups, Int)
end