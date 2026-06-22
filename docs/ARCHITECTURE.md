# Architecture

A short walkthrough of the systems and the rationale behind each. Read top-to-bottom; each section names the file(s) that own it.

---

## Design tenets

1. **Data-driven scenarios.** Units, terrains, factions and entire battles are JSON. Adding a new scenario must not require touching any `.gd` file. Code is the runtime; content is the data layer.
2. **Determinism.** Combat, AI scoring and victory checking are pure functions of game state. No RNG — same inputs, same outputs. This keeps tests reliable and AI evaluation honest.
3. **Visual / logic split.** Game state mutates immediately when an action resolves; visuals (movement tweens, damage popups, death fade-outs, wreckage) play in parallel and never block logic. The AI's next move never waits for a previous animation to finish.
4. **Static methods over orchestration objects.** `Pathfinding`, `CombatResolver`, `VictoryChecker` are stateless `RefCounted` classes with pure static methods. The Battle scene is the only owner of mutable state.

---

## Module map

```
Battle (scenes/battle.tscn, scripts/battle.gd)
│
├── HexMap ─────────── tile renderer + occupancy + overlays + wreckage
│   └── Polygon2D children (tiles, range overlays, objective pulse, wreckage)
│
├── Camera (CameraController) — WASD pan / wheel zoom / middle-drag
│
├── Units ([Unit, Unit, …])
│   └── Each: faction-coloured circle + type letter + HP bar + selection halo
│
└── UI (CanvasLayer)
    ├── InfoLabel (top status)
    ├── StatusLabel (bottom faction counts + turn)
    ├── InfoPanel (right side: selected unit stats + terrain)
    ├── TurnBanner (centre, fades in/out on turn change)
    ├── EndTurnButton
    └── ResultPanel (modal, end of game)

Autoloads (singletons)
├── DataLoader — loads units.json / terrains.json / scenarios/*.json once
├── GameState  — inter-scene state (current scenario id, last result)
├── AudioBank  — lazy .ogg loader, no-op for missing files
└── ScreenshotHelper — F12 → user://screenshots/

Pure logic (RefCounted, all static methods)
├── HexCoord       — axial coordinate math + pixel conversion
├── Pathfinding    — Dijkstra movement range + path reconstruction
├── CombatResolver — attack damage formula + counter-attack
├── VictoryChecker — eliminate / capture / survive evaluators
├── TurnManager    — faction rotation + turn counter
├── AIController   — heuristic per-unit move scoring
└── UnitFactory    — scenario JSON → instantiated Units
```

---

## Coordinate system — axial hex

[scripts/grid/hex_coord.gd](../scripts/grid/hex_coord.gd) implements pointy-top axial coordinates `(q, r)`. Reference: <https://www.redblobgames.com/grids/hexagons/>.

The scenario JSON uses the more readable **odd-r offset** form (rows in a rectangular grid):

```
tiles[row][col]   →   axial (col - floor(row/2), row)
```

Conversion is done once in `HexMap.load_from_scenario`. Once a hex is in memory it's always axial — neighbors, distances, range queries all use the cleaner `(q, r)` math.

Tested in [tests/test_hex_coord.gd](../tests/test_hex_coord.gd) — neighbor count, distance correctness, range size, pixel round-trip.

---

## Movement — Dijkstra with terrain weights

[scripts/grid/pathfinding.gd](../scripts/grid/pathfinding.gd) provides two static methods:

- `movement_range(start, move_points, hex_map, occupied) → Dictionary[Vector2i, int]` — returns every reachable hex with the cumulative move cost. Honors per-terrain `move_cost` (forest = 2, mountain = 3, river = 4) and blocks on any hex occupied by a unit.
- `reconstruct_path(start, goal, cost_to, hex_map) → Array[Vector2i]` — walks the cost-to map backwards from `goal` to recover the actual route. Used to animate the unit hex-by-hex along its path instead of teleporting.

Pathfinding takes `hex_map` as a duck-typed argument (anything with `terrain_at(coord)` and `move_cost_at(coord)`) so tests can pass a tiny stub without spinning up the whole engine.

Tested in [tests/test_pathfinding.gd](../tests/test_pathfinding.gd) — open ground, terrain cost, occupied-block, off-map filtering.

---

## Combat — deterministic formula

[scripts/combat/combat_resolver.gd](../scripts/combat/combat_resolver.gd):

