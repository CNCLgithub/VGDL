using VGDL
using Accessors

function test()
    l = Lens!(@optic _[1])
    o = Dict(1 => :x)
    # set(o, l, 0)
    delete(o, l)
    insert(o, l, :y)
    @show o
end

test();
