function random_scene(bounds::Tuple, density::Float64, npinecones::Int)
    #m = Matrix{StaticElement}(undef, bounds)
    m = fill(floor, bounds)
    # obstacles first
    @inbounds for i = eachindex(m)
        if rand() < density
            m[i] = obstacle
        end
    end
    # pinecones
    
end

function render_image(state::GameState)
    # 
end