```
base = max(1, attacker.attack + (vs_armor if defender.armor > 0 else 0)
              - defender.defense - defender_terrain.defense)
damage = max(1, round(base * attacker_hp / attacker_max_hp))
```

Two design decisions worth flagging:

1. **HP-ratio scaling.** A wounded attacker hits softer (`attacker_hp / max_hp`). This creates a natural "death spiral" — a 30%-HP unit is much weaker than the same unit at full HP — without needing a separate morale system.
2. **Counter-attack at half damage.** If the defender survives and the attacker is within the defender's range, the defender retaliates at 50% damage. Artillery (`indirect: true`) cannot counter — they're vulnerable in melee.

`vs_armor` only triggers against units with `armor > 0`, so AT guns shred tanks but waste their bonus on infantry.

Tested in [tests/test_combat_resolver.gd](../tests/test_combat_resolver.gd) — 7 cases covering base damage, terrain modifier, vs_armor, HP scaling, lethal damage, indirect-no-counter, out-of-range-no-counter.

---

## AI — heuristic scoring with personality weights

[scripts/turn/ai_controller.gd](../scripts/turn/ai_controller.gd). Roughly 140 lines.

For each AI unit on its faction's turn:

1. Compute the full movement range (Dijkstra, same as the player).
2. For each candidate hex (including "stay in place"), score:
   ```
   score = -dist_to_nearest_enemy        × 1.0   (advance toward objective)
         + best_damage_from_here         × 2.5   (reward attacks)
         + 5.0 if attack would kill              (finish bonus)
         - 0.6 × counter_damage_we'd_eat         (avoid bad trades)
         - exposure_to_enemy_threat      × 0.5   (don't walk into kill zones)
         + terrain.defense               × 0.3   (use cover)
   ```
3. Pick the highest-scoring destination, move there, attack best target if in range.

The "best target from here" reuses the same `CombatResolver.resolve` the player's hits go through — so the AI's evaluation matches the actual damage that would happen.

**Personality weights** modulate the final score:

