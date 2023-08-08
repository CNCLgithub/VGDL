export NoAction,
    Up,
    Down,
    Left,
    Right,
    Stepback,
    KilledBy,
    Clone,
    ChangeScore,
    CompositeRule


struct NoAction <: Rule{NoEffect, Many} end
promise(::Type{NoAction}) = (i, o) -> NoAction()
# Don't need to change the queue
add!(::PriorityQueue, ::NoAction) = nothing

abstract type  Move <: Rule{ChangeEffect, Many} end

_move_lens(ref) = opcompose(get_agent(ref), @optic _.position)

struct Up <: Move
    lens
    Up(ref) = new(_move_lens(ref))
end
struct Down <: Move
    lens
    Down(ref) = new(_move_lens(ref))
end
struct Left <: Move
    lens
    Left(ref) = new(_move_lens(ref))
end
struct Right <: Move
    lens
    Right(ref) = new(_move_lens(ref))
end
lens(r::Move) = r.lens
priority(::Move) = 1
transform(r::Up) = x -> x + up
transform(r::Down) = x -> x + down
transform(r::Left) = x -> x + left
transform(r::Right) = x -> x + right
promise(::Type{Up}) = (i, o) -> Up(i)
promise(::Type{Down}) = (i, o) -> Down(i)
promise(::Type{Left}) = (i, o) -> Left(i)
promise(::Type{Right}) = (i, o) -> Right(i)

const up = SVector{2, Int64}([-1,0])
const down = SVector{2, Int64}([1,0])
const left = SVector{2, Int64}([0,-1])
const right = SVector{2, Int64}([0,1])


struct Stepback <: Rule{ChangeEffect, Single}
    ref::Int64
end
lens(r::Stepback) = _move_lens(r.ref)
transform(r::Stepback) = x -> x # REVIEW: feels weird
promise(::Type{Stepback}) = (i, o) -> Stepback(i)
add!(::PriorityQueue, ::Stepback) = nothing

"Removes a single move rule"
function modify!(q::PriorityQueue, ::Stepback)
    for (r, p) in q
        if typeof(r) <: Move
            delete!(q, r)
            break
        end
    end
    return nothing
end


# struct Applicator{T} <: Rule{T}
#     lens
#     transform::Function
#     base::Rule{T}
#     function Applicator(r::Rule{<:Effect}, l)
#         new{T}(opcompose(l, lens(r)), transform(r), r)
#     end
# end
# TODO: Implement lens and transform

struct Clone <: Rule{BirthEffect, Many}
    ref::Int64
    lens
    function Clone(ref)
        l = get_agent(ref)
        new(ref, l)
    end
end
lens(r::Clone) = r.lens
transform(r::Clone) = deepcopy
promise(::Type{Clone}) = (i, o) -> Clone(i)

struct KilledBy <: Rule{DeathEffect, Single}
    ref
    killer
    function KilledBy(ref::Int64, killer::Int64)
        new(get_agent(ref), get_agent(killer))
    end
    function KilledBy(ref::Int64, killer)
        new(get_agent(ref), get_static(killer))
    end
end
lens(r::KilledBy) = r.ref
transform(r::KilledBy) = x -> x # REVIEW: not used
promise(::Type{KilledBy}) = KilledBy
priority(::KilledBy) = 0

# used in `sync!`
function modify!(queue::PriorityQueue, rule::KilledBy)
    empty!(queue)
    return nothing
end

# used in `resolve`
function pushtoqueue!(r::KilledBy, c::Dict, b::Dict, d::Dict)
    lr = lens(r)
    # contingent on killer staying alive
    # or if the target is already dead
    (haskey(d, r.killer) || haskey(d, lr)) && return false
    tr = transform(r)
    d[lr] = tr
    return true
end

struct ChangeScore <: Rule{ChangeEffect, Many} end
lens(::ChangeScore) = @optic _.reward
transform(::ChangeScore) = x -> x + 1
const _chngscore = ChangeScore()
promise(::Type{ChangeScore}) = (i, o) -> _chngscore


struct CompositeRule <: Rule{CompositeEffect, Application}
    a::Rule
    b::Rule
    lens
    transform::Function
    function CompositeRule(a::Rule, b::Rule)
        new(a, b, lens(a), transform(a))
    end
end
lens(r::CompositeRule) = r.lens
transform(r::CompositeRule) = r.transform
promise(::Type{CompositeRule}, a, b) = (i, o) -> CompositeRule(promise(a)(i, o),
                                                               promise(b)(i, o))
priority(r::CompositeRule) = priority(r.a)
function modify!(q::PriorityQueue, r::CompositeRule)
    modify!(q, r.a)
    modify!(q, r.b)
    return nothing
end
function pushtoqueue!(r::CompositeRule, cq::Dict, bq::Dict, dq::Dict)
    pushtoqueue!(r.a, cq, bq, dq) && pushtoqueue!(r.b, cq, bq, dq)
end
