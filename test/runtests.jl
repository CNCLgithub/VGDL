using Test
using StaticArrays
using VGDL
using VideoIO


const l0 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const l1 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const l2 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const l3 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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

const l4 = "wwwwwwwwwwwwwwwwwwwwwwwwwwww
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


function test_one()
    scene = random_scene((30, 30), 0.25, 40)
    state = GameState(scene)
    render_image(state)
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
    tset = termination_set(g)

    state = update_step(state, imap, tset)
end


function collision_test(level::String)
    for i in 1:5
        g = ButterflyGame()
        state = generate_map(g, level)
        imap = compile_interaction_set(g)
        tset = termination_set(g)
        state = update_step(state, imap, tset)
        save_video("level4_$(i)")
    end
end

function save_video(filename::String)
    dir = "output"
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
    scene = random_scene((10,10), 0., 4)
    run_game(g, scene)
end

#test_one()
#test_two()
#collision_test(l4)
run_game_test()