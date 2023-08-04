using Accessors
using Accessors: IndexLens, PropertyLens, ComposedOptic,
    set, delete, insert

export Lens!

struct Lens!{L}
    pure::L
end

# broadcasting `__call_-`
(l::Lens!)(o) = l.pure(o)

function Accessors.set(o, l::Lens!{<: ComposedOptic}, val)
    o_inner = l.pure.inner(o)
    set(o_inner, Lens!(l.pure.outer), val)
end
function Accessors.set(o, l::Lens!{PropertyLens{prop}}, val) where {prop}
    setproperty!(o, prop, val)
    o
end
function Accessors.set(o, l::Lens!{<:IndexLens}, val)
    o[l.pure.indices...] = val
    o
end

function Accessors.delete(o::AbstractDict, l::Lens!{<:IndexLens})
    for i = l.pure.indices
        delete!(o, i)
    end
    o
end

function Accessors.delete(o, l::Lens!{<: ComposedOptic})
    o_inner = l.pure.inner(o)
    delete(o_inner, Lens!(l.pure.outer))
end

function Accessors.insert(o::AbstractDict, l::Lens!{<:IndexLens}, val)
    i = only(l.pure.indices)
    o[i] = val
    o
end

function Accessors.insert(o, l::Lens!{<: ComposedOptic}, val)
    o_inner = l.pure.inner(o)
    insert(o_inner, Lens!(l.pure.outer), val)
end
