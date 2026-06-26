#!/usr/bin/env python3
"""Probe scenario pressure points for tactical gameplay tuning.

This report stays static and deterministic. It complements the broader
scenario balance report by focusing on suppression sources, artillery reach,
spotter coverage, breach reach, objective pressure, and reinforcement power swings.
"""

from __future__ import annotations

import collections
import glob
import heapq
import json
import math
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
UNITS_PATH = ROOT / "data" / "units.json"
TERRAINS_PATH = ROOT / "data" / "terrains.json"
SCENARIOS_GLOB = str(ROOT / "data" / "scenarios" / "*.json")
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "scenario_probe.md"

NEIGHBORS = ((1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1))
SUBHEX = 2
ZOC_PENALTY = 2
IMPASSABLE = 1 << 20
SUPPRESSION_PIN_THRESHOLD = 2

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


def neighbors(coord: tuple[int, int]) -> list[tuple[int, int]]:
    q, r = coord
    return [(q + dq, r + dr) for dq, dr in NEIGHBORS]


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


def scenario_tiles(scenario: dict[str, Any]) -> dict[tuple[int, int], str]:
    tiles: dict[tuple[int, int], str] = {}
    for row_idx, row in enumerate(scenario.get("map", {}).get("tiles", [])):
        for col_idx, terrain_id in enumerate(row):
            tiles[axial_from_offset([col_idx, row_idx])] = str(terrain_id)
    return tiles


def occupied_by_initial_units(scenario: dict[str, Any]) -> dict[tuple[int, int], dict[str, Any]]:
    occupied: dict[tuple[int, int], dict[str, Any]] = {}
    for unit in initial_units(scenario):
        occupied[axial_from_offset(unit.get("at", [0, 0]))] = unit
    return occupied


def movement_step_cost(
    coord: tuple[int, int],
    tiles: dict[tuple[int, int], str],
    terrains: dict[str, Any],
    occupied: dict[tuple[int, int], dict[str, Any]],
    mover_faction: str,
    unit_type: str,
) -> int:
    terrain_id = tiles.get(coord, "")
    if terrain_id == "":
        return IMPASSABLE
    terrain = terrains.get(terrain_id, {})
    if bool(terrain.get("impassable", False)):
        return IMPASSABLE

    if terrain_id == "road":
        step_cost = 1
    elif unit_type == "infantry" and int(terrain.get("move_cost", 1)) >= 2:
        step_cost = SUBHEX
    else:
        step_cost = int(terrain.get("move_cost", 1)) * SUBHEX

    if mover_faction and enters_enemy_zoc(coord, occupied, mover_faction):
        step_cost += ZOC_PENALTY * SUBHEX
    return step_cost


def enters_enemy_zoc(
    coord: tuple[int, int],
    occupied: dict[tuple[int, int], dict[str, Any]],
    mover_faction: str,
) -> bool:
    for neighbor in neighbors(coord):
        unit = occupied.get(neighbor)
        if (
            unit is not None
            and str(unit.get("faction", "")) != mover_faction
            and int(unit.get("suppression", 0)) < SUPPRESSION_PIN_THRESHOLD
        ):
            return True
    return False


def movement_costs(
    start: tuple[int, int],
    scenario: dict[str, Any],
    terrains: dict[str, Any],
    occupied: dict[tuple[int, int], dict[str, Any]],
    mover_faction: str,
    unit_type: str,
    max_cost: int | None = None,
) -> dict[tuple[int, int], int]:
    tiles = scenario_tiles(scenario)
    cost_to: dict[tuple[int, int], int] = {start: 0}
    frontier: list[tuple[int, tuple[int, int]]] = [(0, start)]
    while frontier:
        current_cost, current = heapq.heappop(frontier)
        if current_cost != cost_to[current]:
            continue
        for neighbor in neighbors(current):
            if neighbor != start and occupied.get(neighbor) is not None:
                continue
            step_cost = movement_step_cost(neighbor, tiles, terrains, occupied, mover_faction, unit_type)
            if step_cost >= IMPASSABLE:
                continue
            new_cost = current_cost + step_cost
            if max_cost is not None and new_cost > max_cost:
                continue
            if neighbor not in cost_to or new_cost < cost_to[neighbor]:
                cost_to[neighbor] = new_cost
                heapq.heappush(frontier, (new_cost, neighbor))
    return cost_to


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


