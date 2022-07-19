# CachedDicts

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/CachedDicts.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jw3126.github.io/CachedDicts.jl/dev/)
[![Build Status](https://github.com/jw3126/CachedDicts.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jw3126/CachedDicts.jl/actions/workflows/CI.yml?query=branch%3Amain)

Attach a cache to your `AbstractDict`.

# Usage

```julia
using CachedDicts
d = CachedDicts(cache, storage)::AbstractDict
```
Here `cache` and `storage` can be arbitrary `AbstractDict{K,V}`. 
Where reading from `storage` is slow (e.g. disk lookup) and reading from `cache` is fast.

# Example

```julia
using CachedDicts
using LRUCache

mutable struct SlowDict <: AbstractDict{String, Int}
    dict::Dict{String,Int}
    nslow_calls::Int
end
SlowDict() = SlowDict(Dict{String,Int}(), 0)
for f in [:length, :get, :setindex!, :iterate, :delete!, :empty!]
    @eval (Base.$f)(d::SlowDict, args...) = $(f)(d.dict, args...)
end
function Base.getindex(o::SlowDict, key)
    # slow
    sleep(1e-2)
    o.nslow_calls += 1
    o.dict[key]
end

d_slow = SlowDict()
d_slow["1"] = 1
d_slow["2"] = 2

d_slow["1"]
@assert d_slow.nslow_calls == 1
d_slow["1"]
@assert d_slow.nslow_calls == 2
d_slow["1"]
@assert d_slow.nslow_calls == 3

cache = LRU{String,Int}(maxsize=2)
d = CachedDict(cache, d_slow)
@assert d_slow.nslow_calls == 3
d["1"]
# subsequent calls are cached
@assert d_slow.nslow_calls == 4
d["1"]
@assert d_slow.nslow_calls == 4
d["1"]
@assert d_slow.nslow_calls == 4
```
