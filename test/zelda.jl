using Test
using StaticArrays
using VGDL
using VideoIO


const zelda0 = "wwwwwwwwwwwww
wA.......w..w
w..w........w
w...w...w.+ww
www+w2..wwwww
w.......w.g.w
w.2.........w
w+....2.....w
wwwwwwwwwwwww"

const zelda1 = "wwwwwwwwwwwww
w.3.gw..+.1.w
w..www.....+w
w..........2w
w.......wwwww
w.......w+..w
w...w...w...w
wA..w.......w
wwwwwwwwwwwww"

const zelda2 = "wwwwwwwwwwwww
w..1.ww....Aw
w...+w......w
w.w.....wwwww
w+w.....+..1w
w.w..wwwwwwww
w.......w...w
w...1w....wgw
wwwwwwwwwwwww"

const zelda3 = "wwwwwwwwwwwww
w..........gw
w....w......w
w.w.w+.1....w
w+w.........w
ww1..1..1...w
w..w..w.w.w.w
w...A......+w
wwwwwwwwwwwww"

const zelda4 = "wwwwwwwwwwwww
w+...w....g.w
w...www.....w
w.1..www....w
w..wwwwwww..w
w......w+...w
w....w...1..w
wA...w+...1.w
wwwwwwwwwwwww"


function test_one()
    g = Zelda()
    scene = random_scene(g, (30, 30), 0.25, 40)
    state = GameState(scene)
    render_image(g, state)
end

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
collision_test(zelda0)
#run_game_test()