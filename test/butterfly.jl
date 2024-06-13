using Colors
using ImageCore
using ImageInTerminal
using StaticArrays
using ImageIO
using FileIO

function test_one()
    st = load_level(ButterflyGame, 1)
    run_game(ButterflyGame, st)
    @time x = run_game(ButterflyGame, st)
    println("Game ran for $(x.time) steps")
    return nothing
end

test_one();

function test_graphics()
    state = load_level(ButterflyGame, 4)
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

    m = render(graphics, state)
    img = colorview(RGB, m)
    println("Initial state")
    display(img)
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
