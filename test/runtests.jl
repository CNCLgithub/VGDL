using Test
using ButterflyGame


function initial()
    scene = GridScene((30, 30))
    scene = random_scene((30, 30), 0.25, 40)
    render_image(scene)
end

function collision_test()
    g = BG()
    scene = random_scene((10, 10), 0.25, 0)
    render_image(scene)
    state = GameState(scene)
    agents = state.agents
    p = Player([2,2])
    push!(agents, p)
    b = Butterfly([2,3])
    push!(agents, b)
    imap = compile_interaction_set(g)
    @show step(state, imap)
end

function level_zero()
    scene = GridScene((11, 28))
    m = scene.items
    # render scene (TODO: use symbols & switch to SVector)
    o = CartesianIndex.([(2,4), (2,6), (2,24), (2,26), (4,9), (5,9), (6,10), (4,21), (4,20), (4,19), (7,15), (7,16), (7,17), (7,18), (8,15), (10,4), (10,6), (10,24), (10,26)])
    p = CartesianIndex.([(6,2), (2,5), (2,15), (10,5), (10,15), (2,25), (6,27), (10,25)])
    b = CartesianIndex.([(4,5), (8,6), (5,7), (7,11), (8,17), (7,22), (8,24), (4,13), (5,14), (5,16), (5,20), (4,27)])
    a = CartesianIndex(9,11)
    @inbounds for i = eachindex(o)
        m[o[i]] = obstacle
    end
    @inbounds for i = eachindex(p)
        m[p[i]] = pinecone
    end
    @inbounds for i = eachindex(b)
        m[b[i]] = butterfly
    end
    m[a] = player
    # borders
    col = scene.bounds[1]
    row = scene.bounds[2]
    len = length(m)
    last = len - col
    @inbounds for i = eachindex(m)
        remcol = i % col
        remcol == 0 && (m[i] = obstacle)
        remcol == 1 && (m[i] = obstacle)
        1 <= i <= col && (m[i] = obstacle)
        last <= i <= len && (m[i] = obstacle)
    end
    
    render_image(scene)
end


#initial()
collision_test()
#level_zero()