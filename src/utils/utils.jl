using Distances
using LinearAlgebra

import Base.typemin, Base.typemax, Base.length, Base.:-
export Line, typemin, collisions


# helps with matrix indexing
Base.CartesianIndex(x::SVector{2, Int64}) = CartesianIndex{2}(x[1], x[2])
Base.convert(::Type{CartesianIndex{2}}, x::SVector{2, Int64}) =
    CartesianIndex{2}(x[1], x[2])

# check for collisions
# TODO: fix
#= function Base.length(::Type{Vector{SVector{2, Int64}}})
    2
end
function Base.typemin(::Type{SVector{2, Int64}})
    SVector{2,Int64}([typemin(Int64), typemin(Int64)])
end
function Base.typemax(::Type{SVector{2, Int64}})
    SVector{2,Int64}([typemax(Int64), typemax(Int64)])
end
 Base.:-(a::SVector{2, Int64}, b::Int64) = norm(a,b)
Base.:-(a::Int64, b::SVector{2, Int64}) = norm(b,a)

const Line = Vector{SVector{2, Int64}}
@inline (::Distances.Euclidean)(a::Line, b::Line) = 
    min(cityblock(a[1], b[1]), cityblock(a[1], b[2]), cityblock(a[2], b[1]), cityblock(a[2], b[2]))
 =#

function collisions(tree::NNTree, index::Int64, radius::Int64)
    pos = tree.data[index]
    # is anything present at this location?
    idxs = inrange(tree, pos, radius)
    colliders = filter(x -> x != index, idxs)
    return colliders
end

get_agent(i::Int64) = @optic _.agents[i]
get_static(i::CartesianIndex{2}) = @optic _.scene.items[i]

include("mutating_lens.jl")
