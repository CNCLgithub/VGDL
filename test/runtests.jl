using Test
using StaticArrays
using ButterflyGame


const level_zero = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const easy = "wwwww
w...w
w...w
w...w
wwwww"

Base.convert(ci::CartesianIndex{2}, ::SVector{2, Int64}) = SVector{2, Int64}(ci[1], ci[2])

function initial()
    scene = random_scene((30, 30), 0.25, 40)
    state = GameState(scene)
    render_image(state)
end

function collision_test(level::String)
    g = BG()
    state = generate_map(g, level)
    agents = state.agents

    p = Player([2,2])
    push!(agents, p)
    #=b = Butterfly([3,3])
    push!(agents, b)=#

    #render_image(state)
    imap = compile_interaction_set(g)
    state = update_step(state, imap)
    render_image(state)
end

#initial()
collision_test(easy)
#collision_test(level_zero)