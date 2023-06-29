using Test
using ButterflyGame

function mytest()
    scene = ButterflyGame.GridScene((30, 30))
    scene = random_scene((30, 30), 0.25, 40)
    state = ButterflyGame.GameState(scene)
    render_image(state)
end

mytest()