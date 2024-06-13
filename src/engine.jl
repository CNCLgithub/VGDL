export InteractionMap,
    interaction_set,
    compile_interaction_set,
    run_game,
    isfinished,
    action_step,
    update_step,
    sync!,
    modify!,
    add!,
    resolve


#################################################################################
# Interaction Core
#################################################################################

"Keys of an interaction set"
const IPair = Pair{Type{<:Element}, Type{<:Element}}
"An interaction map"
const InteractionMap = Dict{IPair, Function}

"""
    compile_interaction_set(g::Game)

Returns a flat mapping of element interactions to singular
rule instantiations.

The result is used in `update_step` and `resolve`.
"""
function compile_interaction_set(::Type{G}) where {G<:Game}
    iset = interaction_set(G)
    # a temporary mapping of type pairs ->
    # a vector of functions that will be composed
    vmap = Dict{IPair, Vector{Type{<:Rule}}}()
    for i in eachindex(iset)
        tpair, r = iset[i]
        if haskey(vmap, tpair)
            push!(vmap[tpair], r)
        else
            vmap[tpair] = [r]
        end
    end
    imap = InteractionMap()
    # compose the lenses
    for (tpair, vr) in vmap
        # fold right will help `pushtoqueue!`
        imap[tpair] = if length(vr) == 1
            promise(vr[1])
        else
            foldr((x,y) -> promise(CompositeRule, x, y), vr)
        end
    end
    return imap
end

#################################################################################
# Evolving game state (rule application)
#################################################################################
isfinished(st::GameState, tset::Array{TerminationRule}) =
    any(r -> r.predicate(st), tset)

"""
    run_game(g::Game, scene::GridScene)

Initializes the game state and evolves it.
"""
function run_game(::Type{G}, state::GameState) where {G <: Game}
    imap = compile_interaction_set(G)
    tset = termination_set(G)
    while !isfinished(state, tset)
        queue = action_step(state)
        state  = update_step(state, imap)
    end
    return state
end

function action_step(state::GameState)
    queues = OrderedDict{Int64, PriorityQueue}()
    scene = state.scene
    # action phase
    for i = scene.dynamic.keys
        el = scene.dynamic[i]
        rule = evolve(el, state)
        q = PriorityQueue{Rule, Int64}()
        sync!(q, promise(rule)(i, 0))
        queues[i] = q
    end
    return queues
end

function update_step(state::GameState, imap::InteractionMap)
    queues = action_step(state)
    update_step(state, imap, queues)
end
"""
    update_step(state::GameState, imap::InteractionMap)::GameState

Produces the next game state.
"""
function update_step(state::GameState, imap::InteractionMap,
                     queues::OrderedDict{Int64, PriorityQueue})

    scene = state.scene
    ks = scene.dynamic.keys
    # static interaction phase
    new_pos = lookahead(scene.dynamic, queues)
    for (i, el_id) = enumerate(ks)
        el = scene.dynamic[el_id]
        pot_pos = x, y = new_pos[i]
        # HACK: this is so gross
        if !checkbounds(Bool, scene.static, x, y)
            pos_pos = x, y = el.position
            # @show el_id
            # @show typeof(el)
            # @show el.position
            # @show pot_pos
        end
        tile = scene.static[x, y]
        key = typeof(el) => typeof(tile)
        haskey(imap, key) || continue
        rule = imap[key](el_id, pot_pos)
        sync!(queues[el_id], rule)
    end
    # dynamic interaction phase
    kdtree = KDTree(new_pos, cityblock)
    for (i, el_id) = enumerate(ks)
        el = scene.dynamic[el_id]
        T_el = typeof(el)
        # Check the el's position on the gridscene
        cs = collisions(kdtree, i, 1, scene.kdtree.data)
        # Update
        for ci in cs
            cindex = ks[ci]
            collider = scene.dynamic[cindex]
            key = T_el => typeof(collider)
            haskey(imap, key) || continue
            rule = imap[key](el_id, cindex)
            sync!(queues[el_id], rule)
        end
    end
    state = resolve(queues, state)
end




#################################################################################
# Resolving interactions
#################################################################################

