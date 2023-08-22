export ButterflyGame,
    generate_map, 
    spawn_agents

"A game with butterflies =)"
struct ButterflyGame <: Game end

function interaction_set(::ButterflyGame)
    set = [
        (Player => Obstacle) => Stepback,
        (Butterfly => Obstacle) => Stepback,
        (Butterfly => Player) => KilledBy,
        (Butterfly => Player) => ChangeScore,
        (Butterfly => Pinecone) => Retile{Ground},
        (Butterfly => Pinecone) => Clone,
    ]
end

function termination_set(::ButterflyGame)
    set = [TimeOut, NoPinecone, NoButterfly]
end

"""
    generate_map(game, setup)

Initialize state based on symbol map.
"""
function generate_map(::ButterflyGame, setup::String)::GameState
    h = count(==('\n'), setup) + 1
    w = 0
    for char in setup
        if char == '\n'
            break
        end
        w += 1
    end
    scene = GridScene((h, w))
    m = scene.items
    V = SVector{2, Int64}
    p_pos = Vector{V}()
    b_pos = Vector{V}()

    # StaticElements
    setup = replace(setup, r"\n" => "")
    setup = reshape(collect(setup), (w,h))
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

    # DynamicElements
    state = GameState(scene)
    for pos in p_pos
        p = Player(; position = pos)
        l = new_index(state)
        insert(state, l, p)
    end
    for pos in b_pos
        b = Butterfly(; position = pos)
        l = new_index(state)
        insert(state, l, b)
    end

    return(state)
end


"""
    spawn_agents(state, n_players)

Adds agents to state at random locations.
"""
function spawn_agents(state::GameState, n_players::Int64 = 1)
    # butterfly first (Poisson distribution)
    items = state.scene.items
    size = length(items)
    density = ceil(size/20)
    n_b = poisson(density)
    pot_pos = []
    @inbounds  for i in eachindex(items)
        if m[i] == ground
            push!(pot_pos, i)
        end
    end
    shuffle!(pot_pos)
    @inbounds for i = 1:n_b
        pos = pot_pos[i]
        b = Butterfly(pos)
        l = new_index(state)
        insert(state, l, b)
    end

    # player second
    for i = 1:n_players
        pos = pot_pos[n_b + i]
        p = Player(pos)
        l = new_index(state)
        insert(state, l, p)
    end
end