# Architecture

This project keeps a small runtime and a data-heavy content layer. Rules are deterministic, screens are ordinary Godot scenes, and tests run headlessly.

## Design Rules

1. **Data owns content.** Scenarios, units, terrain, campaigns and conquest regions live under `data/`.
2. **Rules are deterministic.** Combat, AI scoring and campaign/conquest resolution do not use RNG.
3. **Shared rules stay shared.** Player targeting and AI targeting both call `CombatRules`; damage prediction and damage resolution both call `CombatResolver`.
4. **Scenes orchestrate, helpers decide.** `battle.gd` owns battle state, but pathfinding, combat, victory, modifiers and strategic managers stay in focused helper classes.
5. **Validate before shipping.** `tools/validate.sh` is the gate for data, reports, tests and UI smoke.

## Runtime Map

```text
Autoloads
├── DataLoader          loads JSON catalogs once
├── GameState           inter-scene route state
├── AudioBank           lazy SFX dispatch
└── ScreenshotHelper    F12 capture

Scenes
├── main_menu.tscn
├── scenario_select.tscn
├── briefing.tscn
├── deployment.tscn
├── battle.tscn
├── campaign.tscn
├── lounge.tscn
└── conquest.tscn

Core logic
├── grid/               hex math, map renderer, pathfinding, visibility
├── units/              Unit + UnitFactory
├── combat/             rules, resolver, modifiers, suppression effects
├── turn/               TurnManager + AIController
├── scenario/           campaign, conquest, reinforcements, victory, action log
└── ui/                 menus, deployment, formatter, camera, popups
```

## Data Loading

`DataLoader` reads:

- `data/units.json`
- `data/terrains.json`
- `data/generals.json`
- `data/tech_tree.json`
- `data/campaigns.json`
- `data/conquest_map.json`
- every file in `data/scenarios/`

Catalog objects get their ids injected from their JSON key where useful. Scenario files keep their own `"id"`.

## Coordinates

Scenario JSON uses odd-r offset coordinates because they are easy to author in rectangular arrays:

```text
tiles[row][col] -> axial(col - floor(row / 2), row)
```

Runtime uses axial `Vector2i(q, r)` for neighbors, distance, movement and LOS. The conversion happens in `HexMap.load_from_scenario` and `UnitFactory`.

## Battle Scene

`scripts/battle.gd` owns mutable battle state:

- loaded scenario copy
- factions
- units
- selected unit
- turn manager
- visibility/memory maps
- result routing
- action log

Battle setup order:

1. Read `GameState.current_scenario_id`.
2. Duplicate scenario data so conquest/campaign overrides do not mutate `DataLoader`.
3. Load the themed map and connect map input.
4. Apply conquest battle context if conquest mode, before unit construction.
5. Build factions and units, then register them on the map.
6. Apply campaign roster if campaign mode.
7. Apply lounge upgrades.
8. Apply deployment overrides when a mode provides them.
9. Identify player faction and restore conquest garrison XP/rank.
10. Seed fog-of-war memory.
11. Start turn manager.

## Combat

Damage formula:

```text
base = max(1, attacker.attack
              + attacker.vs_armor if defender.armor > 0
              - defender.defense
              - defender_terrain.defense)

damage = max(1, round(base * attacker.hp / attacker.max_hp))
```

`CombatResolver.resolve` also handles counter-damage, dig-in, suppression side effects and active modifier dictionaries. Artillery/indirect units do not counter while defending, but they can still be countered if they attack from close range.

`CombatRules` owns attack legality:

- Direct fire needs range, visibility and LOS.
- Indirect fire needs range and visibility but ignores LOS blockers.

## Modifier Pipeline

`CombatModifiers.for_unit(unit, general_def)` aggregates:

- veteran rank
- attached general base bonus
- general upgrade level
- tech upgrades
- active skill effects

The same dictionary feeds combat attack/defense/vs-armor and movement/vision budgets.

`UnitDetailFormatter` presents this in two ways:

- Deployment: detailed final stats and every source line.
- Battle panel: compact base stats, compact final stats, source summary.

## Tactical Mechanics

**Zone of Control** lives in `Pathfinding`. Entering enemy-adjacent hexes costs extra movement, but pinned enemies do not project ZoC.

**Overwatch** is resolved along the movement path, not only at the destination. A watcher must see and be in range of the crossed hex. Default overwatch uses half damage; MG teams use full reaction-fire damage through `overwatch_damage_pct`.

**Dig In** rewards no-action turns with defense, capped by `Unit.MAX_DIG_IN`.

**Suppression** comes from damaging attacks, especially MG/artillery. Pinned units lose overwatch/dig-in access and stop projecting ZoC; heavier suppression reduces move/attack.

**Rally** spends the action to reduce suppression, with better recovery in defensive terrain.

**Fire-Support Marking** lets a light tank spend its action to mark a visible enemy in LOS. The mark is stored by the battle scene and consumed by the next same-faction active attack against that target, adding +1 suppression through `CombatEffects` only when the hit deals non-lethal damage.

