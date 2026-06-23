class_name ConquestBattleContext
extends RefCounted

const RESERVE_TURN := 2

static func from_regions(source: Dictionary, target: Dictionary) -> Dictionary:
	var context := {
		"attacker_strength": int(source.get("strength", 0)),
		"attacker_production": int(source.get("production", 0)),
		"defender_strength": int(target.get("strength", 0)),
		"defender_production": int(target.get("production", 0)),
	}
	context["attacker_power"] = attacker_power(context)
	context["defender_power"] = defender_power(context)
	context["attacker_rank"] = attacker_rank(context)
	context["defender_dig_in"] = defender_dig_in(context)
	context["reserve_units"] = reserve_units(context)
	return context

static func attacker_power(context: Dictionary) -> int:
	return int(context.get("attacker_strength", 0)) + int(context.get("attacker_production", 0))

static func defender_power(context: Dictionary) -> int:
	return int(context.get("defender_strength", 0)) + int(context.get("defender_production", 0))

static func attacker_rank(context: Dictionary) -> int:
	var power := attacker_power(context)
	if power >= 12:
		return 2
	if power >= 8:
		return 1
	return 0

static func defender_dig_in(context: Dictionary) -> int:
	var power := defender_power(context)
	if power >= 12:
		return 2
	if power >= 8:
		return 1
	return 0

static func reserve_units(context: Dictionary) -> Array[Dictionary]:
	var production := int(context.get("attacker_production", 0))
	var units: Array[Dictionary] = []
	if production >= 6:
		units.append(_reserve_unit("medium_tank", "征服預備裝甲", [0, 0]))
		units.append(_reserve_unit("infantry", "征服預備步兵", [1, 0]))
	elif production >= 4:
		units.append(_reserve_unit("infantry", "征服預備步兵", [0, 0]))
	return units

static func apply_to_scenario(scenario: Dictionary, player_faction_id: String, context: Dictionary) -> void:
	if player_faction_id == "":
		return
	var reserves := _reserve_units_from_context(context)
	if reserves.is_empty():
		return
	var spawn_hexes := _player_reinforcement_hexes(scenario, player_faction_id, reserves.size())
	if spawn_hexes.is_empty():
		return
	var reinforcements: Array = scenario.get("reinforcements", []).duplicate(true)
	for i in range(min(reserves.size(), spawn_hexes.size())):
		var unit: Dictionary = reserves[i].duplicate(true)
		unit["faction"] = player_faction_id
		unit["at_turn"] = RESERVE_TURN
		unit["at"] = spawn_hexes[i]
		reinforcements.append(unit)
	scenario["reinforcements"] = reinforcements

static func battle_summary(context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var atk_power := attacker_power(context)
	var def_power := defender_power(context)
	lines.append("戰力: 攻 %d / 守 %d" % [atk_power, def_power])
	var rank := attacker_rank(context)
	if rank > 0:
		lines.append("攻方前鋒: 老兵 R%d" % rank)
	var dig := defender_dig_in(context)
	if dig > 0:
		lines.append("守方陣地: 構工 +%d" % dig)
	var reserves := _reserve_units_from_context(context)
	if not reserves.is_empty():
		var names: Array[String] = []
		for unit in reserves:
			names.append(String(unit.get("name", unit.get("type", ""))))
		lines.append("第 %d 回合預備隊: %s" % [RESERVE_TURN, ", ".join(names)])
	return lines

static func _reserve_units_from_context(context: Dictionary) -> Array[Dictionary]:
	var stored: Variant = context.get("reserve_units", [])
	var out: Array[Dictionary] = []
	if stored is Array:
		for item in stored:
			if item is Dictionary:
				out.append((item as Dictionary).duplicate(true))
	return out

static func _reserve_unit(type_id: String, name: String, fallback_at: Array) -> Dictionary:
	return {
		"type": type_id,
		"name": name,
		"at": fallback_at,
	}

static func _player_reinforcement_hexes(scenario: Dictionary, player_faction_id: String, needed: int) -> Array:
	var units: Array = scenario.get("units", [])
	var occupied := {}
	var player_hexes: Array[Vector2i] = []
	for item in units:
		var unit: Dictionary = item
		var at: Array = unit.get("at", [])
		if at.size() < 2:
			continue
		var key := Vector2i(int(at[0]), int(at[1]))
		occupied[key] = true
		if String(unit.get("faction", "")) == player_faction_id:
			player_hexes.append(key)
	if player_hexes.is_empty():
		return []
	player_hexes.sort_custom(func(a, b): return a.y < b.y if a.y != b.y else a.x < b.x)

	var out: Array = []
	for origin in player_hexes:
		for offset in _spawn_offsets():
			var candidate := origin + offset
			if candidate.x < 0 or candidate.y < 0:
				continue
			if occupied.has(candidate):
				continue
			occupied[candidate] = true
			out.append([candidate.x, candidate.y])
			if out.size() >= needed:
				return out
	return out

static func _spawn_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-2, 0),
		Vector2i(2, 0),
	]
