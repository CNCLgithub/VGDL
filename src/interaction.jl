using ButterflyGame
export InteractionMap,
        interaction_set,
        compile_interaction_set

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

struct Move <: Action
    dir::SVector{2, Int64}
end
lens(::Move) = @optic _.position
transform(m::Move) = x -> x + m.dir
const up = Move([-1,0])
const down = Move([1,0])
const left = Move([0,-1])
const right = Move([0,1])

struct Stepback end
function stepback(l, r)
    Stepback()
end
const back = Stepback()

function compose end


function sync!(queue::PriorityQueue, rule::Move)
    enqueue!(queue, rule, 1)
    return nothing
end

function sync!(queue::PriorityQueue, rule::Stepback)
    for r in queue
        if typeof(r) === Move
            delete!(queue, r)
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
function resolve(queues::Vector{PriorityQueue}, g::Game, st::GameState) # maybe game-specific
    n_agents = length(queues)

    # change death and birth queue
    d_queue = Dict{Function, Function}() # lens(), transform()
    b_queue = Dict{Function, Function}()
    c_queue = Dict{Function, Function}() 

    for i = 1:n_agents
        for r in queues[i]
            lr = lens(r)
            tr = transform(r)

            # sort r into a queue
            if r == die
                push!(d_queue, lr => tr)
            else
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
    targs = getall(st, batch_lens) # returns selected parts of st
    tvals = values(c_queue)

    # apply tr to targs
    treturn = collect(Iterators.map(x -> tvals[x](targs[x]), 1:length(targs)))
    #= for i in 1:length(targs)
        val = tvals[i]
        arg = targs[i]
        val(arg)
    end =#
    
    setall(st, batch_lens, treturn)
end


const IPair = Pair{Element, Element}
# const Interaction = Pair{IPair, Function}
# const InteractionSet = Vector{Interaction}

# REVIEW: check if type variables are slow
function interaction_set(::BG)
    set = Function[ 
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
    imap = InteractionMap() 
    if haskey(vmap, tpair)
        push!(vmap[tpair], inter)
    else
        vmap[tpair] = [inter]
    end
    # compose the lenses
    imap = InteractionMap()
    for (tpair, vinter) in vmap
        imap[tpair] = ∘(vmap[tpair])
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
    m[position(butterfly)] = floor
end
 =#