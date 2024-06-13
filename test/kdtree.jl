using Distances: cityblock
using NearestNeighbors
using VGDL
using StaticArrays

function test()
    a1 = SVector{2, Int64}(0, 0)
    a2 = SVector{2, Int64}(1, 0)
    b1 = SVector{2, Int64}(1, 0)
    b2 = SVector{2, Int64}(0, 0)
    data = [a2,b2]
    prev = [a1,b1]
    @show tree = KDTree(data, cityblock)
    @show collisions(tree, 1, 3, prev)
end

test()
