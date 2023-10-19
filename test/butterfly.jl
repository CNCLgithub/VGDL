using Colors
using ImageCore
using ImageInTerminal
using StaticArrays
using ImageIO
using FileIO

function test_one()
    st = load_level(ButterflyGame, 1)
    @time st = run_game(ButterflyGame, st)
    @show st.time
    return nothing
end

test_one();

function test_graphics()
    state = load_level(ButterflyGame, 2)
    imap = compile_interaction_set(ButterflyGame)
    tset = termination_set(ButterflyGame)
    graphics = PixelGraphics(Dict(
        Ground => SVector{3, Float64}(0.0, 0.0, 0.0),
        Obstacle => SVector{3, Float64}(1., 1., 1.),
        Pinecone => SVector{3, Float64}(0., 0.8, 0.0),
        Butterfly => SVector{3, Float64}(0.9, 0.4, 0.1),
        Player => SVector{3, Float64}(0., 0., 0.9),
    ))
    path = "test/output"
    isdir(path) || mkpath(path)
    while !isfinished(state, tset)
        queue = action_step(state)
        state  = update_step(state, imap)
        m = render(graphics, state)
        img = colorview(RGB, m)
        # display(img)
        save("$(path)/$(state.time).png", repeat(img, inner = (10,10)))

    end

    return nothing
end

test_graphics();

# function test_two()
#     g = ButterflyGame()
#     scene = random_scene((10,10), 0., 4)
#     state = GameState(scene)

#     p = Player(; position = [2,2])
#     state.agents[1] = p
#     b = Butterfly(; position = [5,5])
#     state.agents[2] = b
#     b2 = Butterfly(; position = [5,7])
#     state.agents[3] = b2

#     imap = compile_interaction_set(g)
#     tset = termination_set(g)

#     state = update_step(state, imap, tset)
# end


# function collision_test(level::String)
#     for i in 1:5
#         g = ButterflyGame()
#         state = generate_map(g, level)
#         imap = compile_interaction_set(g)
#         tset = termination_set(g)
#         state = update_step(state, imap, tset)
#         save_video("level4_$(i)")
#     end
# end
