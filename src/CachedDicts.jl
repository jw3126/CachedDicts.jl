module CachedDicts
using ArgCheck
export CachedDict

################################################################################
##### CachedDict
################################################################################
"""
    CachedDict([cache,] storage) <: AbstractDict

A cached variant of storage. See also [`FullyCachedDict`](@ref).
"""
struct CachedDict{K,V,C,S <: AbstractDict} <: AbstractDict{K,V}
    cache::C
    storage::S
    function CachedDict{K,V}(cache::C, storage::S) where {K,V,C,S}
        check_cache_storage_compatible(cache, storage)
        return new{K,V,C,S}(cache, storage)
    end
end

@noinline function check_cache_storage_compatible(cache::AbstractDict, storage::AbstractDict)
    if keytype(cache) != keytype(storage)
        msg = """
        Cache and storage must have the same keytype. Got:
        keytype(cache) = $(keytype(cache))
        keytype(storage) = $(keytype(storage))
        """
        throw(ArgumentError(msg))
    elseif valtype(cache) != valtype(storage)
        msg = """
        Cache and storage must have the same valtype. Got:
        valtype(cache) = $(valtype(cache))
        valtype(storage) = $(valtype(storage))
        """
        throw(ArgumentError(msg))
    end
end
function check_cache_storage_compatible(cache::Any, storage::Any)
    # hope for the best
end

function CachedDict(cache, storage)
    check_cache_storage_compatible(cache, storage)
    K = keytype(storage)
    V = valtype(storage)
    return CachedDict{K,V}(cache, storage)
end

function CachedDict(storage::AbstractDict{K,V}) where {K,V}
    cache = Dict{K,V}()
    return CachedDict{K,V}(cache, storage)
end

function Base.getindex(o::CachedDict, key)
    get!(o.cache, key) do
        o.storage[key]
    end
end
function Base.haskey(o::CachedDict, key)
    haskey(o.cache, key) || haskey(o.storage, key)
end
function Base.setindex!(o::CachedDict, val, key)
    ret = o.storage[key] = val
    o.cache[key] = val
    return ret
end
function iterate_pairs_key_based(o)
    ks = keys(o)
    next = iterate(ks)
    if next === nothing
        return nothing
    else
        key, keystate = next
        key => o[key], (keystate=keystate, keys=ks)
    end
end
function iterate_pairs_key_based(o, state)
    next = iterate(state.keys, state.keystate)
    if next === nothing
        return nothing
    else
        key, keystate = next
        key => o[key], (keystate=keystate, keys=state.keys)
    end
end
Base.iterate(o::CachedDict) = iterate_pairs_key_based(o)
Base.iterate(o::CachedDict, state) = iterate_pairs_key_based(o, state)

for f in [:(Base.keys), :(Base.values), :(Base.length)]
    @eval $f(o::CachedDict) = $f(o.storage)
end

function Base.empty!(o::CachedDict)
    empty!(o.cache)
    empty!(o.storage)
end
function Base.delete!(o::CachedDict, key)
    if haskey(o.cache, key)
        Base.delete!(o.cache, key)
    end
    return Base.delete!(o.storage, key)
end
function Base.get(o::CachedDict, key, val)
    get(o.cache, key) do
        get(o.storage, key, val)
    end
end
function Base.get!(o::CachedDict, key, val)
    get!(o.cache, key) do
        get!(o.storage, key, val)
    end
end
function Base.get!(f::Base.Callable, o::CachedDict, key)
    get!(o.cache, key) do
        get!(f, o.storage, key)
    end
end
function Base.get(f::Base.Callable, o::CachedDict, key)
    get(o.cache, key) do
        get(f, o.storage, key)
    end
end

end