**Secondary Objectives** are optional scenario-authored capture, hold-turn, destroy-unit or recon-hex tasks. They do not change victory resolution; the battle scene grants one-time `rewards` such as XP, suppression recovery, repair or reinforcement timing, records the event in `ActionLog`, and tracks hold progress per objective. Primary and secondary objectives render as labeled map markers so the player can distinguish victory hexes from optional reward hexes, marked targets and hold progress.

## AI

`AIController` scores candidate positions and actions with deterministic heuristics:

- distance to known enemies/objectives
- expected damage
- kill bonus
- counter-damage risk
- exposure
- terrain defense
- wounded/suppressed target focus
- role shaping for scouts, AT, artillery and engineers
- movement pressure toward primary objectives, secondary objectives and visible breach targets; destroy-unit secondary objectives also bias attack selection toward the marked unit
- rally value when suppressed
- overwatch value when no attack is better
- fire-support marking when a light tank has a visible LOS target and a same-faction follow-up attacker can use the suppression bonus

Hard difficulty adds one-ply lookahead against visible player retaliation.
`tools/ai_trace_report.gd` generates `docs/progress/ai_trace_report.md` through
`AIController.plan_trace_for_unit()` so AI diagnostics stay tied to the runtime
scoring path, including primary/secondary objective score splits and fire-support
mark scores.

## Campaign

`CampaignManager` stores campaign progress and roster snapshots in the campaign save. A campaign battle can:

- restore XP/rank/general assignments before battle
- save survivors after battle
- advance progress only on victory
- grant lounge resources when progress advances

`LoungeManager` spends resources on:

- general upgrades
- tech upgrades

These upgrades are applied to player units before battle.

## Conquest

Conquest is a strategic wrapper around the same tactical battle loop.

Files:

- `data/conquest_map.json`: countries, regions, owners, production, graph.
- `ConquestCatalog`: region -> scenario mapping and country -> side mapping.
- `ConquestManager`: ownership, transfer, end-turn and battle-result resolution.
- `ConquestBattleSetup`: reuses a themed scenario's terrain while replacing factions, rosters and victory rules.

Player-fought tactical flow:

1. Player attacks choose a friendly source and adjacent enemy target; enemy-phase attacks on player regions pause for a defensive battle.
2. `conquest.gd` selects the tactical scenario mapped to the target or defended region.
3. `GameState.pending_conquest_battle` records the attacking garrison, generated defenders, country ids, display names, colors and role (`attack` or `defend`).
4. Briefing shows generated conquest matchup text plus the themed scenario's terrain notes.
5. Deployment applies `ConquestBattleSetup`; enemies start on-map, player units start unplaced, and every player unit must be deployed inside the conquest zone before battle can start.
6. Battle applies the same `ConquestBattleSetup` before building units, then deployment overrides move the placed player units to their chosen hexes.
7. Result panel returns to conquest.
8. `ConquestManager.resolve_battle_result` or `resolve_defense_result` updates region owner, strength and surviving garrisons.

AI-vs-AI conquest moves still use deterministic strategic resolution during `end_turn`.

## Validation

`tools/validate_fast.sh`:

- Godot 4.2 project-feature gate
- JSON syntax checks
- Python compile checks
- `tools/validate_data.py`
- balance report
- scenario report
- scenario report smoke checks
- scenario probe
- scenario breach-path smoke checks
- tutorial probe
- `git diff --check`

`tools/validate_data.py` catches:

- unknown unit/terrain/general/faction references
- out-of-bounds coordinates
- duplicate starting unit coordinates
- invalid victory targets
- campaign references to missing scenarios
- conquest owner/neighbor/production/coordinate errors
- non-reciprocal conquest neighbors

`tools/validate.sh` adds the Godot AI trace report generator and
`bash tests/run_all.sh`.

Headless GDScript coverage currently includes combat, AI, pathfinding, visibility, campaign, conquest, deployment, lounge, reinforcements, UI smoke, and formatter behavior.

## UI Smoke Coverage

`tests/test_ui_smoke.gd` loads all major screens headlessly:

- main menu
- scenario select
- briefing
- deployment
- battle
- campaign
- lounge
- conquest

It checks required nodes and collapsed visible controls. This is intended to catch broken node paths, missing preloads and obvious UI regressions early.

`tests/test_ui_layout.gd` checks the same major screens at the supported desktop
viewport contract (`1280x720` and `1366x768`) and fails when visible containers,
buttons, labels, panels or scroll views leave the viewport. Scroll contents are
allowed to extend inside their scroll container. It also verifies the tactical
camera starts zoomed out enough for large battle/deployment maps while preserving
readable zoom on small tutorial maps.

`tests/test_ui_workflows.gd` drives representative UI paths headlessly: scenario
filtering, briefing, deployment selection, battle action prompting, campaign
selection, lounge upgrade list rendering and order-independent conquest region
selection.

## Adding A Feature

Typical touch list:

1. Add data fields if needed.
2. Add focused helper logic under `scripts/combat`, `scripts/grid`, `scripts/scenario` or `scripts/turn`.
3. Wire the scene controller.
4. Add a targeted GDScript test.
5. Run `tools/validate.sh`.

Keep unrelated refactors out of feature commits.
