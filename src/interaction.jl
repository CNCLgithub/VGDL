using ButterflyGame
export InteractionMap,
        Stepback, Back,
        Move, Up, Down, Left, Right

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

struct Move 
    dir::SVector{2, Int64}
end
lens(::Move) = @optic _.position
transform(m::Move) = x -> x + m.dir
const Up = Move([-1,0])
const Down = Move([1,0])
const Left = Move([0,-1])
const Right = Move([0,1])

struct Stepback end
const Back = Stepback()

function compose end
function compose(::Move, ::Stepback)
    NoAction()
end


const IPair = Pair{ButterflyGame.Element, ButterflyGame.Element}
# const Interaction = Pair{IPair, Function}
const InteractionSet = Vector{Interaction}

# REVIEW: check if type variables are slow
function interaction_set(::Game)
    set = Interaction[ 
        (Player => Obstacle) => stepback,
        (Butterfly => Obstacle) => stepback,
        (Butterfly => Player) => changescore,
        (Butterfly => Player) => kill,
        (Butterfly => Pinecone) => clone,
        (Pinecone => Butterfly) => kill,
    ]
end
        
const InteractionMap = Dict{Pair, Interaction}
        

# TODO: compose lenses (batchlens) - move & stepback & values
function compile_interaction_set(g::Game)
    iset = interaction_set(g)
    # a temporary mapping of type pairs ->
    # a vector of functions that will be composed
    vmap = Dict{IPair, Vector{Function}}()
    imap = InteractionMap()
    if haskey(vmap, tpair)
        push!(vmap[tpair], func)
    else
        vmap[tpair] = [func]
    end
    # compose the lenses
    imap = InteractionMap()
    for (tpair, vfunc) in vmap
        imap[tpair] = ∘(vmap[tpair])
    end
    return imap
end


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