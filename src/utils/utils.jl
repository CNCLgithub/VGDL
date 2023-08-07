
# helps with matrix indexing
#
Base.CartesianIndex(x::SVector{2, Int64}) = CartesianIndex{2}(x[1], x[2])
Base.convert(::Type{CartesianIndex{2}}, x::SVector{2, Int64}) =
    CartesianIndex{2}(x)

function collisions(kd::KDTree, index::Int64, radius::Float64)
    pos = kd.data[index]
    # is anything present at this location?
    idxs = inrange(kd, pos, radius) # length < 1
    colliders = filter(x -> x != index, idxs)
    return colliders
end

get_agent(i::Int64) = @optic _.agents[i]
get_static(i::CartesianIndex{2}) = @optic _.items[i]

include("mutating_lens.jl")
