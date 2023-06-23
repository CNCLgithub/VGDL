module ButterflyGame

# define the main interface
abstract type Observation end
abstract type Element end
abstract type StaticElement <: Element end
abstract type DynamicElement <: Element end
abstract type Agent <: DynamicElement end
abstract type Action end
abstract type Scene end
abstract type Policy end


mutable struct GridScene <: Scene 
    bounds::Tuple{Int, Int}
    items::Matrix{StaticElement} #TODO
end

mutable struct GameState
    scene::GridScene
    agents::Vector{Agent}
    reward::Float64
end

struct Obstacle <: StaticElement end
const obstacle = Obstacle()

struct Pinecone <: StaticElement end
const pinecone = Pinecone()

struct Floor <: StaticElement end
const floor = Floor()

mutable struct Butterfly <: Agent
    position::CartesianIndex{2}
    energy::Float64
    policy::Policy

    function Butterfly(position)
        new(position, 0, RandomPolicy())
    end
end

mutable struct Player <: Agent
    position::CartesianIndex{2}
    policy::Policy
end

struct Left <: Action end
struct Right <: Action end
struct Up <: Action end
struct Down <: Action end
struct NoAction <: Action end
const no_action = NoAction()

const all_moves = [Left(), Right(), Up(), Down(), NoAction()]
function actionspace(agent::Agent)
    return all_moves
end


# evolves the world, generating a new state from an agent's action (possibly no action)
function step(state::GameState)::GameState
    # aggregate actions
    lagents = length(state.agents)
    actions = Vector{Action}(undef, lagents)
    for i = 1:lagents
        agent = state.agents[i]
        obs = observe(agent, state)
        actions[i] = plan(agent, obs)
    end
    # resolve actions
    # player first
    newstate = deepcopy(state) #REVIEW: inefficient
    for i = 1:lagents
        agent = state.agents[i]
        obs = observe(agent, state)
        actions[i] = plan(agent, obs)
    end
end

function resolve!(::GameState, ::Agent, ::NoAction) 
    return nothing
end

function move(state::GameState, agent::Player, action::Up)
    # check if up is out of bounds
    # check if up is blocked
    # return agent with new position if both false
    Player(newposition)
end

function move(state::GameState, agent::Player, action::Down)
    
end

function move(state::GameState, agent::Player, action::Left)
    
end

function move(state::GameState, agent::Player, action::Right)
    
end

function resolve!(state::GameState, agent::Player, action::Action)
    agent = move(state, agent, action)
    # if there's no new position, 
    # check if player can interact in new location - pine cone?

end

struct NoObservation <: Observation end
function observe(::Butterfly, ::GameState)
    return NoObservation()
end
function observe(agent::Player, state::GameState) 
    #TODO
end


# generate an observation for the agent (for now, this can be a simple pixel render but we can flush this out with rendering modules)
observe(state::GameState, agent::Agent)::Observation
plan(agent::Agent, obs::Observation, policy=policy(agent))::Action


# we can have different policies for different units in the game
# here is an "dummy" example, that just picks a random action
struct RandomPolicy <: Policy end
plan(agent::Agent, obs::Observation, policy::RandomPolicy) = rand(actionspace(agent))



end
