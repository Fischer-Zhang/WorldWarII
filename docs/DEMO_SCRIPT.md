# Demo video script — 90s portfolio cut

Target length: **90 seconds**. One continuous play-through edit, no narration (just on-screen captions). Background music optional (CC0 WW2-era march works).

Aim for the viewer to walk away with:
1. *What it is* — within 5 seconds.
2. *That it has depth* — distinct mechanics surfaced per scenario.
3. *That it's polished* — animations / damage popups / wreckage visible in cuts.

---

## Shot list

| Time | Shot | Content | Caption (Chinese / English) |
|---|---|---|---|
| 0:00 – 0:03 | Title card | Static frame: main menu with "WorldWarII / 戰術六角格戰棋" | `Godot 4 / GDScript / ~2400 lines` |
| 0:03 – 0:08 | Menu → list | Cursor clicks 「開始戰役」 → scenario select shows 4 historical battles | `Data-driven scenarios — JSON, no code per battle` |
| 0:08 – 0:12 | Briefing | Brief flash of Sedan 1940 briefing screen | `Historical scenarios with bespoke briefings` |
| **0:12 – 0:28** | **Scenario 1 — Sedan 1940** | Open with the yellow pulsing objective hex. Move a Pz.IV across road, attack a French AT-gun → see damage popup, wreckage, HP bar drop. End turn → AI defensive AI shuffles French line. | `Hex-based movement · Terrain costs · Capture objective pulse` |
| **0:28 – 0:44** | **Scenario 2 — Kiev 1941** | Show artillery's 3-tile range overlay. Fire at distant Soviet T-34 from outside its range, so there is no counter. Tanks close in for kill. | `Range 3 indirect-fire artillery · spotted targets over blockers` |
| **0:44 – 0:58** | **Scenario 3 — Stalingrad 1942** | Player as Soviet defender. Show city blocks (+3 defense tint). German tank attacks Guards infantry → infantry survives in town, counter-attacks. | `Role reversal: defending the city · Town terrain +3 defense` |
| **0:58 – 1:18** | **Scenario 4 — Kursk 1943** | Wide camera over the tank duel. Tiger / Panther / T-34 trading shots. AT-gun reveals a Panzer's vs_armor weakness. One unit dies, scorch wreckage marker persists into next turn. | `Determinstic combat · vs_armor / armor mechanic · Heuristic AI` |
| 1:18 – 1:25 | Victory screen | Victory modal pops up. "🏆 德軍裝甲軍 獲勝!" | `Victory: capture target by turn 12` |
| 1:25 – 1:30 | Code montage / end card | Quick pan across `scripts/` tree in editor, then end card | `24 GDScript files · 79 unit tests · github.com/Fischer-Zhang/WorldWarII` |

---

## Capturing the footage

### Recording

- Use **OBS Studio** (free, runs on Linux/Mac/Win) at **1280×720 / 30 fps**. The project's default viewport.
- Capture the game window, not the editor — set `Capture Method = "Xcomposite Capture"` (Linux) or window capture (Win).
- Record in MP4 (h264) at high quality; edit later.

### Editing

- **Resolve / DaVinci Resolve Free** is the easiest free editor. Kdenlive on Linux also works.
- Cut to each milestone above. Speed-up boring camera-pan moments by 1.5–2x.
- Add 2-second caption overlays in the lower-third using the table's caption column.
- Background audio: search OpenGameArt for CC0 WW2 march / military drum — keep at low volume so popups stand out.

### Screenshots for the README

In-game press **F12** to capture the current viewport. Files land in:

```
~/.local/share/godot/app_userdata/WorldWarII/screenshots/    (Linux/WSL)
%APPDATA%/Godot/app_userdata/WorldWarII/screenshots/         (Windows)
```

Copy the keepers into `docs/screenshots/` and reference from `README.md`. Suggested set:

| Filename | Shot |
|---|---|
| `01_main_menu.png` | Main menu, full-bleed |
| `02_scenario_select.png` | All 4 scenarios listed |
| `03_sedan_objective.png` | Sedan with yellow objective pulse on the target town |
| `04_combat_resolution.png` | Mid-combat with damage popup visible |
| `05_kursk_wide.png` | Kursk tank duel, wide camera |
| `06_victory.png` | Victory modal |

---

## Suggested narrative beats

The video doesn't need narration but the on-screen captions should make these points in this order:

1. **What** — turn-based hex wargame in Godot 4 with 4 historical scenarios.
2. **Tech bones** — data-driven (JSON scenarios), deterministic combat, BFS movement.
3. **Per-scenario mechanic spotlight** — each clip showcases ONE distinct system:
   - Sedan → terrain + capture objective
   - Kiev → artillery range / indirect fire
   - Stalingrad → role reversal + town defense modifier
   - Kursk → armor vs anti-armor interaction
4. **AI** — surface the fact that the AI's behaviour shifts per scenario (defensive at Sedan, aggressive at Stalingrad, holding at Kiev).
5. **Code/tests** — end on a quick code pan + `79/79` tests passing.

---

## Pacing notes

- 90 seconds is **tight**. Resist the urge to explain rules in-video. Captions, not voice-over.
- Cut **before** an animation finishes if it's recognisable in the first 60%. Tight cuts feel deliberate.
- Hold the victory modal on screen for at least 1.5 seconds — it's the closing punch.
- If you go over time, drop Stalingrad first (Sedan + Kiev + Kursk show the widest mechanic variety together).
