using Random
using Colors, Images
using Interpolations

export GridScene,
    random_scene,
    generate_map,
    render_image

mutable struct GridScene <: Scene
    bounds::Tuple{Int, Int}
    items::Matrix{StaticElement}
end
GridScene(bounds) = GridScene(bounds, fill(ground, bounds))

Base.length(::Element) = 1
Base.iterate(e::Element) = (e, nothing)
Base.iterate(e::Element, ::Any) = nothing

function random_scene(bounds::Tuple, density::Float64, npinecones::Int)::GridScene
    m = Matrix{StaticElement}(fill(ground, bounds)) 

    # obstacles first
    @inbounds for i = eachindex(m)
        rand() < density && (m[i] = obstacle)
    end
    # pinecones second
    pine_map = []
    @inbounds for i = eachindex(m)
        if m[i] == ground
            push!(pine_map, i)
        end
    end
    shuffle!(pine_map)
    @inbounds for i = 1:npinecones
        m[pine_map[i]] = pinecone
    end
    # borders last
    m[1:end, 1] .= obstacle
    m[1:end, end] .= obstacle
    m[1, 1:end] .= obstacle
    m[end, 1:end] .= obstacle

    scene = GridScene(bounds, m)

    # agents
    # scene = spawn_agents(GridScene(bounds, m))
    return scene
end



#= function spawn_agents(scene::GridScene)
    m = scene.items

    # butterflies: Poisson distribution
    s = length(m)
    density = ceil(s/25)
    n = poisson(density)
    b_map = []
    @inbounds for i = eachindex(m)
        if m[i] == ground
            push!(b_map, i)
        end
    end
    shuffle!(b_map)
    @inbounds for i = 1:n
        m[b_map[i]] = butterfly
    end

    # player
    i = rand(m)
    while m[i] != ground
        i = rand(m)
    end
    m[i] = player
end =#


"""
    color(::Element)::RGB

Color of an element.
"""
function color end

const gray_color = RGB{Float32}(0.8, 0.8, 0.8)
color(::Ground) = gray_color

const black_color = RGB{Float32}(0, 0, 0)
color(::Obstacle) = black_color

const green_color = RGB{Float32}(0, 1, 0)
color(::Pinecone) = green_color

const pink_color = colorant"rgb(244, 200, 197)"
color(::Butterfly) = pink_color

const blue_color = RGB{Float32}(0, 0, 1)
color(::Player) = blue_color


function render_image(state::GameState, path::String)
    # StaticElements
    scene = state.scene
    bounds = scene.bounds
    items = scene.items
    img = fill(color(ground), bounds)
    img[findall(x -> x == obstacle, items)] .= color(obstacle)
    img[findall(x -> x == pinecone, items)] .= color(pinecone)
    
    # DynamicElements
    agents = state.agents
    for i in eachindex(agents)
        agent = agents[i]
        ci = CartesianIndex(agent.position)
        img[ci] = color(agent)
    end

    # save & open image
    img = imresize(img, (100, 100))
    save(path, img)
end
