# VGDL

A (spiritual) re-implementation of VGDL, focused on runtime safety for probabilistic programming.

> CAUTION: This is a work in progress. The API is not stable and may change abruptly. 

## Usage

see `test/butterfly.jl`

## Design

### Game definitions

Games can be defined with an a theory about interactions and termination rules

```julia

"A game with butterflies =)"
struct ButterflyGame <: Game end
```

``` julia

function interaction_set(::Type{ButterflyGame})
    set = [
        (Player => Obstacle) => Stepback,
        (Butterfly => Obstacle) => Stepback,
        (Butterfly => Player) => KilledBy,
        (Butterfly => Player) => ChangeScore,
        (Butterfly => Pinecone) => Retile{Ground},
        (Butterfly => Pinecone) => Clone,
    ]
end

function termination_set(::Type{ButterflyGame})
    set = [
        TerminationRule(
            st -> count(==(pinecone), st.scene.static) == 0,
            GameOver()), # no pinecones -> Lose!
        TerminationRule(
            st -> st.time >= st.max_time,
            GameOver()), # Time out -> Lose!
        TerminationRule(
            st -> count(x -> isa(x, Butterfly), values(st.scene.dynamic)) == 0,
            GameWon()) # no butterflies -> Win!
    ]
end
```


### Elements

Current design deviation (or limitation?) is the need to declare new types of elements rather than instantiate enums. This is partly to take advantage of Julia's multiple dispatch but may be annoying for theory learning (unless you adopt a meta-programming implementation). 

For example, the `ButterflyGame` declares the following element types:
``` julia

struct Obstacle <: StaticElement end
const obstacle = Obstacle()

struct Pinecone <: StaticElement end
const pinecone = Pinecone()

struct Ground <: StaticElement end
const ground = Ground()

@with_kw mutable struct Butterfly <: Agent
    position::SVector{2, Int64}
    energy::Float64 = 0.0
    policy::Policy = random_policy
end
position(agent::Butterfly) = agent.position
policy(agent::Butterfly) = agent.policy

@with_kw mutable struct Player <: Agent
    position::SVector{2, Int64}
    policy::Policy = greedy_policy
end
position(agent::Player) = agent.position
policy(agent::Player) = agent.policy
```

### Stateless simulation

In order to support probabilistic simulation, where runtime order can vary, `update_step` in the core engine creates independent states of the game.

A simple (to implement) strategy involves copying the previous state then mutating it. For better or for worse, this project took a different, psuedo-declarative approach.
Rather than apply each rule form the interaction set in place, it is placed on a (priority) queue and determines the validity of that rule and that of the other rules already in the queue.
This sync step can cancel out / propagate the logic of each rule without referring to the game state explicitly and more importantly, without repeated mutation of the gamestate. 

After all categories of rules (those that come from dynamic + action, dynamic + static, dynamic + dynamic) are processed in the queue, then the new state is resolved, ensuring only one copy of the game state. 

This strategy may not actually be faster than the simple approach and has some considerable complexity (constantly passing around "function" like objects like Lenses).


## Roadmap

- [ ] Implement Zelda
- [ ] Add sprite graphics
- [ ] Run games interactively
- [ ] Implement other games
