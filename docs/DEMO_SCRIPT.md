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
| 0:00 – 0:03 | Title card | Static frame: main menu with "WorldWarII / 戰術六角格戰棋" | `Godot 4 / GDScript` |
| 0:03 – 0:08 | Menu → list | Cursor clicks 「單次作戰」 → scenario select shows difficulty buttons and the 20-battle list | `Single battles · Easy / Normal / Hard AI` |
| 0:08 – 0:12 | Briefing | Brief flash of Sedan 1940 briefing screen | `Data-driven scenarios — JSON, no code per battle` |
| **0:12 – 0:26** | **Scenario 1 — Sedan 1940** | Open with the yellow pulsing objective hex. Move a Pz.IV across road, attack a French AT-gun → see damage popup, wreckage, HP bar drop. End turn → AI defensive AI shuffles French line. | `Hex-based movement · Terrain costs · Capture objective pulse` |
| **0:26 – 0:40** | **Scenario 2 — Kiev 1941** | Show artillery's 3-tile range overlay. Fire at distant Soviet T-34 from outside its range, so there is no counter. Tanks close in for kill. | `Range 3 indirect-fire artillery · spotted targets over blockers` |
| **0:40 – 0:52** | **Scenario 3 — Stalingrad 1942** | Player as Soviet defender. Show city blocks (+3 defense tint). German tank attacks Guards infantry → infantry survives in town, counter-attacks. | `Role reversal: defending the city · Town terrain +3 defense` |
| **0:52 – 1:08** | **Scenario 4 — Kursk 1943** | Wide camera over the tank duel. Tiger / Panther / T-34 trading shots. AT-gun reveals a Panzer's vs_armor weakness. One unit dies, scorch wreckage marker persists into next turn. | `Deterministic combat · vs_armor / armor mechanic · Heuristic AI` |
| 1:08 – 1:20 | Conquest → battle | Open 「征服」, select a friendly region and adjacent enemy region, click 「攻擊」, cut to the tactical briefing that launches from the map. | `Conquest attacks resolve as real hex battles` |
| 1:20 – 1:25 | Victory screen | Victory modal pops up. "德軍裝甲軍 獲勝!" then returns to conquest map with ownership updated. | `Battle result updates the world map` |
| 1:25 – 1:30 | Code montage / end card | Quick pan across `scripts/` and `tools/validate_data.py`, then end card | `102 unit tests · data validator · github.com/Fischer-Zhang/WorldWarII` |

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
| `02_scenario_select.png` | Scenario list with difficulty selector |
| `03_sedan_objective.png` | Sedan with yellow objective pulse on the target town |
| `04_combat_resolution.png` | Mid-combat with damage popup visible |
| `05_kursk_wide.png` | Kursk tank duel, wide camera |
| `06_victory.png` | Victory modal |
| `07_conquest.png` | Conquest map with attack target selected |

---

## Suggested narrative beats

The video doesn't need narration but the on-screen captions should make these points in this order:

1. **What** — turn-based hex wargame in Godot 4 with 20 historical scenarios.
2. **Tech bones** — data-driven (JSON scenarios), deterministic combat, BFS movement.
3. **Per-scenario mechanic spotlight** — each clip showcases ONE distinct system:
   - Sedan → terrain + capture objective
   - Kiev → artillery range / indirect fire
   - Stalingrad → role reversal + town defense modifier
   - Kursk → armor vs anti-armor interaction
4. **AI** — surface the fact that the AI's behaviour shifts per scenario (defensive at Sedan, aggressive at Stalingrad, holding at Kiev).
5. **Meta layer** — conquest attacks feed into the same tactical battle loop.
6. **Code/tests** — end on a quick code pan + `102/102` tests passing plus data validation.

---

## Pacing notes

- 90 seconds is **tight**. Resist the urge to explain rules in-video. Captions, not voice-over.
- Cut **before** an animation finishes if it's recognisable in the first 60%. Tight cuts feel deliberate.
- Hold the victory modal on screen for at least 1.5 seconds — it's the closing punch.
- If you go over time, drop Stalingrad first (Sedan + Kiev + Kursk show the widest mechanic variety together).
