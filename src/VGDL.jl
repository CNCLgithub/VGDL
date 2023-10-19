module VGDL

using Accessors
using Parameters
using StaticArrays: SVector
using AccessorsExtra
using DataStructures 
# using InteractiveUtils
using NearestNeighbors
using DocStringExtensions

export Game,
    GameState,
    Scene,
    GridScene,
    load_level,
    levels,
    interaction_set,
    Effect, ChangeEffect, DeathEffect, BirthEffect,
    termination_set,
    TerminationEffect,
    Application, Single, Many,
    Rule, lens, transform, priority, promise,
    Element, StaticElement, Agent,
    Graphics,
    render


#################################################################################
# Abstract game
#################################################################################

"A VGDL game"
abstract type Game end

"""
    interaction_set(::Game)

Returns the interaction set for a game.
"""
function interaction_set end


"""
    termination_set(::Game)

Returns the termination set for a game.
"""
function terminination_set end

function levels end
function load_level end

#################################################################################
# Abstract interactions
#################################################################################

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


"""
    interaction_set(::Game)

Returns the interaction set for a game.

"""
function termination_set end

"Termination set"
abstract type TerminationEffect end

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

mutable struct GridScene <: Scene
    bounds::Tuple{Int, Int}
    static::Matrix{StaticElement}
    dynamic::OrderedDict{Int64, DynamicElement}
    kdtree::KDTree
end

mutable struct GameState
    scene::Scene
    reward::Float64
    time::Int64
    max_time::Int64
end

# REVIEW: is this used?
GameState(scene::Scene, max_time::Int64) =
    GameState(scene, 0.0, 0, max_time)

abstract type Graphics end

"""
    render(::Graphics, ::GameState)
"""
function render end

include("utils/utils.jl")
include("rules.jl")
include("elements.jl")
include("engine.jl")
include("graphics.jl")
include("games/games.jl")
end
