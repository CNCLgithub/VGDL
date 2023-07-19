module ButterflyGame
using Accessors
using NearestNeighbors
using StaticArrays
using Setfield
using AccessorsExtra
using DataStructures 

export Game,
        GameState, 
        GridScene,
        Element,
        Player, Butterfly,
        floor, obstacle, pinecone


# define the main interface
abstract type Game end
struct BG <: Game end # TODO: rename
abstract type Rule end
abstract type Action <: Rule end
abstract type Interaction <: Rule end
abstract type Observation end
abstract type Element end
abstract type StaticElement <: Element end
abstract type DynamicElement <: Element end
abstract type Agent <: DynamicElement end
"""
    position (::DynamicElement)::SVector{2, Int64}

position of an element
"""
function position end
"""
    policy (::Agent)::Policy

policy of an agent
"""
function policy end
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

    function Player(position)
        new(position, no_policy)
    end
end
position(agent::Player) = agent.position
policy(agent::Player) = agent.policy

#=
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
=#

include("interaction.jl")

function step(state::GameState, imap::InteractionMap)::GameState
    # action phase
    l_agents = length(state.agents)
    queues = [PriorityQueue{Rule, Int64} for _ in 1:l_agents] # TODO: optimize
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, state)
        action = plan(agent, obs, policy)
        sync!(queues[i], action)
    end

    # static interaction phase
    kdtree = KDTree(potential_positions)
    for i = 1:l_agents
        pot_pos = lookahead(agent, queues[i]) 
        elem = state.scene[pot_pos] # could be a `Floor` | `Obstacle` | `Pinecone`
        key = typeof(agent) => typeof(elem)
        haskey(imap, key) || continue
        rule = imap[key](i, pot_pos)
        sync!(queues[i], rule)
    end

    # dynamic interaction phase
    for i = 1:l_agents
        agent = new_agents[i]
        pot_pos = lookahead(agent, queues[i]) 
        # Check the agent's position on the gridscene
        cs = collisions(state, pot_pos, kdtree)
        agent_type = typeof(elem)
        # Update
        for collider in cs
            key = agent_type => typeof(collider)
            haskey(imap, key) || continue
            sync!(queues[i], imap[key])
        end 
    end

    # resolve the queue

    return state
end


function collisions(state, agent_pos, kdtree)
    # is anything present at this location?
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

# TODO: return lens & function (+1,0)
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

=#

#observe(state::GameState, agent::Agent)::Observation
#plan(state::GameState, agent::Agent, obs::Observation, policy=policy(agent))::Action

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
    index, dist = nn(kdtree, [x, y])
    # returns the location of the nearest butterfly
    return positions[index]
end

function plan(agent::Player, obs::Observation, policy=policy(agent))
    y, x = agent.position[1], agent.position[2]
    bx, by = obs[1], obs[2]
    # moves toward the nearest butterfly
    direction = if y > by
        Up
    elseif y < by
        Down
    elseif x > bx
        Right
    else
        Left
    end
    return direction
end


# we can have different policies for different units in the game
# here is an "dummy" example, that just picks a random action
struct RandomPolicy <: Policy end
plan(agent::Agent, obs::Observation, policy::RandomPolicy) = rand(actionspace(agent))
struct NoPolicy <: Policy end
const no_policy = NoPolicy()


include("scene.jl")
include("interaction.jl")
include("../test/runtests.jl")
end