"Default priority"
priority(::Rule) = 10

"Default modification to queue does nothing"
function modify!(queue::PriorityQueue, rule::Rule)
    return nothing
end

"Adds a rule to the queue with `priority`"
function add!(queue::PriorityQueue, rule::Rule)
    enqueue!(queue, rule, priority(rule))
    return nothing
end

"""

Integrate `rule` into `queue`.
See `modify!` and `add!`.
"""
function sync!(queue::PriorityQueue, rule::Rule)
    modify!(queue, rule)
    add!(queue, rule)
    return nothing
end


# REVIEW: Might want to allow for game specific implementations
"""
    resolve(queues, state)

Integrates all agent based queues into change, birth, and death queues,
then resolves the next game state.
"""
function resolve(queues::OrderedDict{Int64, <:PriorityQueue},
                 st::GameState)

    # change death and birth queue
    cq = Dict{Any, Function}()
    bq = Dict{Any, Function}()
    dq = Dict{Any, Function}()

    scene = st.scene
    # move rules from agent queues to c,b,d queues
    for (_, q) = queues, (r, _) = q
        pushtoqueue!(r, cq, bq, dq)
    end

    new_state = deepcopy(st)

    # changes first
    for (l, f) in cq
        mut_lens = Lens!(l)
        val = f(l(st))
        set(new_state, mut_lens, val)
    end

    # births next
    for (l, f) in bq
        val = f(l(st))
        mut_lens = new_index(new_state)
        Accessors.insert(new_state, mut_lens, val)
    end

    # deaths last
    for (l, f) in dq
        mut_lens = Lens!(l)
        delete(new_state, mut_lens)
    end

    new_state.time = st.time + 1
    new_scene = new_state.scene
    new_scene.kdtree = KDTree(lookahead(new_scene.dynamic), cityblock)
    return new_state
end

"""
    selectqueue(::Rule, c, b, d)

Determines which queue a rule applies to (change, birth, death).
"""
function selectqueue end
selectqueue(::Rule{ChangeEffect, <:Application}, c, b, d) = c
selectqueue(::Rule{BirthEffect, <:Application}, c, b, d) = b
selectqueue(::Rule{DeathEffect, <:Application}, c, b, d) = d

"""
    pushtoqueue!(r::Rule, c,b,d)

Adds `r` to the proper change, birth, or death queue.
"""
function pushtoqueue! end

"Has no effect..."
function pushtoqueue!(::Rule{<:NoEffect, <:Application},
                      ::AbstractDict, ::AbstractDict, ::AbstractDict)
    return true
end

"Add `r` as long as its lens is not already present"
function pushtoqueue!(r::Rule{<:Effect, Single},
                      c::AbstractDict, b::AbstractDict, d::AbstractDict)
    q = selectqueue(r, c, b, d)
    lr = lens(r)
    haskey(q, lr) && return false
    tr = transform(r)
    q[lr] = tr
    return true
end

function pushtoqueue!(r::Rule{<:Effect, Many},
                      c::AbstractDict, b::AbstractDict, d::AbstractDict)
    q = selectqueue(r, c, b, d)
    lr = lens(r)
    tr = transform(r)
    q[lr] = haskey(q, lr) ? opcompose(q[lr], tr) : tr
    return true
end

#################################################################################
# Helpers
#################################################################################

function lookahead(els::OrderedDict{Int64, DynamicElement})
    map(v -> v.position, values(els))
end

function lookahead(els::OrderedDict{Int64,DynamicElement},
                   queues::OrderedDict{Int64, <:PriorityQueue})
    positions = lookahead(els)
    for (i, k) = enumerate(els.keys)
        el = els[k]
        queue = queues[k]
        for (r, p) in queue
            if typeof(r) <: Move
                positions[i] = transform(r)(positions[i])
            end
        end
    end
    return positions
end

function new_index(st::GameState)
    new_index(st.scene)
end
function new_index(s::GridScene)
    keys = s.dynamic.keys
    key = length(keys) == 0 ? 0 : last(keys)
    l = get_dynamic(key + 1)
    Lens!(l)
end
