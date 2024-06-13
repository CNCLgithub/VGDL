export collisions,
    collisions!

#################################################################################
# Game logic
#################################################################################


function collisions(tree::NNTree, index::Int64, radius::Int64,
                     prev_pos::Vector{SVector{2, Int64}})
    colvec = fill(false, length(prev_pos))
    collisions!(colvec, tree, index, radius, prev_pos)
    return colvec
end

"""
$(TYPEDSIGNATURES)

Determine the collisions between an object (`index`) and
other dynamic elements.

- `tree`: The `KDTree` of current object positions (usually cityblock)
- `index`: Object collidee
- `radius`: Distance to consider from `index`
- `prev_pos`: Positions of most recent game state


`prev_pos` is necessary in case objects `a` and `b` swap locations.
"""
function collisions!(colvec::Vector{Bool},
                     tree::NNTree, index::Int64, radius::Int64,
                     prev_pos::Vector{SVector{2, Int64}})
    cur_tgt_loc = tree.data[index]
    pre_tgt_loc = prev_pos[index]
    new_pos = tree.data
    # is anything present at this location?
    idxs = inrange(tree, cur_tgt_loc, radius)
    n = length(idxs)

    fill!(colvec, false)
    for ci = idxs
        colvec[ci] = ci != index && (
            (new_pos[ci] == cur_tgt_loc)   ||
                (new_pos[ci] == pre_tgt_loc)  ||
                (prev_pos[ci] == cur_tgt_loc) ||
                (prev_pos[ci] == pre_tgt_loc))
    end

    return nothing
end


#################################################################################
# Indexing
#################################################################################

# helps with matrix indexing
Base.CartesianIndex(x::SVector{2, Int64}) = CartesianIndex{2}(x[1], x[2])
Base.convert(::Type{CartesianIndex{2}}, x::SVector{2, Int64}) =
    CartesianIndex(x)

#################################################################################
# Lens utils
#################################################################################

get_dynamic(i::Int64) = @optic _.scene.dynamic[i]
@deprecate get_agent(i::Int) get_dynamic(i)
get_static(i::CartesianIndex{2}) = @optic _.scene.static[i]

include("mutating_lens.jl")
