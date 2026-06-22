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


@dataclass(frozen=True)
class CombatResult:
    damage: int
    counter: int
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
) -> int:
    attacker = units[attacker_id]
    defender = units[defender_id]
    if attacker_hp is None:
        attacker_hp = int(attacker.get("hp", 1))

    armor_bonus = int(attacker.get("vs_armor", 0)) if int(defender.get("armor", 0)) > 0 else 0
    defender_defense = int(defender.get("defense", 0)) + defender_dig_in
    terrain_defense = int(terrains[defender_terrain_id].get("defense", 0))
    base = max(1, int(attacker.get("attack", 0)) + armor_bonus - defender_defense - terrain_defense)

    hp_ratio = float(attacker_hp) / float(max(1, int(attacker.get("hp", 1))))
    scaled = max(1, round(base * hp_ratio))
    if is_counter:
        scaled = max(1, scaled // 2)
    return scaled


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
    )
    defender_after = defender_hp - damage
    defender_dies = defender_after <= 0
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
        )
        attacker_dies = attacker_hp - counter <= 0

    return CombatResult(damage, counter, defender_dies, attacker_dies)


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
                unit.get("armor", 0),
                "yes" if unit.get("indirect", False) else "",
            ]
        )
    return table(
        ["id", "name", "hp", "atk", "def", "rng", "move", "vision", "vs armor", "armor", "indirect"],
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
            "Keep future attack helpers routed through Battle._can_attack_target or the same rule.",
        ],
        [
            "indirect semantics",
            "Resolved: indirect units cannot counter while defending, but close indirect attacks can still be countered.",
            "Preserve this distinction in UI text and combat tests.",
        ],
        [
            "ZoC path reconstruction",
            "Resolved: movement range and path reconstruction share the same terrain + ZoC step cost.",
            "Keep new pathfinding callsites passing occupied + mover_faction.",
        ],
        [
            "Town + dig-in",
            "Town defense 3 plus dig-in 3 pushes most attacks to the 1-damage floor.",
            "Consider max dig-in 2, siege traits, or partial artillery/AT entrenchment bypass.",
        ],
    ]
    return table(["risk", "why it matters", "next action"], rows)


def generate_report() -> str:
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
    sections.append("## Hits To Kill\n\n" + ttk_table(units, terrains))
    sections.append("## Role Diagnostics\n\n" + matchup_flags(units, terrains))
    sections.append("## Scenario Exposure\n\n" + scenario_tables(scenarios, units))
    sections.append("## Rule Risks\n\n" + rule_risk_section())
    sections.append(
        "## Recommended Next Pass\n\n"
        "1. Run this report before and after every candidate stat patch, then compare role diagnostics plus hits-to-kill.\n"
        "2. Start with narrow candidate changes: lower AT soft damage, lower artillery armor effectiveness, and give light tanks a stronger scouting identity.\n"
        "3. Validate those changes in Stalingrad, Bastogne, Kursk, Kiev, then Sedan, because those scenarios stress the highest-risk mechanics in order.\n"
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
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_report(), encoding="utf-8")
    print(f"Wrote {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