def secondary_objective_pressure(scenario: dict[str, Any]) -> str:
    objectives = scenario.get("secondary_objectives", [])
    if not isinstance(objectives, list) or not objectives:
        return "none"
    parts: list[str] = []
    for objective in objectives:
        if not isinstance(objective, dict):
            continue
        target = secondary_objective_target_offset(scenario, objective)
        if target is None:
            continue
        faction_id = str(objective.get("faction", ""))
        target_coord = axial_from_offset(target)
        own = [
            u for u in initial_units(scenario)
            if faction_id == "" or str(u.get("faction", "")) == faction_id
        ]
        own_dist = [hex_distance(axial_from_offset(u.get("at", [0, 0])), target_coord) for u in own]
        label = str(objective.get("label", objective.get("id", "secondary")))
        if own_dist:
            parts.append(
                f"{label} {target[0]},{target[1]} {secondary_objective_type_text(objective)} "
                f"min {min(own_dist)} {secondary_reward_text(objective)}"
            )
    return "; ".join(parts) if parts else "none"


def secondary_objective_target_offset(scenario: dict[str, Any], objective: dict[str, Any]) -> list[Any] | None:
    objective_type = str(objective.get("type", "capture"))
    if objective_type in {"capture", "hold_turns", "recon_hex"}:
        target = objective.get("target", [])
        if isinstance(target, list) and len(target) >= 2:
            return target
        return None
    if objective_type == "destroy_unit":
        target_unit = str(objective.get("target_unit", ""))
        unit = find_secondary_target_unit(scenario, target_unit)
        if not unit:
            return None
        at = unit.get("at", [])
        if isinstance(at, list) and len(at) >= 2:
            return at
    return None


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
    legacy_xp = int(objective.get("xp_reward", 0))
    if legacy_xp > 0 and not any(part.startswith("XP ") for part in parts):
        parts.append(f"XP {legacy_xp}")
    return ", ".join(parts) if parts else "no reward"


def needs_breach_pressure(scenario: dict[str, Any], faction_id: str) -> bool:
    objective = scenario.get("victory", {}).get(faction_id, {})
    return str(objective.get("type", "")) in {"capture", "eliminate"}


def breach_targets_for_faction(scenario: dict[str, Any], faction_id: str) -> list[dict[str, Any]]:
    targets: list[dict[str, Any]] = []
    tiles = scenario.get("map", {}).get("tiles", [])
    for unit in initial_units(scenario):
        if str(unit.get("faction", "")) == faction_id:
            continue
        at = unit.get("at", [0, 0])
        row = int(at[1])
        col = int(at[0])
        terrain = ""
        if 0 <= row < len(tiles) and 0 <= col < len(tiles[row]):
            terrain = str(tiles[row][col])
        dig_in = int(unit.get("dig_in", 0))
        if terrain in {"town", "forest", "jungle"} or dig_in > 0:
            targets.append(unit)
    return targets


def breach_path_pressure(scenario: dict[str, Any], units: dict[str, Any]) -> str:
    parts: list[str] = []
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        if not needs_breach_pressure(scenario, faction_id):
            continue
        targets = breach_targets_for_faction(scenario, faction_id)
        if not targets:
            continue
        own_units = [u for u in initial_units(scenario) if str(u.get("faction", "")) == faction_id]
        engineers = [u for u in own_units if str(u.get("type", "")) == "engineer"]
        indirect = [
            u for u in own_units
            if bool(units.get(str(u.get("type", "")), {}).get("indirect", False))
        ]

        target_coords = [axial_from_offset(t.get("at", [0, 0])) for t in targets]
        if engineers:
            eng_distances = [
                hex_distance(axial_from_offset(engineer.get("at", [0, 0])), target)
                for engineer in engineers
                for target in target_coords
            ]
            engineer_bit = f"eng min {min(eng_distances)}"
        else:
            engineer_bit = "eng none"

        covered_targets: set[tuple[int, int]] = set()
        for gun in indirect:
            gun_def = units.get(str(gun.get("type", "")), {})
            gun_coord = axial_from_offset(gun.get("at", [0, 0]))
            rng = int(gun_def.get("range", 1))
            for target in target_coords:
                if hex_distance(gun_coord, target) <= rng:
                    covered_targets.add(target)
        artillery_bit = f"art {len(covered_targets)}/{len(target_coords)}"
        parts.append(f"{faction_id}: {engineer_bit}, {artillery_bit}, targets {len(target_coords)}")
    return "; ".join(parts) if parts else "n/a"


