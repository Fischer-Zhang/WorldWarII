#!/usr/bin/env python3
"""Validate static JSON data used by the Godot runtime."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SCENARIOS = DATA / "scenarios"

MAX_SUPPRESSION = 5
MAX_DIG_IN = 3
MAX_RANK = 3
ALLOWED_SECONDARY_REWARD_TYPES = {
    "xp",
    "recover_suppression",
    "repair_hp",
    "advance_reinforcements",
    "suppress_enemies",
    "strip_enemy_dig_in",
}
ALLOWED_SECONDARY_STRATEGIC_EFFECT_TYPES = {
	"campaign_bonus_points",
	"conquest_reduce_enemy_strength",
	"conquest_reduce_enemy_fortification",
	"conquest_disrupt_enemy_production",
}
ALLOWED_CONQUEST_OBJECTIVE_REWARD_TYPES = {"theater_reinforcement"}
ALLOWED_CONQUEST_REGION_TRAITS = {
    "industrial_hub",
    "fortress_line",
    "rail_junction",
    "airfield_network",
    "naval_base",
    "jungle_front",
    "oilfield",
}
ALLOWED_SECONDARY_OBJECTIVE_TYPES = {"capture", "hold_turns", "destroy_unit", "recon_hex"}
ALLOWED_CONQUEST_VICTORY_TYPES = {"eliminate", "capture", "control_count", "hold_hex_turns"}
# Conquest powers a general may belong to (drives which country can field them);
# "france" has no conquest country but is used by campaign scenarios.
GENERAL_COUNTRIES = {"germany", "soviet", "usa", "britain", "japan", "china", "france"}
REQUIRED_TUTORIAL_MECHANICS = {
    "movement",
    "attack",
    "counterattack",
    "capture",
    "secondary_objective",
    "terrain_defense",
    "zoc",
    "overwatch",
    "suppression",
    "rally",
    "dig_in",
    "direct_fire_los",
    "indirect_fire",
    "spotting",
    "armor",
    "anti_armor",
    "armor_standoff",
    "engineer_bridge",
    "engineer_breach",
    "airdrop",
    "general_skill",
    "veteran",
    "reinforcements",
    "splash_damage",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{path.relative_to(ROOT)} must contain a JSON object")
    return data


def offset_to_axial(at: list[Any]) -> tuple[int, int]:
    col = int(at[0])
    row = int(at[1])
    return col - (row >> 1), row


def fail(errors: list[str], path: Path, message: str) -> None:
    errors.append(f"{path.relative_to(ROOT)}: {message}")


def secondary_target_unit_exists(scenario: dict[str, Any], target_unit: str) -> bool:
    if not target_unit:
        return False
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
                return True
    return False


def validate_catalogs(errors: list[str]) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any]]:
    units = load_json(DATA / "units.json")
    terrains = load_json(DATA / "terrains.json")
    generals = load_json(DATA / "generals.json")
    campaigns = load_json(DATA / "campaigns.json")
    tech_tree = load_json(DATA / "tech_tree.json")

    for unit_id, unit in units.items():
        path = DATA / "units.json"
        if not isinstance(unit, dict):
            fail(errors, path, f"unit {unit_id!r} must be an object")
            continue
        for key in ("hp", "attack", "defense", "range", "move", "vision", "armor"):
            if key not in unit:
                fail(errors, path, f"unit {unit_id!r} missing {key!r}")
            elif int(unit[key]) < 0:
                fail(errors, path, f"unit {unit_id!r} has negative {key!r}")
        if int(unit.get("hp", 0)) <= 0:
            fail(errors, path, f"unit {unit_id!r} hp must be positive")
        if "armor_standoff_vs_armor_bonus" in unit or "armor_standoff_min_range" in unit:
            try:
                bonus = int(unit.get("armor_standoff_vs_armor_bonus", 0))
                min_range = int(unit.get("armor_standoff_min_range", 0))
                if bonus <= 0:
                    fail(errors, path, f"unit {unit_id!r} armor_standoff_vs_armor_bonus must be positive")
                if min_range <= 0:
                    fail(errors, path, f"unit {unit_id!r} armor_standoff_min_range must be positive")
                if min_range > int(unit.get("range", 1)):
                    fail(errors, path, f"unit {unit_id!r} armor_standoff_min_range exceeds range")
            except (TypeError, ValueError):
                fail(errors, path, f"unit {unit_id!r} armor standoff fields must be integers")
        if "overwatch_damage_pct" in unit and int(unit.get("overwatch_damage_pct", 0)) <= 0:
            fail(errors, path, f"unit {unit_id!r} overwatch_damage_pct must be positive")
        req = unit.get("requires_tech")
        if req is not None:
            if not isinstance(req, dict) or "id" not in req or "level" not in req:
                fail(errors, path, f"unit {unit_id!r} requires_tech must be an object with id and level")
            elif str(req["id"]) not in tech_tree:
                fail(errors, path, f"unit {unit_id!r} requires_tech references unknown tech {req['id']!r}")
            else:
                max_level = len(tech_tree[str(req["id"])].get("levels", []))
                if not (1 <= int(req["level"]) <= max_level):
                    fail(errors, path, f"unit {unit_id!r} requires_tech level {req['level']} out of range 1..{max_level}")
                if unit_id not in tech_tree[str(req["id"])].get("applies_to", []):
                    fail(errors, path, f"unit {unit_id!r} requires_tech {req['id']!r} but is not in that tech's applies_to")

    for terrain_id, terrain in terrains.items():
        path = DATA / "terrains.json"
        if not isinstance(terrain, dict):
            fail(errors, path, f"terrain {terrain_id!r} must be an object")
            continue
        for key in ("move_cost", "defense", "color"):
            if key not in terrain:
                fail(errors, path, f"terrain {terrain_id!r} missing {key!r}")
        if int(terrain.get("move_cost", 0)) <= 0:
            fail(errors, path, f"terrain {terrain_id!r} move_cost must be positive")

    for general_id, general in generals.items():
        path = DATA / "generals.json"
        if not isinstance(general, dict):
            fail(errors, path, f"general {general_id!r} must be an object")
            continue
        applies_to = general.get("applies_to", [])
        if not isinstance(applies_to, list) or not applies_to:
            fail(errors, path, f"general {general_id!r} must list applies_to")
        for type_id in applies_to:
            if str(type_id) not in units:
                fail(errors, path, f"general {general_id!r} references unknown unit type {type_id!r}")
        # Nationality drives which conquest power may field the general.
        country = str(general.get("country", ""))
        if country not in GENERAL_COUNTRIES:
            fail(errors, path, f"general {general_id!r} has missing/unknown country {country!r}")

    return units, terrains, generals, campaigns


def validate_scenario(
    path: Path,
    scenario: dict[str, Any],
    units: dict[str, Any],
    terrains: dict[str, Any],
    generals: dict[str, Any],
    scenario_ids: set[str],
    errors: list[str],
) -> None:
    scenario_id = str(scenario.get("id", ""))
    if not scenario_id:
        fail(errors, path, "missing id")
    elif scenario_id in scenario_ids:
        fail(errors, path, f"duplicate scenario id {scenario_id!r}")
    scenario_ids.add(scenario_id)
    if "deployment_locked" in scenario and not isinstance(scenario["deployment_locked"], bool):
        fail(errors, path, "deployment_locked must be a boolean")
    if "deployment_radius" in scenario:
        try:
            if int(scenario["deployment_radius"]) < 0:
                fail(errors, path, "deployment_radius must be non-negative")
        except (TypeError, ValueError):
            fail(errors, path, "deployment_radius must be an integer")

    map_data = scenario.get("map", {})
    if not isinstance(map_data, dict):
        fail(errors, path, "map must be an object")
        return
    width = int(map_data.get("width", 0))
    height = int(map_data.get("height", 0))
    rows = map_data.get("tiles", [])
    if not isinstance(rows, list) or len(rows) != height:
        fail(errors, path, f"map height {height} does not match tile rows {len(rows) if isinstance(rows, list) else 'non-list'}")
        rows = []
    for row_idx, row in enumerate(rows):
        if not isinstance(row, list):
            fail(errors, path, f"map row {row_idx} must be a list")
            continue
        if len(row) != width:
            fail(errors, path, f"map row {row_idx} width {len(row)} does not match declared width {width}")
        for col_idx, terrain_id in enumerate(row):
            if str(terrain_id) not in terrains:
                fail(errors, path, f"tile [{col_idx},{row_idx}] references unknown terrain {terrain_id!r}")

    factions = scenario.get("factions", [])
    faction_ids: set[str] = set()
    if not isinstance(factions, list) or not factions:
        fail(errors, path, "must define at least one faction")
    else:
        player_count = 0
        for faction in factions:
            if not isinstance(faction, dict):
                fail(errors, path, "faction entry must be an object")
                continue
            faction_id = str(faction.get("id", ""))
            if not faction_id:
                fail(errors, path, "faction missing id")
                continue
            if faction_id in faction_ids:
                fail(errors, path, f"duplicate faction id {faction_id!r}")
            faction_ids.add(faction_id)
            if str(faction.get("controller", "")) == "player":
                player_count += 1
        if player_count != 1:
            fail(errors, path, f"expected exactly one player faction, found {player_count}")

    seen_coords: dict[tuple[int, int], str] = {}
    seen_unit_ids: dict[str, str] = {}
    scenario_units = scenario.get("units", [])
    if not isinstance(scenario_units, list) or not scenario_units:
        fail(errors, path, "must define at least one unit")
        scenario_units = []
    for index, unit in enumerate(scenario_units):
        validate_unique_unit_id(path, unit, index, "units", seen_unit_ids, errors)
        validate_unit_entry(path, unit, index, "units", units, generals, faction_ids, width, height, seen_coords, errors)

    reinforcements = scenario.get("reinforcements", [])
    if not isinstance(reinforcements, list):
        fail(errors, path, "reinforcements must be a list when present")
    else:
        for index, unit in enumerate(reinforcements):
            validate_unique_unit_id(path, unit, index, "reinforcements", seen_unit_ids, errors)
            validate_unit_entry(path, unit, index, "reinforcements", units, generals, faction_ids, width, height, {}, errors)
            if int(unit.get("at_turn", 0)) <= 0:
                fail(errors, path, f"reinforcements[{index}] at_turn must be positive")

    victory = scenario.get("victory", {})
    if not isinstance(victory, dict) or not victory:
        fail(errors, path, "victory must be a non-empty object")
    else:
        for faction_id, objective in victory.items():
            if str(faction_id) not in faction_ids:
                fail(errors, path, f"victory references unknown faction {faction_id!r}")
                continue
            if not isinstance(objective, dict):
                fail(errors, path, f"victory {faction_id!r} must be an object")
                continue
            objective_type = str(objective.get("type", ""))
            if objective_type not in {"capture", "survive", "eliminate", "control_count", "hold_hex_turns"}:
                fail(errors, path, f"victory {faction_id!r} has unknown type {objective_type!r}")
            if objective_type in {"capture", "hold_hex_turns"}:
                target = objective.get("target", [])
                if not in_bounds(target, width, height):
                    fail(errors, path, f"victory {faction_id!r} {objective_type} target out of bounds: {target!r}")
            if objective_type == "hold_hex_turns":
                try:
                    if int(objective.get("required_turns", 0)) <= 0:
                        fail(errors, path, f"victory {faction_id!r} hold_hex_turns required_turns must be positive")
                except (TypeError, ValueError):
                    fail(errors, path, f"victory {faction_id!r} hold_hex_turns required_turns must be an integer")
            if objective_type == "control_count":
                targets = objective.get("targets", [])
                if not isinstance(targets, list) or not targets:
                    fail(errors, path, f"victory {faction_id!r} control_count needs a non-empty targets list")
                else:
                    for t in targets:
                        if not in_bounds(t, width, height):
                            fail(errors, path, f"victory {faction_id!r} control_count target out of bounds: {t!r}")
                    try:
                        required = int(objective.get("required", len(targets)))
                        if required <= 0 or required > len(targets):
                            fail(errors, path, f"victory {faction_id!r} control_count required must be 1..{len(targets)}")
                    except (TypeError, ValueError):
                        fail(errors, path, f"victory {faction_id!r} control_count required must be an integer")

    validate_objective_shape(
        path,
        scenario.get("conquest_victory", {}),
        "conquest_victory",
        width,
        height,
        errors,
        allow_empty=True,
    )

    secondary_objectives = scenario.get("secondary_objectives", [])
    if "secondary_objectives" in scenario and not isinstance(secondary_objectives, list):
        fail(errors, path, "secondary_objectives must be a list when present")
    elif isinstance(secondary_objectives, list):
        seen_secondary_ids: set[str] = set()
        objective_entries: list[tuple[int, dict[str, Any], str]] = []
        for index, objective in enumerate(secondary_objectives):
            if not isinstance(objective, dict):
                fail(errors, path, f"secondary_objectives[{index}] must be an object")
                continue
            objective_id = str(objective.get("id", f"secondary_{index}"))
            if objective_id in seen_secondary_ids:
                fail(errors, path, f"secondary_objectives[{index}] duplicate id {objective_id!r}")
            seen_secondary_ids.add(objective_id)
            objective_entries.append((index, objective, objective_id))
            objective_type = str(objective.get("type", "capture"))
            if objective_type not in ALLOWED_SECONDARY_OBJECTIVE_TYPES:
                fail(errors, path, f"secondary_objectives[{index}] unknown type {objective_type!r}")
            exclusive_group = str(objective.get("exclusive_group", ""))
            if "exclusive_group" in objective and not exclusive_group:
                fail(errors, path, f"secondary_objectives[{index}] exclusive_group must not be empty")
            faction_id = str(objective.get("faction", ""))
            if faction_id and faction_id not in faction_ids:
                fail(errors, path, f"secondary_objectives[{index}] references unknown faction {faction_id!r}")
            if objective_type in {"capture", "hold_turns", "recon_hex"}:
                target = objective.get("target", [])
                if not in_bounds(target, width, height):
                    fail(errors, path, f"secondary_objectives[{index}] target out of bounds: {target!r}")
            if objective_type == "hold_turns":
                try:
                    if int(objective.get("required_turns", 0)) <= 0:
                        fail(errors, path, f"secondary_objectives[{index}] required_turns must be positive")
                except (TypeError, ValueError):
                    fail(errors, path, f"secondary_objectives[{index}] required_turns must be an integer")
            if objective_type == "destroy_unit":
                target_unit = str(objective.get("target_unit", ""))
                if not target_unit:
                    fail(errors, path, f"secondary_objectives[{index}] target_unit is required")
                elif not secondary_target_unit_exists(scenario, target_unit):
                    fail(errors, path, f"secondary_objectives[{index}] target_unit {target_unit!r} not found")
            try:
                if int(objective.get("xp_reward", 0)) < 0:
                    fail(errors, path, f"secondary_objectives[{index}] xp_reward must be non-negative")
            except (TypeError, ValueError):
                fail(errors, path, f"secondary_objectives[{index}] xp_reward must be an integer")
            rewards = objective.get("rewards", [])
            if "rewards" in objective and not isinstance(rewards, list):
                fail(errors, path, f"secondary_objectives[{index}] rewards must be a list when present")
            elif isinstance(rewards, list):
                for reward_index, reward in enumerate(rewards):
                    if not isinstance(reward, dict):
                        fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] must be an object")
                        continue
                    reward_type = str(reward.get("type", ""))
                    if reward_type not in ALLOWED_SECONDARY_REWARD_TYPES:
                        fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] unknown type {reward_type!r}")
                    try:
                        if int(reward.get("amount", 0)) <= 0:
                            fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] amount must be positive")
                    except (TypeError, ValueError):
                        fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] amount must be an integer")
                    if reward_type in {"suppress_enemies", "strip_enemy_dig_in"}:
                        try:
                            if int(reward.get("radius", 1)) < 0:
                                fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] radius must be non-negative")
                        except (TypeError, ValueError):
                            fail(errors, path, f"secondary_objectives[{index}].rewards[{reward_index}] radius must be an integer")
            strategic_effects = objective.get("strategic_effects", [])
            if "strategic_effects" in objective and not isinstance(strategic_effects, list):
                fail(errors, path, f"secondary_objectives[{index}] strategic_effects must be a list when present")
            elif isinstance(strategic_effects, list):
                for effect_index, effect in enumerate(strategic_effects):
                    if not isinstance(effect, dict):
                        fail(errors, path, f"secondary_objectives[{index}].strategic_effects[{effect_index}] must be an object")
                        continue
                    effect_type = str(effect.get("type", ""))
                    if effect_type not in ALLOWED_SECONDARY_STRATEGIC_EFFECT_TYPES:
                        fail(errors, path, f"secondary_objectives[{index}].strategic_effects[{effect_index}] unknown type {effect_type!r}")
                    try:
                        if int(effect.get("amount", 0)) <= 0:
                            fail(errors, path, f"secondary_objectives[{index}].strategic_effects[{effect_index}] amount must be positive")
                    except (TypeError, ValueError):
                        fail(errors, path, f"secondary_objectives[{index}].strategic_effects[{effect_index}] amount must be an integer")
        prerequisite_graph: dict[str, list[str]] = {}
        prerequisite_indices: dict[str, int] = {}
        exclusive_groups: dict[str, list[str]] = {}
        objective_groups: dict[str, str] = {}
        objective_index_by_id: dict[str, int] = {}
        for index, objective, objective_id in objective_entries:
            objective_index_by_id[objective_id] = index
            exclusive_group = str(objective.get("exclusive_group", ""))
            if exclusive_group:
                exclusive_groups.setdefault(exclusive_group, []).append(objective_id)
                objective_groups[objective_id] = exclusive_group
        for index, objective, objective_id in objective_entries:
            requires = objective.get("requires", [])
            if "requires" in objective and not isinstance(requires, (list, str)):
                fail(errors, path, f"secondary_objectives[{index}] requires must be a string or list")
                continue
            required_ids = [requires] if isinstance(requires, str) else requires
            prerequisite_graph[objective_id] = []
            prerequisite_indices[objective_id] = index
            for required_id in required_ids:
                if not isinstance(required_id, str):
                    fail(errors, path, f"secondary_objectives[{index}] requires entries must be strings")
                    continue
                required_id = str(required_id)
                if required_id == "":
                    fail(errors, path, f"secondary_objectives[{index}] requires must not contain empty ids")
                elif required_id == objective_id:
                    fail(errors, path, f"secondary_objectives[{index}] cannot require itself")
                elif required_id not in seen_secondary_ids:
                    fail(errors, path, f"secondary_objectives[{index}] requires unknown objective {required_id!r}")
                elif objective_groups.get(objective_id, "") != "" and objective_groups.get(objective_id, "") == objective_groups.get(required_id, ""):
                    fail(errors, path, f"secondary_objectives[{index}] cannot require objective {required_id!r} in the same exclusive_group")
                else:
                    prerequisite_graph[objective_id].append(required_id)
        for group, objective_ids in exclusive_groups.items():
            if len(objective_ids) < 2:
                index = objective_index_by_id.get(objective_ids[0], 0)
                fail(errors, path, f"secondary_objectives[{index}] exclusive_group {group!r} must contain at least two objectives")
        for objective_id in prerequisite_graph:
            if secondary_prerequisite_has_cycle(objective_id, prerequisite_graph):
                index = prerequisite_indices.get(objective_id, 0)
                fail(errors, path, f"secondary_objectives[{index}] requires creates a cycle")
                break

    validate_tutorial_metadata(path, scenario, units, terrains, width, height, errors)


def validate_objective_shape(
    path: Path,
    objective: Any,
    label: str,
    width: int,
    height: int,
    errors: list[str],
    allow_empty: bool = False,
) -> None:
    if allow_empty and objective == {}:
        return
    if not isinstance(objective, dict):
        fail(errors, path, f"{label} must be an object")
        return
    objective_type = str(objective.get("type", ""))
    if objective_type not in ALLOWED_CONQUEST_VICTORY_TYPES:
        fail(errors, path, f"{label} has unknown type {objective_type!r}")
    if objective_type in {"capture", "hold_hex_turns"}:
        target = objective.get("target", [])
        if not in_bounds(target, width, height):
            fail(errors, path, f"{label} {objective_type} target out of bounds: {target!r}")
    if objective_type == "hold_hex_turns":
        try:
            if int(objective.get("required_turns", 0)) <= 0:
                fail(errors, path, f"{label} hold_hex_turns required_turns must be positive")
        except (TypeError, ValueError):
            fail(errors, path, f"{label} hold_hex_turns required_turns must be an integer")
    if objective_type == "control_count":
        targets = objective.get("targets", [])
        if not isinstance(targets, list) or not targets:
            fail(errors, path, f"{label} control_count needs a non-empty targets list")
        else:
            for target in targets:
                if not in_bounds(target, width, height):
                    fail(errors, path, f"{label} control_count target out of bounds: {target!r}")
            try:
                required = int(objective.get("required", len(targets)))
                if required <= 0 or required > len(targets):
                    fail(errors, path, f"{label} control_count required must be 1..{len(targets)}")
            except (TypeError, ValueError):
                fail(errors, path, f"{label} control_count required must be an integer")
    if "by_turn" in objective:
        try:
            if int(objective.get("by_turn", 0)) <= 0:
                fail(errors, path, f"{label} by_turn must be positive")
        except (TypeError, ValueError):
            fail(errors, path, f"{label} by_turn must be an integer")


def secondary_prerequisite_has_cycle(
    start_id: str,
    prerequisite_graph: dict[str, list[str]],
) -> bool:
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(objective_id: str) -> bool:
        if objective_id in visiting:
            return True
        if objective_id in visited:
            return False
        visiting.add(objective_id)
        for required_id in prerequisite_graph.get(objective_id, []):
            if visit(required_id):
                return True
        visiting.remove(objective_id)
        visited.add(objective_id)
        return False

    return visit(start_id)


def validate_unit_entry(
    path: Path,
    unit: Any,
    index: int,
    collection: str,
    units: dict[str, Any],
    generals: dict[str, Any],
    faction_ids: set[str],
    width: int,
    height: int,
    seen_coords: dict[tuple[int, int], str],
    errors: list[str],
) -> None:
    if not isinstance(unit, dict):
        fail(errors, path, f"{collection}[{index}] must be an object")
        return
    faction_id = str(unit.get("faction", ""))
    type_id = str(unit.get("type", ""))
    name = str(unit.get("name", f"{collection}[{index}]"))
    if faction_id not in faction_ids:
        fail(errors, path, f"{collection}[{index}] {name!r} references unknown faction {faction_id!r}")
    if type_id not in units:
        fail(errors, path, f"{collection}[{index}] {name!r} references unknown unit type {type_id!r}")
    general_id = str(unit.get("general", ""))
    if general_id and general_id not in generals:
        fail(errors, path, f"{collection}[{index}] {name!r} references unknown general {general_id!r}")
    at = unit.get("at", [])
    if not in_bounds(at, width, height):
        fail(errors, path, f"{collection}[{index}] {name!r} coordinate out of bounds: {at!r}")
        return
    hp = unit.get("hp")
    if hp is not None:
        try:
            hp_value = int(hp)
            max_hp = int(units.get(type_id, {}).get("hp", 0))
            if hp_value <= 0 or (max_hp > 0 and hp_value > max_hp):
                fail(errors, path, f"{collection}[{index}] {name!r} hp {hp!r} out of range 1..{max_hp}")
        except (TypeError, ValueError):
            fail(errors, path, f"{collection}[{index}] {name!r} hp must be an integer")
    for field, max_value in (("suppression", MAX_SUPPRESSION), ("dig_in", MAX_DIG_IN), ("rank", MAX_RANK)):
        if field in unit:
            try:
                value = int(unit[field])
            except (TypeError, ValueError):
                fail(errors, path, f"{collection}[{index}] {name!r} {field} must be an integer")
                continue
            if not (0 <= value <= max_value):
                fail(errors, path, f"{collection}[{index}] {name!r} {field} {value} out of range 0..{max_value}")
    if "xp" in unit:
        try:
            if int(unit["xp"]) < 0:
                fail(errors, path, f"{collection}[{index}] {name!r} xp must be non-negative")
        except (TypeError, ValueError):
            fail(errors, path, f"{collection}[{index}] {name!r} xp must be an integer")
    if "on_overwatch" in unit and not isinstance(unit["on_overwatch"], bool):
        fail(errors, path, f"{collection}[{index}] {name!r} on_overwatch must be a boolean")
    coord = offset_to_axial(at)
    if coord in seen_coords:
        fail(errors, path, f"{collection}[{index}] {name!r} stacks with {seen_coords[coord]!r} at {at!r}")
    seen_coords[coord] = name


def validate_unique_unit_id(
    path: Path,
    unit: Any,
    index: int,
    collection: str,
    seen_unit_ids: dict[str, str],
    errors: list[str],
) -> None:
    if not isinstance(unit, dict):
        return
    unit_id = str(unit.get("id", ""))
    if unit_id == "":
        return
    location = f"{collection}[{index}]"
    if unit_id in seen_unit_ids:
        fail(errors, path, f"{location} duplicate unit id {unit_id!r}; first seen at {seen_unit_ids[unit_id]}")
        return
    seen_unit_ids[unit_id] = location


def validate_tutorial_metadata(
    path: Path,
    scenario: dict[str, Any],
    units_catalog: dict[str, Any],
    terrains: dict[str, Any],
    width: int,
    height: int,
    errors: list[str],
) -> None:
    scenario_id = str(scenario.get("id", ""))
    mechanics_raw = scenario.get("tutorial_mechanics", [])
    if not scenario_id.startswith("tut_"):
        if mechanics_raw:
            fail(errors, path, "tutorial_mechanics is only allowed on tut_* scenarios")
        return
    if not isinstance(mechanics_raw, list) or not mechanics_raw:
        fail(errors, path, "tutorial scenario must list tutorial_mechanics")
        return
    if not bool(scenario.get("deployment_locked", False)):
        fail(errors, path, "tutorial scenario must set deployment_locked=true")

    mechanics = {str(m) for m in mechanics_raw}
    unknown = sorted(mechanics - REQUIRED_TUTORIAL_MECHANICS)
    for name in unknown:
        fail(errors, path, f"unknown tutorial mechanic {name!r}")

    scenario_units = scenario.get("units", [])
    reinforcements = scenario.get("reinforcements", [])
    if not isinstance(scenario_units, list):
        scenario_units = []
    if not isinstance(reinforcements, list):
        reinforcements = []
    all_units = list(scenario_units) + list(reinforcements)
    unit_types = {str(u.get("type", "")) for u in all_units if isinstance(u, dict)}
    initial_units = [u for u in scenario_units if isinstance(u, dict)]
    terrain_counts = terrain_counter(scenario)
    player_faction = player_faction_id(scenario)
    capture_targets = [
        cfg.get("target", [])
        for fid, cfg in scenario.get("victory", {}).items()
        if isinstance(cfg, dict) and str(fid) == player_faction and cfg.get("type") == "capture"
    ]

    checks = {
        "movement": lambda: len(initial_units) >= 2 and width * height >= 16,
        "attack": lambda: has_enemy_units(scenario),
        "counterattack": lambda: has_close_enemy_pair(initial_units, 1),
        "capture": lambda: bool(capture_targets),
        "secondary_objective": lambda: bool(scenario.get("secondary_objectives", [])),
        "terrain_defense": lambda: any(int(terrains.get(t, {}).get("defense", 0)) >= 2 for t in terrain_counts),
        "zoc": lambda: has_close_enemy_pair(initial_units, 2),
        "overwatch": lambda: "mg_team" in unit_types or any(bool(u.get("on_overwatch", False)) for u in initial_units),
        "suppression": lambda: has_initial_value(initial_units, "suppression") or bool({"mg_team", "artillery", "rocket_artillery"} & unit_types),
        "rally": lambda: any(int(u.get("suppression", 0)) > 0 for u in initial_units),
        "dig_in": lambda: has_initial_value(initial_units, "dig_in") or "engineer" in unit_types,
        "direct_fire_los": lambda: any(terrains.get(t, {}).get("blocks_los", False) for t in terrain_counts),
        "indirect_fire": lambda: any(units_catalog.get(t, {}).get("indirect", False) for t in unit_types),
        "spotting": lambda: "light_tank" in unit_types and any(units_catalog.get(t, {}).get("indirect", False) for t in unit_types),
        "armor": lambda: any(int(units_catalog.get(t, {}).get("armor", 0)) > 0 for t in unit_types),
        "anti_armor": lambda: any(int(units_catalog.get(t, {}).get("vs_armor", 0)) >= 6 for t in unit_types),
        "armor_standoff": lambda: any(
            str(u.get("faction", "")) == player_faction
            and int(units_catalog.get(str(u.get("type", "")), {}).get("armor_standoff_vs_armor_bonus", 0)) > 0
            for u in all_units
            if isinstance(u, dict)
        )
        and any(
            str(u.get("faction", "")) != player_faction
            and int(units_catalog.get(str(u.get("type", "")), {}).get("armor", 0)) > 0
            for u in all_units
            if isinstance(u, dict)
        ),
        "engineer_bridge": lambda: "engineer" in unit_types and has_engineer_adjacent_water(initial_units, scenario),
        "engineer_breach": lambda: "engineer" in unit_types and any(int(u.get("dig_in", 0)) > 0 for u in initial_units if str(u.get("faction", "")) != player_faction),
        "airdrop": lambda: "paratrooper" in unit_types,
        "general_skill": lambda: any(str(u.get("general", "")) for u in all_units if isinstance(u, dict)),
        "veteran": lambda: any(int(u.get("rank", 0)) > 0 or int(u.get("xp", 0)) > 0 for u in all_units if isinstance(u, dict)),
        "reinforcements": lambda: bool(reinforcements),
        "splash_damage": lambda: "rocket_artillery" in unit_types,
    }
    for mechanic in sorted(mechanics & REQUIRED_TUTORIAL_MECHANICS):
        if not checks[mechanic]():
            fail(errors, path, f"tutorial mechanic {mechanic!r} is declared but not supported by scenario data")


def in_bounds(at: Any, width: int, height: int) -> bool:
    if not isinstance(at, list) or len(at) < 2:
        return False
    try:
        col = int(at[0])
        row = int(at[1])
    except (TypeError, ValueError):
        return False
    return 0 <= col < width and 0 <= row < height


def terrain_counter(scenario: dict[str, Any]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in scenario.get("map", {}).get("tiles", []):
        if not isinstance(row, list):
            continue
        for terrain_id in row:
            tid = str(terrain_id)
            counts[tid] = counts.get(tid, 0) + 1
    return counts


def player_faction_id(scenario: dict[str, Any]) -> str:
    for faction in scenario.get("factions", []):
        if isinstance(faction, dict) and str(faction.get("controller", "")) == "player":
            return str(faction.get("id", ""))
    return ""


def has_enemy_units(scenario: dict[str, Any]) -> bool:
    player = player_faction_id(scenario)
    if player == "":
        return False
    own = False
    enemy = False
    for unit in scenario.get("units", []):
        if not isinstance(unit, dict):
            continue
        if str(unit.get("faction", "")) == player:
            own = True
        else:
            enemy = True
    return own and enemy


def hex_distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dq = a[0] - b[0]
    dr = a[1] - b[1]
    return (abs(dq) + abs(dr) + abs(dq + dr)) // 2


def has_close_enemy_pair(units: list[Any], max_distance: int) -> bool:
    typed = [u for u in units if isinstance(u, dict) and isinstance(u.get("at", []), list)]
    for idx, first in enumerate(typed):
        first_faction = str(first.get("faction", ""))
        first_coord = offset_to_axial(first.get("at", [0, 0]))
        for second in typed[idx + 1 :]:
            if str(second.get("faction", "")) == first_faction:
                continue
            if hex_distance(first_coord, offset_to_axial(second.get("at", [0, 0]))) <= max_distance:
                return True
    return False


def has_initial_value(units: list[Any], field: str) -> bool:
    for unit in units:
        if isinstance(unit, dict) and int(unit.get(field, 0)) > 0:
            return True
    return False


def offset_neighbors(at: list[Any]) -> list[list[int]]:
    q, r = offset_to_axial(at)
    axial_neighbors = [
        (q + 1, r),
        (q + 1, r - 1),
        (q, r - 1),
        (q - 1, r),
        (q - 1, r + 1),
        (q, r + 1),
    ]
    out: list[list[int]] = []
    for nq, nr in axial_neighbors:
        col = nq + (nr >> 1)
        out.append([col, nr])
    return out


def terrain_at_offset(scenario: dict[str, Any], at: list[Any]) -> str:
    if not isinstance(at, list) or len(at) < 2:
        return ""
    col = int(at[0])
    row = int(at[1])
    rows = scenario.get("map", {}).get("tiles", [])
    if not isinstance(rows, list) or row < 0 or row >= len(rows):
        return ""
    tiles_row = rows[row]
    if not isinstance(tiles_row, list) or col < 0 or col >= len(tiles_row):
        return ""
    return str(tiles_row[col])


def has_engineer_adjacent_water(units: list[Any], scenario: dict[str, Any]) -> bool:
    for unit in units:
        if not isinstance(unit, dict) or str(unit.get("type", "")) != "engineer":
            continue
        at = unit.get("at", [])
        if not isinstance(at, list):
            continue
        for neighbor in offset_neighbors(at):
            if terrain_at_offset(scenario, neighbor) in {"river", "sea"}:
                return True
    return False


def validate_campaigns(campaigns: dict[str, Any], scenario_ids: set[str], errors: list[str]) -> None:
    path = DATA / "campaigns.json"
    tutorial_ids = {scenario_id for scenario_id in scenario_ids if scenario_id.startswith("tut_")}
    tutorial_order: list[str] = []
    for campaign_id, campaign in campaigns.items():
        if not isinstance(campaign, dict):
            fail(errors, path, f"campaign {campaign_id!r} must be an object")
            continue
        order = campaign.get("scenario_order", [])
        if not isinstance(order, list) or not order:
            fail(errors, path, f"campaign {campaign_id!r} must list scenario_order")
            continue
        for scenario_id in order:
            if str(scenario_id) not in scenario_ids:
                fail(errors, path, f"campaign {campaign_id!r} references unknown scenario {scenario_id!r}")
            if str(scenario_id).startswith("tut_") and str(campaign_id) != "00_tutorial":
                fail(errors, path, f"campaign {campaign_id!r} must not reference tutorial scenario {scenario_id!r}")
        if str(campaign_id) == "00_tutorial":
            tutorial_order = [str(scenario_id) for scenario_id in order]
    if tutorial_ids:
        if not tutorial_order:
            fail(errors, path, "tutorial scenarios require campaign '00_tutorial'")
        elif set(tutorial_order) != tutorial_ids:
            missing = sorted(tutorial_ids - set(tutorial_order))
            extra = sorted(set(tutorial_order) - tutorial_ids)
            fail(errors, path, f"00_tutorial must reference exactly all tutorial scenarios; missing={missing!r} extra={extra!r}")
        elif tutorial_order[0] != "tut_00_basic_turn":
            fail(errors, path, "00_tutorial must start with tut_00_basic_turn")


def validate_conquest(errors: list[str]) -> None:
    path = DATA / "conquest_map.json"
    conquest = load_json(path)
    countries = conquest.get("countries", {})
    regions = conquest.get("regions", [])
    if not isinstance(countries, dict) or not countries:
        fail(errors, path, "countries must be a non-empty object")
        countries = {}
    if str(conquest.get("start_country", "")) not in countries:
        fail(errors, path, "start_country must reference countries")
    try:
        map_width = int(conquest.get("map_width", 0))
        map_height = int(conquest.get("map_height", 0))
    except (TypeError, ValueError):
        fail(errors, path, "map_width/map_height must be integers")
        map_width = 0
        map_height = 0
    if map_width <= 0:
        fail(errors, path, "map_width must be positive")
    if map_height <= 0:
        fail(errors, path, "map_height must be positive")
    region_ids: set[str] = set()
    region_by_id: dict[str, Any] = {}
    coords: dict[tuple[int, int], str] = {}
    supply_source_owners: set[str] = set()
    for region in regions if isinstance(regions, list) else []:
        if not isinstance(region, dict):
            fail(errors, path, "region entries must be objects")
            continue
        region_id = str(region.get("id", ""))
        if not region_id:
            fail(errors, path, "region missing id")
            continue
        if region_id in region_ids:
            fail(errors, path, f"duplicate region id {region_id!r}")
        region_ids.add(region_id)
        region_by_id[region_id] = region
        name = str(region.get("name_zh", ""))
        short_name = str(region.get("short_name_zh", ""))
        if not name:
            fail(errors, path, f"region {region_id!r} missing name_zh")
        if not short_name:
            fail(errors, path, f"region {region_id!r} missing short_name_zh")
        elif len(short_name) > 6:
            fail(errors, path, f"region {region_id!r} short_name_zh should fit map buttons")
        if str(region.get("owner", "")) not in countries:
            fail(errors, path, f"region {region_id!r} owner is unknown")
        elif bool(region.get("supply_source", False)) and str(region.get("owner", "")) != "neutral":
            supply_source_owners.add(str(region.get("owner", "")))
        if int(region.get("production", 0)) <= 0:
            fail(errors, path, f"region {region_id!r} production must be positive")
        if "training_level" in region:
            try:
                training_level = int(region.get("training_level", 0))
                if not 0 <= training_level <= 2:
                    fail(errors, path, f"region {region_id!r} training_level must be between 0 and 2")
            except (TypeError, ValueError):
                fail(errors, path, f"region {region_id!r} training_level must be an integer")
        region_traits = region.get("region_traits", [])
        if "region_traits" in region and not isinstance(region_traits, list):
            fail(errors, path, f"region {region_id!r} region_traits must be a list when present")
        elif isinstance(region_traits, list):
            seen_traits: set[str] = set()
            for trait in region_traits:
                trait_id = str(trait)
                if trait_id not in ALLOWED_CONQUEST_REGION_TRAITS:
                    fail(errors, path, f"region {region_id!r} has unknown region_trait {trait_id!r}")
                elif trait_id in seen_traits:
                    fail(errors, path, f"region {region_id!r} repeats region_trait {trait_id!r}")
                seen_traits.add(trait_id)
        try:
            coord = (int(region.get("x", -1)), int(region.get("y", -1)))
        except (TypeError, ValueError):
            fail(errors, path, f"region {region_id!r} x/y must be integers")
            continue
        if map_width > 0 and map_height > 0 and not (0 <= coord[0] < map_width and 0 <= coord[1] < map_height):
            fail(errors, path, f"region {region_id!r} coordinate {coord!r} outside map bounds {map_width}x{map_height}")
        if coord in coords:
            fail(errors, path, f"region {region_id!r} overlaps {coords[coord]!r} at {coord!r}")
        coords[coord] = region_id
    for region in regions if isinstance(regions, list) else []:
        if not isinstance(region, dict):
            continue
        region_id = str(region.get("id", ""))
        neighbors = [str(n) for n in region.get("neighbors", [])]
        for neighbor in region.get("neighbors", []):
            neighbor_id = str(neighbor)
            if neighbor_id not in region_ids:
                fail(errors, path, f"region {region_id!r} references unknown neighbor {neighbor_id!r}")
                continue
            neighbor_region = region_by_id.get(neighbor_id, {})
            if isinstance(neighbor_region, dict) and region_id not in [str(n) for n in neighbor_region.get("neighbors", [])]:
                fail(errors, path, f"region {region_id!r} neighbor {neighbor_id!r} must be reciprocal")
        for rail_neighbor in region.get("rail_neighbors", []):
            rail_id = str(rail_neighbor)
            if rail_id not in region_ids:
                fail(errors, path, f"region {region_id!r} references unknown rail neighbor {rail_id!r}")
                continue
            if rail_id not in neighbors:
                fail(errors, path, f"region {region_id!r} rail neighbor {rail_id!r} must also be a neighbor")
                continue
            rail_region = region_by_id.get(rail_id, {})
            if isinstance(rail_region, dict) and region_id not in [str(n) for n in rail_region.get("rail_neighbors", [])]:
                fail(errors, path, f"region {region_id!r} rail neighbor {rail_id!r} must be reciprocal")
    starting_owners = {
        str(region.get("owner", ""))
        for region in regions if isinstance(region, dict)
        and str(region.get("owner", "")) not in {"", "neutral"}
    }
    for country_id in sorted(starting_owners - supply_source_owners):
        fail(errors, path, f"country {country_id!r} needs at least one starting supply_source region")

    for country_id, country in countries.items():
        if not isinstance(country, dict):
            continue
        agenda = country.get("agenda_targets", {})
        if "agenda_targets" in country and not isinstance(agenda, dict):
            fail(errors, path, f"country {country_id!r} agenda_targets must be an object")
            continue
        if isinstance(agenda, dict):
            for target_id, score in agenda.items():
                if str(target_id) not in region_ids:
                    fail(errors, path, f"country {country_id!r} agenda target {target_id!r} is unknown")
                    continue
                try:
                    if int(score) <= 0:
                        fail(errors, path, f"country {country_id!r} agenda target {target_id!r} score must be positive")
                except (TypeError, ValueError):
                    fail(errors, path, f"country {country_id!r} agenda target {target_id!r} score must be an integer")

    theater_objectives = conquest.get("theater_objectives", [])
    if "theater_objectives" in conquest and not isinstance(theater_objectives, list):
        fail(errors, path, "theater_objectives must be a list when present")
    elif isinstance(theater_objectives, list):
        seen_objectives: set[str] = set()
        for index, objective in enumerate(theater_objectives):
            if not isinstance(objective, dict):
                fail(errors, path, f"theater_objectives[{index}] must be an object")
                continue
            objective_id = str(objective.get("id", ""))
            if not objective_id:
                fail(errors, path, f"theater_objectives[{index}] missing id")
            elif objective_id in seen_objectives:
                fail(errors, path, f"theater_objectives[{index}] duplicate id {objective_id!r}")
            seen_objectives.add(objective_id)
            if not str(objective.get("name_zh", "")):
                fail(errors, path, f"theater_objectives[{index}] missing name_zh")
            required = objective.get("regions", [])
            if not isinstance(required, list) or not required:
                fail(errors, path, f"theater_objectives[{index}] regions must be a non-empty list")
            elif len({str(region_id) for region_id in required}) != len(required):
                fail(errors, path, f"theater_objectives[{index}] regions must not contain duplicates")
            else:
                for region_id in required:
                    if str(region_id) not in region_ids:
                        fail(errors, path, f"theater_objectives[{index}] references unknown region {region_id!r}")
            reward = objective.get("reward", {})
            if not isinstance(reward, dict):
                fail(errors, path, f"theater_objectives[{index}] reward must be an object")
                continue
            reward_type = str(reward.get("type", ""))
            if reward_type not in ALLOWED_CONQUEST_OBJECTIVE_REWARD_TYPES:
                fail(errors, path, f"theater_objectives[{index}] reward unknown type {reward_type!r}")
            try:
                if int(reward.get("amount", 0)) <= 0:
                    fail(errors, path, f"theater_objectives[{index}] reward amount must be positive")
            except (TypeError, ValueError):
                fail(errors, path, f"theater_objectives[{index}] reward amount must be an integer")


def main() -> int:
    errors: list[str] = []
    units, terrains, generals, campaigns = validate_catalogs(errors)
    scenario_ids: set[str] = set()
    for path in sorted(SCENARIOS.glob("*.json")):
        validate_scenario(path, load_json(path), units, terrains, generals, scenario_ids, errors)
    validate_campaigns(campaigns, scenario_ids, errors)
    validate_conquest(errors)

    if errors:
        print("Data validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Data validation passed: {len(scenario_ids)} scenarios")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
