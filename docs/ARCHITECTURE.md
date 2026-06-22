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
| **Total** | | **20 ✓** |

The Battle scene itself is exercised by booting each scene headless (`godot --headless --main-scene SCENE --quit-after 30`) — proves the parser + autoload chain + scene load are clean even when no GUI test exists.
