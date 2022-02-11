# DirectedAcyclicGraphs.jl

[![Unit Tests](https://github.com/Juice-jl/DirectedAcyclicGraphs.jl/workflows/Unit%20Tests/badge.svg)](https://github.com/Juice-jl/DirectedAcyclicGraphs.jl/actions?query=workflow%3A%22Unit+Tests%22+branch%3Amain)  [![codecov](https://codecov.io/gh/Juice-jl/DirectedAcyclicGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Juice-jl/DirectedAcyclicGraphs.jl) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://juice-jl.github.io/DirectedAcyclicGraphs.jl/dev/)

This package provides basic infrastructure to work with [Directed Acyclic Graphs](https://en.wikipedia.org/wiki/Directed_acyclic_graph) (DAGs) in Julia.
It forms the foundation for packages such as [LogicCircuits](https://github.com/Juice-jl/LogicCircuits.jl) and [ProbabilisticCircuits](https://github.com/Juice-jl/ProbabilisticCircuits.jl), which define custom DAGs that represent logical or probabilistic computation graphs. 

Functionality includes:
 * applying `foreach` over the nodes of the DAG in topological or reverse topological order, linearize the DAG
 * computing the number of nodes, number of edges
 * propagating a value through the DAG, that is, a `foldup` operation
 * `filter` the nodes in the DAG
 * `iterate` over the nodes in the DAG, compute `maximum`, `minimum`, and other Base functions.
 * find the `lca` (lowest common ancestor) of nodes in a tree
 * arrange the DAG nodes in feedforward layers
 * collecting various statistics about the types of nodes and their in/out-degree

For example usage, please see the unit tests for [DAGs](https://github.com/Juice-jl/DirectedAcyclicGraphs.jl/blob/main/test/dags_test.jl) and the special case of [trees](https://github.com/Juice-jl/DirectedAcyclicGraphs.jl/blob/main/test/trees_test.jl), or the source code of the dependent packages. A brief description of functions can be found in the [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://juice-jl.github.io/DirectedAcyclicGraphs.jl/dev/).
