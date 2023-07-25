module ButterflyGame
using Accessors
using NearestNeighbors
using StaticArrays
using Setfield
using AccessorsExtra
using DataStructures 

export Game, BG,
        GameState, GridScene, getindex,
        Element, ground, obstacle, pinecone,
        Agent, Player, Butterfly,
        Rule,
        update_step


# define the main interface
abstract type Game end
struct BG <: Game end # TODO: rename
abstract type Rule end
abstract type Action <: Rule end
abstract type Interaction <: Rule end
abstract type Observation end
struct PosObs <: Observation
    data::SVector{2, Int32}
end
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

GridScene(bounds) = GridScene(bounds, fill(ground, bounds))

mutable struct GameState
    scene::GridScene
    agents::Vector{Agent}
    reward::Float64
end
GameState(scene) = GameState(scene, Agent[], 0)


struct Obstacle <: StaticElement end
const obstacle = Obstacle()
struct Pinecone <: StaticElement end
const pinecone = Pinecone()
struct Ground <: StaticElement end
const ground = Ground()


mutable struct Butterfly <: Agent
    position::SVector{2, Int64}
    energy::Float64
    policy::Policy
end
Butterfly(position) = Butterfly(position, 0, RandomPolicy())
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy


mutable struct Player <: Agent
    position::SVector{2, Int64}
    policy::Policy
end
Player(position) = Player(position, no_policy)
position(agent::Player) = agent.position
policy(agent::Player) = agent.policy

function Base.getindex(A::Array, index::SVector{2, Int64})
    y, x = index
    return A[y, x]
end


include("interaction.jl")

function update_step(state::GameState, imap::InteractionMap)::GameState
    # action phase
    l_agents = length(state.agents)
    queues = [PriorityQueue{Rule, Int64}() for _ in 1:l_agents] # TODO: optimize
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, state)
        action = plan(agent, obs, policy(agent))
        sync!(queues[i], action)
    end

    # static interaction phase
    for i = 1:l_agents 
        agent = state.agents[i]
        pot_pos = lookahead(agent, queues[i]) 
        elem = state.scene.items[pot_pos] # could be a `Ground` | `Obstacle` | `Pinecone`
        key = typeof(agent) => typeof(elem)
        haskey(imap, key) || continue
        @show rule = imap[key](i, pot_pos)
        sync!(queues[i], rule)
    end

    # dynamic interaction phase
    for i = 1:l_agents
        agent = state.agents[i]
        @show pot_pos = lookahead(agent, queues[i])
        # Check the agent's position on the gridscene
        # kdtree = KDTree(pot_pos)
        cs = collisions(state, pot_pos)
        # Update
        agent_type = typeof(agent)
        for collider in cs
            @show key = agent_type => typeof(collider)
            haskey(imap, key) || continue
            sync!(queues[i], imap[key])
        end 
    end

    # resolve the queue
    resolve(queues, state)
    return state
end

function lookahead(agent::Agent, queue::PriorityQueue)
    queue_array = collect(queue)
    for (act, p) in queue_array
        act_type = typeof(act)
        if act_type == Move
            dir = act.dir
            pos = agent.position
            return dir + pos
        end
    end
end

function collisions(state, agent_pos)
    # is anything present at this location?
    #= idxs = inrange(kdtree, agent_pos, 1.0) # length > 1
    other_agents = state.agents[agent_pos]
    collisions = [state.scene.items[agent_pos]]
    append!(collisions, other_agents)
    return collisions =#
    collisions = []
    collider = state.scene.items[agent_pos]
    append!(collisions, collider)
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

function observe(::Agent, ::GameState)
    return NoObservation()
end

function observe(agent::Player, state::GameState)::Observation
    # get all butterfly locations
    l_agents = length(state.agents)
    V = SVector{2, Int32}
    positions = Vector{V}(undef, l_agents-1)
    for i = 2:l_agents 
        butterfly = state.agents[i]
        y, x = butterfly.position[1], butterfly.position[2]
        positions[i-1] = [y, x]
    end
    # nearest neighbor search
    kdtree = KDTree(positions)
    y, x = agent.position[1], agent.position[2]
    index, dist = nn(kdtree, [y, x])
    # returns the location of the nearest butterfly
    return PosObs(positions[index])
end

function plan(agent::Player, obs::Observation, policy=policy(agent))
    y, x = agent.position[1], agent.position[2]
    by, bx = obs.data[1], obs.data[2]
    # moves toward the nearest butterfly
    direction = if y > by
        up
    elseif y < by
        down
    elseif x < bx
        right
    else
        left
    end
    return direction
end


# we can have different policies for different units in the game
# here is an "dummy" example, that just picks a random action
struct RandomPolicy <: Policy end
plan(agent::Agent, obs::Observation, policy::RandomPolicy) = rand(actionspace(agent))
struct NoPolicy <: Policy end
const no_policy = NoPolicy()
policy(::Agent) = RandomPolicy()

include("scene.jl")
include("../test/runtests.jl")
end