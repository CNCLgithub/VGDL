export InteractionMap,
        interaction_set,
        compile_interaction_set,
        resolve,
        Move, up, down, right, left, no_action, all_moves,
        actionspace

#= InteractionSet
        avatar    wall   > stepBack
        butterfly wall > stepBack
        butterfly avatar > changeScore value=2
        butterfly avatar > killSprite
        butterfly cocoon > cloneSprite
        butterfly butterfly > nothing
        avatar cocoon > nothing
        butterfly wall > nothing
        cocoon butterfly > killSprite =#

"""
    lens(::Rule)

The lens that the rule applies to
"""
function lens end

"""
    transform(::Rule)

The transformation applied at the lens.
"""
function transform end

struct CompositeRule <: Rule{CompositeEffect}
    a::Rule
    b::Rule
    # TODO: Implement these!
    lens::Lens
    transform::Function
end

get_agent(i::Int) = @optics _.agents[i]

struct Move <: Rule{ChangeEffect}
    dir::SVector{2, Int64}
end
lens(::Move) = @optic _.position
transform(m::Move) = x -> x + m.dir

const up = Move([-1,0])
const down = Move([1,0])
const left = Move([0,-1])
const right = Move([0,1])
const no_action = Move([0,0])
const all_moves = [up, down, left, right, no_action]
function actionspace(::Agent)
    return all_moves
end

struct Stepback <: Rule{ChangeEffect} end
function stepback(l, r)
    Stepback()
end
lens(::Stepback) = @optic _.position
transform(m::Stepback) = x -> x # REVIEW: feels weird

struct Applicator{T} <: Rule{T}
    lens::Lens
    transform::Function
    base::Rule{T}
    function Applicator(r::Rule{<:Effect}, l::Lens)
        new{T}(opcompose(l, lens(r)), transform(r), r)
    end
end
# TODO: Implement lens and transform

struct Clone <: Rule{BirthEffect} end
const clone = Clone()
struct Die <: Rule{DeathEffect}
    lens::Lens
    transform::Function
    function Die(ref::Int64)
        new(IndexLens(ref), x -> x)
    end
end

function die(i, o)
    Die(i)
end

struct ChangeScore <: Rule{ChangeEffect} end
lens(::ChangeScore) = @optic _.reward
transform(::ChangeScore) = x -> x + 1

function changescore(i, o)
    ChangeScore()
end



function sync!(queue::PriorityQueue, rule::Move)
    enqueue!(queue, rule, 1)
    return nothing
end

function sync!(queue::PriorityQueue, ::Stepback)
    for r in queue
        if typeof(r.first) == Move
            delete!(queue, r.first)
            break
        end
    end
    return nothing
end

function sync!(queue::PriorityQueue, rule::Die, a::Int64, b)
    empty!(queue)
    enqueue!(queue, rule, 0)
    return nothing
end

# compose all the lenses
function resolve(queues::Vector, st::GameState) # maybe game-specific
    n_agents = length(queues)

    # change death and birth queue
    cq = Dict{Lens, Function}()
    bq = Dict{Lens, Function}()
    dq = Dict{Lens, Function}()

    for i = 1:n_agents
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
    for (l, f) in cq
        val = f(l(st))
        # TODO: implement `new_index`
        mut_lens = new_index(st, l) # writing to new agent index
        insert(new_state, mut_lens, val)
    end

    # deaths last
    for (l, f) in cq
        mut_lens = Lens!(l)
        # val = f(l(st))
        delete(new_state, mut_lens, val)
    end

    batch_lens = reduce(++, keys(cq))
    @show targs = getall(st, batch_lens) # returns selected parts of st
    @show tvals = values(cq)
    @show treturn = collect(map((f, arg) -> f(arg), tvals, targs))

    st = setall(st, batch_lens, treturn)
end

function pushtoqueue!(r::CompositeRule, cq::Dict, bq::Dict, dq::Dict)
    pushtoqueue!(r.a, cq, bq, dq) && pushtoqueue!(r.b, cq, bq, dq)
end

function pushtoqueue!(r::Rule{ChangeEffect}, cq::Dict, ::Dict, dq::Dict)
    lr = lens(r)
    haskey(cq, lr) && return false
    tr = transform(r)
    cq[lr] = tr
    return true
end

function pushtoqueue!(r::Rule{BirthEffect}, ::Dict, bq::Dict, ::Dict)
    lr = lens(r)
    haskey(cq, lr) && return false
    tr = transform(r)
    bq[lr] = tr
end

function pushtoqueue!(r::Rule{DeathEffect}, ::Dict, ::Dict, dq::Dict)
    lr = lens(r)
    tr = transform(r)
    haskey(cq, lr) && return false
    qq[lr] = tr
end

const IPair = Pair{Any, Any}
# const Interaction = Pair{IPair, Function} 
# const InteractionSet = Vector{Interaction}

# REVIEW: check if type variables are slow
function interaction_set(::BG)
    set = [ 
        (Player => Obstacle) => stepback,
        (Butterfly => Obstacle) => stepback,
        (Butterfly => Player) => die,
        (Butterfly => Player) => changescore,
        # (Butterfly => Pinecone) => kill,
        # (Butterfly => Pinecone) => clone,
        # (Pinecone => Butterfly) => die,
    ]
end
        
const InteractionMap = Dict{IPair, Function}
        

function compile_interaction_set(g::Game) # Generic
    iset = interaction_set(g)
    # a temporary mapping of type pairs ->
    # a vector of functions that will be composed
    vmap = Dict{IPair, Vector{Function}}()
    for i in eachindex(iset)
        tpair = iset[i].first
        r = iset[i].second
        if haskey(vmap, tpair)
            push!(vmap[tpair], r)
        else
            vmap[tpair] = [r]
        end
    end
    imap = InteractionMap() # Dict{IPair, Function}
    # compose the lenses
    for (tpair, vinter) in vmap
        imap[tpair] = reduce(∘, vmap[tpair])
    end
    return imap
end

# composite rule 
# args: two constructors for rules
# such that the left & right are broadcasted to the constructor rules


#= function changescore(state::GameState, butterfly::Butterfly, player::Player)
    state.reward += 1
end

function kill(state::GameState, butterfly::Butterfly, player::Player) #TODO: remove agent from agents
    agents = state.agents
end

function clone(state::GameState, butterfly::Butterfly)
    # clone one for now
    agents = state.agents
    action = rand(actionspace(butterfly))
    new_butterfly = move(state, butterfly, action)
    agents.push!(new_butterfly)
end

function kill(pinecone::Pinecone, butterfly::Butterfly)
    m = scene.items
    m[position(butterfly)] = ground
end
 =#
