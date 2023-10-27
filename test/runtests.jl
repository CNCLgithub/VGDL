using Colors
using ImageCore
using ImageInTerminal
using StaticArrays
using ImageIO
using FileIO

export test_one,
    test_graphics

function test_one(::Type{T}) where {T<:Game} # GENERIC
    st = load_level(T, 1)
    @time st = run_game(T, st)
    @show st.time
    return nothing
end

function test_graphics(::Type{T}) where {T<:Game} # GENERIC
    state = load_level(T, 1)
    imap = compile_interaction_set(T)
    tset = termination_set(T)
    graphics = PixelGraphics(default_colormap(T))
    path = "test/output"
    isdir(path) || mkpath(path)
    while !isfinished(state, tset)
        queue = action_step(state)
        state  = update_step(state, imap)
        m = render(graphics, state)
        img = colorview(RGB, m)
        # display(img)
        save("$(path)/$(state.time).png", repeat(img, inner = (10,10)))
    end
    return nothing
end

#include("butterfly.jl")
include("zelda.jl")