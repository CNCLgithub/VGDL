module ButterflyGame
using Accessors
using NearestNeighbors
using StaticArrays
using Setfield
using AccessorsExtra

export GameState

# define the main interface
abstract type Game end
struct ButterflyGame <: Game end
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
    items::Matrix{StaticElement}
end

GridScene(bounds) = GridScene(bounds, fill(floor, bounds))

mutable struct GameState
    scene::GridScene
    agents::Vector{Agent}
    reward::Float64

    GameState(scene) = new(scene, Agent[], 0)
end

struct Obstacle <: StaticElement end
const obstacle = Obstacle()

struct Pinecone <: StaticElement end
const pinecone = Pinecone()

struct Floor <: StaticElement end
const floor = Floor()


mutable struct Butterfly <: Agent
    position::SVector{2, Int64}
    energy::Float64
    policy::Policy

    function Butterfly(position)
        new(position, 0, RandomPolicy())
    end
end

position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy


mutable struct Player <: Agent
    position::SVector{2, Int64}
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


function step(state::GameState, imap::InteractionMap)::GameState
    # queue actions
    l_agents = length(state.agents)
    new_agents = Vector{Agent}(undef, l_agents)
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, state)
        new_agents[i] = plan(state, agent, obs, policy) # TODO: policy
    end
    # detect (and resolve?) interactions (collisions)
    newscene = deepcopy(state.scene) # REVIEW: inefficient
    positions = map(position, new_agents)
    kdtree = KDTree(positions)
    for i = 1:l_agents
        agent = new_agents[i]
        # Check the agent's position on the gridscene
        cs = collisions(state, position(agent), kdtree)
        agent_type = typeof(agent)
        # Update
        for collider in cs
            key = agent_type => typeof(collider)
            haskey(imap, key) || continue
            #rule = get(imap, key, x -> x)
            #rule = imap[key]
            new_agents[i] = rule(new_agents[i])
        end 
    end
end

function collisions(state, agent_pos, kdtree)
    # is anything present at this location?
    elem::Element = state.scene[agent_pos] # could a `Floor` | `Obstacle` | `Pinecone`
    idxs = inrange(kdtree, agent_pos, 1.0) # length > 1
    other_agents = state.agents[idxs]
    collisions = Vector{Element}[state.scene[agent_pos]]
    append!(collisions, other_agents)
    return collisions
end


#=

function resolve!(::GameState, ::Agent, ::NoAction) 
    return nothing
end

function move(state::GameState, agent::Agent, action::Up)
    y, x = position(agent)
    @set agent.position = [y-1, x]
    return agent
end

function move(state::GameState, agent::Agent, action::Down)
    y, x = position(agent)
    @set agent.position = [y+1, x]
    return agent
end

function move(state::GameState, agent::Player, action::Left)
    y, x = position(agent)
    new_position = CartesianIndex(y, x-1)
    @set agent.position = new_position
    return agent
end

function move(state::GameState, agent::Player, action::Right)
    y, x = position(agent)
    new_position = CartesianIndex(y, x+1)
    @set agent.position = new_position
    return agent
end


function resolve!(state::GameState, agent::Player, action::Action)
    new_position = move(state, agent, action)
    # check if new_position collides w obstacle
    state.scene.item[new_position] = obstacle && return agent
    @set agent.position = new_position
    end
end

function resolve!(state::GameState, agent::Butterfly, action::Action)
    # TODO: butterfly gets eaten, score increases
    return nothing
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
    # nearest neighbor search
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
    direction = if y > by
        Up()
    elseif y < by
        Down()
    elseif x > bx
        Right()
     else
        Left()
    end
   new_pos = move(state, agent, direction)
end

# generate an observation for the agent
observe(state::GameState, agent::Agent)::Observation
plan(agent::Agent, obs::Observation, policy=policy(agent))::Action


# we can have different policies for different units in the game
# here is an "dummy" example, that just picks a random action
struct RandomPolicy <: Policy end
plan(agent::Agent, obs::Observation, policy::RandomPolicy) = rand(actionspace(agent))
=#
include("scene.jl")
end