#!/usr/bin/env python3
"""Validate static JSON data used by the Godot runtime."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SCENARIOS = DATA / "scenarios"


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
    scenario_units = scenario.get("units", [])
    if not isinstance(scenario_units, list) or not scenario_units:
        fail(errors, path, "must define at least one unit")
        scenario_units = []
    for index, unit in enumerate(scenario_units):
        validate_unit_entry(path, unit, index, "units", units, generals, faction_ids, width, height, seen_coords, errors)

    reinforcements = scenario.get("reinforcements", [])
    if not isinstance(reinforcements, list):
        fail(errors, path, "reinforcements must be a list when present")
    else:
        for index, unit in enumerate(reinforcements):
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
            if objective_type not in {"capture", "survive", "eliminate"}:
                fail(errors, path, f"victory {faction_id!r} has unknown type {objective_type!r}")
            if objective_type == "capture":
                target = objective.get("target", [])
                if not in_bounds(target, width, height):
                    fail(errors, path, f"victory {faction_id!r} capture target out of bounds: {target!r}")


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
    coord = offset_to_axial(at)
    if coord in seen_coords:
        fail(errors, path, f"{collection}[{index}] {name!r} stacks with {seen_coords[coord]!r} at {at!r}")
    seen_coords[coord] = name


def in_bounds(at: Any, width: int, height: int) -> bool:
    if not isinstance(at, list) or len(at) < 2:
        return False
    try:
        col = int(at[0])
        row = int(at[1])
    except (TypeError, ValueError):
        return False
    return 0 <= col < width and 0 <= row < height


def validate_campaigns(campaigns: dict[str, Any], scenario_ids: set[str], errors: list[str]) -> None:
    path = DATA / "campaigns.json"
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
    region_ids: set[str] = set()
    region_by_id: dict[str, Any] = {}
    coords: dict[tuple[int, int], str] = {}
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
        if str(region.get("owner", "")) not in countries:
            fail(errors, path, f"region {region_id!r} owner is unknown")
        if int(region.get("production", 0)) <= 0:
            fail(errors, path, f"region {region_id!r} production must be positive")
        try:
            coord = (int(region.get("x", -1)), int(region.get("y", -1)))
        except (TypeError, ValueError):
            fail(errors, path, f"region {region_id!r} x/y must be integers")
            continue
        if coord in coords:
            fail(errors, path, f"region {region_id!r} overlaps {coords[coord]!r} at {coord!r}")
        coords[coord] = region_id
    for region in regions if isinstance(regions, list) else []:
        if not isinstance(region, dict):
            continue
        region_id = str(region.get("id", ""))
        for neighbor in region.get("neighbors", []):
            neighbor_id = str(neighbor)
            if neighbor_id not in region_ids:
                fail(errors, path, f"region {region_id!r} references unknown neighbor {neighbor_id!r}")
                continue
            neighbor_region = region_by_id.get(neighbor_id, {})
            if isinstance(neighbor_region, dict) and region_id not in [str(n) for n in neighbor_region.get("neighbors", [])]:
                fail(errors, path, f"region {region_id!r} neighbor {neighbor_id!r} must be reciprocal")


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
