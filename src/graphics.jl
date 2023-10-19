export PixelGraphics

const F3V = SVector{3, Float64}

struct PixelGraphics <: Graphics
    color_map::Dict{Type{<:VGDL.Element}, F3V}
end

function PixelGraphics(::Type{G}) where {G<:Game}
    PixelGraphics(default_colormap(G))
end

"""
    default_colormap(g::VGDL.Game)

Default colormap for a game.
"""
function default_colormap end

function render(g::PixelGraphics, gs::GameState)
    render(g, gs.scene)
end
function render(g::PixelGraphics, scene::GridScene)
    nx, ny = scene.bounds
    # m = Array{Float64}(undef, (3, nx, ny))
    m = zeros((3, nx, ny))

    cis = CartesianIndices(scene.static)
    for i = cis
        x,y = i.I # REVIEW: assumes `i` is `CartesianIndex{2}`
        mv = @view m[:, x, y]
        T = typeof(scene.static[i])
        mv[:] = g.color_map[T]
    end
    for (_, el) = scene.dynamic
        x, y = el.position
        m[:, x, y] = g.color_map[typeof(el)]
    end
    return m
end
