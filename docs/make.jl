using Documenter
using DocumenterLaTeX
using DirectedAcyclicGraphs
using Literate


pages = [
    "Home" => "index.md",
    #"Quick Tutorial" => "generated/usage.md",
    "Installation" => "installation.md",
    "API" => "api.md",
    # "Development" => "development.md"
]

format = Documenter.HTML(
    prettyurls = !("local" in ARGS),
    canonical = "https://tractables.github.io/DirectedAcyclicGraphs.jl/stable/",
    assets = ["assets/favicon.ico"],
    analytics = "UA-136089579-2",
    highlights = ["yaml"],
    collapselevel = 1,
)

makedocs(
    sitename = "DirectedAcyclicGraphs.jl",
    pages    = pages,
    format   = format,
    doctest  = true,
    modules  = [DirectedAcyclicGraphs],
    linkcheck_ignore = [
        # We'll ignore links that point to GitHub's edit pages, as they redirect to the
        # login screen and cause a warning:
        r"https://github.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/edit(.*)"
    ], 
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    target = "build",
    repo = "github.com/Tractables/DirectedAcyclicGraphs.jl.git",
    branch = "gh-pages",
    devbranch = "main",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#"],
)
