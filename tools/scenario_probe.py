#!/usr/bin/env python3
"""Probe scenario pressure points for tactical gameplay tuning.

This report stays static and deterministic. It complements the broader
scenario balance report by focusing on suppression sources, artillery reach,
spotter coverage, capture-target pressure, and reinforcement power swings.
"""

from __future__ import annotations

import collections
import glob
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
UNITS_PATH = ROOT / "data" / "units.json"
SCENARIOS_GLOB = str(ROOT / "data" / "scenarios" / "*.json")
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "scenario_probe.md"

SUPPRESSION_BY_TYPE = {
    "infantry": 1,
    "mg_team": 3,
    "at_gun": 1,
    "light_tank": 1,
    "medium_tank": 1,
    "artillery": 3,
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def axial_from_offset(at: list[Any]) -> tuple[int, int]:
    col = int(at[0])
    row = int(at[1])
    return (col - (row >> 1), row)


def hex_distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dq = a[0] - b[0]
    dr = a[1] - b[1]
    return (abs(dq) + abs(dr) + abs(dq + dr)) // 2


def table(headers: list[str], rows: list[list[Any]]) -> str:
    out = ["| " + " | ".join(headers) + " |"]
    out.append("| " + " | ".join(["---"] * len(headers)) + " |")
    for row in rows:
        out.append("| " + " | ".join(str(cell) for cell in row) + " |")
    return "\n".join(out)


def unit_power(unit_type: str, units: dict[str, Any]) -> float:
    data = units[unit_type]
    hp = float(data.get("hp", 0))
    attack = float(data.get("attack", 0))
    defense = float(data.get("defense", 0))
    armor = float(data.get("armor", 0))
    move = float(data.get("move", 0))
    vision = float(data.get("vision", 0))
    rng = float(data.get("range", 1))
    vs_armor = float(data.get("vs_armor", 0))
    indirect_bonus = 4.0 if data.get("indirect", False) else 0.0
    return hp + attack * 2.0 + defense * 1.5 + armor * 1.5 + move * 0.8 + vision * 0.5 + (rng - 1.0) * 2.0 + vs_armor * 0.8 + indirect_bonus


def initial_units(scenario: dict[str, Any]) -> list[dict[str, Any]]:
    return list(scenario.get("units", []))


def suppression_sources(scenario: dict[str, Any]) -> str:
    by_faction: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    for unit in initial_units(scenario):
        unit_type = str(unit.get("type", ""))
        suppression = SUPPRESSION_BY_TYPE.get(unit_type, 1)
        if suppression >= 3:
            by_faction[str(unit.get("faction", ""))][unit_type] += 1
    if not by_faction:
        return "none"
    parts: list[str] = []
    for faction, counts in sorted(by_faction.items()):
        labels = ", ".join(f"{unit_type}:{count}" for unit_type, count in sorted(counts.items()))
        parts.append(f"{faction} {labels}")
    return "; ".join(parts)


def artillery_coverage(scenario: dict[str, Any], units: dict[str, Any]) -> str:
    map_cfg = scenario.get("map", {})
    width = int(map_cfg.get("width", 0))
    height = int(map_cfg.get("height", 0))
    total = max(1, width * height)
    by_faction: dict[str, set[tuple[int, int]]] = collections.defaultdict(set)
    for unit in initial_units(scenario):
        unit_type = str(unit.get("type", ""))
        unit_def = units.get(unit_type, {})
        if not bool(unit_def.get("indirect", False)):
            continue
        center = axial_from_offset(unit.get("at", [0, 0]))
        rng = int(unit_def.get("range", 1))
        for col in range(width):
            for row in range(height):
                coord = axial_from_offset([col, row])
                if hex_distance(center, coord) <= rng:
                    by_faction[str(unit.get("faction", ""))].add(coord)
    if not by_faction:
        return "none"
    return "; ".join(
        f"{faction} {len(coords)}/{total} ({len(coords) / total:.0%})"
        for faction, coords in sorted(by_faction.items())
    )


def spotter_coverage(scenario: dict[str, Any], units: dict[str, Any]) -> str:
    map_cfg = scenario.get("map", {})
    width = int(map_cfg.get("width", 0))
    height = int(map_cfg.get("height", 0))
    total = max(1, width * height)
    by_faction: dict[str, set[tuple[int, int]]] = collections.defaultdict(set)
    for unit in initial_units(scenario):
        unit_type = str(unit.get("type", ""))
        if unit_type != "light_tank":
            continue
        center = axial_from_offset(unit.get("at", [0, 0]))
        vision = int(units.get(unit_type, {}).get("vision", 3))
        for col in range(width):
            for row in range(height):
                coord = axial_from_offset([col, row])
                if hex_distance(center, coord) <= vision:
                    by_faction[str(unit.get("faction", ""))].add(coord)
    if not by_faction:
        return "none"
    parts: list[str] = []
    for faction, coords in sorted(by_faction.items()):
        seen_enemies = 0
        for unit in initial_units(scenario):
            if str(unit.get("faction", "")) == faction:
                continue
            if axial_from_offset(unit.get("at", [0, 0])) in coords:
                seen_enemies += 1
        parts.append(f"{faction} {len(coords)}/{total} ({len(coords) / total:.0%}), spots {seen_enemies}")
    return "; ".join(parts)


def objective_pressure(scenario: dict[str, Any]) -> str:
    parts: list[str] = []
    for faction_id, cfg in scenario.get("victory", {}).items():
        if cfg.get("type") != "capture":
            continue
        target = cfg.get("target", [])
        if not isinstance(target, list) or len(target) < 2:
            continue
        target_coord = axial_from_offset(target)
        own = [u for u in initial_units(scenario) if u.get("faction") == faction_id]
        enemies = [u for u in initial_units(scenario) if u.get("faction") != faction_id]
        own_dist = [hex_distance(axial_from_offset(u.get("at", [0, 0])), target_coord) for u in own]
        enemy_dist = [hex_distance(axial_from_offset(u.get("at", [0, 0])), target_coord) for u in enemies]
        if own_dist and enemy_dist:
            parts.append(
                f"{faction_id} target {target[0]},{target[1]} own min {min(own_dist)} enemy min {min(enemy_dist)}"
            )
    return "; ".join(parts) if parts else "n/a"


def reinforcement_delta(scenario: dict[str, Any], units: dict[str, Any]) -> str:
    by_faction: dict[str, float] = collections.defaultdict(float)
    by_turn: dict[int, list[str]] = collections.defaultdict(list)
    for unit in scenario.get("reinforcements", []):
        unit_type = str(unit.get("type", ""))
        faction = str(unit.get("faction", ""))
        power = unit_power(unit_type, units)
        by_faction[faction] += power
        by_turn[int(unit.get("at_turn", 0))].append(f"{faction}:{unit_type}")
    if not by_faction:
        return "none"
    faction_bits = ", ".join(f"{faction} +{power:.1f}" for faction, power in sorted(by_faction.items()))
    turn_bits = ", ".join(f"T{turn} {len(items)} units" for turn, items in sorted(by_turn.items()))
    return f"{faction_bits}; {turn_bits}"


def generate_report() -> str:
    units = load_json(UNITS_PATH)
    scenarios = [load_json(Path(path)) for path in sorted(glob.glob(SCENARIOS_GLOB))]

    rows: list[list[Any]] = []
    for scenario in scenarios:
        rows.append(
            [
                scenario.get("id", ""),
                suppression_sources(scenario),
                artillery_coverage(scenario, units),
                spotter_coverage(scenario, units),
                objective_pressure(scenario),
                reinforcement_delta(scenario, units),
            ]
        )

    sections = [
        "# Scenario Probe",
        "Static tactical probe for pressure tuning. Coverage is approximate and ignores LOS/fog; use it to spot scenarios that need manual playtesting.",
        table(
            [
                "scenario",
                "suppression sources",
                "artillery coverage",
                "spotter coverage",
                "objective pressure",
                "reinforcement delta",
            ],
            rows,
        ),
    ]
    return "\n\n".join(sections) + "\n"


def main() -> None:
    DEFAULT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    DEFAULT_OUTPUT.write_text(generate_report(), encoding="utf-8")
    print(f"Wrote {DEFAULT_OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
