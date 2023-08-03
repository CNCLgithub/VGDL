using ButterflyGame
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

struct CompositeRule <: Rule
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

struct Stepback end
function stepback(l, r)
    Stepback()
end

struct Applicator{T<:Effect} <: Rule{T}
    lens::Lens
    transform::Function
    base::Rule{T}
    function Applicator(r::Rule{T<:Effect}, l::Lens)
        new{T}(opcompose(l, lens(r)), transform(r), r)
    end
end

struct Clone <: Rule{BirthEffect} end
const clone = Clone()
struct Die <: Rule{DeathEffect} end
const die = Die()


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
            pushtoqueue(r, cq, bq, dq)
        end
    end

    if isempty(cq) && isempty(bq) && isempty(dq)
        return st
    end

    batch_lens = reduce(++, keys(cq))
    @show targs = getall(st, batch_lens) # returns selected parts of st
    @show tvals = values(cq)
    @show treturn = collect(map((f, arg) -> f(arg), tvals, targs))
    
    st = setall(st, batch_lens, treturn)
end

function pushtoqueue(r::Rule{ChangeEffect}, cq::Dict, ::Dict, dq::Dict)
    lr = lens(r)
    tr = transform(r)
    push!(cq, lr => tr)
end

function pushqueue(r::Rule{BirthEffect}, ::Dict, bq::Dict, ::Dict)
    lr = lens(r)
    tr = transform(r)
    push!(bq, lr => tr)
end

function pushqueue(r::Rule{DeathEffect}, ::Dict, ::Dict, dq::Dict)
    lr = lens(r)
    tr = transform(r)
    push!(dq, lr => tr)
end

const IPair = Pair{Any, Any}
# const Interaction = Pair{IPair, Function} 
# const InteractionSet = Vector{Interaction}

# REVIEW: check if type variables are slow
function interaction_set(::BG)
    set = [ 
        (Player => Obstacle) => stepback,
        #= (Butterfly => Obstacle) => stepback,
        (Butterfly => Player) => changescore,
        (Butterfly => Player) => die,
        (Butterfly => Pinecone) => kill,
        (Butterfly => Pinecone) => clone,
        (Pinecone => Butterfly) => die, =#
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