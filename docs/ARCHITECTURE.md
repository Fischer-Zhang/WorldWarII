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

- `movement_range(start, move_points, hex_map, occupied, mover_faction) → Dictionary[Vector2i, int]` — returns every reachable hex with the cumulative move cost. Honors per-terrain `move_cost` (forest = 2, mountain = 3, river = 4), blocks on any hex occupied by a unit, and applies enemy ZoC when `mover_faction` is provided.
- `reconstruct_path(start, goal, cost_to, hex_map, occupied, mover_faction) → Array[Vector2i]` — walks the cost-to map backwards from `goal` using the same terrain + ZoC step costs to recover the actual route. Used to animate the unit hex-by-hex along its path instead of teleporting.

Pathfinding takes `hex_map` as a duck-typed argument (anything with `terrain_at(coord)` and `move_cost_at(coord)`) so tests can pass a tiny stub without spinning up the whole engine.

**ZoC opt-out.** `mover_faction` is optional (default `""`). When empty, ZoC adjacency is **not** applied — the BFS uses pure terrain costs. The opt-out exists so the pathfinding unit tests (and any future caller that wants "raw reachability") can ignore ZoC without constructing fake faction state. Production callsites always pass `unit.faction_id`.

Tested in [tests/test_pathfinding.gd](../tests/test_pathfinding.gd) — open ground, terrain cost, occupied-block, off-map filtering, ZoC blocks expensive hex / friendly does not / opt-out.

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
2. **Counter-attack at half damage.** If the defender survives and the attacker is within the defender's range, the defender retaliates at 50% damage. Artillery (`indirect: true`) cannot counter while defending; it is still countered if it attacks from inside the defender's range.
3. **Suppression side effects.** Damaging non-lethal hits return side effects alongside damage: light suppression for most attacks, stronger pinning from MG/artillery, and one dig-in level stripped by damaging indirect fire.
4. **Rally as action economy.** Suppressed units can spend their action to recover suppression, with extra recovery in cover. This turns suppression into a reversible tempo cost rather than a one-way debuff.

Attack legality is owned by [scripts/combat/combat_rules.gd](../scripts/combat/combat_rules.gd): direct attacks require current faction visibility and line of sight; indirect attacks still require a spotted target but ignore LOS blockers. Player targeting and AI attack evaluation both call this shared rule layer.

`vs_armor` only triggers against units with `armor > 0`, so AT guns shred tanks but waste their bonus on infantry.

Suppression thresholds live in [scripts/combat/combat_effects.gd](../scripts/combat/combat_effects.gd): pinned units cannot overwatch or build dig-in, heavier suppression reduces movement, and the highest band reduces attack. Suppression recovers by 1 at the start of the unit's faction turn; Rally recovers 2 immediately, or 3 when the unit is in defensive cover.

