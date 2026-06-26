#!/usr/bin/env python3
"""Probe tutorial scenarios for actionable teaching setups.

This is stricter than validate_data.py's metadata checks. It verifies that each
declared tutorial mechanic has a plausible first-position interaction in the
scenario data: units can move, attacks exist, LOS can be blocked, artillery has
visible targets, engineers start next to water, etc. It is static and
deterministic; it does not simulate AI turns.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SCENARIOS = DATA / "scenarios"
DEFAULT_OUTPUT = ROOT / "docs" / "progress" / "tutorial_probe.md"

NEIGHBORS = ((1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1))
SUBHEX = 2
ZOC_PENALTY = 2
IMPASSABLE = 1 << 20
SUPPRESSION_PIN_THRESHOLD = 2


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{path.relative_to(ROOT)} must be an object")
    return data


def axial_from_offset(at: list[Any]) -> tuple[int, int]:
    col = int(at[0])
    row = int(at[1])
    return col - (row >> 1), row


def hex_distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dq = a[0] - b[0]
    dr = a[1] - b[1]
    return (abs(dq) + abs(dr) + abs(dq + dr)) // 2


def neighbors(coord: tuple[int, int]) -> Iterable[tuple[int, int]]:
    q, r = coord
    for dq, dr in NEIGHBORS:
        yield q + dq, r + dr


def range_within(center: tuple[int, int], radius: int) -> Iterable[tuple[int, int]]:
    cq, cr = center
    for dq in range(-radius, radius + 1):
        r_min = max(-radius, -dq - radius)
        r_max = min(radius, -dq + radius)
        for dr in range(r_min, r_max + 1):
            yield cq + dq, cr + dr


def round_axial(q_frac: float, r_frac: float) -> tuple[int, int]:
    s_frac = -q_frac - r_frac
    q = round(q_frac)
    r = round(r_frac)
    s = round(s_frac)
    dq = abs(q - q_frac)
    dr = abs(r - r_frac)
    ds = abs(s - s_frac)
    if dq > dr and dq > ds:
        q = -r - s
    elif dr > ds:
        r = -q - s
    return int(q), int(r)


def hex_line(a: tuple[int, int], b: tuple[int, int]) -> list[tuple[int, int]]:
    dist = hex_distance(a, b)
    if dist == 0:
        return [a]
    out: list[tuple[int, int]] = []
    for i in range(dist + 1):
        t = i / dist
        out.append(round_axial(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


def scenario_tiles(scenario: dict[str, Any]) -> dict[tuple[int, int], str]:
    tiles: dict[tuple[int, int], str] = {}
    rows = scenario.get("map", {}).get("tiles", [])
    for row_idx, row in enumerate(rows):
        for col_idx, terrain_id in enumerate(row):
            tiles[axial_from_offset([col_idx, row_idx])] = str(terrain_id)
    return tiles


def scenario_units(scenario: dict[str, Any], include_reinforcements: bool = False) -> list[dict[str, Any]]:
    units = [u for u in scenario.get("units", []) if isinstance(u, dict)]
    if include_reinforcements:
        units.extend(u for u in scenario.get("reinforcements", []) if isinstance(u, dict))
    return units


def unit_coord(unit: dict[str, Any]) -> tuple[int, int]:
    return axial_from_offset(unit.get("at", [0, 0]))


def player_faction(scenario: dict[str, Any]) -> str:
    for faction in scenario.get("factions", []):
        if isinstance(faction, dict) and str(faction.get("controller", "")) == "player":
            return str(faction.get("id", ""))
    return ""


class ProbeMap:
    def __init__(self, scenario: dict[str, Any], terrains: dict[str, Any]) -> None:
        self.tiles = scenario_tiles(scenario)
        self.terrains = terrains

    def terrain_at(self, coord: tuple[int, int]) -> str:
        return self.tiles.get(coord, "")

    def terrain_def(self, coord: tuple[int, int]) -> dict[str, Any]:
        return self.terrains.get(self.terrain_at(coord), {})

    def blocks_los_at(self, coord: tuple[int, int]) -> bool:
        return bool(self.terrain_def(coord).get("blocks_los", False))

    def impassable_at(self, coord: tuple[int, int]) -> bool:
        return bool(self.terrain_def(coord).get("impassable", False))

    def move_cost_at(self, coord: tuple[int, int]) -> int:
        return int(self.terrain_def(coord).get("move_cost", 1))


def has_los(pmap: ProbeMap, observer: tuple[int, int], target: tuple[int, int]) -> bool:
    return has_los_with_units(pmap, observer, target, {}, "", False)


def has_los_with_units(
    pmap: ProbeMap,
    observer: tuple[int, int],
    target: tuple[int, int],
    occupied: dict[tuple[int, int], dict[str, Any]],
    observer_faction: str,
    block_all_units: bool,
) -> bool:
    if observer == target:
        return True
    for coord in hex_line(observer, target)[1:-1]:
        if pmap.terrain_at(coord) and pmap.blocks_los_at(coord):
            return False
        unit = occupied.get(coord)
        if unit is not None and (block_all_units or str(unit.get("faction", "")) != observer_faction):
            return False
    return True


def has_vision_los(
    scenario: dict[str, Any], pmap: ProbeMap, observer: tuple[int, int], target: tuple[int, int], faction_id: str
) -> bool:
    return has_los_with_units(pmap, observer, target, occupied_by_initial_units(scenario), faction_id, False)


def has_direct_fire_los(
    scenario: dict[str, Any], pmap: ProbeMap, observer: tuple[int, int], target: tuple[int, int]
) -> bool:
    return has_los_with_units(pmap, observer, target, occupied_by_initial_units(scenario), "", True)


def visible_hexes(
    scenario: dict[str, Any], pmap: ProbeMap, units_catalog: dict[str, Any], faction_id: str
) -> set[tuple[int, int]]:
    visible: set[tuple[int, int]] = set()
    for unit in scenario_units(scenario):
        if str(unit.get("faction", "")) != faction_id:
            continue
        coord = unit_coord(unit)
        unit_def = units_catalog.get(str(unit.get("type", "")), {})
        vision = int(unit_def.get("vision", 3))
        visible.add(coord)
        for candidate in range_within(coord, vision):
            if pmap.terrain_at(candidate) and has_vision_los(scenario, pmap, coord, candidate, faction_id):
                visible.add(candidate)
    return visible


def occupied_by_initial_units(scenario: dict[str, Any]) -> dict[tuple[int, int], dict[str, Any]]:
    return {unit_coord(unit): unit for unit in scenario_units(scenario)}


def enters_enemy_zoc(coord: tuple[int, int], occupied: dict[tuple[int, int], dict[str, Any]], mover_faction: str) -> bool:
    for nb in neighbors(coord):
        unit = occupied.get(nb)
        if (
            unit is not None
            and str(unit.get("faction", "")) != mover_faction
            and int(unit.get("suppression", 0)) < SUPPRESSION_PIN_THRESHOLD
        ):
            return True
    return False


def movement_step_cost(
    coord: tuple[int, int],
    pmap: ProbeMap,
    occupied: dict[tuple[int, int], dict[str, Any]],
    mover_faction: str,
    unit_type: str,
) -> int:
    terrain = pmap.terrain_at(coord)
    if pmap.impassable_at(coord):
        return IMPASSABLE
    if terrain == "road":
        step = 1
    elif unit_type == "infantry" and pmap.move_cost_at(coord) >= 2:
        step = SUBHEX
    else:
        step = pmap.move_cost_at(coord) * SUBHEX
    if enters_enemy_zoc(coord, occupied, mover_faction):
        step += ZOC_PENALTY * SUBHEX
    return step


def movement_range(
    unit: dict[str, Any], scenario: dict[str, Any], pmap: ProbeMap, units_catalog: dict[str, Any]
) -> set[tuple[int, int]]:
    start = unit_coord(unit)
    unit_type = str(unit.get("type", ""))
    move = int(units_catalog.get(unit_type, {}).get("move", 0))
    budget = move * SUBHEX
    occupied = occupied_by_initial_units(scenario)
    occupied.pop(start, None)
    cost_to: dict[tuple[int, int], int] = {start: 0}
    frontier = [start]
    while frontier:
        current = frontier.pop(0)
        current_cost = cost_to[current]
        for nb in neighbors(current):
            if pmap.terrain_at(nb) == "" or nb in occupied:
                continue
            step = movement_step_cost(nb, pmap, occupied, str(unit.get("faction", "")), unit_type)
            if step >= IMPASSABLE:
                continue
            new_cost = current_cost + step
            if new_cost <= budget and (nb not in cost_to or new_cost < cost_to[nb]):
                cost_to[nb] = new_cost
                frontier.append(nb)
    cost_to.pop(start, None)
    return set(cost_to)


def initial_attack_pairs(
    scenario: dict[str, Any],
    pmap: ProbeMap,
    units_catalog: dict[str, Any],
    faction_id: str,
    require_direct_blocker: bool = False,
) -> list[str]:
    visible = visible_hexes(scenario, pmap, units_catalog, faction_id)
    out: list[str] = []
    units = scenario_units(scenario)
    for attacker in units:
        if str(attacker.get("faction", "")) != faction_id:
            continue
        atk_def = units_catalog.get(str(attacker.get("type", "")), {})
        attacker_coord = unit_coord(attacker)
        rng = int(atk_def.get("range", 1))
        indirect = bool(atk_def.get("indirect", False))
        for target in units:
            if str(target.get("faction", "")) == faction_id:
                continue
            target_coord = unit_coord(target)
            if hex_distance(attacker_coord, target_coord) > rng or target_coord not in visible:
                continue
            clear = has_direct_fire_los(scenario, pmap, attacker_coord, target_coord)
            if require_direct_blocker:
                if not indirect and not clear:
                    out.append(f"{attacker.get('name', attacker.get('type'))}->{target.get('name', target.get('type'))}")
                continue
            if indirect or clear:
                out.append(f"{attacker.get('name', attacker.get('type'))}->{target.get('name', target.get('type'))}")
    return out


def direct_los_blockers(
    scenario: dict[str, Any], pmap: ProbeMap, units_catalog: dict[str, Any], faction_id: str
) -> list[str]:
    out: list[str] = []
    units = scenario_units(scenario)
    visible = visible_hexes(scenario, pmap, units_catalog, faction_id)
    for attacker in units:
        if str(attacker.get("faction", "")) != faction_id:
            continue
        atk_def = units_catalog.get(str(attacker.get("type", "")), {})
        if bool(atk_def.get("indirect", False)):
            continue
        attacker_coord = unit_coord(attacker)
        rng = int(atk_def.get("range", 1))
        for target in units:
            if str(target.get("faction", "")) == faction_id:
                continue
            target_coord = unit_coord(target)
            if (
                target_coord in visible
                and hex_distance(attacker_coord, target_coord) <= rng
                and not has_direct_fire_los(scenario, pmap, attacker_coord, target_coord)
            ):
                out.append(f"{attacker.get('name', attacker.get('type'))}->{target.get('name', target.get('type'))}")
    return out


def has_enemy_pair_with_distance(scenario: dict[str, Any], max_distance: int) -> bool:
    units = scenario_units(scenario)
    for idx, first in enumerate(units):
        for second in units[idx + 1 :]:
            if str(first.get("faction", "")) == str(second.get("faction", "")):
                continue
            if hex_distance(unit_coord(first), unit_coord(second)) <= max_distance:
                return True
    return False


def has_engineer_adjacent_water(scenario: dict[str, Any], pmap: ProbeMap, faction_id: str) -> bool:
    for unit in scenario_units(scenario):
        if str(unit.get("faction", "")) != faction_id or str(unit.get("type", "")) != "engineer":
            continue
        for nb in neighbors(unit_coord(unit)):
            if pmap.terrain_at(nb) in {"river", "sea"}:
                return True
    return False


def has_light_tank_spotter_for_indirect_target(
    scenario: dict[str, Any], pmap: ProbeMap, units_catalog: dict[str, Any], faction_id: str
) -> bool:
    units = scenario_units(scenario)
    enemies = [u for u in units if str(u.get("faction", "")) != faction_id]
    indirect_units = [
        u
        for u in units
        if str(u.get("faction", "")) == faction_id
        and units_catalog.get(str(u.get("type", "")), {}).get("indirect", False)
    ]
    if not indirect_units:
        return False
    for spotter in units:
        if str(spotter.get("faction", "")) != faction_id or str(spotter.get("type", "")) != "light_tank":
            continue
        s_coord = unit_coord(spotter)
        vision = int(units_catalog.get("light_tank", {}).get("vision", 0))
        for enemy in enemies:
            e_coord = unit_coord(enemy)
            if hex_distance(s_coord, e_coord) <= vision and has_vision_los(scenario, pmap, s_coord, e_coord, faction_id):
                for artillery in indirect_units:
                    artillery_def = units_catalog.get(str(artillery.get("type", "")), {})
                    if hex_distance(unit_coord(artillery), e_coord) <= int(artillery_def.get("range", 1)):
                        return True
    return False


def engineer_breach_pairs(
    scenario: dict[str, Any], pmap: ProbeMap, units_catalog: dict[str, Any], faction_id: str
) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    enemies = [
        u
        for u in scenario_units(scenario)
        if str(u.get("faction", "")) != faction_id and int(u.get("dig_in", 0)) > 0
    ]
    if not enemies:
        return out
    engineer_def = units_catalog.get("engineer", {})
    attack_range = int(engineer_def.get("range", 1))
    vision = int(engineer_def.get("vision", 3))
    for engineer in scenario_units(scenario):
        if str(engineer.get("faction", "")) != faction_id or str(engineer.get("type", "")) != "engineer":
            continue
        positions = {unit_coord(engineer)}
        positions.update(movement_range(engineer, scenario, pmap, units_catalog))
        for pos in positions:
            for enemy in enemies:
                enemy_coord = unit_coord(enemy)
                if hex_distance(pos, enemy_coord) > attack_range:
                    continue
                if hex_distance(pos, enemy_coord) > vision:
                    continue
                if not has_los_with_units(pmap, pos, enemy_coord, occupied_by_initial_units(scenario), faction_id, True):
                    continue
                label = f"{engineer.get('name', engineer.get('type'))}->{enemy.get('name', enemy.get('type'))}"
                if label not in seen:
                    seen.add(label)
                    out.append(label)
                break
    return out


def has_adjacent_enemy_cluster(scenario: dict[str, Any]) -> bool:
    units = scenario_units(scenario)
    enemies_by_faction: dict[str, list[dict[str, Any]]] = {}
    for unit in units:
        enemies_by_faction.setdefault(str(unit.get("faction", "")), []).append(unit)
    for group in enemies_by_faction.values():
        for idx, first in enumerate(group):
            for second in group[idx + 1 :]:
                if hex_distance(unit_coord(first), unit_coord(second)) <= 1:
                    return True
    return False


def probe_scenario(scenario: dict[str, Any], units_catalog: dict[str, Any], terrains: dict[str, Any]) -> tuple[list[str], list[str]]:
    scenario_id = str(scenario.get("id", ""))
    pmap = ProbeMap(scenario, terrains)
    faction_id = player_faction(scenario)
    mechanics = {str(m) for m in scenario.get("tutorial_mechanics", [])}
    passed: list[str] = []
    failed: list[str] = []

    def record(name: str, ok: bool, detail: str = "") -> None:
        if name not in mechanics:
            return
        label = name if detail == "" else f"{name} ({detail})"
        if ok:
            passed.append(label)
        else:
            failed.append(label)

    player_units = [u for u in scenario_units(scenario) if str(u.get("faction", "")) == faction_id]
    move_candidates = [u for u in player_units if movement_range(u, scenario, pmap, units_catalog)]
    attack_pairs = initial_attack_pairs(scenario, pmap, units_catalog, faction_id)
    blocked_direct = direct_los_blockers(scenario, pmap, units_catalog, faction_id)

    record("movement", bool(move_candidates), f"{len(move_candidates)} units can move")
    record("attack", bool(attack_pairs), ", ".join(attack_pairs[:2]))
    record("counterattack", has_enemy_pair_with_distance(scenario, 1), "adjacent enemy pair")
    capture_targets = [
        cfg.get("target", [])
        for fid, cfg in scenario.get("victory", {}).items()
        if str(fid) == faction_id and isinstance(cfg, dict) and cfg.get("type") == "capture"
    ]
    record("capture", bool(capture_targets), f"targets={capture_targets}")
    record(
        "terrain_defense",
        any(int(terrains.get(t, {}).get("defense", 0)) >= 2 for t in pmap.tiles.values()),
        "defensive terrain present",
    )
    record("zoc", has_enemy_pair_with_distance(scenario, 2), "enemy near player")
    record(
        "overwatch",
        any(str(u.get("type", "")) == "mg_team" for u in player_units),
        "player MG available",
    )
    record(
        "suppression",
        any(int(u.get("suppression", 0)) > 0 for u in player_units)
        or any(str(u.get("type", "")) in {"mg_team", "artillery", "rocket_artillery"} for u in scenario_units(scenario)),
        "source or initial suppression",
    )
    record("rally", any(int(u.get("suppression", 0)) > 0 for u in player_units), "suppressed player unit")
    record(
        "dig_in",
        any(int(u.get("dig_in", 0)) > 0 for u in scenario_units(scenario)),
        "initial dug-in unit",
    )
    record("direct_fire_los", bool(blocked_direct), ", ".join(blocked_direct[:2]))
    indirect_attacks = [
        pair for pair in attack_pairs if any(str(u.get("type", "")) in {"artillery", "rocket_artillery"} and str(u.get("name", u.get("type"))) in pair for u in player_units)
    ]
    record("indirect_fire", bool(indirect_attacks), ", ".join(indirect_attacks[:2]))
    record(
        "spotting",
        has_light_tank_spotter_for_indirect_target(scenario, pmap, units_catalog, faction_id),
        "light tank sees target for indirect fire",
    )
    record(
        "armor",
        any(int(units_catalog.get(str(u.get("type", "")), {}).get("armor", 0)) > 0 for u in scenario_units(scenario)),
        "armored units present",
    )
    record(
        "anti_armor",
        any(str(u.get("faction", "")) == faction_id and int(units_catalog.get(str(u.get("type", "")), {}).get("vs_armor", 0)) >= 6 for u in scenario_units(scenario)),
        "player AT weapon present",
    )
    record("engineer_bridge", has_engineer_adjacent_water(scenario, pmap, faction_id), "engineer adjacent to water")
    engineer_breaches = engineer_breach_pairs(scenario, pmap, units_catalog, faction_id)
    record("engineer_breach", bool(engineer_breaches), ", ".join(engineer_breaches[:2]))
    record("airdrop", any(str(u.get("type", "")) == "paratrooper" for u in player_units), "player paratrooper")
    record("general_skill", any(str(u.get("general", "")) for u in player_units), "player general")
    record("veteran", any(int(u.get("rank", 0)) > 0 or int(u.get("xp", 0)) > 0 for u in player_units), "player veteran")
    record("reinforcements", bool(scenario.get("reinforcements", [])), "scheduled reinforcements")
    record("splash_damage", has_adjacent_enemy_cluster(scenario), "adjacent clustered units")

    if not bool(scenario.get("deployment_locked", False)):
        failed.append("deployment_locked (tutorial setup can be moved before battle)")
    else:
        passed.append("deployment_locked")
    return passed, failed


def table(headers: list[str], rows: list[list[Any]]) -> str:
    out = ["| " + " | ".join(headers) + " |"]
    out.append("| " + " | ".join(["---"] * len(headers)) + " |")
    for row in rows:
        out.append("| " + " | ".join(str(cell) for cell in row) + " |")
    return "\n".join(out)


def generate_report() -> tuple[str, int]:
    units = load_json(DATA / "units.json")
    terrains = load_json(DATA / "terrains.json")
    scenarios = [load_json(path) for path in sorted(SCENARIOS.glob("tut_*.json"))]
    rows: list[list[Any]] = []
    failures = 0
    for scenario in scenarios:
        passed, failed = probe_scenario(scenario, units, terrains)
        failures += len(failed)
        rows.append([
            scenario.get("id", ""),
            len(passed),
            ", ".join(passed) if passed else "-",
            ", ".join(failed) if failed else "none",
        ])
    report = "\n\n".join([
        "# Tutorial Probe",
        "Static checks that tutorial scenario mechanics are actionable from authored starting data.",
        table(["scenario", "passes", "passed checks", "failed checks"], rows),
    ]) + "\n"
    return report, failures


def main() -> int:
    report, failures = generate_report()
    DEFAULT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    DEFAULT_OUTPUT.write_text(report, encoding="utf-8")
    print(f"Wrote {DEFAULT_OUTPUT.relative_to(ROOT)}")
    if failures:
        print(f"Tutorial probe failed: {failures} failed checks")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
