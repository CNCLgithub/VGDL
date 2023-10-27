using Colors
using ImageCore
using StaticArrays
using ImageIO
using FileIO


test_one(Zelda);
test_graphics(Zelda);

function test_two()
    g = ButterflyGame()
    scene = random_scene(g, (10,10), 0., 4)
    state = GameState(scene)

    p = Player(; position = [2,2])
    state.agents[1] = p
    b = Butterfly(; position = [5,5])
    state.agents[2] = b
    b2 = Butterfly(; position = [5,7])
    state.agents[3] = b2

    imap = compile_interaction_set(g)
    tset = termination_set(g)

    state = update_step(state, imap, tset)
end


function collision_test(level::String)
    g = Zelda()
    state = generate_map(g, level)
    for i = 1:20
        run_game(g, state)
        render_image(g, state, "output/zelda")
    end
    save_video("zelda", "level0")
end

function save_video(dir::String, filename::String)
    framestack = readdir(dir)
    framestack = sort(filter(x -> endswith(x, ".png"), framestack), by = x -> parse(Int, split(x, ".")[1]))
    
    firstframevec = VideoIO.load(joinpath(dir, framestack[1]))
    firstframe = firstframevec[1]

    encoder_options = (crf=23, preset="medium")
    fps = 10
    
    open_video_out("$(filename).mp4", firstframe, framerate=fps, encoder_options=encoder_options) do writer
        for frame in framestack
            framevec = VideoIO.load(joinpath(dir, frame))
            f = framevec[1]
            write(writer, f)
        end
    end
end

function run_game_test()
    g = ButterflyGame()
    scene = random_scene(g, (10,10), 0., 4)
    state = GameState(scene)
    render_image(g, run_game(g, state), "output/new.jpg")
end

#test_one()
#test_two()
#collision_test(zelda0)
#run_game_test()