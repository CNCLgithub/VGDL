export Obstacle, obstacle,
    Pinecone, pinecone,
    Ground, ground,
    position,
    policy,
    observe,
    plan,
    Observation,
    NoObservation,
    PosObs,
    Policy,
    RandomPolicy,
    GreedyPolicy,
    Player,
    Butterfly


#################################################################################
# Static Elements
#################################################################################

struct Obstacle <: StaticElement end
const obstacle = Obstacle()

struct Pinecone <: StaticElement end
const pinecone = Pinecone()

struct Ground <: StaticElement end
const ground = Ground()

#################################################################################
# Agents
#################################################################################

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

"""
    observe(a::Agent, st::GameState)::Observation

How an agent observes the game state
"""
function observe end


const _default_actionspace = [Up, Down, Left, Right, NoAction]
actionspace(::Agent) = _default_actionspace

#################################################################################
# Agent observations
#################################################################################

abstract type Observation end

struct PosObs <: Observation
    data::SVector{2, Int32}
end

struct NoObservation <: Observation end
const no_obs = NoObservation()


#################################################################################
# Agent policies
#################################################################################

abstract type Policy end

"Sugar to extract agent's policy and use it for planning"
function plan(agent::Agent, agent_index::Int, obs::Observation)
    plan(policy(agent), agent, agent_index, obs)
end

"""
Why think when you can act.
"""
struct GreedyPolicy <: Policy end
const greedy_policy = GreedyPolicy()

function plan(::GreedyPolicy, agent::Agent, agent_index::Int, ::NoObservation)
    action = rand(actionspace(agent))
    promise(action)(agent_index, 0)# REVIEW: the second argument is not used
end

"""
Just close your eyes, everything will be fine
"""
struct RandomPolicy <: Policy end
const random_policy = RandomPolicy()

function plan(::RandomPolicy, agent::Agent, agent_index::Int, ::Observation)
    action = rand(actionspace(agent))
    promise(action)(agent_index, 0)# REVIEW: the second argument is not used
end

#################################################################################
# Agent implementations
#################################################################################

"Default, no observation"
observe(::Agent, index::Int64, ::GameState, ::KDTree) = no_obs

"Default, random policy"
policy(::Agent) = random_policy

@with_kw mutable struct Butterfly <: Agent
    position::SVector{2, Int64}
    energy::Float64 = 0.0
    policy::Policy = random_policy
end
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy

@with_kw mutable struct Player <: Agent
    position::SVector{2, Int64}
    policy::Policy = greedy_policy
end

position(agent::Player) = agent.position
policy(agent::Player) = agent.policy

function observe(agent::Player, agent_index::Int, state::GameState, kdtree::KDTree)::Observation
    # get all butterfly locations
    l_agents = length(state.agents)
    if l_agents == 1
        return NoObservation()
    end

    #TODO: ensure returns in order
    cs = collisions(kdtree, agent_index, 50.0) # TODO: get radius from state
    ci = cs[1]

    # returns the location of the nearest butterfly
    position = kdtree.data[ci]
    return PosObs(position)
end


function plan(::GreedyPolicy, agent::Player, agent_index::Int, obs::PosObs)
    # moves toward the nearest butterfly
    dx, dy = agent.position - obs.data
    direction = if abs(dx) < abs(dy)
        dx > 0 ? Left : Right
    else
        dy > 0 ? Up : Down
    end
    direction(agent_index)
end

#################################################################################
# helpers
#################################################################################
