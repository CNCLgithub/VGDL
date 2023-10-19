# using Test
# using StaticArrays
using VGDL
# using VideoIO

include("butterfly.jl")



# function test_one()
#     scene = random_scene((30, 30), 0.25, 40)
#     state = GameState(scene)
#     render_image(state)
# end

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

# function save_video(filename::String)
#     dir = "output"
#     framestack = readdir(dir)
#     framestack = sort(filter(x -> endswith(x, ".png"), framestack), by = x -> parse(Int, split(x, ".")[1]))

#     firstframevec = VideoIO.load(joinpath(dir, framestack[1]))
#     firstframe = firstframevec[1]

#     encoder_options = (crf=23, preset="medium")
#     fps = 10

#     open_video_out("$(filename).mp4", firstframe, framerate=fps, encoder_options=encoder_options) do writer
#         for frame in framestack
#             framevec = VideoIO.load(joinpath(dir, frame))
#             f = framevec[1]
#             write(writer, f)
#         end
#     end
# end

# function run_game_test()
#     g = ButterflyGame()
#     scene = random_scene((10,10), 0., 4)
#     run_game(g, scene)
# end

# #test_one()
# #test_two()
# #collision_test(l4)
# run_game_test()
