using Test
using StaticArrays
using ButterflyGame

function Base.convert(ci::CartesianIndex, ::SVector{2, Int64})
    x = SVector{2, Int64}(ci[1], ci[2])
    return x
end

function initial()
    scene = random_scene((30, 30), 0.25, 40)
    state = GameState(scene)
    render_image(state)
end

function collision_test()
    g = BG()
    scene = random_scene((10, 10), 0.25, 0)
    state = GameState(scene)
    agents = state.agents
    p = Player([2,2])
    push!(agents, p)
    b = Butterfly([2,3])
    push!(agents, b)

    render_image(state)
    imap = compile_interaction_set(g)
    update_step(state, imap)
end

function level(setup::String)
    scene = GridScene((11, 28))
    m = scene.items
    V = SVector{2, Int64}
    p_pos = Vector{V}()
    b_pos = Vector{V}()
    
    # StaticElements
    setup = replace(setup, r"\n" => "")
    setup = reshape(collect(setup), (28,11))
    setup = permutedims(setup, (2,1))

    for (index, char) in enumerate(setup)
        if char == 'w'
            m[index] = obstacle
        elseif char == '.'
            m[index] = ground
        elseif char == '0'
            m[index] = pinecone
        else
            ci = CartesianIndices(m)[index]
            if char == '1'
                push!(b_pos, ci)
            else
                push!(p_pos, ci)
            end
        end
    end

    #= o = CartesianIndex.([(2,4), (2,6), (2,24), (2,26), (4,9), (5,9), (6,10), (4,21), (4,20), (4,19), (7,15), (7,16), (7,17), (7,18), (8,15), (10,4), (10,6), (10,24), (10,26)])
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
    m[a] = player =#

    # DynamicElements
    state = GameState(scene)
    agents = state.agents
    for pos in p_pos
        typeof(pos)
        p = Player(pos)
        push!(agents, p)
    end
    for pos in b_pos
        b = Butterfly(pos)
        push!(agents, b)
    end

    render_image(state)
end


#initial()
#collision_test()

const zero = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
w..1.....1..w...0.0.0.0w000w
w.1....................w000w
w...1...0.....A........w000w
wwwwwwwwwwww.............00w
w0..................w.....ww
w0......1..................w
w0.........wwwww....1.....0w
wwwww................w.....w
w........0.0.0.0.0...w0...0w
wwwwwwwwwwwwwwwwwwwwwwwwwwww"
level(zero)