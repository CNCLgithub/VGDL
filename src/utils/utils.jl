using Distances
using LinearAlgebra

import Base.typemin, Base.typemax, Base.length, Base.:-
export Line, typemin, collisions


# helps with matrix indexing
Base.CartesianIndex(x::SVector{2, Int64}) = CartesianIndex{2}(x[1], x[2])
Base.convert(::Type{CartesianIndex{2}}, x::SVector{2, Int64}) =
    CartesianIndex(x)

function collisions(tree::NNTree, index::Int64, radius::Int64,
                    prev_pos::Vector{SVector{2, Int64}})
    cur_tgt_loc = tree.data[index]
    pre_tgt_loc = prev_pos[index]
    new_pos = tree.data
    # is anything present at this location?
    idxs = inrange(tree, cur_tgt_loc, radius)
    n = length(idxs)

    # TODO: improve, maybe with channels?
    colliders = Int64[] # Channel{Int64}(n)
    for ci = idxs
        ci == index && continue
        if (new_pos[ci] == cur_tgt_loc)  ||
            (new_pos[ci] == pre_tgt_loc) ||
            (prev_pos[ci] == cur_tgt_loc)

            push!(colliders, ci)
        end
    end

    return colliders
end

get_dynamic(i::Int64) = @optic _.scene.dynamic[i]
get_agent(i::Int64) = get_dynamic(i) # TODO: depricate
get_static(i::CartesianIndex{2}) = @optic _.scene.static[i]

include("mutating_lens.jl")
