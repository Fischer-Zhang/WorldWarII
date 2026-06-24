# WorldWarII

Turn-based WW2 tactical hex wargame built in **Godot 4.2+ / GDScript**.

[![Tests](https://img.shields.io/badge/tests-118%2F118-brightgreen)]() [![Engine](https://img.shields.io/badge/Godot-4.2%2B-blue)]() [![License](https://img.shields.io/badge/license-MIT-lightgrey)]()

![Sedan 1940 objective pulse](docs/screenshots/03_sedan_objective.png)

## What It Is

WorldWarII is a compact tactical wargame inspired by *Panzer General* and *Advance Wars*: move infantry, armor, guns and artillery across hex maps, exploit terrain, break objectives, and carry campaign progress through a light strategic layer.

The project is intentionally data-driven. Units, terrain, scenarios, campaigns and conquest regions live in JSON. The code owns rules and orchestration; content owns the war.

## Current Game Modes

| Mode | Flow | What matters |
|---|---|---|
| Single Battle | Main Menu -> Scenario Select -> Briefing -> Deployment -> Battle | Pick any scenario, choose AI difficulty, assign generals and deploy before fighting. |
| Campaign | Campaign Map -> Lounge -> Deployment -> Battle -> Result | Campaign progress persists roster XP and general assignment; victories grant lounge upgrade points. |
| Conquest | World Map -> Real Hex Battle -> World Map Result | Region attacks launch normal tactical battles. Region strength and production become battle context: attacker veteran edge, defender dig-in, and production reserves. |

## Highlights

- **20 historical scenarios + sandbox** across early war, eastern front and western front.
- **Scenario category tabs** for faster single-battle selection.
- **Pre-battle deployment** with scenario-scoped unit placement, general reassignment and upgrade breakdown.
- **Deterministic combat**: same position, HP, terrain and modifiers always resolve the same way.
- **Shared attack legality** for player and AI through `CombatRules`.
- **Fog of war + LOS** with AI last-known-position memory.
- **ZoC, overwatch, dig-in, suppression and rally** layered into movement and action economy.
- **Historical generals, veteran XP, lounge upgrades and tech upgrades** routed through a shared modifier pipeline.
- **Conquest battles are real tactical battles**, not a separate mini-simulator.
- **118 headless GDScript checks + static validators**, including UI smoke coverage for all major screens.

## Gameplay Loop

```text
Main Menu
  -> Single Battle -> Scenario Select -> Briefing -> Deployment -> Battle -> Result
  -> Campaign      -> Campaign Map -> Lounge/Deployment -> Battle -> Result
  -> Conquest      -> World Map -> Briefing/Deployment -> Battle -> World Map Result
```

In battle:

| Action | Input |
|---|---|
| Select unit | Click a friendly unit. |
| Move | Click a blue reachable hex. |
| Attack | After moving/selecting, click a red target. |
| Overwatch | Use `進入警戒`. |
| Rally | Use `整隊` when suppressed. |
| End turn | Button at the bottom-right. |
| Camera | WASD, mouse wheel, middle-drag. |
| Screenshot | F12 to `user://screenshots/`. |

## Systems In Brief

**Combat formula**

```text
base = max(1, attack + vs_armor_if_target_armored - defense - terrain_defense)
damage = max(1, round(base * attacker_hp / attacker_max_hp))
```

Combat modifiers come from veteran rank, generals, general upgrades, tech upgrades and temporary skill effects. Deployment shows detailed source lines; the battle info panel shows compact final values plus source summary.

**AI**

AI scores movement candidates by distance, terrain, exposure, attack value, kill value, counter-damage risk, role shaping and objective pressure. Hard difficulty enables a one-ply lookahead against visible player retaliation.

**Conquest**

Conquest region data is stored in `data/conquest_map.json`. Player attacks choose an existing tactical scenario through `ConquestCatalog`, pass region strength/production through `ConquestBattleContext`, and apply battle results back to ownership and strength through `ConquestManager`.

## Running

```bash
godot --path .
```

Run the full validation suite:

```bash
tools/validate.sh
```

Fast data/report validation without Godot:

```bash
tools/validate_fast.sh
```

Individual headless tests:

```bash
bash tests/run_all.sh
```

## Validation Coverage

`tools/validate.sh` runs:

- JSON/data validator: unknown refs, bounds, duplicate unit coordinates, campaign references, conquest region graph integrity.
- Balance reports: unit matrix, scenario pressure report, tactical probe.
- 118 GDScript checks: combat, AI, pathfinding, visibility, campaign, conquest, deployment, lounge, reinforcements, UI smoke, formatter behavior.

The UI smoke test loads these screens headlessly: main menu, scenario select, briefing, deployment, battle, campaign, lounge and conquest.

## Adding A Scenario

1. Copy a JSON file in `data/scenarios/`.
2. Change `id`, `title`, `briefing`, `map`, `factions`, `units`, `victory`.
3. Use odd-r offset coordinates in JSON; runtime converts to axial hex coordinates.
4. Run `tools/validate_fast.sh`.
5. Launch the game. The scenario appears automatically in the single-battle list.

## Project Layout

```text
data/       JSON units, terrains, generals, campaigns, conquest map, scenarios
scenes/     Godot scenes
scripts/    autoloads, grid, units, combat, turn AI, scenario managers, UI
tests/      headless GDScript tests
tools/      validators and reports
docs/       architecture, demo script, progress reports, screenshots
```

Detailed system notes: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

Demo capture plan: [docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md)

## Roadmap

Done:

- Hex movement, deterministic combat, turn cycle.
- Fog of war, LOS, ZoC, overwatch, dig-in, suppression, rally.
- Single battle, campaign, lounge upgrades and conquest-to-battle flow.
- Deployment setup and upgrade visibility.
- Conquest battle context from strategic regions.
- Per-region conquest battlefields — one themed map per region, with its terrain note surfaced in the briefing.
- Headless validators and UI smoke coverage.

Open:

- Save/load mid-scenario.
- Art replacement for tiles and units.
- Better in-game tutorial/onboarding.

## License

MIT for code. Historical scenario text is original. Any future third-party audio/art should keep its own license notes.