Tested in [tests/test_combat_resolver.gd](../tests/test_combat_resolver.gd) and [tests/test_combat_effects.gd](../tests/test_combat_effects.gd) — base damage, terrain modifier, vs_armor, HP scaling, lethal damage, indirect defender no-counter, out-of-range no-counter, close indirect attack counter, dig-in, suppression, Rally, and artillery dig-in stripping.

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
         + wounded/suppressed target focus       (finish damaged units)
         + suppression / dig-in break value      (prefer pinning and siege hits)
         + capture-objective pressure            (for capture factions)
         - exposure_to_enemy_threat      × 0.5   (don't walk into kill zones)
         + terrain.defense               × 0.3   (use cover)
         + role_score                            (scout / AT / artillery shaping)
   ```
3. Pick the highest-scoring destination, move there, attack best target if in range.

The "best target from here" reuses the same `CombatResolver.resolve` the player's hits go through — so the AI's evaluation matches the actual damage that would happen.

Role shaping keeps specialist units from collapsing back into raw damage math:

- Light tanks with high move + vision get a small scouting bonus when they close toward last-known enemy positions without current contact.
- AT guns get a target bonus against armored units and a small penalty against soft targets.
- Indirect-fire units are penalized for candidate positions within 1-2 hexes of known enemies, encouraging standoff behavior.
- Suppression and dig-in break are part of attack value, so artillery and MG teams can be preferred even when raw damage ties.
- Capture factions value positions closer to their objective hex.
- Pinned units can choose Rally in place when suppression recovery beats moving, attacking or overwatch.
- Focus-fire scoring gives extra value to already wounded or suppressed targets, making the AI finish damaged units instead of spreading equal attacks.

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

## Tactical mechanics — ZoC, Overwatch, Dig In, Suppression, Rally

Classic hex-wargame mechanics layered onto the existing systems.

### Zone of Control (ZoC)

Every unit projects ZoC onto its 6 adjacent hexes. Entering a ZoC hex costs `Pathfinding.ZOC_PENALTY = 2` extra movement. The effect:

- Slipping past an enemy is *possible* but expensive (often more than a single turn's movement budget).
- A defender doesn't have to physically chase — placement alone narrows the attacker's options.

Implementation lives entirely inside [scripts/grid/pathfinding.gd](../scripts/grid/pathfinding.gd) — `movement_range` takes an optional `mover_faction` parameter and, for each candidate hex `n`, adds the penalty if any neighbour of `n` is occupied by a different-faction unit. The cost stacks with terrain (forest + ZoC = 4 to enter). `reconstruct_path` uses the same step-cost helper, so the animated route matches the reachable-cost map. Callsites pass `unit.faction_id`; tests pass `""` to opt out, preserving the original behaviour.

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

### Suppression + Rally

Damaging attacks apply suppression through [scripts/combat/combat_effects.gd](../scripts/combat/combat_effects.gd). Most direct-fire units apply light suppression; MG teams and artillery apply strong suppression. Thresholds:

- `2+`: pinned; cannot enter overwatch or build dig-in.
- `3+`: movement -1.
- `4+`: attack -1.

Suppression decays by 1 at the start of the unit's own faction turn. Rally is the active counterplay: the unit spends its action, clears overwatch/dig-in intent, and immediately removes 2 suppression, or 3 if its current terrain has defense 2 or higher. The player uses `整隊 (R)`; the AI evaluates Rally as a fourth action beside attack, overwatch and wait.

When selecting a unit, visible enemy threat reach is shown as an orange overlay behind the blue movement range. The selected unit's info panel expands suppression into concrete effects (`無法警戒/構工`, `移動 -1`, `攻擊 -1`) and shows the expected suppression value after Rally.

### Combined behaviour

The three mechanics interact in pleasant ways:

- ZoC forces the player to invest movement to bypass an enemy — by then, that enemy can react on its turn.
- Overwatch lets a static unit pin a corridor without spending its attack.
- Dig In rewards holding ground in cover; a unit in town (+3 defense) with dig-in 3 (+3 defense) is hard to remove without artillery.
- Suppression prevents a dug-in line from staying fully locked forever, while Rally gives the defender a tempo-cost recovery option.

Together they recover most of the strategic-depth gap between a "minimal tactical wargame" and something like Panzer General.

### Scope notes

- AI uses Overwatch via the explicit branch above; AI digs in implicitly when it stays put with no good target (the end-of-turn rule increments `dig_in_level` for any unit that didn't move, attack, or overwatch).
- Overwatch fires at every step of the mover's path, not just the destination. A unit can no longer rush past an overwatching unit without taking fire.

---

## Generals + Veteran XP (single modifier pipeline)

Two systems, one code path:

- **Generals** ([data/generals.json](../data/generals.json)). Named historical commanders attached to specific units in a scenario via `"general": "rommel"`. Each general declares `quality` (gold/silver/bronze — visual ring colour), `applies_to` (list of unit types the bonus targets), and additive bonuses (`attack_bonus`, `defense_bonus`, `vs_armor_bonus`, `move_bonus`, `vision_bonus`). Specialisation is enforced by `applies_to` — Rommel on a Panzer fires; Rommel on an infantry unit doesn't.

- **Veteran rank** (in-battle XP, no save/load needed). Each `Unit` carries `xp` and `rank`. XP earned: +1 per damage round dealt, +3 for a kill. Thresholds **0 / 2 / 5 / 9** map to ranks **0 / 1 / 2 / 3**. Bonuses are cumulative:

  | Rank | Bonus |
  |---|---|
  | 1 | +1 attack |
  | 2 | +1 attack, +1 defense |
  | 3 | +1 attack, +1 defense, +1 move, +1 vision |

Both feed [scripts/combat/combat_modifiers.gd](../scripts/combat/combat_modifiers.gd)'s single `for_unit(unit, general_def) → Dictionary` helper. The returned dict is then passed to:

- `CombatResolver.resolve(..., attacker_mods, defender_mods)` — additive on top of base attack/defense/vs_armor.
- `Unit.effective_move(unit_def, general_def)` / `effective_vision(...)` — used by Pathfinding callsites for the movement budget and by Visibility for sight range.

Why one pipeline: every future modifier source (terrain auras, equipment, weather, etc.) plugs into the same dict, so combat math doesn't need to know where the bonuses came from. The AI consumes the same modifier helper in its scoring functions, so its damage predictions match what the player will actually see.

Visual surface: gold/silver/bronze ring around units with a general; yellow chevrons (1–3) above units with rank > 0; info panel lines:
- `★ 隆美爾「沙漠之狐」` (general line, coloured by quality)
- `老兵 ★☆☆ (XP 1/2)` (rank stars + progress)

10 historical generals ship with the game (Rommel, Guderian, Manstein, Manteuffel, Patton, Bradley, Zhukov, Chuikov, Konev, de Gaulle); each scenario deploys 2–4 in narratively appropriate spots (Guderian's Pz.IV at Sedan, Chuikov on a Soviet infantry at Stalingrad, Patton on the Sherman that arrives at Bastogne turn 7).

Tested in [tests/test_combat_modifiers.gd](../tests/test_combat_modifiers.gd) (rank thresholds + general aggregation, 9 cases) and [tests/test_combat_resolver.gd](../tests/test_combat_resolver.gd) (modifier integration into damage formula, 3 added cases).

---

## Cookbook — Adding a new action type

If you want to add a new per-unit action (e.g. an Engineer's "Repair adjacent friendly"), here's the touch list. Each existing action — Attack, Overwatch, Dig In — already follows this pattern, so use them as templates.

**Data layer**
1. [data/units.json](../data/units.json): add the unit type with stats + any new fields the action reads (e.g. `repair_amount: 3`).
2. (optional) [data/terrains.json](../data/terrains.json): if the action interacts with terrain.

**Unit state**
3. [scripts/units/unit.gd](../scripts/units/unit.gd): add a boolean flag (`on_overwatch` / `is_repairing`) or a small integer state (`dig_in_level`). Update `reset_for_new_turn()` to clear or persist it as the rule dictates.
4. Same file's `_draw()`: add a visual marker so the player can see which units are in the new state.

**Combat / rules layer (only if the action interacts with combat math)**
5. [scripts/combat/combat_resolver.gd](../scripts/combat/combat_resolver.gd): if the action modifies damage taken or dealt, add a parameter to `resolve()` (see `defender_dig_in` for the pattern). Counters use a `0` default to keep the existing math.
6. [scripts/combat/combat_rules.gd](../scripts/combat/combat_rules.gd): if the action enables a *new kind of attack* (e.g. healing as an attack on a friendly), extend `can_attack_target` / `can_attack_from_coord`.

**Battle orchestration**
7. [scripts/battle.gd](../scripts/battle.gd):
   - Add a UI button to [scenes/battle.tscn](../scenes/battle.tscn) (mirror `OverwatchButton`'s wiring in `_ready`).
   - Add an action handler (`_on_repair_pressed`) and show/hide the button in `_enter_attack_phase` / `_deselect`.
   - Add the action's effect in a new helper (`_resolve_repair`) — apply the state change, spawn a damage-popup-style visual, play an `AudioBank.play(...)` cue.
   - If the action ends the unit's turn, set `unit.has_attacked = true` and call `_deselect()`.
   - Update `_update_dig_in_for_current_faction` (or its equivalent) so the new action's "no-action" exclusion list stays accurate.

**AI layer**
8. [scripts/turn/ai_controller.gd](../scripts/turn/ai_controller.gd):
   - Add an `_action_score(unit, pos, ...)` helper that returns the pre-weighted contribution for choosing this action from `pos`. Mirror `_overwatch_score` / `_best_attack_value`.
   - In `plan_for_unit`, add a third branch alongside `attack` / `overwatch`: `if action_score > best_score → best_action = "repair"`.
   - In `_process_ai_units` (back in battle.gd), add a `match` arm for the new action.

**Info panel**
9. [scripts/battle.gd](../scripts/battle.gd) `_update_info_panel_for_unit`: show the new state line so the player can read it.

**Tests**
10. [tests/test_ai_controller.gd](../tests/test_ai_controller.gd): add a behaviour test — "Engineer with damaged friendly adjacent should pick `repair`."
11. If combat math changed: [tests/test_combat_resolver.gd](../tests/test_combat_resolver.gd) gets a case with the new parameter.

**Docs**
12. Append a subsection to *Tactical mechanics* with the rule wording.
13. Update the visual / logic split section if the new action has its own animation pipeline.

A clean action add touches ~6 files, ~80–150 LOC, and 2–3 tests. Items 5/6 and 8 are skippable for pure self-modifications (e.g. a "Camouflage" action that just adjusts your own defense without interacting with combat resolution).

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
| `test_pathfinding` | Open / blocked / terrain-cost / off-map / start-excluded / ZoC + reconstruction | 10 |
| `test_combat_resolver` | Damage formula, counters, dig-in, modifiers, suppression output, artillery dig-in break | 16 |
| `test_combat_effects` | Suppression amount, pin thresholds, cap/recovery, movement/attack penalties, Rally, lethal/no-damage handling | 7 |
| `test_combat_modifiers` | Rank thresholds and general modifier aggregation | 9 |
| `test_combat_rules` | Direct/indirect attack legality, visibility, LOS blockers, faction/dead/range filters, candidate-position checks | 10 |
| `test_visibility` | Hex line + LOS through forest / endpoints / adjacency | 7 |
| `test_ai_controller` | AT armor target priority, artillery standoff, light-tank scout positioning, Hard 1-ply lookahead, suppression/dig-in target value, capture objective pressure, Rally action, focus fire | 8 |
| `test_reinforcements` | Bastogne scheduled turn 7 spawn, coordinate conversion, ready-to-act state, no duplicate spawn, occupied-hex skip | 6 |
| **Total** | | **80 ✓** |

The Battle scene itself is exercised by booting each scene headless (`godot --headless --main-scene SCENE --quit-after 30`) — proves the parser + autoload chain + scene load are clean even when no GUI test exists.
