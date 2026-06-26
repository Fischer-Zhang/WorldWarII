#!/usr/bin/env python3
"""Generate scenario-level balance diagnostics.

This is a static companion to balance_report.py. It does not simulate turns;
it checks scenario composition, terrain pressure, deployment distances, and
role coverage so scenario tuning has a repeatable starting point.
"""

from __future__ import annotations

import collections
import glob
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
UNITS_PATH = ROOT / "data" / "units.json"
TERRAINS_PATH = ROOT / "data" / "terrains.json"
SCENARIOS_GLOB = str(ROOT / "data" / "scenarios" / "*.json")
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "scenario_balance_report.md"


ROLE_BY_TYPE = {
    "infantry": "infantry",
    "mg_team": "support",
    "at_gun": "anti_armor",
    "light_tank": "scout_armor",
    "medium_tank": "armor",
    "artillery": "artillery",
    "engineer": "engineer",
    "paratrooper": "infantry",
    "tank_destroyer": "anti_armor",
    "heavy_tank": "armor",
    "rocket_artillery": "artillery",
}

BREACH_TYPES = ("engineer", "artillery", "rocket_artillery")


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


def terrain_counts(scenario: dict[str, Any]) -> collections.Counter[str]:
    counter: collections.Counter[str] = collections.Counter()
    for row in scenario.get("map", {}).get("tiles", []):
        counter.update(str(tile) for tile in row)
    return counter


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


def scenario_units(scenario: dict[str, Any]) -> list[dict[str, Any]]:
    out = list(scenario.get("units", []))
    out.extend(scenario.get("reinforcements", []))
    return out


def faction_rows(scenario: dict[str, Any], units: dict[str, Any]) -> tuple[list[list[Any]], dict[str, Any]]:
    by_faction: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    for unit in scenario_units(scenario):
        by_faction[str(unit.get("faction", ""))].append(unit)

    rows: list[list[Any]] = []
    summary: dict[str, Any] = {}
    for faction in scenario.get("factions", []):
        fid = str(faction.get("id", ""))
        roster = by_faction.get(fid, [])
        role_counts: collections.Counter[str] = collections.Counter()
        power = 0.0
        armor_count = 0
        anti_armor_count = 0
        artillery_count = 0
        unit_counts: collections.Counter[str] = collections.Counter()
        for unit in roster:
            unit_type = str(unit.get("type", ""))
            unit_counts[unit_type] += 1
            role = ROLE_BY_TYPE.get(unit_type, unit_type)
            role_counts[role] += 1
            power += unit_power(unit_type, units)
            if role in ["armor", "scout_armor"]:
                armor_count += 1
            if role == "anti_armor":
                anti_armor_count += 1
            if role == "artillery":
                artillery_count += 1
        summary[fid] = {
            "power": power,
            "count": len(roster),
            "roles": role_counts,
            "armor": armor_count,
            "anti_armor": anti_armor_count,
            "artillery": artillery_count,
            "unit_counts": unit_counts,
        }
        rows.append([
            fid,
            faction.get("name", fid),
            faction.get("controller", ""),
            len(roster),
            f"{power:.1f}",
            ", ".join(f"{role}:{count}" for role, count in sorted(role_counts.items())),
        ])
    return rows, summary


def objective_distance(scenario: dict[str, Any]) -> str:
    victory = scenario.get("victory", {})
    units = scenario.get("units", [])
    parts: list[str] = []
    for fid, cfg in victory.items():
        if cfg.get("type") != "capture":
            continue
        target = cfg.get("target", [])
        if not isinstance(target, list) or len(target) < 2:
            continue
        target_coord = axial_from_offset(target)
        own_units = [u for u in units if u.get("faction") == fid]
        if not own_units:
            continue
        distances = [hex_distance(axial_from_offset(u.get("at", [0, 0])), target_coord) for u in own_units]
        parts.append(f"{fid}->{target[0]},{target[1]} min {min(distances)} avg {sum(distances) / len(distances):.1f}")
    return "; ".join(parts) if parts else "n/a"


