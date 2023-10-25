export  evolve,
    position,
    policy,
    observe,
    plan,
    actionspace,
    actionspace,
    Observation,
    NoObservation,
    no_obs,
    no_obs,
    Policy,
    RandomPolicy,
    random_policy,
    random_policy,
    GreedyPolicy,
    greedy_policy
    greedy_policy


#################################################################################
# Static Elements
#################################################################################

#################################################################################
# Dynamic Elements
#################################################################################

function evolve end

"""
    position(::DynamicElement)::SVector{2, Int64}

position of an element
"""
function position end

#################################################################################
# Agents
#################################################################################

function evolve(g::Game, el::Agent, state::GameState)
    obs = observe(g, el, state)
    action = plan(g, el, obs)
end

"""
    policy(::Agent)::Policy

policy of an agent
"""
function policy end

"""
    observe(::Game, a::Agent, st::GameState)::Observation

How an agent observes the game state
"""
function observe end

const _default_actionspace = [Up, Down, Left, Right, NoAction]
actionspace(::Agent) = _default_actionspace

#################################################################################
# Agent observations
#################################################################################

abstract type Observation end

struct DirectObs <: Observation
    state::GameState
end

struct NoObservation <: Observation end
const no_obs = NoObservation()

#################################################################################
# Agent policies
#################################################################################

abstract type Policy end

"Sugar to extract agent's policy and use it for planning"
function plan(g::Game, agent::Agent, agent_index::Int, obs::Observation)
    plan(g, policy(agent), agent, agent_index, obs)
end


"""
Why think when you can act.
"""
struct GreedyPolicy <: Policy end
const greedy_policy = GreedyPolicy()

function plan(::Game, ::GreedyPolicy, agent::Agent, agent_index::Int, ::NoObservation)
    @show action = rand(actionspace(agent))
    promise(action)(agent_index, 0)# REVIEW: the second argument is not used
end


"""
Just close your eyes, everything will be fine
"""
struct RandomPolicy <: Policy end
const random_policy = RandomPolicy()

function plan(::Game, ::RandomPolicy, agent::Agent, agent_index::Int, ::Observation)
    action = rand(actionspace(agent))
end


#################################################################################
# Agent implementations
#################################################################################

"Default, DirectObs"
observe(::Game, ::Agent, gs::GameState)  =
    DirectObs(gs)

"Default, random policy"
policy(::Agent) = random_policy


#################################################################################
# helpers
#################################################################################

Base.length(::Element) = 1
Base.iterate(e::Element) = (e, nothing)
Base.iterate(e::Element, ::Any) = nothing