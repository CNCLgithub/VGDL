using Random
using Colors, Images

function random_scene(bounds::Tuple, density::Float64, npinecones::Int)
    # m = Matrix{StaticElement}(undef, bounds)
    m = fill(floor, bounds)
    # obstacles first
    @inbounds for i = eachindex(m)
        rand() < density && (m[i] = obstacle)
    end
    # pinecones can potentially overwrite obstacles
    pine_map = shuffle!(Vector(keys(m)))
    for i = 1:npinecones
        m[pine_map[i]] = pinecone
    end
    return m
end

function render_image(state::GameState)
    bounds = state.scene.bounds
    map = state.scene.items

    # floor: white
    img = fill(RGB{Float32}(0, 0, 0), bounds)
    
    # obstacles: black; pinecones: green
    img[map .== obstacle] .= RGB{Float32}(0, 0, 0)
    img[map .== pinecone] .= RGB{Float32}(0, 1, 0)

    # save & open image
    output_path = "downloads/output_img.png"
    save(output_path, img)
    run(`open $output_path`)
end