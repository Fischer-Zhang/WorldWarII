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
CAMPAIGNS_PATH = ROOT / "data" / "campaigns.json"
CONQUEST_MAP_PATH = ROOT / "data" / "conquest_map.json"
SCENARIOS_GLOB = str(ROOT / "data" / "scenarios" / "*.json")
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "scenario_probe.md"

NEIGHBORS = ((1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1))
SUBHEX = 2
ZOC_PENALTY = 2
IMPASSABLE = 1 << 20
SUPPRESSION_PIN_THRESHOLD = 2
IDENTITY_TERRAINS = ("desert", "jungle", "town", "river", "sea", "mountain", "forest")
IDENTITY_THRESHOLDS = {
    "desert": 0.20,
    "jungle": 0.08,
    "town": 0.12,
    "river": 0.05,
    "sea": 0.08,
    "mountain": 0.06,
    "forest": 0.10,
}

SUPPRESSION_BY_TYPE = {
    "infantry": 1,
    "mg_team": 3,
    "at_gun": 1,
    "light_tank": 1,
    "medium_tank": 1,
    "artillery": 3,
}
REGION_TRAIT_EFFECTS = {
    "industrial_hub": {"strength": 1},
    "fortress_line": {"support": ["mg_team"]},
    "rail_junction": {"xp": 1},
    "airfield_network": {"xp": 1},
    "naval_base": {"strength": 1},
    "jungle_front": {"support": ["infantry"]},
    "oilfield": {"strength": 1},
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
    standoff_bonus = float(data.get("armor_standoff_vs_armor_bonus", 0)) * 0.6
    return hp + attack * 2.0 + defense * 1.5 + armor * 1.5 + move * 0.8 + vision * 0.5 + (rng - 1.0) * 2.0 + vs_armor * 0.8 + standoff_bonus + indirect_bonus


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
        objective_type = str(cfg.get("type", ""))
        if objective_type not in {"capture", "control_count", "hold_hex_turns"}:
            continue
        targets = primary_objective_targets(cfg)
        if not targets:
            continue
        own = [u for u in initial_units(scenario) if u.get("faction") == faction_id]
        enemies = [u for u in initial_units(scenario) if u.get("faction") != faction_id]
        own_dist = [nearest_distance_to_targets(u, targets) for u in own]
        enemy_dist = [nearest_distance_to_targets(u, targets) for u in enemies]
        if own_dist and enemy_dist:
            if objective_type == "capture":
                target = targets[0]
                parts.append(
                    f"{faction_id} target {target[0]},{target[1]} own min {min(own_dist)} enemy min {min(enemy_dist)}"
                )
            elif objective_type == "control_count":
                required = int(cfg.get("required", len(targets)))
                parts.append(
                    f"{faction_id} control {required}/{len(targets)} own min {min(own_dist)} enemy min {min(enemy_dist)}"
                )
            else:
                target = targets[0]
                turns = int(cfg.get("required_turns", 1))
                parts.append(
                    f"{faction_id} hold {target[0]},{target[1]} {turns}t own min {min(own_dist)} enemy min {min(enemy_dist)}"
                )
    return "; ".join(parts) if parts else "n/a"


def primary_objective_targets(objective: dict[str, Any]) -> list[list[Any]]:
    objective_type = str(objective.get("type", ""))
    if objective_type in {"capture", "hold_hex_turns"}:
        target = objective.get("target", [])
        if isinstance(target, list) and len(target) >= 2:
            return [target]
        return []
    if objective_type == "control_count":
        targets = objective.get("targets", [])
        if isinstance(targets, list):
            return [target for target in targets if isinstance(target, list) and len(target) >= 2]
    return []


def nearest_distance_to_targets(unit: dict[str, Any], targets: list[list[Any]]) -> int:
    unit_coord = axial_from_offset(unit.get("at", [0, 0]))
    return min(hex_distance(unit_coord, axial_from_offset(target)) for target in targets)


def scenario_faction_ids(scenario: dict[str, Any]) -> list[str]:
    return [str(faction.get("id", "")) for faction in scenario.get("factions", [])]


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
            prerequisite_text = secondary_objective_prerequisite_text(objective)
            branch_text = secondary_objective_branch_text(objective)
            parts.append(
                f"{label} {target[0]},{target[1]} {secondary_objective_type_text(objective)}{prerequisite_text}{branch_text} "
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


def secondary_objective_prerequisite_text(objective: dict[str, Any]) -> str:
    requires = objective.get("requires", [])
    if isinstance(requires, str):
        return f" after {requires}" if requires else ""
    if isinstance(requires, list):
        required_ids = [item for item in requires if isinstance(item, str) and item]
        if required_ids:
            return f" after {','.join(required_ids)}"
    return ""


def secondary_objective_branch_text(objective: dict[str, Any]) -> str:
    group = str(objective.get("exclusive_group", ""))
    return f" branch {group}" if group else ""


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
            elif reward_type == "suppress_enemies":
                radius = int(reward.get("radius", 1))
                parts.append(f"enemy supp +{amount} R{radius}")
            elif reward_type == "strip_enemy_dig_in":
                radius = int(reward.get("radius", 1))
                parts.append(f"enemy dig -{amount} R{radius}")
    legacy_xp = int(objective.get("xp_reward", 0))
    if legacy_xp > 0 and not any(part.startswith("XP ") for part in parts):
        parts.append(f"XP {legacy_xp}")
    strategic_effects = objective.get("strategic_effects", [])
    if isinstance(strategic_effects, list):
        for effect in strategic_effects:
            if not isinstance(effect, dict):
                continue
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            if amount <= 0:
                continue
            if effect_type == "campaign_bonus_points":
                parts.append(f"campaign +{amount}p")
            elif effect_type == "conquest_reduce_enemy_strength":
                parts.append(f"conquest enemy -{amount}")
            elif effect_type == "conquest_reduce_enemy_fortification":
                parts.append(f"conquest fort -{amount}")
            elif effect_type == "conquest_disrupt_enemy_production":
                parts.append(f"conquest prod -{amount}")
    return ", ".join(parts) if parts else "no reward"


def secondary_objective_focus_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        objectives = scenario.get("secondary_objectives", [])
        if not isinstance(objectives, list):
            continue
        scenario_id = str(scenario.get("id", ""))
        for objective in objectives:
            if not isinstance(objective, dict):
                continue
            rows.append([
                scenario_id,
                str(objective.get("label", objective.get("id", "secondary"))),
                secondary_objective_focus_target_text(scenario, objective),
                secondary_objective_faction_text(scenario, objective),
                secondary_objective_distance_text(scenario, objective),
                secondary_reward_text(objective),
                secondary_objective_audit_text(scenario, objective),
            ])
    return rows


def secondary_objective_focus_target_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    target = secondary_objective_target_offset(scenario, objective)
    prerequisite_text = secondary_objective_prerequisite_text(objective)
    branch_text = secondary_objective_branch_text(objective)
    if target is None:
        return f"{secondary_objective_type_text(objective)} n/a{prerequisite_text}{branch_text}"
    return f"{secondary_objective_type_text(objective)} {target[0]},{target[1]}{prerequisite_text}{branch_text}"


def secondary_objective_factions(scenario: dict[str, Any], objective: dict[str, Any]) -> list[str]:
    faction_id = str(objective.get("faction", ""))
    if faction_id:
        return [faction_id]
    return scenario_faction_ids(scenario)


def secondary_objective_faction_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    faction_id = str(objective.get("faction", ""))
    if faction_id:
        return faction_id
    factions = scenario_faction_ids(scenario)
    return "any" if len(factions) > 1 else (factions[0] if factions else "any")


def secondary_objective_distance_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    target = secondary_objective_target_offset(scenario, objective)
    if target is None:
        return "n/a"
    target_coord = axial_from_offset(target)
    factions = set(secondary_objective_factions(scenario, objective))
    own_dist: list[int] = []
    enemy_dist: list[int] = []
    for unit in initial_units(scenario):
        unit_coord = axial_from_offset(unit.get("at", [0, 0]))
        distance = hex_distance(unit_coord, target_coord)
        if str(unit.get("faction", "")) in factions:
            own_dist.append(distance)
        else:
            enemy_dist.append(distance)
    own = "n/a" if not own_dist else str(min(own_dist))
    enemy = "n/a" if not enemy_dist else str(min(enemy_dist))
    return f"own {own} / enemy {enemy}"


def secondary_objective_audit_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    notes: list[str] = []
    target = secondary_objective_target_offset(scenario, objective)
    if target is None:
        notes.append("missing target")
    else:
        target_coord = axial_from_offset(target)
        factions = set(secondary_objective_factions(scenario, objective))
        own_dist: list[int] = []
        enemy_dist: list[int] = []
        for unit in initial_units(scenario):
            distance = hex_distance(axial_from_offset(unit.get("at", [0, 0])), target_coord)
            if str(unit.get("faction", "")) in factions:
                own_dist.append(distance)
            else:
                enemy_dist.append(distance)
        if own_dist and enemy_dist and min(enemy_dist) < min(own_dist):
            notes.append("enemy closer")
        if own_dist and min(own_dist) == 0:
            notes.append("starts held")

    if str(objective.get("type", "capture")) == "destroy_unit":
        target_unit = find_secondary_target_unit(scenario, str(objective.get("target_unit", "")))
        if target_unit is not None and target_unit in scenario.get("reinforcements", []):
            notes.append(f"target T{int(target_unit.get('at_turn', 0))}")

    reward_notes = secondary_reward_audit_notes(scenario, objective)
    notes.extend(reward_notes)
    return "; ".join(notes) if notes else "ok"


def secondary_reward_audit_notes(scenario: dict[str, Any], objective: dict[str, Any]) -> list[str]:
    rewards = objective.get("rewards", [])
    strategic_effects = objective.get("strategic_effects", [])
    notes: list[str] = []
    if not isinstance(rewards, list) or not rewards:
        if int(objective.get("xp_reward", 0)) <= 0 and not (
            isinstance(strategic_effects, list) and strategic_effects
        ):
            return ["no reward"]
    if isinstance(rewards, list):
        for reward in rewards:
            if not isinstance(reward, dict):
                continue
            reward_type = str(reward.get("type", ""))
            amount = int(reward.get("amount", 0))
            if amount <= 0:
                continue
            if reward_type == "advance_reinforcements":
                notes.append(secondary_reinforcement_reward_audit(scenario, objective, amount))
            elif reward_type == "recover_suppression":
                notes.append("sustain reward")
            elif reward_type == "repair_hp":
                notes.append("damage recovery")
            elif reward_type == "suppress_enemies":
                radius = int(reward.get("radius", 1))
                notes.append(f"tactical suppression reward R{radius}")
            elif reward_type == "strip_enemy_dig_in":
                radius = int(reward.get("radius", 1))
                notes.append(f"breach reward R{radius}")
    if isinstance(strategic_effects, list):
        for effect in strategic_effects:
            if not isinstance(effect, dict):
                continue
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            if amount <= 0:
                continue
            if effect_type == "campaign_bonus_points":
                notes.append(f"campaign bonus +{amount}")
            elif effect_type == "conquest_reduce_enemy_strength":
                notes.append(f"conquest pressure -{amount}")
            elif effect_type == "conquest_reduce_enemy_fortification":
                notes.append(f"conquest fort -{amount}")
            elif effect_type == "conquest_disrupt_enemy_production":
                notes.append(f"conquest production -{amount}")
    return notes


def secondary_reinforcement_reward_audit(
    scenario: dict[str, Any],
    objective: dict[str, Any],
    amount: int,
) -> str:
    factions = set(secondary_objective_factions(scenario, objective))
    bits: list[str] = []
    for reinforcement in scenario.get("reinforcements", []):
        if not isinstance(reinforcement, dict):
            continue
        if str(reinforcement.get("faction", "")) not in factions:
            continue
        current_turn = int(reinforcement.get("at_turn", 0))
        if current_turn <= 1:
            continue
        new_turn = max(1, current_turn - amount)
        bits.append(f"T{current_turn}->T{new_turn}")
    if not bits:
        return "reinforce reward has no matching future reinforcement"
    return "reinforce best " + ", ".join(sorted(set(bits)))


def conquest_secondary_coverage_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not scenario_id.startswith("conq_"):
            continue
        objectives = scenario.get("secondary_objectives", [])
        objective_count = 0
        strategic_objectives = 0
        effect_counts: collections.Counter[str] = collections.Counter()
        if isinstance(objectives, list):
            for objective in objectives:
                if not isinstance(objective, dict):
                    continue
                objective_count += 1
                objective_effect_counts = conquest_effect_counts(objective)
                if objective_effect_counts:
                    strategic_objectives += 1
                    effect_counts.update(objective_effect_counts)
        rows.append([
            scenario_id,
            objective_count,
            strategic_objectives,
            conquest_effect_mix_text(effect_counts),
            conquest_secondary_check_text(objective_count, strategic_objectives, effect_counts),
        ])
    return rows


def conquest_effect_counts(objective: dict[str, Any]) -> collections.Counter[str]:
    counts: collections.Counter[str] = collections.Counter()
    strategic_effects = objective.get("strategic_effects", [])
    if not isinstance(strategic_effects, list):
        return counts
    for effect in strategic_effects:
        if not isinstance(effect, dict):
            continue
        effect_type = str(effect.get("type", ""))
        amount = int(effect.get("amount", 0))
        if amount <= 0:
            continue
        if effect_type == "conquest_reduce_enemy_strength":
            counts["strength"] += amount
        elif effect_type == "conquest_reduce_enemy_fortification":
            counts["fort"] += amount
        elif effect_type == "conquest_disrupt_enemy_production":
            counts["production"] += amount
    return counts


def conquest_effect_mix_text(effect_counts: collections.Counter[str]) -> str:
    parts: list[str] = []
    for key, label in [("strength", "strength"), ("fort", "fort"), ("production", "production")]:
        amount = int(effect_counts.get(key, 0))
        if amount > 0:
            parts.append(f"{label} -{amount}")
    return ", ".join(parts) if parts else "none"


def conquest_secondary_check_text(
    objective_count: int,
    strategic_objectives: int,
    effect_counts: collections.Counter[str],
) -> str:
    if objective_count <= 0:
        return "missing secondary"
    if strategic_objectives <= 0 or not effect_counts:
        return "missing conquest effect"
    if strategic_objectives < objective_count:
        return "partial"
    if len([key for key, amount in effect_counts.items() if amount > 0]) < 2:
        return "single effect"
    return "covered"


def conquest_primary_variety_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not scenario_id.startswith("conq_"):
            continue
        objective = conquest_primary_objective(scenario)
        rows.append([
            scenario_id,
            conquest_primary_text(objective),
            conquest_primary_pressure_text(scenario, objective),
            conquest_primary_check_text(objective),
        ])
    return rows


def conquest_primary_objective(scenario: dict[str, Any]) -> dict[str, Any]:
    objective = scenario.get("conquest_victory", {})
    if isinstance(objective, dict) and objective:
        return objective
    return {"type": "eliminate"}


def conquest_primary_text(objective: dict[str, Any]) -> str:
    objective_type = str(objective.get("type", "eliminate"))
    by_turn = int(objective.get("by_turn", 12))
    if objective_type == "capture":
        target = objective.get("target", [])
        return f"capture {target[0]},{target[1]} by T{by_turn}" if valid_offset_target(target) else "capture n/a"
    if objective_type == "control_count":
        targets = objective.get("targets", [])
        required = int(objective.get("required", len(targets)))
        return f"control {required}/{len(targets)} by T{by_turn}"
    if objective_type == "hold_hex_turns":
        target = objective.get("target", [])
        turns = int(objective.get("required_turns", 1))
        if valid_offset_target(target):
            return f"hold {target[0]},{target[1]} {turns}t by T{by_turn}"
        return f"hold n/a {turns}t by T{by_turn}"
    return "eliminate defenders"


def conquest_primary_pressure_text(scenario: dict[str, Any], objective: dict[str, Any]) -> str:
    targets = primary_objective_targets(objective)
    if not targets:
        return "roster wipe"
    player_faction = player_faction_id(scenario)
    own = [
        unit for unit in initial_units(scenario)
        if str(unit.get("faction", "")) == player_faction
    ]
    enemies = [
        unit for unit in initial_units(scenario)
        if str(unit.get("faction", "")) != player_faction
    ]
    own_dist = [nearest_distance_to_targets(unit, targets) for unit in own]
    enemy_dist = [nearest_distance_to_targets(unit, targets) for unit in enemies]
    own_text = "n/a" if not own_dist else str(min(own_dist))
    enemy_text = "n/a" if not enemy_dist else str(min(enemy_dist))
    return f"own min {own_text} enemy min {enemy_text}"


def conquest_primary_check_text(objective: dict[str, Any]) -> str:
    objective_type = str(objective.get("type", "eliminate"))
    if objective_type == "eliminate":
        return "fallback eliminate"
    if objective_type == "control_count":
        targets = objective.get("targets", [])
        required = int(objective.get("required", len(targets)))
        if len(targets) < 2 or required <= 0 or required > len(targets):
            return "check target count"
    elif objective_type in {"capture", "hold_hex_turns"}:
        if not valid_offset_target(objective.get("target", [])):
            return "missing target"
    return "varied"


def conquest_region_trait_rows(conquest_map: dict[str, Any]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for region in conquest_map.get("regions", []):
        if not isinstance(region, dict):
            continue
        traits = [str(trait) for trait in region.get("region_traits", [])]
        rows.append([
            str(region.get("id", "")),
            str(region.get("owner", "")),
            conquest_region_logistics_text(region),
            ", ".join(traits) if traits else "none",
            conquest_region_trait_effect_text(traits),
            conquest_region_trait_check_text(region, traits),
        ])
    return rows


def conquest_region_logistics_text(region: dict[str, Any]) -> str:
    parts = [f"prod {int(region.get('production', 0))}"]
    if bool(region.get("supply_source", False)):
        parts.append("supply")
    if bool(region.get("port", False)):
        parts.append("port")
    rail_count = len(region.get("rail_neighbors", [])) if isinstance(region.get("rail_neighbors", []), list) else 0
    if rail_count > 0:
        parts.append(f"rail {rail_count}")
    return ", ".join(parts)


def conquest_region_trait_effect_text(traits: list[str]) -> str:
    strength = 0
    xp = 0
    support: list[str] = []
    for trait in traits:
        effect = REGION_TRAIT_EFFECTS.get(trait, {})
        strength += int(effect.get("strength", 0))
        xp += int(effect.get("xp", 0))
        for unit_type in effect.get("support", []):
            support.append(str(unit_type))
    parts: list[str] = []
    if strength > 0:
        parts.append(f"strength +{strength}")
    if support:
        counts = collections.Counter(support)
        parts.append("support " + ",".join(f"{unit}:{count}" for unit, count in sorted(counts.items())))
    if xp > 0:
        parts.append(f"XP +{xp}")
    return ", ".join(parts) if parts else "none"


def conquest_region_trait_check_text(region: dict[str, Any], traits: list[str]) -> str:
    notes: list[str] = []
    if not traits:
        notes.append("missing trait")
    unknown = [trait for trait in traits if trait not in REGION_TRAIT_EFFECTS]
    if unknown:
        notes.append("unknown " + ",".join(sorted(set(unknown))))
    if len(set(traits)) != len(traits):
        notes.append("duplicate trait")
    if "naval_base" in traits and not bool(region.get("port", False)):
        notes.append("naval without port")
    rail_neighbors = region.get("rail_neighbors", [])
    has_rail = isinstance(rail_neighbors, list) and len(rail_neighbors) > 0
    if "rail_junction" in traits and not has_rail:
        notes.append("rail trait without rail")
    if has_rail and "rail_junction" not in traits:
        notes.append("rail links missing trait")
    return "; ".join(notes) if notes else "covered"


def valid_offset_target(target: Any) -> bool:
    return isinstance(target, list) and len(target) >= 2


def terrain_identity_rows(scenarios: list[dict[str, Any]], units: dict[str, Any]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not is_theater_identity_scenario(scenario_id):
            continue
        profile = terrain_identity_profile(scenario)
        objective_hooks = terrain_objective_identity_text(scenario)
        role_hooks = terrain_role_identity_text(scenario, units)
        rows.append([
            scenario_id,
            terrain_identity_theme_text(profile),
            terrain_identity_signal_text(profile),
            objective_hooks,
            role_hooks,
            terrain_identity_check_text(profile, objective_hooks, role_hooks),
        ])
    return rows


def is_theater_identity_scenario(scenario_id: str) -> bool:
    return scenario_id != "00_sandbox" and not scenario_id.startswith("tut_")


def terrain_identity_profile(scenario: dict[str, Any]) -> dict[str, Any]:
    counts: collections.Counter[str] = collections.Counter()
    for row in scenario.get("map", {}).get("tiles", []):
        counts.update(str(tile) for tile in row)
    total = sum(counts.values()) or 1
    ratios = {terrain: counts.get(terrain, 0) / total for terrain in IDENTITY_TERRAINS}
    themes = [
        terrain for terrain in IDENTITY_TERRAINS
        if ratios.get(terrain, 0.0) >= IDENTITY_THRESHOLDS[terrain]
    ]
    if not themes:
        themes = ["open"]
    return {"counts": counts, "ratios": ratios, "themes": themes, "total": total}


def terrain_identity_theme_text(profile: dict[str, Any]) -> str:
    themes: list[str] = profile.get("themes", [])
    return ", ".join(themes) if themes else "open"


def terrain_identity_signal_text(profile: dict[str, Any]) -> str:
    ratios: dict[str, float] = profile.get("ratios", {})
    items = [
        (terrain, ratio) for terrain, ratio in ratios.items()
        if ratio >= 0.05
    ]
    items.sort(key=lambda item: (-item[1], item[0]))
    return ", ".join(f"{terrain}:{ratio:.0%}" for terrain, ratio in items[:4]) if items else "plain/open"


def terrain_objective_identity_text(scenario: dict[str, Any]) -> str:
    target_terrains: collections.Counter[str] = collections.Counter()
    objective_types: collections.Counter[str] = collections.Counter()
    for objective in formal_identity_objectives(scenario):
        objective_type = str(objective.get("type", ""))
        if objective_type:
            objective_types[objective_type] += 1
        for target in primary_objective_targets(objective):
            terrain = terrain_at_offset(scenario, target)
            if terrain:
                target_terrains[terrain] += 1
    objectives = scenario.get("secondary_objectives", [])
    if isinstance(objectives, list):
        for objective in objectives:
            if not isinstance(objective, dict):
                continue
            objective_type = str(objective.get("type", "capture"))
            objective_types[objective_type] += 1
            target = secondary_objective_target_offset(scenario, objective)
            if target is None:
                continue
            terrain = terrain_at_offset(scenario, target)
            if terrain:
                target_terrains[terrain] += 1
    parts: list[str] = []
    if objective_types:
        parts.append(", ".join(f"{kind}:{count}" for kind, count in sorted(objective_types.items())))
    terrain_parts = [
        f"{terrain}:{count}" for terrain, count in sorted(target_terrains.items())
        if terrain in IDENTITY_TERRAINS
    ]
    if terrain_parts:
        parts.append("targets " + ", ".join(terrain_parts))
    return "; ".join(parts) if parts else "none"


def formal_identity_objectives(scenario: dict[str, Any]) -> list[dict[str, Any]]:
    scenario_id = str(scenario.get("id", ""))
    if scenario_id.startswith("conq_"):
        objective = scenario.get("conquest_victory", {})
        return [objective] if isinstance(objective, dict) and objective else []
    player_faction = player_faction_id(scenario)
    objective = scenario.get("victory", {}).get(player_faction, {})
    return [objective] if isinstance(objective, dict) and objective else []


def terrain_at_offset(scenario: dict[str, Any], target: Any) -> str:
    if not valid_offset_target(target):
        return ""
    col = int(target[0])
    row = int(target[1])
    tiles = scenario.get("map", {}).get("tiles", [])
    if 0 <= row < len(tiles) and isinstance(tiles[row], list) and 0 <= col < len(tiles[row]):
        return str(tiles[row][col])
    return ""


def terrain_role_identity_text(scenario: dict[str, Any], units: dict[str, Any]) -> str:
    player_faction = player_faction_id(scenario)
    player_units = [
        unit for unit in initial_units(scenario)
        if str(unit.get("faction", "")) == player_faction
    ]
    role_counts: collections.Counter[str] = collections.Counter()
    for unit in player_units:
        unit_type = str(unit.get("type", ""))
        unit_def = units.get(unit_type, {})
        if unit_type == "light_tank":
            role_counts["scout"] += 1
        if unit_type == "engineer":
            role_counts["engineer"] += 1
        if unit_type == "paratrooper":
            role_counts["airdrop"] += 1
        if unit_type in {"light_tank", "medium_tank", "tank_destroyer"}:
            role_counts["armor"] += 1
        if unit_type == "mg_team":
            role_counts["mg"] += 1
        if bool(unit_def.get("indirect", False)):
            role_counts["artillery"] += 1
    for objective in scenario.get("secondary_objectives", []):
        if not isinstance(objective, dict):
            continue
        if str(objective.get("type", "")) == "recon_hex":
            role_counts["recon"] += 1
        for reward in objective.get("rewards", []):
            if not isinstance(reward, dict):
                continue
            if str(reward.get("type", "")) == "strip_enemy_dig_in":
                role_counts["breach"] += 1
            elif str(reward.get("type", "")) == "suppress_enemies":
                role_counts["suppression"] += 1
    return ", ".join(f"{role}:{count}" for role, count in sorted(role_counts.items())) if role_counts else "none"


def terrain_identity_check_text(
    profile: dict[str, Any],
    objective_hooks: str,
    role_hooks: str,
) -> str:
    themes: list[str] = profile.get("themes", [])
    if not themes or themes == ["open"]:
        return "tracked"
    if objective_hooks == "none" and role_hooks == "none":
        return "needs terrain hook"
    if objective_hooks == "none" or role_hooks == "none":
        return "partial"
    return "covered"


def gameplay_depth_coverage_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not is_main_battle_scenario(scenario_id):
            continue
        objectives = [
            objective
            for objective in scenario.get("secondary_objectives", [])
            if isinstance(objective, dict)
        ]
        xp_only = sum(1 for objective in objectives if is_xp_only_secondary(objective))
        enriched = len(objectives) - xp_only
        rows.append([
            scenario_id,
            len(objectives),
            xp_only,
            enriched,
            gameplay_depth_check_text(len(objectives), xp_only),
        ])
    return rows


def operation_chain_coverage_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not is_main_battle_scenario(scenario_id):
            continue
        objectives = [
            objective
            for objective in scenario.get("secondary_objectives", [])
            if isinstance(objective, dict)
        ]
        best_chain = longest_secondary_objective_chain(objectives)
        chain_links = sum(1 for objective in objectives if secondary_objective_required_ids(objective))
        rows.append([
            scenario_id,
            chain_links,
            len(best_chain),
            operation_chain_path_text(best_chain),
            operation_chain_reward_text(best_chain),
            operation_chain_check_text(chain_links, len(best_chain)),
        ])
    return rows


def objective_branch_coverage_rows(scenarios: list[dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if not is_main_battle_scenario(scenario_id):
            continue
        groups: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
        for objective in scenario.get("secondary_objectives", []):
            if not isinstance(objective, dict):
                continue
            group = str(objective.get("exclusive_group", ""))
            if group:
                groups[group].append(objective)
        for group, objectives in sorted(groups.items()):
            rows.append([
                scenario_id,
                group,
                len(objectives),
                objective_branch_option_text(objectives),
                objective_branch_reward_text(objectives),
                objective_branch_check_text(len(objectives)),
            ])
    return rows


def objective_branch_option_text(objectives: list[dict[str, Any]]) -> str:
    return " / ".join(str(objective.get("label", objective.get("id", "secondary"))) for objective in objectives)


def objective_branch_reward_text(objectives: list[dict[str, Any]]) -> str:
    return " / ".join(operation_reward_family(objective) for objective in objectives)


def objective_branch_check_text(option_count: int) -> str:
    if option_count < 2:
        return "broken branch"
    return "covered"


def campaign_strategic_reward_rows(
    scenarios: list[dict[str, Any]],
    campaigns: dict[str, Any],
) -> list[list[Any]]:
    scenario_by_id = {str(scenario.get("id", "")): scenario for scenario in scenarios}
    rows: list[list[Any]] = []
    for campaign_id, campaign in campaigns.items():
        if campaign_id == "00_tutorial" or not isinstance(campaign, dict):
            continue
        scenario_ids = [str(scenario_id) for scenario_id in campaign.get("scenario_order", [])]
        campaign_scenarios = [
            scenario_by_id[scenario_id]
            for scenario_id in scenario_ids
            if scenario_id in scenario_by_id
        ]
        objectives = campaign_bonus_objectives(campaign_scenarios)
        rows.append([
            campaign_id,
            len(campaign_scenarios),
            len(objectives),
            campaign_bonus_scenario_text(objectives),
            campaign_bonus_path_text(objectives),
            campaign_strategic_reward_check_text(len(campaign_scenarios), len(objectives)),
        ])
    return rows


def campaign_bonus_objectives(scenarios: list[dict[str, Any]]) -> list[tuple[str, dict[str, Any]]]:
    objectives: list[tuple[str, dict[str, Any]]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        for objective in scenario.get("secondary_objectives", []):
            if not isinstance(objective, dict):
                continue
            if secondary_objective_campaign_bonus(objective) > 0:
                objectives.append((scenario_id, objective))
    return objectives


def secondary_objective_campaign_bonus(objective: dict[str, Any]) -> int:
    total = 0
    strategic_effects = objective.get("strategic_effects", [])
    if not isinstance(strategic_effects, list):
        return 0
    for effect in strategic_effects:
        if not isinstance(effect, dict):
            continue
        if str(effect.get("type", "")) == "campaign_bonus_points":
            total += max(0, int(effect.get("amount", 0)))
    return total


def campaign_bonus_scenario_text(objectives: list[tuple[str, dict[str, Any]]]) -> str:
    if not objectives:
        return "none"
    scenario_ids = sorted({scenario_id for scenario_id, _objective in objectives})
    return ", ".join(scenario_ids)


def campaign_bonus_path_text(objectives: list[tuple[str, dict[str, Any]]]) -> str:
    if not objectives:
        return "none"
    parts: list[str] = []
    for scenario_id, objective in objectives:
        label = str(objective.get("label", objective.get("id", "secondary")))
        amount = secondary_objective_campaign_bonus(objective)
        parts.append(f"{scenario_id}:{label} +{amount}p")
    return "; ".join(parts)


def campaign_strategic_reward_check_text(scenario_count: int, objective_count: int) -> str:
    if scenario_count <= 0:
        return "missing scenarios"
    if objective_count <= 0:
        return "missing campaign reward"
    return "covered"


def longest_secondary_objective_chain(objectives: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_id = {
        secondary_objective_id(objective, index): objective
        for index, objective in enumerate(objectives)
    }
    memo: dict[str, list[dict[str, Any]]] = {}

    def best_path_to(objective_id: str, visiting: set[str] | None = None) -> list[dict[str, Any]]:
        if objective_id in memo:
            return memo[objective_id]
        if objective_id not in by_id:
            return []
        visiting = set() if visiting is None else set(visiting)
        if objective_id in visiting:
            return []
        visiting.add(objective_id)
        objective = by_id[objective_id]
        required_ids = [
            required_id for required_id in secondary_objective_required_ids(objective)
            if required_id in by_id
        ]
        if not required_ids:
            path = [objective]
        else:
            prefix = max(
                (best_path_to(required_id, visiting) for required_id in required_ids),
                key=len,
                default=[],
            )
            path = prefix + [objective]
        memo[objective_id] = path
        return path

    best: list[dict[str, Any]] = []
    for objective_id in by_id:
        path = best_path_to(objective_id)
        if len(path) > len(best):
            best = path
    return best


def secondary_objective_id(objective: dict[str, Any], index: int) -> str:
    return str(objective.get("id", f"secondary_{index}"))


def secondary_objective_required_ids(objective: dict[str, Any]) -> list[str]:
    requires = objective.get("requires", [])
    if isinstance(requires, str):
        return [requires] if requires else []
    if isinstance(requires, list):
        return [item for item in requires if isinstance(item, str) and item]
    return []


def operation_chain_path_text(chain: list[dict[str, Any]]) -> str:
    if len(chain) < 2:
        return "none"
    return " -> ".join(str(objective.get("label", objective.get("id", "secondary"))) for objective in chain)


def operation_chain_reward_text(chain: list[dict[str, Any]]) -> str:
    if len(chain) < 2:
        return "none"
    parts = [operation_reward_family(objective) for objective in chain]
    return " -> ".join(parts)


def operation_reward_family(objective: dict[str, Any]) -> str:
    families: list[str] = []
    rewards = objective.get("rewards", [])
    if isinstance(rewards, list):
        for reward in rewards:
            if not isinstance(reward, dict):
                continue
            reward_type = str(reward.get("type", ""))
            amount = int(reward.get("amount", 0))
            if amount <= 0:
                continue
            if reward_type == "strip_enemy_dig_in":
                families.append("breach")
            elif reward_type == "suppress_enemies":
                families.append("suppression")
            elif reward_type == "advance_reinforcements":
                families.append("reinforcement")
            elif reward_type == "recover_suppression":
                families.append("sustain")
            elif reward_type == "repair_hp":
                families.append("repair")
    strategic_effects = objective.get("strategic_effects", [])
    if isinstance(strategic_effects, list):
        for effect in strategic_effects:
            if not isinstance(effect, dict):
                continue
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            if amount <= 0:
                continue
            if effect_type == "campaign_bonus_points":
                families.append("campaign")
            elif effect_type == "conquest_reduce_enemy_strength":
                families.append("conquest")
            elif effect_type == "conquest_reduce_enemy_fortification":
                families.append("conquest-fort")
            elif effect_type == "conquest_disrupt_enemy_production":
                families.append("conquest-production")
    if not families:
        return "xp"
    return "+".join(dict.fromkeys(families))


def operation_chain_check_text(chain_links: int, longest_chain: int) -> str:
    if chain_links <= 0:
        return "missing chain"
    if longest_chain < 2:
        return "broken chain"
    return "covered"


def expansion_coverage_rows(scenarios: list[dict[str, Any]], campaigns: dict[str, Any]) -> list[list[Any]]:
    rows: list[list[Any]] = []
    for campaign_id, campaign in campaigns.items():
        if campaign_id == "00_tutorial" or not isinstance(campaign, dict):
            continue
        scenario_ids = [str(scenario_id) for scenario_id in campaign.get("scenario_order", [])]
        campaign_scenarios = [
            scenario for scenario in scenarios
            if str(scenario.get("id", "")) in scenario_ids
        ]
        rows.append([
            campaign_id,
            len(campaign_scenarios),
            campaign_victory_text(campaign_scenarios),
            campaign_special_terrain_text(campaign_scenarios),
            campaign_role_coverage_text(campaign_scenarios),
            expansion_check_text(campaign_id, campaign_scenarios),
        ])
    return rows


def player_faction_id(scenario: dict[str, Any]) -> str:
    for faction in scenario.get("factions", []):
        if isinstance(faction, dict) and str(faction.get("controller", "")) == "player":
            return str(faction.get("id", ""))
    return ""


def campaign_victory_text(scenarios: list[dict[str, Any]]) -> str:
    counts: collections.Counter[str] = collections.Counter()
    for scenario in scenarios:
        player_faction = player_faction_id(scenario)
        victory = scenario.get("victory", {}).get(player_faction, {})
        counts[str(victory.get("type", "unknown"))] += 1
    return ", ".join(f"{kind}:{count}" for kind, count in sorted(counts.items())) if counts else "none"


def campaign_special_terrain_text(scenarios: list[dict[str, Any]]) -> str:
    terrain_hits: dict[str, int] = {
        "desert": 0,
        "jungle": 0,
        "sea": 0,
        "river": 0,
        "town": 0,
    }
    for scenario in scenarios:
        counts: collections.Counter[str] = collections.Counter()
        for row in scenario.get("map", {}).get("tiles", []):
            counts.update(str(tile) for tile in row)
        total = sum(counts.values()) or 1
        for terrain in terrain_hits:
            if counts.get(terrain, 0) / total >= 0.05:
                terrain_hits[terrain] += 1
    return ", ".join(f"{terrain}:{count}" for terrain, count in terrain_hits.items() if count > 0) or "none"


def campaign_role_coverage_text(scenarios: list[dict[str, Any]]) -> str:
    counts = {
        "reinforcement": 0,
        "scout": 0,
        "engineer": 0,
        "airdrop": 0,
    }
    for scenario in scenarios:
        player_faction = player_faction_id(scenario)
        player_units = [
            unit for unit in scenario.get("units", [])
            if isinstance(unit, dict) and str(unit.get("faction", "")) == player_faction
        ]
        if scenario.get("reinforcements", []):
            counts["reinforcement"] += 1
        if any(str(unit.get("type", "")) == "light_tank" for unit in player_units):
            counts["scout"] += 1
        if any(str(unit.get("type", "")) == "engineer" for unit in player_units):
            counts["engineer"] += 1
        if any(str(unit.get("type", "")) == "paratrooper" for unit in player_units):
            counts["airdrop"] += 1
    return ", ".join(f"{key}:{value}" for key, value in counts.items() if value > 0) or "none"


def expansion_check_text(campaign_id: str, scenarios: list[dict[str, Any]]) -> str:
    if not scenarios:
        return "missing scenarios"
    victory_text = campaign_victory_text(scenarios)
    terrain_text = campaign_special_terrain_text(scenarios)
    role_text = campaign_role_coverage_text(scenarios)
    if campaign_id in {"north_africa", "pacific_front"} and "capture:" in victory_text and "eliminate:" not in victory_text:
        return "needs non-capture pressure"
    if campaign_id == "north_africa" and "desert:" not in terrain_text:
        return "missing desert"
    if campaign_id == "pacific_front" and "jungle:" not in terrain_text:
        return "missing jungle"
    if campaign_id == "western_front" and "airdrop:" not in role_text:
        return "missing airdrop focus"
    return "tracked"


def is_main_battle_scenario(scenario_id: str) -> bool:
    return (
        scenario_id != "00_sandbox"
        and not scenario_id.startswith("tut_")
        and not scenario_id.startswith("conq_")
    )


def is_xp_only_secondary(objective: dict[str, Any]) -> bool:
    rewards = objective.get("rewards", [])
    strategic_effects = objective.get("strategic_effects", [])
    has_xp = int(objective.get("xp_reward", 0)) > 0
    non_xp_reward = False
    if isinstance(rewards, list):
        for reward in rewards:
            if not isinstance(reward, dict):
                continue
            amount = int(reward.get("amount", 0))
            if amount <= 0:
                continue
            reward_type = str(reward.get("type", ""))
            if reward_type == "xp":
                has_xp = True
            else:
                non_xp_reward = True
    has_strategic = isinstance(strategic_effects, list) and any(
        isinstance(effect, dict) and int(effect.get("amount", 0)) != 0
        for effect in strategic_effects
    )
    return has_xp and not non_xp_reward and not has_strategic


def gameplay_depth_check_text(objective_count: int, xp_only: int) -> str:
    if objective_count <= 0:
        return "missing secondary"
    if xp_only == objective_count:
        return "xp-only"
    return "covered"


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


def breach_path_pressure(
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    parts: list[str] = []
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        stats = breach_stats_for_faction(scenario, faction_id, units, terrains)
        if stats is None:
            continue
        engineer_bit = "eng none"
        if int(stats["engineers"]) > 0:
            engineer_bit = f"eng min {stats['engineer_min']}"
        artillery_bit = f"art {stats['artillery_coverage']}/{stats['targets']}"
        parts.append(f"{faction_id}: {engineer_bit}, {artillery_bit}, targets {stats['targets']}")
    return "; ".join(parts) if parts else "n/a"


def engineer_breach_tempo(
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    parts: list[str] = []
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        stats = breach_stats_for_faction(scenario, faction_id, units, terrains)
        if stats is None:
            continue
        if int(stats["engineers"]) <= 0:
            parts.append(f"{faction_id}: eng turns none")
            continue
        if stats["engineer_turns"] is None:
            parts.append(f"{faction_id}: eng turns blocked")
        else:
            parts.append(f"{faction_id}: eng turns {stats['engineer_turns']}")
    return "; ".join(parts) if parts else "n/a"


def artillery_reposition_pressure(
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> str:
    parts: list[str] = []
    faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
    for faction_id in faction_ids:
        stats = breach_stats_for_faction(scenario, faction_id, units, terrains)
        if stats is None:
            continue
        if int(stats["artillery"]) <= 0:
            parts.append(f"{faction_id}: art move none")
            continue
        parts.append(f"{faction_id}: art move {stats['artillery_move_coverage']}/{stats['targets']}")
    return "; ".join(parts) if parts else "n/a"


def breach_stats_for_faction(
    scenario: dict[str, Any],
    faction_id: str,
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> dict[str, Any] | None:
    if not needs_breach_pressure(scenario, faction_id):
        return None
    targets = breach_targets_for_faction(scenario, faction_id)
    if not targets:
        return None

    own_units = [u for u in initial_units(scenario) if str(u.get("faction", "")) == faction_id]
    engineers = [u for u in own_units if str(u.get("type", "")) == "engineer"]
    indirect = [
        u for u in own_units
        if bool(units.get(str(u.get("type", "")), {}).get("indirect", False))
    ]
    target_coords = [axial_from_offset(target.get("at", [0, 0])) for target in targets]

    engineer_min: int | None = None
    if engineers:
        engineer_min = min(
            hex_distance(axial_from_offset(engineer.get("at", [0, 0])), target)
            for engineer in engineers
            for target in target_coords
        )

    covered_targets: set[tuple[int, int]] = set()
    for gun in indirect:
        gun_def = units.get(str(gun.get("type", "")), {})
        gun_coord = axial_from_offset(gun.get("at", [0, 0]))
        rng = int(gun_def.get("range", 1))
        for target in target_coords:
            if hex_distance(gun_coord, target) <= rng:
                covered_targets.add(target)

    best_turns: int | None = None
    if engineers:
        occupied = occupied_by_initial_units(scenario)
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
            for target in target_coords:
                attack_costs = [
                    cost for coord, cost in costs.items()
                    if hex_distance(coord, target) <= attack_range
                ]
                if not attack_costs:
                    continue
                turns = max(0, math.ceil(min(attack_costs) / move_budget))
                best_turns = turns if best_turns is None else min(best_turns, turns)

    movable_artillery_coverage: set[tuple[int, int]] = set()
    if indirect:
        occupied = occupied_by_initial_units(scenario)
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
                        movable_artillery_coverage.add(target_coord)

    high_cover_targets = 0
    tiles = scenario_tiles(scenario)
    for target in targets:
        coord = axial_from_offset(target.get("at", [0, 0]))
        terrain_id = tiles.get(coord, "")
        terrain_def = terrains.get(terrain_id, {})
        if int(terrain_def.get("defense", 0)) >= 2 or int(target.get("dig_in", 0)) > 0:
            high_cover_targets += 1

    return {
        "targets": len(target_coords),
        "high_cover_targets": high_cover_targets,
        "engineers": len(engineers),
        "engineer_min": engineer_min,
        "engineer_turns": best_turns,
        "artillery": len(indirect),
        "artillery_coverage": len(covered_targets),
        "artillery_move_coverage": len(movable_artillery_coverage),
    }


def urban_breach_focus_rows(
    scenarios: list[dict[str, Any]],
    units: dict[str, Any],
    terrains: dict[str, Any],
) -> list[list[Any]]:
    focus_ids = {"03_stalingrad_1942", "east_10_berlin_1945"}
    rows: list[list[Any]] = []
    for scenario in scenarios:
        scenario_id = str(scenario.get("id", ""))
        if scenario_id not in focus_ids:
            continue
        faction_ids = [str(faction.get("id", "")) for faction in scenario.get("factions", [])]
        for faction_id in faction_ids:
            stats = breach_stats_for_faction(scenario, faction_id, units, terrains)
            if stats is None:
                continue
            check = urban_breach_check_text(stats)
            rows.append([
                scenario_id,
                faction_id,
                f"{stats['high_cover_targets']}/{stats['targets']}",
                "none" if stats["engineer_min"] is None else stats["engineer_min"],
                "blocked" if stats["engineer_turns"] is None else stats["engineer_turns"],
                f"{stats['artillery_coverage']}/{stats['targets']}",
                f"{stats['artillery_move_coverage']}/{stats['targets']}",
                check,
            ])
    return rows


def urban_breach_check_text(stats: dict[str, Any]) -> str:
    if int(stats["engineers"]) <= 0:
        return "missing engineer"
    if stats["engineer_turns"] is None:
        return "engineer route blocked"
    if int(stats["artillery_coverage"]) == 0 and int(stats["artillery_move_coverage"]) == 0:
        return "playtest engineer survivability; no artillery breach coverage"
    if int(stats["engineer_turns"]) >= 4:
        return "playtest breach timing"
    return "supported"


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
    campaigns = load_json(CAMPAIGNS_PATH)
    conquest_map = load_json(CONQUEST_MAP_PATH)
    scenarios = [load_json(Path(path)) for path in sorted(glob.glob(SCENARIOS_GLOB))]

    rows: list[list[Any]] = []
    for scenario in scenarios:
        rows.append(
            [
                scenario.get("id", ""),
                suppression_sources(scenario),
                artillery_coverage(scenario, units),
                spotter_coverage(scenario, units),
                breach_path_pressure(scenario, units, terrains),
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
        "## Urban Breach Focus",
        "Focused gate for city assaults that already have breach tools but still need manual survivability checks.",
        table(
            [
                "scenario",
                "faction",
                "high-cover targets",
                "eng min",
                "eng turns",
                "art now",
                "art after move",
                "check",
            ],
            urban_breach_focus_rows(scenarios, units, terrains),
        ),
        "## Secondary Objective Reward Audit",
        "Focused audit of optional objective pressure, reward type, and static reward effectiveness.",
        table(
            [
                "scenario",
                "objective",
                "target",
                "faction",
                "distance",
                "rewards",
                "audit",
            ],
            secondary_objective_focus_rows(scenarios),
        ),
        "## Conquest Secondary Coverage",
        "Focused gate for conquest templates: each conq_* battle should give optional objectives varied strategic effects instead of XP-only or single-axis pressure.",
        table(
            [
                "scenario",
                "secondary objectives",
                "strategic objectives",
                "strategic effect mix",
                "check",
            ],
            conquest_secondary_coverage_rows(scenarios),
        ),
        "## Conquest Primary Variety",
        "Focused gate for conquest templates: attack battles should vary their formal objective instead of defaulting every region to a roster wipe.",
        table(
            [
                "scenario",
                "attack objective",
                "objective pressure",
                "check",
            ],
            conquest_primary_variety_rows(scenarios),
        ),
        "## Conquest Region Trait Coverage",
        "Focused gate for conquest-map identity: each strategic region should carry deterministic tactical traits that match its logistics and theater role.",
        table(
            [
                "region",
                "owner",
                "logistics",
                "traits",
                "battle effects",
                "check",
            ],
            conquest_region_trait_rows(conquest_map),
        ),
        "## Terrain Identity Coverage",
        "Focused gate for terrain/theater identity: each non-tutorial battle should expose its dominant terrain signals, objective hooks, and player-side role hooks.",
        table(
            [
                "scenario",
                "terrain theme",
                "terrain signals",
                "objective hooks",
                "role hooks",
                "check",
            ],
            terrain_identity_rows(scenarios, units),
        ),
        "## Gameplay Depth Coverage",
        "Focused gate for non-tutorial, non-conquest battles: each main battle should have optional pressure, and reports should show XP-only objectives separately from richer tactical or strategic rewards.",
        table(
            [
                "scenario",
                "secondary objectives",
                "xp-only objectives",
                "enriched objectives",
                "check",
            ],
            gameplay_depth_coverage_rows(scenarios),
        ),
        "## Operation Chain Coverage",
        "Focused gate for main battles: secondary objectives should form at least one explicit operation chain so optional goals create staged tactical tempo.",
        table(
            [
                "scenario",
                "chain links",
                "longest chain",
                "operation path",
                "reward ladder",
                "check",
            ],
            operation_chain_coverage_rows(scenarios),
        ),
        "## Objective Branch Coverage",
        "Focused gate for main battles with explicit secondary-objective tradeoffs: exclusive branches should present at least two mutually exclusive tactical rewards.",
        table(
            [
                "scenario",
                "branch",
                "options",
                "choices",
                "reward families",
                "check",
            ],
            objective_branch_coverage_rows(scenarios),
        ),
        "## Campaign Strategic Reward Coverage",
        "Focused gate for formal campaigns: optional objectives should create at least one cross-battle resource decision per campaign.",
        table(
            [
                "campaign",
                "scenarios",
                "campaign reward objectives",
                "reward scenarios",
                "reward paths",
                "check",
            ],
            campaign_strategic_reward_rows(scenarios, campaigns),
        ),
        "## Scenario Expansion Coverage",
        "Dynamic coverage gate for formal campaign expansion: reports campaign size, victory variety, special terrain usage, and role hooks that should diversify new battles.",
        table(
            [
                "campaign",
                "scenarios",
                "victory mix",
                "special terrain",
                "role hooks",
                "check",
            ],
            expansion_coverage_rows(scenarios, campaigns),
        ),
    ]
    return "\n\n".join(sections) + "\n"


def main() -> None:
    DEFAULT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    DEFAULT_OUTPUT.write_text(generate_report(), encoding="utf-8")
    print(f"Wrote {DEFAULT_OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