def engineer_breach_tempo(
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    parts: list[str] = []
    occupied = occupied_by_initial_units(scenario)
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        if not needs_breach_pressure(scenario, faction_id):
            continue
        targets = breach_targets_for_faction(scenario, faction_id)
        if not targets:
            continue
        engineers = [
            unit for unit in initial_units(scenario)
            if str(unit.get("faction", "")) == faction_id and str(unit.get("type", "")) == "engineer"
        ]
        if not engineers:
            parts.append(f"{faction_id}: eng turns none")
            continue

        best_turns: int | None = None
        for engineer in engineers:
            engineer_def = units.get(str(engineer.get("type", "")), {})
            move_budget = int(engineer_def.get("move", 0)) * SUBHEX
            attack_range = int(engineer_def.get("range", 1))
            if move_budget <= 0:
                continue
            costs = movement_costs(
                axial_from_offset(engineer.get("at", [0, 0])),
                scenario,
                terrains,
                occupied,
                faction_id,
                str(engineer.get("type", "")),
            )
            for target in targets:
                target_coord = axial_from_offset(target.get("at", [0, 0]))
                attack_costs = [
                    cost for coord, cost in costs.items()
                    if hex_distance(coord, target_coord) <= attack_range
                ]
                if not attack_costs:
                    continue
                turns = max(0, math.ceil(min(attack_costs) / move_budget))
                best_turns = turns if best_turns is None else min(best_turns, turns)
        if best_turns is None:
            parts.append(f"{faction_id}: eng turns blocked")
        else:
            parts.append(f"{faction_id}: eng turns {best_turns}")
    return "; ".join(parts) if parts else "n/a"


def artillery_reposition_pressure(
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    parts: list[str] = []
    occupied = occupied_by_initial_units(scenario)
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        if not needs_breach_pressure(scenario, faction_id):
            continue
        targets = breach_targets_for_faction(scenario, faction_id)
        if not targets:
            continue
        target_coords = [axial_from_offset(target.get("at", [0, 0])) for target in targets]
        indirect = [
            unit for unit in initial_units(scenario)
            if str(unit.get("faction", "")) == faction_id
            and bool(units.get(str(unit.get("type", "")), {}).get("indirect", False))
        ]
        if not indirect:
            parts.append(f"{faction_id}: art move none")
            continue

        covered_targets: set[tuple[int, int]] = set()
        for gun in indirect:
            gun_type = str(gun.get("type", ""))
            gun_def = units.get(gun_type, {})
            move_budget = int(gun_def.get("move", 0)) * SUBHEX
            attack_range = int(gun_def.get("range", 1))
            costs = movement_costs(
                axial_from_offset(gun.get("at", [0, 0])),
                scenario,
                terrains,
                occupied,
                faction_id,
                gun_type,
                move_budget,
            )
            for coord in costs:
                for target_coord in target_coords:
                    if hex_distance(coord, target_coord) <= attack_range:
                        covered_targets.add(target_coord)
        parts.append(f"{faction_id}: art move {len(covered_targets)}/{len(target_coords)}")
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
    terrains = load_json(TERRAINS_PATH)
    scenarios = [load_json(Path(path)) for path in sorted(glob.glob(SCENARIOS_GLOB))]

    rows: list[list[Any]] = []
    for scenario in scenarios:
        rows.append(
            [
                scenario.get("id", ""),
                suppression_sources(scenario),
                artillery_coverage(scenario, units),
                spotter_coverage(scenario, units),
                breach_path_pressure(scenario, units),
                engineer_breach_tempo(scenario, units, terrains),
                artillery_reposition_pressure(scenario, units, terrains),
                objective_pressure(scenario),
                secondary_objective_pressure(scenario),
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
                "breach path",
                "breach tempo",
                "artillery reposition",
                "objective pressure",
                "secondary pressure",
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
