using Distances

# helps with matrix indexing
Base.CartesianIndex(x::SVector{2, Int64}) = CartesianIndex{2}(x[1], x[2])
Base.convert(::Type{CartesianIndex{2}}, x::SVector{2, Int64}) =
    CartesianIndex{2}(x[1], x[2])

# check for collisions
# TODO: fix
begin
	struct Intersection <: Distances.Metric end
	@inline (::Intersection)(a, b) = 
        min(cityblock(a[1], b[1]), cityblock(a[1], b[2]), cityblock(a[2], b[1]), cityblock(a[2], b[2]))
    intersection(a::SVector{2, SVector{2, Int64}}, b::SVector{2, SVector{2, Int64}}) = 
        Intersection()(a, b)
end

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
