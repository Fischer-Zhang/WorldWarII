#!/usr/bin/env python3
"""Generate a deterministic balance report from the data catalogs.

The script intentionally mirrors CombatResolver instead of importing Godot.
It gives designers a stable baseline that can be re-run after every unit or
terrain tweak without requiring a working headless Godot runtime.
"""

from __future__ import annotations

import argparse
import collections
import glob
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
UNITS_PATH = ROOT / "data" / "units.json"
TERRAINS_PATH = ROOT / "data" / "terrains.json"
SCENARIOS_GLOB = str(ROOT / "data" / "scenarios" / "*.json")
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "balance_report.md"

TERRAIN_CASES = [
    ("plain", "plain", 0),
    ("forest", "forest", 0),
    ("town", "town", 0),
    ("town_dig2", "town", 2),
    ("town_dig3", "town", 3),
]

URBAN_BREACH_DEFENDERS = ["infantry", "mg_team", "at_gun", "medium_tank"]
URBAN_BREACH_DIG_IN = 3
URBAN_BREACH_MAX_HITS = 12

SUPPRESSION_BY_TYPE = {
    "infantry": 1,
    "mg_team": 3,
    "at_gun": 1,
    "light_tank": 1,
    "medium_tank": 1,
    "artillery": 3,
}


@dataclass(frozen=True)
class CombatResult:
    damage: int
    counter: int
    suppression: int
    dig_in_loss: int
    defender_dies: bool
    attacker_dies: bool


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def unit_name(unit_id: str, units: dict[str, Any]) -> str:
    return str(units[unit_id].get("name_zh", unit_id))


