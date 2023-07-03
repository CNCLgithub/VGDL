using Test
using ButterflyGame

function initial()
    scene = ButterflyGame.GridScene((30, 30))
    scene = random_scene((30, 30), 0.25, 40)
    render_image(scene)
end

function testlevel()
    scene = ButterflyGame.GridScene((11, 28))
    m = scene.items
    # render scene
    o = [(2,4), (2,6), (2,24), (2,26), (4,9), (5,9), (6,10), (4,21), (4,20), (4,19), (7,15), (7,16), (7,17), (7,18), (8,15), (10,4), (10,6), (10,24), (10,26)]
    p = [(6,2), (2,5), (2,15), (10,5), (10,15), (2,25), (6,27), (10,25)]
    @inbounds for i = eachindex(o)
        m[CartesianIndex(o[i])] = ButterflyGame.obstacle
    end
    @inbounds for i = eachindex(p)
        m[CartesianIndex(p[i])] = ButterflyGame.pinecone
    end
    # borders
    col = scene.bounds[1]
    row = scene.bounds[2]
    len = length(m)
    last = len - col
    @inbounds for i = eachindex(m)
        remcol = i % col
        remcol == 0 && (m[i] = ButterflyGame.obstacle)
        remcol == 1 && (m[i] = ButterflyGame.obstacle)
        1 <= i <= col && (m[i] = ButterflyGame.obstacle)
        last <= i <= len && (m[i] = ButterflyGame.obstacle)
    end
    
    render_image(scene)
end


#initial()
testlevel()