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

struct Move <: Action
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

struct Die end
const die = Die()
struct Clone end
const clone = Clone()

function compose end

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

function sync!(queue::PriorityQueue, rule::Interaction, a::Int64, b)
    empty!(queue)
    enqueue!(queue, rule, 0)
    return nothing
end

# compose all the lenses
function resolve(queues::Vector, st::GameState) # maybe game-specific
    n_agents = length(queues)

    # change death and birth queue
    d_queue = Dict{Function, Function}() # lens(), transform()
    b_queue = Dict{Function, Function}()
    c_queue = Dict{Function, Function}() 

    for i = 1:n_agents
        for (r, p) in queues[i]
            @show lr = opcompose(get_agent(i), lens(r))
            @show tr = transform(r)

            # sort r into a queue
            if r == die
                push!(d_queue, lr => tr)
            elseif r == clone
                push!(b_queue, lr => tr)
            end
            # check if lens r exist in queue
            if !haskey(c_queue, lr)
                push!(c_queue, lr => tr)
            else
                continue
            end
        end
    end

    batch_lens = reduce(++, keys(c_queue))
    @show targs = getall(st, batch_lens) # returns selected parts of st
    @show tvals = values(c_queue)

    # apply tr to targs
    #= for i in 1:length(targs)
        val = tvals[i]
        arg = targs[i]
        val(arg)
    end =#
    @show treturn = collect(map((f, arg) -> f(arg), tvals, targs))
    
    st = setall(st, batch_lens, treturn)
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