export  evolve,
    position,
    policy,
    observe,
    plan,
    actionspace,
    Observation,
    NoObservation,
    no_obs,
    Policy,
    RandomPolicy,
    random_policy,
    GreedyPolicy,
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

function evolve(el::Agent, state::GameState)
    obs = observe(el, state)
    action = plan(el, obs)
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
function plan(agent::Agent, obs::Observation)
        plan(agent, obs, policy(agent))
end


"""
Why think when you can act.
"""
struct GreedyPolicy <: Policy end
const greedy_policy = GreedyPolicy()


"""
Just close your eyes, everything will be fine
"""
struct RandomPolicy <: Policy end
const random_policy = RandomPolicy()

function plan(agent::Agent, ::Observation, ::RandomPolicy)
    action = rand(actionspace(agent))
end

#################################################################################
# Agent implementations
#################################################################################

"Default, DirectObs"
observe(::Agent, gs::GameState)  =
    DirectObs(gs)

"Default, random policy"
policy(::Agent) = random_policy


#################################################################################
# helpers
#################################################################################

Base.length(::Element) = 1
Base.iterate(e::Element) = (e, nothing)
Base.iterate(e::Element, ::Any) = nothing