def compute_damage(
    attacker_id: str,
    defender_id: str,
    units: dict[str, Any],
    terrains: dict[str, Any],
    attacker_hp: int | None = None,
    defender_terrain_id: str = "plain",
    defender_dig_in: int = 0,
    is_counter: bool = False,
    distance: int = 1,
) -> int:
    attacker = units[attacker_id]
    defender = units[defender_id]
    if attacker_hp is None:
        attacker_hp = int(attacker.get("hp", 1))

    armor_bonus = int(attacker.get("vs_armor", 0)) if int(defender.get("armor", 0)) > 0 else 0
    if armor_bonus > 0 and distance >= int(attacker.get("armor_standoff_min_range", 9999)):
        armor_bonus += int(attacker.get("armor_standoff_vs_armor_bonus", 0))
    defender_defense = int(defender.get("defense", 0)) + defender_dig_in
    terrain_defense = int(terrains[defender_terrain_id].get("defense", 0))
    base = max(1, int(attacker.get("attack", 0)) + armor_bonus - defender_defense - terrain_defense)

    hp_ratio = float(attacker_hp) / float(max(1, int(attacker.get("hp", 1))))
    scaled = max(1, round(base * hp_ratio))
    if is_counter:
        scaled = max(1, scaled // 2)
    return scaled


def suppression_for_attack(attacker_id: str, attacker: dict[str, Any], damage: int, defender_dies: bool) -> int:
    if defender_dies or damage <= 0:
        return 0
    base = SUPPRESSION_BY_TYPE.get(attacker_id, 1)
    if bool(attacker.get("indirect", False)):
        base = max(base, 3)
    return base


def dig_in_loss_for_attack(
    attacker_id: str,
    attacker: dict[str, Any],
    damage: int,
    defender_dig_in: int,
) -> int:
    if damage <= 0 or defender_dig_in <= 0:
        return 0
    if attacker_id == "engineer":
        return min(2, defender_dig_in)
    return 1 if bool(attacker.get("indirect", False)) else 0


def resolve(
    attacker_id: str,
    defender_id: str,
    units: dict[str, Any],
    terrains: dict[str, Any],
    attacker_hp: int | None = None,
    defender_hp: int | None = None,
    attacker_terrain_id: str = "plain",
    defender_terrain_id: str = "plain",
    defender_dig_in: int = 0,
    distance: int | None = None,
) -> CombatResult:
    attacker = units[attacker_id]
    defender = units[defender_id]
    if attacker_hp is None:
        attacker_hp = int(attacker.get("hp", 1))
    if defender_hp is None:
        defender_hp = int(defender.get("hp", 1))
    if distance is None:
        distance = int(attacker.get("range", 1))

    damage = compute_damage(
        attacker_id,
        defender_id,
        units,
        terrains,
        attacker_hp=attacker_hp,
        defender_terrain_id=defender_terrain_id,
        defender_dig_in=defender_dig_in,
        distance=distance,
    )
    defender_after = defender_hp - damage
    defender_dies = defender_after <= 0
    suppression = suppression_for_attack(attacker_id, attacker, damage, defender_dies)
    dig_in_loss = dig_in_loss_for_attack(attacker_id, attacker, damage, defender_dig_in)
    counter = 0
    attacker_dies = False

    defender_range = int(defender.get("range", 1))
    if not defender_dies and distance <= defender_range and not bool(defender.get("indirect", False)):
        counter = compute_damage(
            defender_id,
            attacker_id,
            units,
            terrains,
            attacker_hp=defender_after,
            defender_terrain_id=attacker_terrain_id,
            is_counter=True,
            distance=distance,
        )
        attacker_dies = attacker_hp - counter <= 0

    return CombatResult(damage, counter, suppression, dig_in_loss, defender_dies, attacker_dies)


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def terrain_counts(scenario: dict[str, Any]) -> collections.Counter[str]:
    rows = scenario.get("map", {}).get("tiles", [])
    counter: collections.Counter[str] = collections.Counter()
    for row in rows:
        counter.update(str(tile) for tile in row)
    return counter


def scenario_unit_counts(scenario: dict[str, Any]) -> collections.Counter[str]:
    counter: collections.Counter[str] = collections.Counter()
    for unit in scenario.get("units", []):
        counter[str(unit.get("type", ""))] += 1
    for unit in scenario.get("reinforcements", []):
        counter[str(unit.get("type", ""))] += 1
    if "" in counter:
        del counter[""]
    return counter


def table(headers: list[str], rows: list[list[Any]]) -> str:
    out = ["| " + " | ".join(headers) + " |"]
    out.append("| " + " | ".join(["---"] * len(headers)) + " |")
    for row in rows:
        out.append("| " + " | ".join(str(cell) for cell in row) + " |")
    return "\n".join(out)


def unit_stat_table(units: dict[str, Any]) -> str:
    rows: list[list[Any]] = []
    for unit_id, unit in units.items():
        rows.append(
            [
                unit_id,
                unit.get("name_zh", unit_id),
                unit.get("hp", 0),
                unit.get("attack", 0),
                unit.get("defense", 0),
                unit.get("range", 1),
                unit.get("move", 0),
                unit.get("vision", 0),
                unit.get("vs_armor", 0),
                "%s@%s" % (
                    unit.get("armor_standoff_vs_armor_bonus", 0),
                    unit.get("armor_standoff_min_range", ""),
                ) if int(unit.get("armor_standoff_vs_armor_bonus", 0)) > 0 else "",
                unit.get("armor", 0),
                unit.get("overwatch_damage_pct", 50),
                "yes" if unit.get("indirect", False) else "",
            ]
        )
    return table(
        ["id", "name", "hp", "atk", "def", "rng", "move", "vision", "vs armor", "standoff", "armor", "ow%", "indirect"],
        rows,
    )


def damage_matrix(
    units: dict[str, Any],
    terrains: dict[str, Any],
    terrain_id: str,
    dig_in: int,
    include_counter: bool,
) -> str:
    unit_ids = list(units.keys())
    headers = ["atk \\ def"] + [unit_name(unit_id, units) for unit_id in unit_ids]
    rows: list[list[Any]] = []
    for attacker_id in unit_ids:
        row: list[Any] = [unit_name(attacker_id, units)]
        for defender_id in unit_ids:
            result = resolve(
                attacker_id,
                defender_id,
                units,
                terrains,
                defender_terrain_id=terrain_id,
                defender_dig_in=dig_in,
            )
            cell = f"{result.damage}/{result.counter}" if include_counter else result.damage
            row.append(cell)
        rows.append(row)
    return table(headers, rows)


def effect_matrix(units: dict[str, Any], terrains: dict[str, Any], terrain_id: str, dig_in: int) -> str:
    unit_ids = list(units.keys())
    headers = ["atk \\ def"] + [unit_name(unit_id, units) for unit_id in unit_ids]
    rows: list[list[Any]] = []
    for attacker_id in unit_ids:
        row: list[Any] = [unit_name(attacker_id, units)]
        for defender_id in unit_ids:
            result = resolve(
                attacker_id,
                defender_id,
                units,
                terrains,
                defender_terrain_id=terrain_id,
                defender_dig_in=dig_in,
            )
            row.append(f"S{result.suppression}/D{result.dig_in_loss}")
        rows.append(row)
    return table(headers, rows)


def urban_breach_cell(
    attacker_id: str,
    defender_id: str,
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    hp = int(units[defender_id].get("hp", 1))
    dig_in = URBAN_BREACH_DIG_IN
    first_hit: CombatResult | None = None
    hits_to_clear: int | None = None
    hits_to_kill: int | None = None

    for hit in range(1, URBAN_BREACH_MAX_HITS + 1):
        result = resolve(
            attacker_id,
            defender_id,
            units,
            terrains,
            defender_hp=hp,
            defender_terrain_id="town",
            defender_dig_in=dig_in,
        )
        if first_hit is None:
            first_hit = result
        hp -= result.damage
        dig_in = max(0, dig_in - result.dig_in_loss)
        if hits_to_clear is None and dig_in == 0:
            hits_to_clear = hit
        if hp <= 0:
            hits_to_kill = hit
            break

    assert first_hit is not None
    clear_text = str(hits_to_clear) if hits_to_clear is not None else "--"
    kill_text = str(hits_to_kill) if hits_to_kill is not None else f">{URBAN_BREACH_MAX_HITS}"
    return f"{first_hit.damage} dmg S{first_hit.suppression}/D{first_hit.dig_in_loss}; clear {clear_text}; kill {kill_text}"


def urban_breach_matrix(units: dict[str, Any], terrains: dict[str, Any]) -> str:
    defender_ids = [unit_id for unit_id in URBAN_BREACH_DEFENDERS if unit_id in units]
    headers = ["attacker"] + [unit_name(unit_id, units) for unit_id in defender_ids]
    rows: list[list[Any]] = []
    for attacker_id in units.keys():
        row: list[Any] = [unit_name(attacker_id, units)]
        for defender_id in defender_ids:
            row.append(urban_breach_cell(attacker_id, defender_id, units, terrains))
        rows.append(row)
    return table(headers, rows)


def ttk_table(units: dict[str, Any], terrains: dict[str, Any]) -> str:
    unit_ids = list(units.keys())
    rows: list[list[Any]] = []
    for attacker_id in unit_ids:
        for defender_id in unit_ids:
            plain = resolve(attacker_id, defender_id, units, terrains)
            town_dig = resolve(
                attacker_id,
                defender_id,
                units,
                terrains,
                defender_terrain_id="town",
                defender_dig_in=3,
            )
            defender_hp = int(units[defender_id].get("hp", 1))
            rows.append(
                [
                    unit_name(attacker_id, units),
                    unit_name(defender_id, units),
                    plain.damage,
                    ceil_div(defender_hp, plain.damage),
                    town_dig.damage,
                    ceil_div(defender_hp, town_dig.damage),
                ]
            )
    return table(["attacker", "defender", "plain dmg", "plain hits", "town+dig3 dmg", "town+dig3 hits"], rows)


def fmt_delta(value: int | float) -> str:
    if isinstance(value, float):
        if abs(value) < 0.005:
            return "0.00"
        return f"{value:+.2f}"
    if value == 0:
        return "0"
    return f"{value:+d}"


def baseline_delta_section(
    units: dict[str, Any],
    baseline_units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    sections: list[str] = []
    sections.append("## Baseline Delta")
    sections.append("Baseline deltas compare current `data/units.json` against the provided `--baseline` unit catalog.")
    sections.append("### Stat Changes\n\n" + unit_delta_table(units, baseline_units))
    sections.append("### Plain Damage Delta\n\n" + damage_delta_matrix(units, baseline_units, terrains, "plain", 0))
    sections.append("### Hits-To-Kill Delta\n\n" + ttk_delta_table(units, baseline_units, terrains))
    sections.append("### High-Risk TTK Changes\n\n" + high_risk_ttk_changes(units, baseline_units, terrains))
    return "\n\n".join(sections)


def unit_delta_table(units: dict[str, Any], baseline_units: dict[str, Any]) -> str:
    stat_keys = [
        "hp",
        "attack",
        "defense",
        "range",
        "move",
        "vision",
        "vs_armor",
        "armor",
        "armor_standoff_min_range",
        "armor_standoff_vs_armor_bonus",
    ]
    defaults = {"overwatch_damage_pct": 50}
    unit_keys = stat_keys + ["overwatch_damage_pct"]
    rows: list[list[Any]] = []
    for unit_id, unit in units.items():
        if unit_id not in baseline_units:
            rows.append([unit_id, unit.get("name_zh", unit_id), "new unit"])
            continue
        baseline = baseline_units[unit_id]
        changes: list[str] = []
        for key in unit_keys:
            default = defaults.get(key, 0)
            old = int(baseline.get(key, default))
            new = int(unit.get(key, default))
            if old != new:
                changes.append(f"{key} {old}->{new} ({fmt_delta(new - old)})")
        if bool(baseline.get("indirect", False)) != bool(unit.get("indirect", False)):
            changes.append(f"indirect {baseline.get('indirect', False)}->{unit.get('indirect', False)}")
        if changes:
            rows.append([unit_id, unit.get("name_zh", unit_id), "<br>".join(changes)])
    if not rows:
        rows.append(["-", "-", "no stat changes"])
    return table(["id", "name", "changes"], rows)


def damage_delta_matrix(
    units: dict[str, Any],
    baseline_units: dict[str, Any],
    terrains: dict[str, Any],
    terrain_id: str,
    dig_in: int,
) -> str:
    unit_ids = [unit_id for unit_id in units.keys() if unit_id in baseline_units]
    headers = ["atk \\ def"] + [unit_name(unit_id, units) for unit_id in unit_ids]
    rows: list[list[Any]] = []
    for attacker_id in unit_ids:
        row: list[Any] = [unit_name(attacker_id, units)]
        for defender_id in unit_ids:
            current = resolve(
                attacker_id, defender_id, units, terrains,
                defender_terrain_id=terrain_id, defender_dig_in=dig_in,
            )
            baseline = resolve(
                attacker_id, defender_id, baseline_units, terrains,
                defender_terrain_id=terrain_id, defender_dig_in=dig_in,
            )
            row.append(fmt_delta(current.damage - baseline.damage))
        rows.append(row)
    return table(headers, rows)


def ttk_delta_table(
    units: dict[str, Any],
    baseline_units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    rows: list[list[Any]] = []
    unit_ids = [unit_id for unit_id in units.keys() if unit_id in baseline_units]
    for attacker_id in unit_ids:
        for defender_id in unit_ids:
            current = resolve(attacker_id, defender_id, units, terrains)
            baseline = resolve(attacker_id, defender_id, baseline_units, terrains)
            current_hits = ceil_div(int(units[defender_id].get("hp", 1)), current.damage)
            baseline_hits = ceil_div(int(baseline_units[defender_id].get("hp", 1)), baseline.damage)
            delta = current_hits - baseline_hits
            if delta == 0:
                continue
            rows.append([
                unit_name(attacker_id, units),
                unit_name(defender_id, units),
                baseline_hits,
                current_hits,
                fmt_delta(delta),
            ])
    if not rows:
        rows.append(["-", "-", "-", "-", "no plain TTK changes"])
    return table(["attacker", "defender", "baseline hits", "current hits", "delta"], rows)


def high_risk_ttk_changes(
    units: dict[str, Any],
    baseline_units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    rows: list[list[Any]] = []
    unit_ids = [unit_id for unit_id in units.keys() if unit_id in baseline_units]
    for attacker_id in unit_ids:
        for defender_id in unit_ids:
            baseline = resolve(attacker_id, defender_id, baseline_units, terrains)
            current = resolve(attacker_id, defender_id, units, terrains)
            baseline_hits = ceil_div(int(baseline_units[defender_id].get("hp", 1)), baseline.damage)
            current_hits = ceil_div(int(units[defender_id].get("hp", 1)), current.damage)
            if baseline_hits == current_hits:
                continue
            pct = (float(current_hits - baseline_hits) / float(max(1, baseline_hits))) * 100.0
            if abs(pct) < 30.0:
                continue
            rows.append([
                unit_name(attacker_id, units),
                unit_name(defender_id, units),
                baseline_hits,
                current_hits,
                f"{pct:+.0f}%",
            ])
    if not rows:
        rows.append(["-", "-", "-", "-", "no >=30% plain TTK changes"])
    return table(["attacker", "defender", "baseline hits", "current hits", "change"], rows)


def matchup_flags(units: dict[str, Any], terrains: dict[str, Any]) -> str:
    rows: list[list[Any]] = []
    for attacker_id in units.keys():
        non_armor_damage = []
        armor_damage = []
        for defender_id, defender in units.items():
            damage = resolve(attacker_id, defender_id, units, terrains).damage
            if int(defender.get("armor", 0)) > 0:
                armor_damage.append(damage)
            else:
                non_armor_damage.append(damage)
        avg_soft = sum(non_armor_damage) / max(1, len(non_armor_damage))
        avg_armor = sum(armor_damage) / max(1, len(armor_damage))
        rows.append(
            [
                unit_name(attacker_id, units),
                f"{avg_soft:.2f}",
                f"{avg_armor:.2f}",
                f"{(avg_armor - avg_soft):+.2f}",
                note_for_unit(attacker_id, units, avg_soft, avg_armor),
            ]
        )
    return table(["unit", "avg vs soft", "avg vs armor", "armor delta", "diagnostic"], rows)


def note_for_unit(unit_id: str, units: dict[str, Any], avg_soft: float, avg_armor: float) -> str:
    unit = units[unit_id]
    if unit_id == "at_gun" and avg_soft >= 4.0:
        return "AT has high soft-target output"
    if unit_id == "artillery" and avg_armor >= 4.0:
        return "Artillery remains strong into armor"
    if unit_id == "light_tank":
        return "Mobility/vision must justify lower damage"
    if unit_id == "medium_tank":
        return "Baseline main battle unit; many named tanks share this stat"
    if int(unit.get("move", 0)) <= 1:
        return "Role depends heavily on setup and map placement"
    return ""


def scenario_tables(scenarios: list[dict[str, Any]], units: dict[str, Any]) -> str:
    unit_ids = list(units.keys())
    unit_rows: list[list[Any]] = []
    terrain_rows: list[list[Any]] = []
    total_units: collections.Counter[str] = collections.Counter()

    for scenario in scenarios:
        counts = scenario_unit_counts(scenario)
        total_units.update(counts)
        unit_rows.append(
            [scenario.get("id", "")] + [counts.get(unit_id, 0) for unit_id in unit_ids]
        )

        terrain = terrain_counts(scenario)
        tile_total = sum(terrain.values()) or 1
        dominant = ", ".join(
            f"{terrain_id} {count / tile_total:.0%}"
            for terrain_id, count in terrain.most_common(3)
        )
        terrain_rows.append([scenario.get("id", ""), tile_total, dominant])

    total_row = ["TOTAL"] + [total_units.get(unit_id, 0) for unit_id in unit_ids]
    unit_rows.append(total_row)

    return "\n\n".join(
        [
            table(["scenario"] + [unit_name(unit_id, units) for unit_id in unit_ids], unit_rows),
            table(["scenario", "tiles", "dominant terrain"], terrain_rows),
        ]
    )


def rule_risk_section() -> str:
    rows = [
        [
            "Attack visibility",
            "Resolved: direct attacks require visibility + LOS; indirect attacks require visibility and ignore LOS blockers.",
            "Keep future attack helpers routed through CombatRules.",
        ],
        [
            "indirect semantics",
            "Resolved: indirect units cannot counter while defending, but close indirect attacks can still be countered.",
            "Preserve this distinction in UI text and combat tests.",
        ],
        [
            "ZoC path reconstruction",
            "Resolved: movement range and path reconstruction share the same terrain + active-ZoC step cost; pinned units do not project ZoC.",
            "Keep new pathfinding callsites passing occupied + mover_faction.",
        ],
        [
            "Town + dig-in",
            "Town defense 3 plus dig-in 3 still pushes many attacks to the 1-damage floor, but artillery strips one dig-in level and engineers strip up to two on damaging hits.",
            "Monitor scenario_probe.md breach paths plus playtests to confirm Stalingrad/Berlin create breach decisions instead of static 1-damage stalls.",
        ],
        [
            "MG overwatch",
            "MG teams use overwatch_damage_pct 100 while default reaction fire remains 50, making MGs the premier lane-denial unit.",
            "Keep AI overwatch scoring and help text aligned with unit-data reaction-fire percentages.",
        ],
    ]
    return table(["risk", "why it matters", "next action"], rows)


def generate_report(baseline_units: dict[str, Any] | None = None) -> str:
    units = load_json(UNITS_PATH)
    terrains = load_json(TERRAINS_PATH)
    scenarios = [load_json(Path(path)) for path in sorted(glob.glob(SCENARIOS_GLOB))]

    sections: list[str] = []
    sections.append("# Balance Report\n")
    sections.append(
        "Generated from `data/units.json`, `data/terrains.json`, and `data/scenarios/*.json`. "
        "Damage mirrors `scripts/combat/combat_resolver.gd`: attack plus armor bonus, minus defender defense, terrain, and dig-in; minimum 1; scaled by attacker HP."
    )
    sections.append("## Unit Catalog\n\n" + unit_stat_table(units))
    sections.append("## Plain Damage / Counter\n\nCell format is `damage/counter`.\n\n" + damage_matrix(units, terrains, "plain", 0, True))
    for label, terrain_id, dig_in in TERRAIN_CASES[1:]:
        sections.append(f"## Damage Matrix: {label}\n\n" + damage_matrix(units, terrains, terrain_id, dig_in, False))
    sections.append(
        "## Suppression / Dig-In Break Matrix\n\n"
        "Cell format is `Sx/Dy`: suppression applied to a surviving defender and dig-in levels stripped on town+dig2. "
        "MG teams and indirect fire are the primary pinning tools; indirect fire strips one dig-in level, while engineers strip up to two levels when they damage an entrenched target.\n\n"
        + effect_matrix(units, terrains, "town", 2)
    )
    sections.append(
        "## Urban Breach Baseline\n\n"
        "Town breach cells simulate repeated attacks into town+dig3 without defender recovery. "
        "Cell format is first-hit `damage Sx/Dy`, then hits to clear all dig-in and hits to kill the defender within the simulation cap.\n\n"
        + urban_breach_matrix(units, terrains)
    )
    sections.append("## Hits To Kill\n\n" + ttk_table(units, terrains))
    if baseline_units is not None:
        sections.append(baseline_delta_section(units, baseline_units, terrains))
    sections.append("## Role Diagnostics\n\n" + matchup_flags(units, terrains))
    sections.append("## Scenario Exposure\n\n" + scenario_tables(scenarios, units))
    sections.append("## Rule Risks\n\n" + rule_risk_section())
    sections.append(
        "## Recommended Next Pass\n\n"
        "1. Run this report before and after every candidate stat patch, then compare role diagnostics plus hits-to-kill.\n"
        "2. Use the Urban Breach Baseline, scenario breach tools, and scenario_probe.md breach paths before changing Stalingrad or Berlin rosters or turn clocks.\n"
        "3. Validate whether engineers survive the approach and open town+dig3 positions; Stalingrad/Berlin now have closer engineer starts but still lack artillery breach coverage, so playtest before further defender nerfs.\n"
        "4. Validate Rally and suppression tempo in Stalingrad, Bastogne, Kursk, Kiev, then Sedan, because those scenarios stress the highest-risk mechanics in order.\n"
    )
    return "\n\n".join(sections) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"report path, default: {DEFAULT_OUTPUT.relative_to(ROOT)}",
    )
    parser.add_argument(
        "--baseline",
        type=Path,
        help="optional baseline units.json to compare against current data/units.json",
    )
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    baseline_units = None
    if args.baseline is not None:
        baseline_path = args.baseline if args.baseline.is_absolute() else ROOT / args.baseline
        baseline_units = load_json(baseline_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_report(baseline_units), encoding="utf-8")
    print(f"Wrote {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