| Personality | Effect |
|---|---|
| `aggressive` | +0.3 × attack term (Stalingrad's Wehrmacht, Sedan's Panzers) |
| `defensive`  | +0.8 × exposure term, i.e. more risk-averse (Sedan's French) |
| `hold`       | -0.5 flat bias against moving (Kiev's encircled Soviets) |

Each scenario sets the personality via the faction's `"ai"` key. The Soviet survivors at Kiev should sit in their cover, the Germans at Stalingrad should press into the city — and they do.

### Difficulty profiles + 1-ply lookahead

A player-selectable difficulty (`GameState.difficulty`, chosen on the scenario-select screen) maps to a profile that tunes the heuristic weights and toggles a 1-ply lookahead:

| Difficulty | `attack_w` | `kill_bonus` | `exposure_w` | Lookahead |
|---|---:|---:|---:|---:|
| Easy   | 1.5 | 2.5 | 0.3 | off |
| Normal | 2.5 | 5.0 | 0.5 | off |
| Hard   | 3.0 | 7.0 | 0.4 | **on** |

When lookahead is on, for every candidate hex `M` the AI considers, it computes the worst counter-attack damage any *currently visible* player unit could deliver to a unit at `M` on the player's next turn. That damage is subtracted from the candidate's score (weight `W_LOOKAHEAD = 1.0`).

The implementation caches each player unit's full reachable-hex set once per AI turn (Dijkstra from the player's current position, honouring current occupancy). Per candidate, the threat check is then just a `HexCoord.distance(...) <= player_range` membership test over the cached set — cheap even for ~30 candidates × 8 AI units × 5 players.

Damage is a real `CombatResolver.resolve(...)` using the player's actual HP and the AI unit's HP + terrain at `M` — not a stat-based proxy. Attacker terrain is ignored because it only affects counter-counter damage, which we don't simulate.

Behaviour you'll notice on Hard:
- The AI stops advancing through open ground when a player unit could one-shot it.
- It picks longer routes through forest / town to break the player's LOS to its destination.
- Wounded AI units retreat more aggressively because the counter-cost relative to their HP shoots up.

---

## Tactical mechanics — ZoC, Overwatch, Dig In

Three classic hex-wargame mechanics layered onto the existing systems.

### Zone of Control (ZoC)

Every unit projects ZoC onto its 6 adjacent hexes. Entering a ZoC hex costs `Pathfinding.ZOC_PENALTY = 2` extra movement. The effect:

- Slipping past an enemy is *possible* but expensive (often more than a single turn's movement budget).
- A defender doesn't have to physically chase — placement alone narrows the attacker's options.

Implementation lives entirely inside [scripts/grid/pathfinding.gd](../scripts/grid/pathfinding.gd) — `movement_range` takes an optional `mover_faction` parameter and, for each candidate hex `n`, adds the penalty if any neighbour of `n` is occupied by a different-faction unit. The cost stacks with terrain (forest + ZoC = 4 to enter). Callsites pass `unit.faction_id`; tests pass `""` to opt out, preserving the original behaviour.

### Overwatch

A unit that finishes its turn on overwatch (clicking the `進入警戒 (O)` button after its move, or the AI choosing the overwatch branch) takes a *snap shot* at any enemy that **passes through** its sight + attack range during the rest of the round. Rules:

- Half damage rounded up, no counter-attack — it's a reactive shot, not a deliberate engagement.
- Watcher must currently see the hex the mover is entering (uses the per-faction `visibility_by_faction` set).
- Each watcher fires once per setup; the flag is cleared after firing.
- The flag also clears at the start of the watcher's own next turn (lost focus).
- Multiple watchers can all fire on the same mover, in faction-roster order.

Path-crossing implementation ([scripts/battle.gd](../scripts/battle.gd)):
- `_trigger_overwatch_along_path(mover, path)` iterates each hex along the BFS path. For every overwatch-flagged enemy unit that sees the hex AND has it in range, applies snap damage at that hex's world position. Returns the path index at which the mover died (if any).
- `_move_with_overwatch(mover, path)` is the unified move helper: resolves overwatch first, truncates the visual path to the death hex if the mover doesn't survive, then runs the normal `hex_map.move_unit_along_path` animation, finally places wreckage + plays the death animation if needed.

So a unit can be shot multiple times during a single move — once per overwatching enemy whose range it passes through. ZoC's +2 cost interacts naturally: covering more ZoC hexes means more potential overwatch triggers.

Visual marker: a red gunsight triangle above the watcher; gold damage popups mark snap-shot hits versus the red of a normal attack.

### AI overwatch decision

The AI evaluates overwatch as a third action class alongside attack and wait. For every candidate hex `M`:

- `attack_value(M)` = best damage to a visible enemy from `M`, with the existing kill bonus / counter penalty
- `overwatch_value(M)` = best snap-shot damage to any enemy that could *enter* the watcher's range next turn, multiplied by 0.6 (uncertainty discount) and the same `_attack_w`

Both are pre-weighted contributions, so swapping them in/out of the base position score gives directly-comparable scores. The AI picks whichever (M, action) pair scores highest. Indirect-fire units (artillery) skip overwatch consideration — they don't snap-shot moving troops well.

The result: the AI naturally garrisons chokepoints. When it can't find a profitable attack but enemies are about to walk into a sight line, it sets overwatch and lets the player pay the cost of crossing.

### Dig In

A unit that ends its turn with neither move, attack, nor overwatch active gains `dig_in_level += 1` (capped at `Unit.MAX_DIG_IN = 3`). The level is added to the unit's defense in any incoming attack via the new `defender_dig_in` parameter on `CombatResolver.resolve`. Counter-attacks ignore the attacker's dig-in (they just acted, so they're not entrenched).

Any move, attack or overwatch resets the level to zero — entrenchment is a binary choice between standing fast and committing to action.

Visual marker: brown chevrons below the unit's HP bar, one per level. The info-panel stats line shows `⛤ 構工 +N 防禦` when active.

### Combined behaviour

The three mechanics interact in pleasant ways:

- ZoC forces the player to invest movement to bypass an enemy — by then, that enemy can react on its turn.
- Overwatch lets a static unit pin a corridor without spending its attack.
- Dig In rewards holding ground in cover; a unit in town (+3 defense) with dig-in 3 (+3 defense) is effectively unkillable to anything but armor with full vs_armor bonus.

Together they recover most of the strategic-depth gap between a "minimal tactical wargame" and something like Panzer General.

### Scope notes

- AI uses Overwatch via the explicit branch above; AI digs in implicitly when it stays put with no good target (the end-of-turn rule increments `dig_in_level` for any unit that didn't move, attack, or overwatch).
- Overwatch fires at every step of the mover's path, not just the destination. A unit can no longer rush past an overwatching unit without taking fire.

---

## Scenarios — data, not code

[data/scenarios/*.json](../data/scenarios/). One file per battle. Shape:

```json
{
  "id": "01_sedan_1940",
  "title": "色當突破 1940",
  "briefing": "1940 年 5 月 13 日。古德林的第 19 裝甲軍...",
  "map": {
    "width": 14, "height": 10,
    "tiles": [["plain", "forest", ...], ...]
  },
  "factions": [
    {"id": "axis",   "controller": "player", "color": "#7a4a3a"},
    {"id": "allies", "controller": "ai", "ai": "defensive", "color": "#3a5a7a"}
  ],
  "units": [
    {"faction": "axis", "type": "medium_tank", "name": "Pz.IV", "at": [12, 0]},
    ...
  ],
  "victory": {
    "axis":   {"type": "capture", "target": [10, 8], "by_turn": 12},
    "allies": {"type": "survive", "by_turn": 12}
  }
}
```

Three victory types are recognised by [scripts/scenario/victory_checker.gd](../scripts/scenario/victory_checker.gd):

- **eliminate** — destroy every living enemy unit.
- **capture** — occupy a specific hex by turn N.
- **survive** — still have any living units at turn N.

The player's "capture" target automatically gets a yellow pulse overlay so you can see the goal at a glance — no need to read the briefing twice.

### Reinforcements

Scenarios can optionally specify `reinforcements[]` — units that spawn part-way through the battle:

```json
"reinforcements": [
  {"at_turn": 7, "faction": "allies", "type": "medium_tank", "name": "M4 雪曼", "at": [5, 9]}
]
```

When `TurnManager` rolls into turn `at_turn` AND the current faction is the reinforcement's `faction`, the unit spawns at its `at` coordinate, `reset_for_new_turn` is called so it can act this turn, and an `★ 援軍抵達` banner appears in the info label. Used by Bastogne 1944 for Patton's relief column on turn 7.

If the spawn hex is already occupied, the reinforcement is silently dropped (with a `push_warning`) — caller can adjust map design rather than us picking a random fallback hex.

---

## Fog of war + line-of-sight

[scripts/grid/visibility.gd](../scripts/grid/visibility.gd) (~50 LOC).

### Vision per unit type

Each unit type declares `vision` in [data/units.json](../data/units.json):

| Unit type | Vision | Why |
|---|---|---|
| `at_gun` | 2 | Static, low profile — bad scout |
| `infantry` / `mg_team` | 3 | Boots on the ground baseline |
| `light_tank` / `medium_tank` | 4 | Mobile, higher viewpoint |
| `artillery` | 5 | High vantage / observers — doubles as a spotter |

Adding a stat to the data tier (rather than hard-coding) lets a future scenario override vision (e.g. night ops) without touching code.

### Hex line drawing

`HexCoord.line(a, b)` walks the line from `a` to `b`, sampling at `t = step / distance` and snapping to the nearest hex via the cube-rounding logic already used for pixel → axial conversion. Returns the full path inclusive of both endpoints.

### LOS check

`Visibility.has_los(observer, target, hex_map)` walks the line, **skipping the endpoints**, and returns false if any intermediate hex's terrain has `blocks_los: true` (currently `forest` and `mountain`). A unit on a forest tile can still be seen by an adjacent observer — only line-crossing forest breaks vision.

### Visibility computation

`Visibility.compute_visible_hexes(units, faction_id, hex_map)` returns a `Dictionary[Vector2i, true]` of every hex visible to **any** living unit of the given faction. For each unit, it iterates `HexCoord.range_within(coord, vision)` and tests LOS to each candidate. Map sizes are small (140 hexes max), so the naive O(units × range² × line_length) is well under one millisecond.

### Symmetric design + AI memory

Both the player and the AI factions have fog. The AI does **not** cheat — it can only score moves and pick targets based on what its own units currently see, plus what it remembers seeing.

**Per-faction visibility.** `battle.gd` keeps `visibility_by_faction: Dictionary[String, Dictionary[Vector2i, true]]` and recomputes every entry on the same triggers as the player's fog (init, every move, after combat, after reinforcement spawn). Only the player's set is rendered as the on-screen fog overlay.

**Last-known-position memory.** For each `(viewer_faction, target_unit)` pair the engine records the last coord the viewer saw the target at (`last_known_positions: Dictionary[String, Dictionary[Unit, Vector2i]]`). On every visibility recompute the table is updated:

- Dead targets are evicted.
- Currently-visible enemies have their entry refreshed to their current coord.
- Out-of-sight enemies keep their stale entry — that's the memory.

**Seed memory.** At scenario start, each faction is seeded with intel on every opponent unit's starting position (the "briefing-table" knowledge). This avoids the first-turn nonsense of armies pretending each other don't exist. Memory grows stale from there as units move out of view.

**How the AI uses it.** `battle.get_known_enemies(faction_id)` returns a list of `{unit, coord, visible}` entries — coord is current if visible, stale-memory otherwise. The AI then:

- **Distance / advance scoring** uses each known enemy's `coord` (memory ok — it wants to walk *toward* where you were last seen).
- **Attack target selection** is restricted to `visible == true` (you can't shoot fog).
- **Threat / exposure scoring** also restricted to visible enemies (the AI has no information to weigh hidden units' threat).

The behaviour reads as: the AI advances toward your last known position, scouts when it loses sight, and engages when it spots you. Fog gives the player real tactical levers — pulling back through a forest to break LOS makes the AI commit to a stale path it can no longer punish you for.

### Rendering

`HexMap._spawn_fog_layer()` creates a Node2D at `z_index = 8` (between range overlays and units) and adds one fog Polygon2D per hex, initially invisible. `HexMap.apply_visibility(visible_hexes, viewer_faction)` then:

1. Sets each fog overlay's `visible` to the inverse of the hex's visibility.
2. Iterates every occupant; if `unit.faction_id == viewer_faction` shows it unconditionally, otherwise mirrors the hex's visibility.

This means enemy units pop in and out as the player advances or pulls back.

### Recomputation triggers

The `_recompute_visibility()` helper in [scripts/battle.gd](../scripts/battle.gd) fires after:

- Initial scene `_ready` (so the player sees the right state on load).
- Player movement completes.
- AI movement completes (for each AI unit individually — the player watches the fog peel back as the AI advances toward them).
- Combat resolution (a killed unit might have been the only spotter).
- Reinforcement spawn (new units extend visibility).

Tested in [tests/test_visibility.gd](../tests/test_visibility.gd) — 7 cases covering identity, line endpoints, consecutive hexes, clear LOS, forest blocker, endpoint-not-blocker, adjacent visibility.

---

## Visual / logic split

A worked example: when a unit attacks and the defender dies,

1. **Logic (synchronous, this frame):**
   - `CombatResolver.resolve` computes damages and death.
   - `defender.take_damage` flips its HP to 0.
   - `hex_map.unregister_unit` clears occupancy.
   - `units = units.filter(is_alive)` drops it from the roster.
   - `VictoryChecker.evaluate` runs; if a winner is determined, `_handle_game_over` fires.

2. **Visuals (async, next 0–4 seconds, parallel):**
   - Attacker plays its lunge tween (~0.28s).
   - Damage popup floats up over defender (~0.9s).
   - `place_wreckage` drops a scorch mark on the dead unit's hex (~4.0s + 0.8s fade).
   - `play_death_animation` flashes the dying unit red, fades alpha to 0, then `queue_free`s it (~0.55s).
   - `AudioBank.play("attack")` / `play("death")` fire (silently if no .ogg loaded).

The AI's between-action delay (`AI_STEP_DELAY = 0.6s`) gives the player time to watch one resolution before the next begins, but the underlying game state has already advanced.

---

## Testing

Headless GDScript tests, run with `bash tests/run_all.sh`:

| Suite | Coverage | Cases |
|---|---|---|
| `test_hex_coord` | Axial math, neighbors, distance, range size, pixel round-trip | 7 |
| `test_pathfinding` | Open / blocked / terrain-cost / off-map / start-excluded | 6 |
| `test_combat_resolver` | Base, terrain, vs_armor, HP scaling, lethal, indirect, OOR | 7 |
| `test_visibility` | Hex line + LOS through forest / endpoints / adjacency | 7 |
| `test_pathfinding` (cont.) | ZoC + friendly-not-ZoC + no-faction opt-out | +3 |
| `test_combat_resolver` (cont.) | Dig-in defense bonus + counter-no-dig-in | +2 |
| **Total** | | **32 ✓** |

The Battle scene itself is exercised by booting each scene headless (`godot --headless --main-scene SCENE --quit-after 30`) — proves the parser + autoload chain + scene load are clean even when no GUI test exists.
