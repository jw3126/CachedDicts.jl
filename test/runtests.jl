using CachedDicts
using Test

function test_dict_interface(d_candidate, d_test)
    @assert isempty(d_candidate)
    @assert !isempty(d_test)
    @test keytype(d_candidate) isa Type
    @test valtype(d_candidate) isa Type

    @test isempty(d_candidate)
    @test isempty(keys(d_candidate))
    @test isempty(values(d_candidate))
    @test length(d_candidate) == 0

    k, v = first(d_test)
    @test !haskey(d_candidate, k)
    @test v === get(d_candidate, k, v)
    d_candidate[k] = v
    @test !isempty(d_candidate)
    @test !isempty(keys(d_candidate))
    @test !isempty(values(d_candidate))
    @test haskey(d_candidate, k)
    @test d_candidate[k] == v
    @test k isa keytype(d_candidate)
    @test d_candidate[k] isa valtype(d_candidate)
    @test d_candidate == delete!(d_candidate, k)
    @test_throws KeyError d_candidate[k]
    @test d_candidate == delete!(d_candidate, k)
    @test isempty(d_candidate)
    @test v === get!(d_candidate, k, v)
    get!(error, d_candidate, k)
    get(error, d_candidate, k)
    delete!(d_candidate, k)
    @test v === get(() -> v, d_candidate, k)
    @test !haskey(d_candidate, k)
    @test v === get!(() -> v, d_candidate, k)
    @test d_candidate[k] === v

    merge!(d_candidate, d_test)
    @test length(d_candidate) == length(d_test)
    @test length(d_candidate) == length(keys(d_candidate))
    @test length(d_candidate) == length(values(d_candidate))
    test_dicts_equal(d_candidate, d_test)

    @test !isempty(d_candidate)
    @test isempty(empty!(d_candidate))
end

function test_dicts_equal(d1,d2)
    @test length(d1) == length(d2)
    for (k,v) in d1
        @test haskey(d2, k)
        @test d2[k] == v
    end
end

struct MyString
    a::String
end
Base.:(==)(s1::MyString, s2::MyString) = s1.a == s2.a
struct MyInt
    b::Int
end
struct MyPair
    s::MyString
    t::MyInt
end
struct MyContainer{T}
    inner::T
end

struct MyDict{K,V} <: AbstractDict{K,V}
    # Test.GenericDict does not support Base.get properly
    # that is why we roll our own
    dict::Dict{K,V}
end
MyDict{K,V}() where {K,V} = MyDict{K,V}(Dict{K,V}())
for f in [:length, :get, :getindex, :setindex!, :iterate, :delete!, :empty!]
    @eval (Base.$f)(d::MyDict, args...) = $(f)(d.dict, args...)
end
Base.get(f::Base.Callable, d::MyDict, key) = get(f,d.dict, key)

struct MyCache{K,V} <: AbstractDict{K,V}
    # mimics a cache with limited memory
    dict::Dict{K,V}
end
MyCache{K,V}() where {K,V} = MyCache{K,V}(Dict{K,V}())
for f in [:get, :getindex, :delete!, :empty!, :keytype, :valtype]
    @eval (Base.$f)(d::MyCache, args...) = $(f)(d.dict, args...)
end
function Base.setindex!(d::MyCache, val, key)
    ret = d.dict[key] = val
    for k in keys(d.dict)
        if rand() < 0.5
            delete!(d.dict, k)
        end
    end
    ret
end
Base.get(f::Base.Callable, d::MyCache, key) = get(f,d.dict, key)

@testset "AbstractDict interface" begin
    test_dicts = []

    d_test = Dict("a"=>1, "b"=>2)
    push!(test_dicts, d_test)

    t = MyInt(1)
    s = MyString("s")
    st = MyPair(s,t)
    d_test = Dict("a"=>1, "b"=>2, "s" => s, st => t)
    push!(test_dicts, d_test)

    d_test = Dict(MyString("a") => MyInt(2), MyString("") => MyInt(0))
    push!(test_dicts, d_test)

    for d_test in test_dicts
        K = eltype(keys(d_test))
        V = eltype(values(d_test))
        candidates = [
            MyDict{K,V}(),
            Dict{K,V}(),
            CachedDict(MyDict{K,V}(), MyDict{K,V}()),
            CachedDict(MyCache{K,V}(), MyDict{K,V}()),
            CachedDict(Dict{K,V}(), Dict{K,V}()),
        ]
        for d_candidate in candidates
            test_dict_interface(d_candidate, d_test)
        end
    end
end
