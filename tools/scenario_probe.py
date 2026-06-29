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
            parts.append(
                f"{label} {target[0]},{target[1]} {secondary_objective_type_text(objective)}{prerequisite_text} "
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
    if target is None:
        return f"{secondary_objective_type_text(objective)} n/a{prerequisite_text}"
    return f"{secondary_objective_type_text(objective)} {target[0]},{target[1]}{prerequisite_text}"


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
        pressure = 0
        if isinstance(objectives, list):
            for objective in objectives:
                if not isinstance(objective, dict):
                    continue
                objective_count += 1
                objective_pressure = conquest_pressure_amount(objective)
                if objective_pressure > 0:
                    strategic_objectives += 1
                    pressure += objective_pressure
        rows.append([
            scenario_id,
            objective_count,
            strategic_objectives,
            f"-{pressure}" if pressure > 0 else "0",
            conquest_secondary_check_text(objective_count, strategic_objectives, pressure),
        ])
    return rows


def conquest_pressure_amount(objective: dict[str, Any]) -> int:
    total = 0
    strategic_effects = objective.get("strategic_effects", [])
    if not isinstance(strategic_effects, list):
        return 0
    for effect in strategic_effects:
        if not isinstance(effect, dict):
            continue
        if str(effect.get("type", "")) != "conquest_reduce_enemy_strength":
            continue
        amount = int(effect.get("amount", 0))
        if amount > 0:
            total += amount
    return total


def conquest_secondary_check_text(objective_count: int, strategic_objectives: int, pressure: int) -> str:
    if objective_count <= 0:
        return "missing secondary"
    if strategic_objectives <= 0 or pressure <= 0:
        return "missing conquest pressure"
    if strategic_objectives < objective_count:
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
        "Focused gate for conquest templates: each conq_* battle should give optional objectives a strategic enemy-strength effect instead of XP-only pressure.",
        table(
            [
                "scenario",
                "secondary objectives",
                "strategic objectives",
                "enemy strength pressure",
                "check",
            ],
            conquest_secondary_coverage_rows(scenarios),
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
