# Installation

### Prerequisites

Julia 1.6 or greater. For installation, please refer to [the official Julia Website](https://julialang.org/downloads/).

### Installing DAGs

#### From Command Line

To install the latest stable release, run:

```bash
julia -e 'using Pkg; Pkg.add("DAGs")'
```

To install the package with the latest commits on master branch, run:

```bash
julia -e 'using Pkg; Pkg.add(PackageSpec(url="https://github.com/Juice-jl/DAGs.jl.git"))'
```

#### From Julia Pkg REPL

!!! note
    To get to Pkg mode, you need to run `julia`, then to press `]`. Press backspace or ^C to get back to normal REPL mode.

While in Pkg mode, run the following to install the latest release:

```julia
] add DAGs
```

Similarly, to install from the latest commits on master branch, run:

```julia
] add DAGs#master
```

### Testing

If you are installing the latest commit, we recommend running the test suite to make sure everything is in order, to do that run:

```bash
julia --color=yes -e 'using Pkg; Pkg.test("DAGs")'
```
