export InteractionMap,
    interaction_set,
    compile_interaction_set,
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
function compile_interaction_set(g::Game) # Generic
    iset = interaction_set(g)
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
    #n_agents = length(queues)
    ks = collect(keys(st.agents))

    # change death and birth queue
    cq = Dict{Any, Function}()
    bq = Dict{Any, Function}()
    dq = Dict{Any, Function}()

    # move rules from agent queues to c,b,d queues
    for i = ks
        for (r, p) in queues[i]
            pushtoqueue!(r, cq, bq, dq)
        end
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
function pushtoqueue!(r::Rule{<:NoEffect, <:Application},
                      c::AbstractDict, b::AbstractDict, d::AbstractDict)
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
# Evolving game state (rule application)
#################################################################################

"""
    update_step(state::GameState, imap::InteractionMap)::GameState

Produces the next game state.
"""
function update_step(state::GameState, imap::InteractionMap)::GameState
    @show ks = collect(keys(state.agents))
    # REVIEW: this is gross
    queues = OrderedDict{Int64, PriorityQueue}(
        [i => PriorityQueue{Rule, Int64}() for i in ks]
    )
    og_pos = lookahead(state.agents)
    kdtree = KDTree(og_pos, cityblock)
    # action phase
    for i = ks
        agent = state.agents[i]
        obs = observe(agent, i, state, kdtree)
        action = plan(agent, i, obs)
        sync!(queues[i], action)
    end
    # static interaction phase
    new_pos = lookahead(state.agents, queues)
    for i = eachindex(ks)
        agent_id = ks[i]
        agent = state.agents[agent_id]
        pot_pos = new_pos[i]
        # could be a `Ground` | `Obstacle` | `Pinecone`
        elem = state.scene.items[CartesianIndex(pot_pos)]
        key = typeof(agent) => typeof(elem)
        haskey(imap, key) || continue
        rule = imap[key](agent_id, pot_pos)
        sync!(queues[agent_id], rule)
    end
    # dynamic interaction phase
    kdtree = KDTree(new_pos, cityblock)
    for i = eachindex(ks)
        agent_id = ks[i]
        agent = state.agents[agent_id]
        # Check the agent's position on the gridscene
        cs = collisions(kdtree, i, 1, og_pos)
        # Update
        for ci in cs
            cindex = ks[ci]
            collider = state.agents[cindex]

            @show key = typeof(agent) => typeof(collider)
            haskey(imap, key) || continue
            rule = imap[key](agent_id, cindex)
            sync!(queues[agent_id], rule)
        end
    end

    state = resolve(queues, state)
end


#################################################################################
# Helpers
#################################################################################

function lookahead(agents::OrderedDict{Int64, Agent})
    map(v -> v.position, values(agents))
end

function lookahead(agents::OrderedDict{Int64,Agent},
                   queues::OrderedDict{Int64, <:PriorityQueue})
    positions = lookahead(agents)
    ks = collect(keys(agents))
    for i in eachindex(ks)
        agent = agents[ks[i]]
        queue = queues[ks[i]]
        # queue_array = collect(queue)
        for (r, p) in queue
            if typeof(r) <: Move
                positions[i] = transform(r)(positions[i])
            end
        end
    end
    return positions
end

function new_index(st::GameState)
    l = get_agent(length(st.agents) + 1)
    Lens!(l)
end
