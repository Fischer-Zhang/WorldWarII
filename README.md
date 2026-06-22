# WorldWarII — 戰術六角格戰棋

> 二戰戰術級交戰回合制戰棋。資料驅動架構、確定性戰鬥模型、啟發式 AI 含三種性格,4 個歷史戰役關卡。**Godot 4 + 純 GDScript**。

[![Tests](https://img.shields.io/badge/tests-32%2F32-brightgreen)]() [![Engine](https://img.shields.io/badge/Godot-4.2%2B-blue)]() [![License](https://img.shields.io/badge/license-MIT-lightgrey)]()

<!-- Drop screenshot in docs/screenshots/03_sedan_objective.png to populate -->
![Sedan 1940 — objective pulse on the target town, German Panzer line ready to advance](docs/screenshots/03_sedan_objective.png)

---

## What it is

A small, focused tactical wargame inspired by *Panzer General* and *Advance Wars*. You command WW2-era infantry, armor and artillery on a hex grid, completing scenarios with distinct victory conditions across the European theatre.

The project was built as a **month-scale portfolio piece** with an explicit constraint: keep the rules and AI small enough to read, and spend the saved time on **scenario authoring**, **deterministic systems** and **game-feel polish**.

### Built-in scenarios

| # | Title | Mechanic spotlight |
|---|---|---|
| 1 | **色當突破 1940** | Capture-objective + terrain costs (Ardennes forest, Meuse crossings) |
| 2 | **基輔包圍戰 1941** | Indirect-fire artillery (range 3, can fire over LOS blockers) |
| 3 | **史達林格勒巷戰 1942** | Role reversal — player defends; town terrain gives +3 defense |
| 4 | **庫斯克裝甲決戰 1943** | Tank-on-tank `vs_armor` / `armor` interaction with AT-gun defense in depth |
| 5 | **突出部:Bastogne 1944** | Survive-until-relief — scripted reinforcements arrive on turn 7 |

A sandbox scenario for development is also included.

---

## Highlights

- **Data-driven scenarios** — units, terrains, factions and entire battles live in JSON ([data/](data/)). Adding a new battle does **not** touch any `.gd` file.
- **Symmetric fog of war + hex line-of-sight** — units have per-type vision ranges; forests and mountains break LOS. The AI obeys the same fog and keeps a per-faction last-known-position memory of enemies it has seen, so it advances toward your last position rather than cheating.
- **Tactical depth: Zone of Control, Overwatch, Dig In** — slipping past an enemy costs +2 movement, ending a turn watching makes any unit that enters your range take a snap shot, and staying put compounds entrenchment (+1/+2/+3 defense). All three are classic wargame mechanics with one-paragraph rules each.
- **Deterministic combat model** — `max(1, atk + vs_armor − def − terrain_def)` scaled by attacker HP ratio. Same inputs → same damage. Tests can assert exact numbers.
- **AI with three personality presets + three difficulty profiles** — `aggressive` / `defensive` / `hold` per scenario; `easy` / `normal` / `hard` per session. Hard enables a 1-ply lookahead that simulates the player's worst counter-attack and discounts the score.
- **Visual / logic split** — game state mutates immediately; movement tweens, damage popups, death fades, wreckage markers, and audio all play in parallel without blocking the next move.
- **44 GDScript unit tests** running headless via `bash tests/run_all.sh`. Covers hex math, BFS pathfinding (incl. ZoC), combat formula edge cases (incl. dig-in), attack legality, hex line drawing, line-of-sight.
- **~3000 LOC** of GDScript across 19 files. Read it top-to-bottom in an afternoon.

---

## Gameplay flow

```
Main menu  →  Scenario select  →  Briefing  →  Battle  →  Result  →  back to select
```

In-battle interactions:

| Action | How |
|---|---|
| Select your unit | Click it — yellow pulse halo appears, side panel populates with stats |
| See movement range | Blue overlay on reachable hexes (BFS with per-terrain costs) |
| Move | Click a blue hex — unit walks the path hex-by-hex |
| Attack | After moving, red overlay shows enemies in range — click one |
| Pass | After moving, click anywhere off the red overlay |
| End turn | Bottom-right button (or wait for animations and click) |
| Camera | WASD pan / mouse-wheel zoom / middle-click drag |
| Screenshot | F12 → `user://screenshots/` |

---

## Architecture

Full breakdown in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). High level:

```
Battle scene
├── HexMap          tiles, occupancy, range overlays, wreckage, objective pulse
├── Camera          WASD / wheel / drag
├── [Units]         faction-colour circle + type letter + HP bar + selection halo
└── UI              info / status / unit panel / turn banner / end-turn / result

Autoloads
├── DataLoader      JSON catalog loader
├── GameState       inter-scene state
├── AudioBank       lazy .ogg dispatcher (no-ops if file missing)
└── ScreenshotHelper F12 → PNG

Pure logic  (all static, all deterministic)
├── HexCoord        axial coord math
├── Pathfinding     Dijkstra movement range + path reconstruction
├── CombatResolver  damage formula + counter-attack
├── VictoryChecker  eliminate / capture / survive
├── TurnManager     faction rotation + turn count
├── AIController    heuristic move scoring
└── UnitFactory     scenario JSON → instantiated units
```

### Combat formula

```
base   = max(1, attacker.attack
              + (vs_armor if defender.armor > 0 else 0)
              - defender.defense
              - defender_terrain.defense)
damage = max(1, round(base × attacker.hp / attacker.max_hp))
```

Counter-attack at half damage if the defender survives, is within its own range, and is not `indirect: true` (artillery cannot counter while defending). Direct attacks require visibility and LOS; indirect attacks still require a spotted target but can fire over LOS blockers.

### AI heuristic

For every reachable hex (including "stay in place"), the AI scores:

```
score = −distance_to_nearest_enemy            × 1.0
      + best_attack_damage_from_here          × 2.5
      + 5.0 if attack would kill the target           (kill bonus)
      − 0.6 × counter_damage_taken                    (avoid bad trades)
      − exposure_to_enemy_attacks             × 0.5
      + terrain.defense                       × 0.3

× personality_modifier
```

Personality modifiers ship in each scenario JSON. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full breakdown.

---

## Running it

You need **Godot 4.2 or newer**. Linux/macOS/Windows all supported.

```bash
git clone git@github.com:Fischer-Zhang/WorldWarII.git
cd WorldWarII

# Run the game
godot --path .

# Open in editor instead
godot -e .

# Run the headless test suite (no GUI required)
bash tests/run_all.sh
```

### WSL2 caveats

If you see `libasound.so.2: cannot open` on startup, audio falls back to a dummy driver (silent). To enable real audio:

```bash
sudo apt install libasound2 libpulse0
```

CC0 sound effects can then be dropped into [assets/audio/](assets/audio/) — see [assets/audio/README.md](assets/audio/README.md) for filename conventions and sourcing.

---

## Adding a new scenario

1. Copy any file in [data/scenarios/](data/scenarios/) to a new id, e.g. `05_bastogne_1944.json`.
2. Edit the `map.tiles` grid (rectangular `tiles[row][col]`, terrains from [data/terrains.json](data/terrains.json)).
3. Edit `factions[]` (controller `player` or `ai`, optional `ai` personality), `units[]` (positions in odd-r offset), and `victory` (eliminate / capture / survive).
4. Re-launch — it appears in the scenario select automatically.

No code changes required.

---

## Roadmap

**Done**
- [x] Hex grid, BFS movement, combat model, turn cycle
- [x] AI with three personality presets + three difficulty profiles + 1-ply lookahead on Hard
- [x] Zone of Control, Overwatch, Dig In
- [x] 5 historical scenarios + sandbox
- [x] Scheduled reinforcements (Bastogne)
- [x] Symmetric fog of war + line-of-sight + AI last-known-position memory
- [x] Path animation, damage popups, attack lunge, death fade, wreckage markers
- [x] Selection halo, objective pulse, turn-change banner
- [x] Audio scaffolding (works once .ogg files are added)
- [x] 44 unit tests, headless runner

**Open**
- [ ] CC0 art swap (Kenney hex tiles + unit sprites — currently Polygon2D + label)
- [ ] Save / load mid-scenario

---

## Project structure

```
WorldWarII/
├── project.godot
├── README.md                  this file
├── data/
│   ├── units.json             unit catalog
│   ├── terrains.json          terrain catalog
│   └── scenarios/             one file per battle
├── scenes/                    Godot scenes (.tscn)
│   ├── main_menu.tscn
│   ├── scenario_select.tscn
│   ├── briefing.tscn
│   └── battle.tscn
├── scripts/
│   ├── autoload/              DataLoader, GameState, AudioBank, ScreenshotHelper
│   ├── grid/                  hex coord math, hex map renderer, BFS pathfinder
│   ├── units/                 Unit class + factory
│   ├── combat/                damage resolver
│   ├── turn/                  turn manager + AI controller
│   ├── scenario/              victory checker
│   ├── ui/                    camera, menus, damage popup
│   └── battle.gd              battle scene controller (the orchestrator)
├── assets/
│   ├── audio/                 .ogg sound effects (placeholder dir)
│   └── tiles/  units/  ui/    (placeholder dirs for art swap)
├── tests/                     headless GDScript tests + run_all.sh
└── docs/
    ├── ARCHITECTURE.md        system-by-system walkthrough
    ├── DEMO_SCRIPT.md         90s portfolio video script
    └── screenshots/           drop captured PNGs here
```

---

## Credits

- Design + code: built in Godot 4.2 with GDScript.
- Coordinate math: based on [Red Blob Games — Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/) (no code copied, just the formulas).
- Built collaboratively with Claude.

---

## License

MIT (code). Historical scenario content is original; any third-party CC0 audio/art added later inherits its own license.