def secondary_objective_summary(scenario: dict[str, Any]) -> str:
    objectives = scenario.get("secondary_objectives", [])
    if not isinstance(objectives, list) or not objectives:
        return "none"
    parts: list[str] = []
    for objective in objectives:
        if not isinstance(objective, dict):
            continue
        label = str(objective.get("label", objective.get("id", "secondary")))
        target = secondary_objective_target_text(scenario, objective)
        target_text = f" {target}" if target else ""
        parts.append(f"{label} [{secondary_objective_type_text(objective)}{target_text}] ({secondary_reward_text(objective)})")
    return "; ".join(parts) if parts else "none"


def secondary_objective_type_text(objective: dict[str, Any]) -> str:
    objective_type = str(objective.get("type", "capture"))
    if objective_type == "hold_turns":
        turns = int(objective.get("required_turns", 1))
        return f"hold {turns}t"
    if objective_type == "recon_hex":
        return "recon"
    if objective_type == "destroy_unit":
        return "destroy"
    return "capture"


def secondary_objective_target_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    objective_type = str(objective.get("type", "capture"))
    if objective_type in {"capture", "hold_turns", "recon_hex"}:
        target = objective.get("target", [])
        if isinstance(target, list) and len(target) >= 2:
            return f"{target[0]},{target[1]}"
        return ""
    if objective_type == "destroy_unit":
        target_unit = str(objective.get("target_unit", ""))
        unit = find_secondary_target_unit(scenario, target_unit)
        if unit:
            name = str(unit.get("name", target_unit))
            at = unit.get("at", [])
            if isinstance(at, list) and len(at) >= 2:
                return f"{name}@{at[0]},{at[1]}"
            return name
        return target_unit
    return ""


def find_secondary_target_unit(scenario: dict[str, Any], target_unit: str) -> dict[str, Any] | None:
    if target_unit == "":
        return None
    for collection in ("units", "reinforcements"):
        entries = scenario.get(collection, [])
        if not isinstance(entries, list):
            continue
        for unit in entries:
            if not isinstance(unit, dict):
                continue
            unit_id = str(unit.get("id", ""))
            unit_name = str(unit.get("name", ""))
            unit_faction = str(unit.get("faction", ""))
            if target_unit in {unit_id, unit_name, f"{unit_faction}:{unit_name}"}:
                return unit
    return None


def secondary_reward_text(objective: dict[str, Any]) -> str:
    rewards = objective.get("rewards", [])
    parts: list[str] = []
    if isinstance(rewards, list):
        for reward in rewards:
            if not isinstance(reward, dict):
                continue
            reward_type = str(reward.get("type", ""))
            amount = int(reward.get("amount", 0))
            if amount <= 0:
                continue
            if reward_type == "xp":
                parts.append(f"XP {amount}")
            elif reward_type == "recover_suppression":
                parts.append(f"supp -{amount}")
            elif reward_type == "repair_hp":
                parts.append(f"repair {amount}")
            elif reward_type == "advance_reinforcements":
                parts.append(f"reinforce -{amount}t")
    legacy_xp = int(objective.get("xp_reward", 0))
    if legacy_xp > 0 and not any(part.startswith("XP ") for part in parts):
        parts.append(f"XP {legacy_xp}")
    return ", ".join(parts) if parts else "no reward"


def terrain_summary(scenario: dict[str, Any], terrains: dict[str, Any]) -> str:
    counts = terrain_counts(scenario)
    total = sum(counts.values()) or 1
    defensive = sum(count for terrain, count in counts.items() if int(terrains[terrain].get("defense", 0)) >= 2)
    slow = sum(count for terrain, count in counts.items() if int(terrains[terrain].get("move_cost", 1)) >= 3)
    top = ", ".join(f"{terrain} {count / total:.0%}" for terrain, count in counts.most_common(3))
    return f"{top}; def>=2 {defensive / total:.0%}; move>=3 {slow / total:.0%}"


def needs_urban_breach(scenario: dict[str, Any], faction_id: str) -> bool:
    victory = scenario.get("victory", {})
    objective = victory.get(faction_id, {})
    objective_type = str(objective.get("type", ""))
    return objective_type in {"capture", "eliminate"}


def breach_tool_count(summary: dict[str, Any]) -> int:
    unit_counts: collections.Counter[str] = summary.get("unit_counts", collections.Counter())
    return sum(unit_counts.get(unit_type, 0) for unit_type in BREACH_TYPES)


