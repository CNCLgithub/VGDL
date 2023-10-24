using Random
using Colors, Images

export GridScene,
    random_scene,
    color,
    gray_color,
    black_color,
    green_color,
    pink_color,
    blue_color,
    orange_color,
    render_image

Base.length(::Element) = 1
Base.iterate(e::Element) = (e, nothing)
Base.iterate(e::Element, ::Any) = nothing

"""
    random_scene (::Game, ::Tuple)::Gridscene

Generate a random scene
"""
function random_scene end

"""
    color(::Element)::RGB

Color of an element.
"""
function color end

const gray_color = RGB{Float32}(0.8, 0.8, 0.8)
const black_color = RGB{Float32}(0, 0, 0)
const green_color = RGB{Float32}(0, 1, 0)
const pink_color = colorant"rgb(244, 200, 197)"
const blue_color = RGB{Float32}(0, 0, 1)
const orange_color = RGB{Float32}(1, 0.6, 0)

"""
    render_image(::Game, ::GameState, ::String)

Save image of current game state.
"""
function render_image end