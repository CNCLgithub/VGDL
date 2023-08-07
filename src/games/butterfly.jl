export ButterflyGame,
    generate_map

"A game with butterflies =)"
struct ButterflyGame <: Game end

function interaction_set(::ButterflyGame)
    set = [
        (Player => Obstacle) => Stepback,
        (Butterfly => Obstacle) => Stepback,
        (Butterfly => Player) => KilledBy,
        (Butterfly => Player) => ChangeScore,
        # (Butterfly => Pinecone) => kill,
        # (Butterfly => Pinecone) => clone,
        # (Pinecone => Butterfly) => die,
    ]
end


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
    agents = state.agents
    for pos in p_pos
        typeof(pos)
        p = Player(pos)
        l = new_index(state)
        insert(state, l, p)
    end
    for pos in b_pos
        b = Butterfly(pos)
        l = new_index(state)
        insert(state, l, b)
    end

    return(state)
end