def urban_breach_summary(faction_summary: dict[str, Any]) -> str:
    parts: list[str] = []
    for fid, summary in faction_summary.items():
        unit_counts: collections.Counter[str] = summary.get("unit_counts", collections.Counter())
        values = [
            f"eng {unit_counts.get('engineer', 0)}",
            f"art {unit_counts.get('artillery', 0)}",
            f"rocket {unit_counts.get('rocket_artillery', 0)}",
            f"mg {unit_counts.get('mg_team', 0)}",
        ]
        parts.append(f"{fid}: " + ", ".join(values))
    return "; ".join(parts) if parts else "n/a"


def risk_notes(scenario: dict[str, Any], faction_summary: dict[str, Any], terrains: dict[str, Any]) -> str:
    notes: list[str] = []
    counts = terrain_counts(scenario)
    total_tiles = sum(counts.values()) or 1
    town_pct = counts.get("town", 0) / total_tiles
    river_pct = counts.get("river", 0) / total_tiles
    forest_pct = counts.get("forest", 0) / total_tiles
    if town_pct >= 0.25:
        notes.append("high town density: dig-in pacing risk")
        for fid, summary in faction_summary.items():
            if not needs_urban_breach(scenario, fid):
                continue
            unit_counts: collections.Counter[str] = summary.get("unit_counts", collections.Counter())
            if breach_tool_count(summary) == 0:
                notes.append(f"{fid} lacks breach tools for urban objective")
            elif town_pct >= 0.40 and unit_counts.get("engineer", 0) == 0:
                notes.append(f"{fid} has no engineers for dense urban breach")
    if forest_pct >= 0.20:
        notes.append("high forest density: LOS and breakthrough tempo risk")
    if river_pct >= 0.07:
        notes.append("river crossings may dominate tempo")

    fids = list(faction_summary.keys())
    if len(fids) >= 2:
        first = faction_summary[fids[0]]
        second = faction_summary[fids[1]]
        low = min(first["power"], second["power"])
        high = max(first["power"], second["power"])
        if low > 0 and high / low >= 1.35:
            notes.append("force power ratio above 1.35: check victory-clock compensation")
        for fid, summary in faction_summary.items():
            enemy_armor = sum(other["armor"] for other_fid, other in faction_summary.items() if other_fid != fid)
            if enemy_armor >= 3 and summary["anti_armor"] == 0:
                notes.append(f"{fid} lacks AT against {enemy_armor} enemy armor units")
            if summary["artillery"] >= 2:
                notes.append(f"{fid} artillery-heavy: watch standoff dominance")
    return "; ".join(notes) if notes else "no major static risks"


def generate_report() -> str:
    units = load_json(UNITS_PATH)
    terrains = load_json(TERRAINS_PATH)
    scenarios = [load_json(Path(path)) for path in sorted(glob.glob(SCENARIOS_GLOB))]

    sections: list[str] = [
        "# Scenario Balance Report",
        "Static diagnostics from scenario JSON. This report does not simulate turns; it highlights force composition, terrain pressure, objective distance, and obvious role-coverage risks.",
    ]

    overview_rows: list[list[Any]] = []
    detail_sections: list[str] = []
    for scenario in scenarios:
        faction_table_rows, summary = faction_rows(scenario, units)
        terrain = terrain_summary(scenario, terrains)
        breach = urban_breach_summary(summary)
        objective = objective_distance(scenario)
        secondary = secondary_objective_summary(scenario)
        risks = risk_notes(scenario, summary, terrains)
        overview_rows.append([
            scenario.get("id", ""),
            scenario.get("title", ""),
            terrain,
            breach,
            objective,
            secondary,
            risks,
        ])
        detail_sections.append(
            "## " + str(scenario.get("id", "")) + "\n\n"
            + table(["faction", "name", "controller", "units", "power", "roles"], faction_table_rows)
        )

    sections.append("## Overview\n\n" + table([
        "scenario", "title", "terrain pressure", "urban breach tools", "objective distance", "secondary objectives", "risk notes",
    ], overview_rows))
    sections.extend(detail_sections)
    return "\n\n".join(sections) + "\n"


def main() -> None:
    DEFAULT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    DEFAULT_OUTPUT.write_text(generate_report(), encoding="utf-8")
    print(f"Wrote {DEFAULT_OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
