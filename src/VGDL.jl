module VGDL

using Accessors
using Setfield
using NearestNeighbors
using StaticArrays
using AccessorsExtra
using DataStructures 
using InteractiveUtils

export Game, BG,
        GameState, GridScene, get_element,
        Element, ground, obstacle, pinecone,
        Agent, Player, Butterfly,
        greedy_policy,
        Rule, Effect, ChangeEffect, DeathEffect, BirthEffect, 
        update_step


# define the main interface
abstract type Game end

struct BG <: Game end # TODO: rename

abstract type Effect end
abstract type ChangeEffect <: Effect end
abstract type BirthEffect <: Effect end
abstract type DeathEffect <: Effect end
abstract type CompositeEffect <: Effect end

abstract type Rule{T<:Effect} end

abstract type Observation end
struct PosObs <: Observation
    data::SVector{2, Int32}
end
struct NoObservation <: Observation end

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
struct GreedyPolicy <: Policy end
const greedy_policy = GreedyPolicy()
struct RandomPolicy <: Policy end
const random_policy = RandomPolicy()


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
Butterfly(position) = Butterfly(position, 0, random_policy)
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy

mutable struct Player <: Agent
    position::SVector{2, Int64}
    policy::Policy
end
Player(position) = Player(position, greedy_policy)
position(agent::Player) = agent.position
policy(agent::Player) = agent.policy


get_element(::Matrix, sv::SVector{2, Int64}) = IndexLens(sv[1], sv[2])


include("mutating_lens.jl")
include("interaction.jl")

function update_step(state::GameState, imap::InteractionMap)::GameState
    # action phase
    l_agents = length(state.agents)
    queues = [PriorityQueue{Rule, Int64}() for _ in 1:l_agents] # TODO: optimize
    kdtree = KDTree(lookahead(state.agents))
    for i = 1:l_agents
        agent = state.agents[i]
        obs = observe(agent, i, state, kdtree)
        action = plan(agent, i, obs)
        sync!(queues[i], action)
    end
    
    # static interaction phase
    positions = lookahead(state.agents, queues)
    for i = 1:l_agents 
        agent = state.agents[i]
        @show pot_pos = positions[i]
        lens = get_element(state.scene.items, pot_pos)
        @show elem = lens(state.scene.items) # could be a `Ground` | `Obstacle` | `Pinecone`
        @show key = typeof(agent) => typeof(elem)
        haskey(imap, key) || continue
        @show rule = imap[key](i, pot_pos)
        sync!(queues[i], rule)
    end

    # dynamic interaction phase
    positions = lookahead(state.agents, queues)
    kdtree = KDTree(positions)
    for i = 1:l_agents
        agent = state.agents[i]
        @show pot_pos = positions[i]
        # Check the agent's position on the gridscene
        @show cs = collisions(kdtree, pot_pos, 1, i)
        # Update
        agent_type = typeof(agent)
        for ci in cs
            collider = state.agents[ci]
            @show key = agent_type => typeof(collider)
            haskey(imap, key) || continue
            sync!(queues[i], imap[key])
        end 
    end

    # resolve the queue
    state = resolve(queues, state)
end

function lookahead(agents::Vector{Agent})
    positions = map(x -> x.position, agents)
end

function lookahead(agents::Vector{Agent}, queues::Vector)
    positions = map(x -> x.position, agents)
    for i in eachindex(agents)
        agent = agents[i]
        queue = queues[i] 
        queue_array = collect(queue)
        for (r, p) in queue_array
            if lens(r) == @optic _.position
                positions[i] = transform(r)(positions[i])
            end                                                                  
        end
    end
    return positions
end

function collisions(kdtree, agent_pos, radius::Float64, agent_index::Int64)
    # is anything present at this location?
    idxs = inrange(kdtree, agent_pos, radius) # length < 1
    colliders = filter(x -> x != agent_index, idxs)
    return colliders
end

#observe(state::GameState, agent::Agent)::Observation
#plan(state::GameState, agent::Agent, obs::Observation, policy=policy(agent))::Action

function observe(::Agent, ::GameState)
    return NoObservation()
end

function observe(agent::Player, agent_index::Int, state::GameState, kdtree::KDTree)::Observation
    # get all butterfly locations
    l_agents = length(state.agents)
    if l_agents == 1
        return NoObservation()
    end

    #TODO: ensure returns in order
    agent_pos = kdtree.data[agent_index]
    cs = collisions(kdtree, agent_pos, 50, agent_index) # TODO: get dimensions from state
    ci = cs[1]

    # returns the location of the nearest butterfly
    position = kdtree.data[ci]
    return PosObs(position)
end

function observe(::Butterfly, ::GameState, ::KDTree)
    return NoObservation()
end

function plan(agent::Agent, agent_index::Int, obs::Observation)
    plan(policy(agent), agent, agent_index, obs)
end

function plan(::GreedyPolicy, agent::Player, agent_index::Int, obs::PosObs)
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
    Applicator(direction, get_agent(agent_index))
end

function plan(::GreedyPolicy, agent::Agent, agent_index::Int, ::NoObservation)
    direction = rand(actionspace(agent))
    Applicator(direction, get_agent(agent_index))
end

function plan(::RandomPolicy, agent::Agent, agent_index::Int, ::Observation)
    direction = rand(actionspace(agent))
    Applicator(direction, get_agent(agent_index))
end

include("scene.jl")
end
