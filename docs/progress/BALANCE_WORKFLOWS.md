# Balance Workflows

This project should treat balance as a repeatable workflow, not a one-off stat edit.

## Workflow 1: Numeric Diagnosis

Use `python3 tools/balance_report.py` to regenerate `docs/progress/balance_report.md`.
Use `python3 tools/balance_report.py --baseline docs/progress/baselines/units_pre_balance_patch.json`
when reviewing the first balance patch against the pre-patch catalog.

The generated report covers:

- Unit catalog values.
- Damage and counter matrices.
- Terrain and dig-in damage matrices.
- Suppression / dig-in break matrix (`Sx/Dy`) for town + dig-in targets.
- Hits-to-kill under plain and town + dig-in 3 conditions.
- Optional baseline deltas for stat changes, damage changes, and hits-to-kill changes.
- Scenario unit and terrain exposure.
- Known rule risks.

This workflow should run before and after every proposed stat patch.

## Workflow 1.5: Validation Hook

Use `tools/validate_fast.sh` for validation that does not launch Godot:

- Godot 4.2 project-feature gate.
- JSON validation for unit catalogs.
- Python syntax checks for report, probe and validator tools.
- Regeneration of balance and scenario reports.
- Scenario balance report smoke checks for urban breach diagnostics.
- Regeneration of scenario probe report.
- Scenario probe smoke checks for breach-path diagnostics.
- Regeneration of tutorial probe report.
- `git diff --check`.

Use `tools/validate.sh` for the full standard validation sequence:

- Everything in `tools/validate_fast.sh`.
- `bash tests/run_all.sh`.

Use `tools/install_hooks.sh` to install a local git `pre-commit` hook that runs
`tools/validate.sh` before every commit.

## Workflow 2: Rule Semantics

Current rules established before large number changes:

- Direct attack target selection requires current visibility and LOS.
- Indirect attack target selection requires current visibility but ignores LOS blockers.
- `indirect` means the unit cannot counter-attack while defending; it does not grant close-range immunity when attacking.
- ZoC cost is part of both movement range and path reconstruction.
- Damaging attacks apply suppression through `CombatEffects`; MG teams and artillery are the primary pinning sources.
- Damaging indirect fire gets +1 suppression when a same-faction light tank has LOS and vision to the target.
- Pinned units cannot overwatch or build dig-in and do not project ZoC; heavier suppression reduces movement/attack, indirect fire strips one dig-in level on damaging hits, and engineers strip up to two dig-in levels on damaging attacks.
- Rally spends the unit's action to recover suppression; defensive cover improves the recovery amount.

These semantics materially affect artillery, AT guns, overwatch, and fog-of-war balance.

## Workflow 3: Role Differentiation

Target identities:

- Infantry: durable terrain holder and ZoC anchor.
- MG team: anti-infantry overwatch and static fire support.
- AT gun: anti-armor specialist with weak soft-target pressure.
- Light tank: scouting, flanking, capture pressure, wounded-target cleanup.
- Medium tank: general-purpose armored mainstay.
- Artillery: long-range suppression with clear close-range vulnerability.
- Engineer: close assault support that can strip up to two dig-in levels from entrenched defenders, but still has low raw damage and must accept counter-risk.

## Workflow 4: Scenario Pass

Use `python3 tools/scenario_balance_report.py` to regenerate
`docs/progress/scenario_balance_report.md`.
Use `python3 tools/scenario_probe.py` to regenerate
`docs/progress/scenario_probe.md` for suppression sources, artillery coverage,
spotter coverage, breach-path distance, terrain-aware breach tempo, artillery
reposition coverage, objective pressure, and reinforcement deltas.

Evaluate scenarios in this order:

1. `03_stalingrad_1942`: town density and dig-in durability.
2. `05_bastogne_1944`: survival pacing and reinforcement timing.
3. `04_kursk_1943`: armor versus AT-gun interaction.
4. `02_kiev_1941`: artillery dominance and screening requirements.
5. `01_sedan_1940`: river/forest breakthrough tempo.

Urban breach gates before scenario edits:

- Check `urban breach tools` in `scenario_balance_report.md` before changing rosters.
- `03_stalingrad_1942` now gives the Axis one engineer and one artillery unit, and the engineer starts closer to the central ruins (`eng min 12`, `eng turns 4`), but artillery still covers no breach targets (`art 0/6`); playtest whether the engineer survives and creates real breach decisions before further roster or turn-clock changes.
- `east_10_berlin_1945` gives the Soviet assault group one engineer and one artillery unit, and the engineer starts closer to the western approach (`eng min 12`, `eng turns 4`), but artillery still covers no breach targets (`art 0/3`); tune turns or defenders only after confirming the engineer survives and reaches dig-in targets in time.
- Do not treat MG teams as breach tools. They are suppression support for the assault sequence.

## Workflow 5: AI Compatibility

After rule or stat changes, inspect whether AI scoring still understands the new roles.

Current role-shaping pass:

- Light tanks get a scouting-position bonus when no enemy is currently visible.
- AT guns prefer armored targets over soft targets when damage is otherwise close.
- Artillery avoids close positions near known enemies.
- Engineers prefer entrenched urban/high-cover targets when their attack would remove dig-in.
- Engineers can also move toward visible entrenched/high-cover breach targets before they are already in attack range.
- Attack value includes suppression and dig-in break, so AI can prefer pinning/siege hits over equal raw damage.
- Attack value includes light-tank spotter support for artillery, so scouting can break raw-damage ties.
- Capture factions bias movement toward their target hex.
- Suppressed units can choose Rally when recovery is worth more than other actions.

Likely follow-up:

- Revisit overwatch scoring if MG teams become the premier reaction-fire unit.
