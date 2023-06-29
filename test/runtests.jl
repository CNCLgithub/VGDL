using Test
using ButterflyGame

include("../src/scene.jl")

@testset "random scene" begin
    state::GameState
    state.scene = random_scene(Tuple([10, 10])), 0.3, 20)
    render_image(state)
end
