export Zelda,
    Lock, lock,
    Key, key

"Find your key out the dungeon!"
struct Zelda <: Game end

function GridScene(::Type{Zelda}, bounds::Tuple{Int, Int})
    kdtree = KDTree(SVector{2, Int64}[], cityblock)
    GridScene(bounds, fill(ground, bounds),
              OrderedDict{Int64, Agent}(), kdtree)
end

#################################################################################
# Elements
#################################################################################

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


@with_kw mutable struct Monster{T} <: Agent
    position::SVector{2, Int64}
    policy::Policy = random_policy
    energy::T = 2.

    function Monster(pos, x::Float64) where T
        new{typeof(x)}(pos, random_policy, x)
    end
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
# Theory
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
        TerminationRule(
            st -> isempty(findall(x -> isa(x, Link), st.agents)), 
            GameOver()), # killed
        TerminationRule(
            st -> st.time >= st.max_time, 
            GameOver()), # Time out
        TerminationRule(
            st -> isempty(findall(st.scene.items .== lock)), 
            GameWon()), # victory!
    ]
end

#################################################################################
# Graphics
#################################################################################

const _zelda_colormap =
    Dict{Type{<:Element}, SVector{3, Float64}}(
        Ground => F3V(0.8, 0.8, 0.8),
        Obstacle => F3V(0., 0., 0.),
        Key => F3V(0., 1, 0.),
        Lock => F3V(1., 0.6, 0.),
        Monster => F3V(1, 0.6, 0.5), #TODO: parametrized monsters
        Link => F3V(0., 0., 0.9),
    )
default_colormap(::Type{Zelda}) = _zelda_colormap


#################################################################################
# Levels
#################################################################################

const _zelda_l0 = "wwwwwwwwwwwww
wA.......w..w
w..w........w
w...w...w.+ww
www+w2..wwwww
w.......w.g.w
w.2.........w
w+....2.....w
wwwwwwwwwwwww"

const _zelda_l1 = "wwwwwwwwwwwww
w.3.gw..+.1.w
w..www.....+w
w..........2w
w.......wwwww
w.......w+..w
w...w...w...w
wA..w.......w
wwwwwwwwwwwww"

const _zelda_l2 = "wwwwwwwwwwwww
w..1.ww....Aw
w...+w......w
w.w.....wwwww
w+w.....+..1w
w.w..wwwwwwww
w.......w...w
w...1w....wgw
wwwwwwwwwwwww"

const _zelda_l3 = "wwwwwwwwwwwww
w..........gw
w....w......w
w.w.w+.1....w
w+w.........w
ww1..1..1...w
w..w..w.w.w.w
w...A......+w
wwwwwwwwwwwww"

const _zelda_l4 = "wwwwwwwwwwwww
w+...w....g.w
w...www.....w
w.1..www....w
w..wwwwwww..w
w......w+...w
w....w...1..w
wA...w+...1.w
wwwwwwwwwwwww"

const _zelda_levels = [
    _zelda_l0,
    _zelda_l1,
    _zelda_l2,
    _zelda_l3,
    _zelda_l4
]

levels(::Type{Zelda}) = _zelda_levels

function load_level(::Type{T}, lvl::Int) where {T <: Zelda}
    load_level(T, levels(T)[lvl])
end

function load_level(::Type{T}, lvl::String) where {T <: Zelda} 
    lines = findall('\n', lvl)
    h = length(lines) + 1
    w = lines[1] - 1

    scene = GridScene(T, (h, w))
    links = Link[]
    monsters = Monster[]

    # matrix of characters
    lvl  = replace(lvl, r"\n" => "")
    lvl = reshape(collect(lvl), (w,h))
    lvl = permutedims(lvl, (2,1))

    cinds = CartesianIndices(scene.static)
    for (index, char) in enumerate(lvl)
        if char == 'g'
            scene.static[index] = lock
        elseif char == '+'
            scene.static[index] = key
        elseif char == 'w'
            scene.static[index] = obstacle
        elseif char == '.'
            scene.static[index] = ground
        elseif char == '2'
            pos = cinds[index]
            push!(monsters, Monster(;position=pos))
        elseif char == 'A'
            pos = cinds[index]
            push!(links, Link(;position=pos))
        else
            error("unsupported tile $(char)")
        end
    end

    # DynamicElements
    state = GameState(scene, 1000)
    for link in links
        l = new_index(state)
        insert(state, l, link)
    end
    for monster in monsters
        l = new_index(state)
        insert(state, l, monster)
    end

    state.scene.kdtree = KDTree(lookahead(state.scene.dynamic), cityblock)

    return state
end


#################################################################################
# helpers
#################################################################################