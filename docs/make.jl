using CachedDicts
using Documenter

DocMeta.setdocmeta!(CachedDicts, :DocTestSetup, :(using CachedDicts); recursive=true)

makedocs(;
    modules=[CachedDicts],
    authors="Jan Weidner <jw3126@gmail.com> and contributors",
    repo="https://github.com/jw3126/CachedDicts.jl/blob/{commit}{path}#{line}",
    sitename="CachedDicts.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jw3126.github.io/CachedDicts.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jw3126/CachedDicts.jl",
    devbranch="main",
)
