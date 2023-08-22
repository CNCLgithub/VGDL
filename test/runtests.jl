using Test
using StaticArrays
using VGDL


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

function initial()
    scene = random_scene((30, 30), 0.25, 40)
    state = GameState(scene)
    render_image(state)
end

function collision_test(level::String)
    g = ButterflyGame()
    state = generate_map(g, level)
    agents = state.agents
    imap = compile_interaction_set(g)
    tset = termination_set(g)
    state = update_step(state, imap, tset)
end

function test_two()
    g = ButterflyGame()
    scene = random_scene((10,10), 0., 4)
    state = GameState(scene)

    p = Player(; position = [2,2])
    state.agents[1] = p
    b = Butterfly(; position = [5,5])
    state.agents[2] = b
    b2 = Butterfly(; position = [5,7])
    state.agents[3] = b2

    imap = compile_interaction_set(g)

    for i in 1:10
       # println("\nROUND$(i)")
        state = update_step(state, imap)
        #img = render_image(state, "output/$(i).png")
    end
end

#initial()
#collision_test(easy)
collision_test(level_zero)
#test_two()

