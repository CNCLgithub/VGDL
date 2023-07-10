using ButterflyGame

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

const IPair = Pair{Element, Element}
const Interaction = Pair{IPair, Function}
const InteractionSet = Vector{Interaction}
        
# REVIEW: check if type variables are slow
function interaction_set(::ButterflyGame)
    set = Interaction[ 
        (Player => Obstacle) => stepback,
        (Butterfly => Obstacle) => stepback,
        (Butterfly => Player) => changescore,
        (Butterfly => Player) => kill,
        (Butterfly => Pinecone) => clone,
        (Pinecone => Butterfly) => kill,
    ]
end
        
const InteractionMap = Dict{Pair, Function}
        
        
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
    end
    # actually compose the functions
    imap = InteractionMap()
    for (tpair, vfunc) in vmap
        imap[tpair] = ∘(vmap[tpair])
    end
    return imap
end


function stepback(agent::Agent, obstacle::Obstacle) #TODO: let the agent step back
    new_agent = 
    agent = new_agent
end

function changescore(state::GameState, butterfly::Butterfly, player::Player)
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
