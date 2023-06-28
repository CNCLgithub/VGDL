module ButterflyGame
using Accessors
using NearestNeighbors

# define the main interface
abstract type Observation end
abstract type Element end
abstract type StaticElement <: Element end
abstract type DynamicElement <: Element end
abstract type Agent <: DynamicElement end
"""
    position (::DynamicElement)::CartesianIndex{2}

position of an element
"""
function position end
"""
    policy (::Agent)::Policy

policy of an agent
"""
function policy end
abstract type Action end
abstract type Scene end
abstract type Policy end



mutable struct GridScene <: Scene 
    bounds::Tuple{Int, Int}
    items::Matrix{StaticElement} #TODO: obstacles & pinecones
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
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy

mutable struct Player <: Agent
    position::CartesianIndex{2}
    policy::Policy
end
position(agent::Player) = agent.position
policy(agent::Player) = agent.policy


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
    l_agents = length(state.agents)
    actions = Vector{Action}(undef, l_agents)
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, state)
        actions[i] = plan(agent, obs)
    end
    # resolve actions
    # player first
    newstate = deepcopy(state) #REVIEW: inefficient
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, state)
        actions[i] = plan(agent, obs)
    end
end

function resolve!(::GameState, ::Agent, ::NoAction) 
    return nothing
end

function move(state::GameState, agent::Agent, action::Up)
    pos = y, x = position(agent)
    y == 1 && return pos
    new_position = CartesianIndex(y-1, x)
    return new_position
end

function move(state::GameState, agent::Agent, action::Down)
    pos = y, x = position(agent)
    y == state.scene.bounds[2] && return pos
    new_position = CartesianIndex(y+1, x)
    return new_position
end

function move(state::GameState, agent::Player, action::Left)
    pos = y, x = position(agent)
    x == 1 && return pos
    new_position = CartesianIndex(y, x-1)
    return new_position
end

function move(state::GameState, agent::Player, action::Right)
    pos = y, x = position(agent)
    x == state.scene.bounds[1] && return pos
    new_position = CartesianIndex(y, x+1)
    return new_position
end


function resolve!(state::GameState, agent::Player, action::Action)
    new_position = move(state, agent, action)
    # check if new_position collides w obstacle
    state.scene.item[new_position] = obstacle && return agent
    @set agent.position = new_position
    end
end
module ButterflyGame


end

function resolve!(state::GameState, agent::Butterfly, action::Action)
    # TODO: butterfly gets eaten, score increases
end


struct NoObservation <: Observation end

function observe(::Butterfly, ::GameState)
    return NoObservation()
end

function observe(agent::Player, state::GameState)::Observation
    # get all butterfly locations
    l_agents = length(state.agents)
    V = SVector{2, Int32}
    positions = Vector{V}(undef, l_agents-1)
    for i = 2:l_agents 
        agent = state.agents[i]
        y, x = agent.position[1], agent.position[2]
        positions[i-1] = [x, y]
    end
    # nearest neighbot search
    kdtree = KDTree(positions)
    y, x = agent.position[1], agent.position[2]
    nn(kdtree, [x, y]) = index, dist
    # returns the location of the nearest butterfly
    return positions[index]
end

function plan(state::GameState, agent::Player, obs::Observation, policy=policy(agent))
    y, x = agent.position[1], agent.position[2]
    bx, by = obs[1], obs[2]
    # moves toward the nearest butterfly
    if y > by
        move(state, agent, Up())
    else if y < by
        move(state, agent, Down())
    else if x > bx 
        move(state, agent, Right())
    else if x < bx
        move(state, agent, Left())
    end
end

# generate an observation for the agent (for now, this can be a simple pixel render but we can flush this out with rendering modules)
observe(state::GameState, agent::Agent)::Observation
plan(agent::Agent, obs::Observation, policy=policy(agent))::Action


# we can have different policies for different units in the game
# here is an "dummy" example, that just picks a random action
struct RandomPolicy <: Policy end
plan(agent::Agent, obs::Observation, policy::RandomPolicy) = rand(actionspace(agent))


end