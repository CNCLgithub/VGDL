using Random
using Colors, Images

export random_scene, 
        render_image

function random_scene(bounds::Tuple, density::Float64, npinecones::Int)
    # m = Matrix{StaticElement}(undef, bounds)
    m = Matrix{StaticElement}(fill(floor, bounds)) 

    # obstacles first
    @inbounds for i = eachindex(m)
        rand() < density && (m[i] = obstacle)
    end

    # pinecones can potentially overwrite obstacles
    pine_map = shuffle!(collect(eachindex(m)))
    @inbounds for i = 1:npinecones
        m[pine_map[i]] = pinecone
    end

    # borders
    col = bounds[1]
    row = bounds[2]
    len = length(m)
    last = len - col
    @inbounds for i = eachindex(m)
        remcol = i % col
        remcol == 0 && (m[i] = obstacle)
        remcol == 1 && (m[i] = obstacle)
        1 <= i <= col && (m[i] = obstacle)
        last <= i <= len && (m[i] = obstacle)
    end
    return GridScene(bounds, m)
end

function spawn_butterfly()
end

"""
    color(::Element)::RGB

Color of an element.
"""
function color end

const gray_color = RGB{Float32}(0.8, 0.8, 0.8)
color(::Floor) = gray_color

const black_color = RGB{Float32}(0, 0, 0)
color(::Obstacle) = black_color

const green_color = RGB{Float32}(0, 1, 0)
color(::Pinecone) = green_color

const pink_color = colorant"rgb(244, 200, 197)"
color(::Butterfly) = pink_color


function render_image(scene::GridScene)
    bounds = scene.bounds
    items = scene.items
    img = fill(color(floor), bounds)
    
    # obstacles: black; pinecones: green
    img[findall(x -> x == obstacle, items)] .= color(obstacle)
    img[findall(x -> x == pinecone, items)] .= color(pinecone)
    
    # save & open image
    #img = imresize(img, ratio=25)
    output_path = "downloads/output_img.png"
    save(output_path, img)
    run(`open $output_path`)
end