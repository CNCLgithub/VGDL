export ButterflyGame,
    Obstacle,
    obstacle,
    Pinecone,
    pinecone,
    Ground,
    ground,
    Player,
    Butterfly

"A game with butterflies =)"
struct ButterflyGame <: Game end

function GridScene(::Type{ButterflyGame}, bounds::Tuple{Int, Int})
    kdtree = KDTree(SVector{2, Int64}[], cityblock)
    GridScene(bounds, fill(ground, bounds),
              OrderedDict{Int64, Agent}(), kdtree)
end

#################################################################################
# Elements
#################################################################################

struct Obstacle <: StaticElement end
const obstacle = Obstacle()

struct Pinecone <: StaticElement end
const pinecone = Pinecone()

struct Ground <: StaticElement end
const ground = Ground()

@with_kw mutable struct Butterfly <: Agent
    position::SVector{2, Int64}
    energy::Float64 = 0.0
    policy::Policy = random_policy
end
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy

@with_kw mutable struct Player <: Agent
    position::SVector{2, Int64}
    policy::Policy = greedy_policy
end

position(agent::Player) = agent.position
policy(agent::Player) = agent.policy

function plan(agent::Player, obs::DirectObs, ::GreedyPolicy)

    state = obs.state
    scene = state.scene
    # get closest butterfly
    l_agents = length(scene.dynamic)

    # if there are no butterflies, don't move
    action = NoAction
    if l_agents >= 2
        # get nearest two agents
        # the closest should be the agent itself
        idxs, _= knn(scene.kdtree, agent.position, 2, true)

        # see if the nearest agent is a butterfly
        target = scene.dynamic[scene.dynamic.keys[idxs[2]]]

        if typeof(target) <: Butterfly
            pos = scene.kdtree.data[idxs[2]]
            dy, dx = agent.position - pos
            action = if abs(dx) > abs(dy)
                dx > 0 ? Left : Right
            else
                dy > 0 ? Up : Down
            end
        end
    end
    return action
end

#################################################################################
# Theory
#################################################################################

function interaction_set(::Type{ButterflyGame})
    set = [
        (Player => Obstacle) => Stepback,
        (Butterfly => Obstacle) => Stepback,
        (Butterfly => Player) => KilledBy,
        (Butterfly => Player) => ChangeScore,
        (Butterfly => Pinecone) => Retile{Ground},
        (Butterfly => Pinecone) => Clone,
    ]
end

function termination_set(::Type{ButterflyGame})
    set = [
        TerminationRule(
            st -> count(==(pinecone), st.scene.static) == 0,
            GameOver()), # no pinecones
        TerminationRule(
            st -> st.time >= st.max_time,
            GameOver()), # Time out
        TerminationRule(
            st -> count(x -> isa(x, Butterfly), st.scene.dynamic) == 0,
            GameWon()) # victory!
    ]
end

#################################################################################
# Graphics
#################################################################################

const _butterflygame_colormap =
    Dict{Type{<:Element}, SVector{3, Float64}}(
        Ground => F3V(0.8, 0.8, 0.8),
        Obstacle => F3V(0., 0., 0.),
        Pinecone => F3V(0., 0.8, 0.0),
        Butterfly => F3V(0.9, 0.7, 0.2),
        Player => F3V(0., 0., 0.9),
    )
default_colormap(::Type{ButterflyGame}) = _butterflygame_colormap

#################################################################################
# Levels
#################################################################################

const _bg_l1 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const _bg_l2 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
w..w0w........0........w0w.w
w..........................w
w...1...w...1.....www.....1w
w.....1.w....1.1...1.......w
w0.......w................0w
w.........1...wwww...1.....w
w....1........w.1......1...w
w.........A................w
w..w0w........0........w0w.w
wwwwwwwwwwwwwwwwwwwwwwwwwwww"

const _bg_l3 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
w..............1.........0.w
w..0000........1..........0w
w...00......1..1..www......w
w..w......1................w
w00w...1wwwwww1ww......A...w
w..w......1................w
w...00......1..1..www......w
w..0000........1..........0w
w..............1.........0.w
wwwwwwwwwwwwwwwwwwwwwwwwwwww"

const _bg_l4 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
w00w.......................w
w00w.................1.....w
w00w......1................w
w.ww..........1....1...1...w
w......0..............1....w
w...........1..........1...w
w............0....1.1......w
w......................wwwww
w.....A..................00w
wwwwwwwwwwwwwwwwwwwwwwwwwwww"

const _bg_l5 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
w.........A................w
w..........................w
w..........................w
w..........................w
wwwwwwwwwwwww.wwwwwwwwwwwwww
w.......................w..w
w.....1...1.1..1.......w...w
w.....................w..0.w
w....1..1..1.........w.0...w
w...................w..0...w
wwwwwwwwwwwwwwwwwwwwwwwwwwww"

const _bg_levels = [
    _bg_l1,
    _bg_l2,
    _bg_l3,
    _bg_l4,
    _bg_l5,
]

levels(::Type{ButterflyGame}) = _bg_levels

function load_level(::Type{T}, lvl::Int) where {T <: ButterflyGame}
    load_level(T, levels(T)[lvl])
end

function load_level(::Type{T}, lvl::String) where {T<:ButterflyGame}
    lines = findall('\n', lvl)
    h = length(lines) + 1
    w = lines[1] - 1

    scene = GridScene(T, (h, w))
    players = Player[]
    bflies = Butterfly[]

    # matrix of characters
    lvl  = replace(lvl, r"\n" => "")
    lvl = reshape(collect(lvl), (w,h))
    lvl = permutedims(lvl, (2,1))

    cinds = CartesianIndices(scene.static)
    for (index, char) in enumerate(lvl)
        if char == 'w'
            scene.static[index] = obstacle
        elseif char == '.'
            scene.static[index] = ground
        elseif char == '0'
            scene.static[index] = pinecone
        elseif char == '1'
            pos = cinds[index]
            push!(bflies, Butterfly(;position=pos))
        elseif char == 'A'
            pos = cinds[index]
            push!(players, Player(;position=pos))
        else
            error("unsupported tile $(char)")
        end
    end

    # DynamicElements
    state = GameState(scene, 1000)
    for player = players
        l = new_index(state)
        insert(state, l, player)
    end
    for bfly = bflies
        l = new_index(state)
        insert(state, l, bfly)
    end

    state.scene.kdtree = KDTree(lookahead(state.scene.dynamic), cityblock)


    return state
end

#################################################################################
# helpers
#################################################################################
