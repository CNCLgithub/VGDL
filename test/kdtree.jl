using Distances
using NearestNeighbors
using VGDL

function test()
    a = Line(undef, 2)
    a[1], a[2] = [2,1], [2,3]
    b = Line(undef, 2)
    b[1], b[2] = [1,2], [3,2]
    @show data = [a,b]
    @show tree = KDTree(data)
    idxs = collisions(tree, 1, 10)
end

test()
