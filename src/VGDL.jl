"""
An (spiritual) implementation of [VGDL2](https://github.com/rubenvereecken/py-vgdl).

Exports:

$(EXPORTS)

Imports:

$(IMPORTS)

---

$(README)

"""
module VGDL

using Accessors
using Parameters
using StaticArrays: SVector
using AccessorsExtra
using DataStructures 
using NearestNeighbors
using DocStringExtensions
using Distances: cityblock

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

---

$(METHODLIST)
"""
function interaction_set end


"""
    termination_set(::Game)

Returns the termination set for a game.

---

$(METHODLIST)
"""
function terminination_set end


"""
    levels(::Game)

A collection of pre-packaged levels.

---

$(METHODLIST)
"""
function levels end


"""
    load_level(::Game, level::Int)

Load a specified level.

---

$(METHODLIST)
"""
function load_level end

#################################################################################
# Abstract interactions
#################################################################################

""" An effect that changes the world """
abstract type Effect end

""" An effect that changes a tile or object """
abstract type ChangeEffect <: Effect end

""" An effect that creates a new object """
abstract type BirthEffect <: Effect end

""" An effect that kills an object """
abstract type DeathEffect <: Effect end


""" A strange effect =) """
abstract type NoEffect <: Effect end

"""

A composition of effects.

Each effect is applied conditional to its parents.
"""
abstract type CompositeEffect <: Effect end


""" How an `Effect` is applied to the world """
abstract type Application end

""" Can only occur once """
abstract type Single <: Application end


""" Can occur many times """
abstract type Many <: Application end


""" A game rule """
abstract type Rule{E<:Effect, A<:Application} end

"""
    lens(::Rule)

The lens that the rule applies to

---

$(METHODLIST)
"""
function lens end

"""
    transform(::Rule)

The transformation applied at the lens.

---

$(METHODLIST)
"""
function transform end

"""
    promise(::Type{Rule}, ref, other)::Rule

Promises to apply the rule to game state

---

$(METHODLIST)
"""
function promise end

"""
    priority(::Rule)::Int

The priority of a rule.

---

$(METHODLIST)
"""
function priority end


"Termination set"
abstract type TerminationEffect end

#################################################################################
# Element types
#################################################################################

""" Something in the world """
abstract type Element end

""" Something that doesn't change (but could go away) """
abstract type StaticElement <: Element end

""" Something moves aorund """
abstract type DynamicElement <: Element end

""" Something like you and me """
abstract type Agent <: DynamicElement end


#################################################################################
# Scene
#################################################################################


""" A collection of elements """
abstract type Scene end


"""
$(TYPEDEF)

A rectangular scene with discrete locations.

---

$(TYPEDFIELDS)

"""
mutable struct GridScene <: Scene
    "Dimensions of the scene"
    bounds::Tuple{Int, Int}
    "All static elements"
    static::Matrix{StaticElement}
    "All dynamic elements"
    dynamic::OrderedDict{Int64, DynamicElement}
    "Spatial map over dynamic elements"
    kdtree::KDTree
end

#################################################################################
# State
#################################################################################

"""
$(TYPEDEF)

A live game.

> See [`GameState`](@ref)

---

$(TYPEDFIELDS)

"""
mutable struct GameState
    "State of the world"
    scene::Scene
    "How many points the player has"
    reward::Float64
    "World age"
    time::Int64
    "Maximum world age"
    max_time::Int64
end

# REVIEW: is this used?
"""
$(TYPEDSIGNATURES)

Return a fresh game state.
"""
GameState(scene::Scene, max_time::Int64) =
    GameState(scene, 0.0, 0, max_time)



#################################################################################
# Graphics
#################################################################################

"""" A graphics protocol """
abstract type Graphics end

"""
    render(::Graphics, ::GameState)

Render the game state.

---

$(METHODLIST)
"""
function render end

include("utils/utils.jl")
include("rules.jl")
include("elements.jl")
include("engine.jl")
include("graphics.jl")
include("games/games.jl")
end
