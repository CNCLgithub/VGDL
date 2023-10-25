export Zelda,
    Lock, lock,
    Key, key

"Find your key out the dungeon!"
struct Zelda <: Game end

struct Lock <: StaticElement end
const lock = Lock()

struct Key <: StaticElement end
const key = Key()

struct Sword <: StaticElement end
const sword = Sword()

#REVIEW: subtype of player
@with_kw mutable struct Link <: Agent
    position::SVector{2, Int64}
    direction::SVector{2, Int64} = [0,1]
    policy::Policy = greedy_policy
end
position(agent::Link) = agent.position
policy(agent::Link) = agent.policy


abstract type Monster <: Agent end
@with_kw mutable struct MonsterSlow <: Monster
    position::SVector{2, Int64}
    policy::Policy = random_policy
    energy::Float64 = 1.0
end
@with_kw mutable struct MonsterNormal <: Monster
    position::SVector{2, Int64}
    policy::Policy = random_policy
    energy::Float64 = 2.0
end
@with_kw mutable struct MonsterQuick <: Monster
    position::SVector{2, Int64}
    policy::Policy = random_policy
    energy::Float64 = 3.0
end
position(agent::Monster) = agent.position
policy(agent::Monster) = agent.policy

#################################################################################
# Game-specific agent implementation
#################################################################################

function observe(::Zelda, agent::Link, agent_index::Int, state::GameState, kdtree::KDTree)::Observation
    # get all butterfly locations
    l_agents = length(state.agents)
    if l_agents == 1
        return NoObservation()
    end
    # get nearest two agents
    bounds = state.scene.bounds
    a, b = bounds
    r = max(a, b)
    idxs, dist = knn(kdtree, agent.position, 2, true)
    # returns the location of the nearest butterfly
    position = kdtree.data[idxs[2]]
    return DirectObs(position)
end


function plan(::Zelda, ::GreedyPolicy, agent::Link, agent_index::Int, obs::DirectObs)
    # moves toward the nearest butterfly
    dy, dx = agent.position - obs.data
    direction = if abs(dx) > abs(dy)
        dx > 0 ? Left : Right
    else
        dy > 0 ? Up : Down
    end
    direction(agent_index)
end

#################################################################################
# Game definition
#################################################################################

function interaction_set(::Zelda)
    set = [
        (Link => Obstacle) => Stepback,
        (Monster => Monster) => Stepback,
        (Monster => Obstacle) => Stepback,
        (Sword => Element) => Die,
        #(Monster => Sword) => KilledBy,
        #(Link => Monster) => KilledBy,
        (Key => Link) => Retile{Ground}, 
        (Link => Key) => Add{Key},
        (Lock => Link) => Retile{Ground}, ##If Link has key
    ]
end

function termination_set(::Zelda)
    set = [
        TerminationRule(st -> isempty(findall(x -> isa(x, Link), st.agents)), GameOver()),
        TerminationRule(st -> isempty(findall(st.scene.items .== lock)), GameOver()), # no pinecones
        TerminationRule(st -> st.time > time, GameOver()) # Time out
    ]
end

#################################################################################
# Scene initialization
#################################################################################

"""
    generate_map(game, setup)

Initialize state based on symbol map.
"""
function generate_map(::Zelda, setup::String)::GameState
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
    m_pos = Vector{V}()

    # StaticElements
    setup = replace(setup, r"\n" => "")
    setup = reshape(collect(setup), (w,h))
    setup = permutedims(setup, (2,1))

    for (index, char) in enumerate(setup)
        if char == 'g'
            m[index] = lock
        elseif char == '+'
            m[index] = key
        elseif char == 'w'
            m[index] = obstacle
        elseif char == '.'
            m[index] = ground
        else
            ci = CartesianIndices(m)[index]
            if char == '2'
                push!(m_pos, ci)
            else
                push!(p_pos, ci)
            end
        end
    end

    # DynamicElements
    state = GameState(scene)
    for pos in p_pos
        p = Link(; position = pos)
        l = new_index(state)
        insert(state, l, p)
    end
    for pos in m_pos
        b = MonsterNormal(; position = pos)
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

#################################################################################
# Scene rendering
#################################################################################

color(::Ground) = gray_color
color(::Obstacle) = black_color
color(::Key) = green_color
color(::Lock) = orange_color
color(::Monster) = pink_color
color(::Player) = blue_color

function render_image(::Zelda, state::GameState, path::String;
    img_res::Tuple{Int64, Int64} = (100,100))

    # StaticElements
    scene = state.scene
    bounds = scene.bounds
    items = scene.items
    img = fill(color(ground), bounds)
    img[findall(x -> x == obstacle, items)] .= color(obstacle)
    img[findall(x -> x == key, items)] .= color(key)
    img[findall(x -> x == lock, items)] .= color(lock)

    # DynamicElements
    agents = state.agents
    for i in eachindex(agents)
    agent = agents[i]
    ci = CartesianIndex(agent.position)
    img[ci] = color(agent)
    end

    # save & open image
    img = repeat(img, inner = img_res)
    save(path, img)

end