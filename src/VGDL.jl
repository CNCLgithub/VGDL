module VGDL

using Accessors
using Parameters
using StaticArrays: SVector
using AccessorsExtra
using DataStructures 
using InteractiveUtils
using NearestNeighbors

export Game,
    interaction_set,
    Effect, ChangeEffect, DeathEffect, BirthEffect,
    Application, Single, Many,
    Rule, lens, transform, priority, promise,
    GameState,
    Element, StaticElement, Agent


#################################################################################
# Abstract game types
#################################################################################

# define the main interface
abstract type Game end

"""
    interaction_set(::Game)

Returns the interaction set for a game.

"""
function interaction_set end

abstract type Effect end
abstract type ChangeEffect <: Effect end
abstract type BirthEffect <: Effect end
abstract type DeathEffect <: Effect end
abstract type NoEffect <: Effect end
abstract type CompositeEffect <: Effect end

abstract type Application end
abstract type Single <: Application end
abstract type Many <: Application end

abstract type Rule{E<:Effect, A<:Application} end
"""
    lens(::Rule)

The lens that the rule applies to
"""
function lens end

"""
    transform(::Rule)

The transformation applied at the lens.
"""
function transform end

"""
    promise(::Type{Rule}, ref, other)::Rule

Promises to apply the rule to game state
"""
function promise end

"Priority of a rule (Int)"
function priority end


#################################################################################
# Element types
#################################################################################

abstract type Element end
abstract type StaticElement <: Element end
abstract type DynamicElement <: Element end
abstract type Agent <: DynamicElement end


#################################################################################
# Scene and state
#################################################################################

abstract type Scene end

mutable struct GameState
    scene::Scene
    agents::OrderedDict{Int64, Agent}
    reward::Float64
end
GameState(scene) = GameState(scene, OrderedDict{Int64, Agent}(), 0.0)

include("utils/utils.jl")
include("rules.jl")
include("elements.jl")
include("engine.jl")
include("scene.jl")
include("games/games.jl")
end
