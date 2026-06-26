class_name SecondaryObjectiveRules
extends RefCounted

# Pure helpers for optional secondary objectives. Battle state changes stay in
# battle.gd; this file keeps shared parsing and matching rules from drifting.

static func key(objective: Dictionary, index: int) -> String:
	return String(objective.get("id", "secondary_%d" % index))

static func objective_type(objective: Dictionary) -> String:
	return String(objective.get("type", "capture"))

static func applies_to_faction(objective: Dictionary, default_faction: String, faction_id: String) -> bool:
	var objective_faction := String(objective.get("faction", default_faction))
	return objective_faction == "" or objective_faction == faction_id

static func coord_from_offset_array(value) -> Variant:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return null
	var col := int(value[0])
	var row := int(value[1])
	return Vector2i(col - (row >> 1), row)

static func target_coord(objective: Dictionary, units: Array = []) -> Variant:
	if objective_type(objective) == "destroy_unit":
		var unit = target_unit(objective, units)
		if unit != null:
			return unit.coord
		return null
	return coord_from_offset_array(objective.get("target", []))

static func target_unit(objective: Dictionary, units: Array):
	for u in units:
		var unit = u
		if unit.is_alive() and target_matches_unit(objective, unit):
			return unit
	return null

static func target_matches_unit(objective: Dictionary, unit) -> bool:
	if unit == null:
		return false
	var target_unit_id := String(objective.get("target_unit", ""))
	if target_unit_id == "":
		return false
	var scenario_unit_id := ""
	var scenario_id_value: Variant = unit.get("scenario_unit_id")
	if typeof(scenario_id_value) == TYPE_STRING:
		scenario_unit_id = String(scenario_id_value)
	if target_unit_id == scenario_unit_id:
		return true
	var display_name := String(unit.get("display_name"))
	if target_unit_id == display_name:
		return true
	return target_unit_id == "%s:%s" % [String(unit.get("faction_id")), display_name]

static func required_turns(objective: Dictionary) -> int:
	return max(1, int(objective.get("required_turns", 1)))

static func rewards(objective: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var raw_rewards: Array = objective.get("rewards", [])
	for raw in raw_rewards:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var reward: Dictionary = raw
		var reward_type := String(reward.get("type", ""))
		var amount := int(reward.get("amount", 0))
		if reward_type == "" or amount <= 0:
			continue
		out.append({"type": reward_type, "amount": amount})
	var legacy_xp := int(objective.get("xp_reward", 0))
	if legacy_xp > 0 and xp_reward(out) <= 0:
		out.append({"type": "xp", "amount": legacy_xp})
	return out

static func xp_reward(rewards: Array[Dictionary]) -> int:
	var total := 0
	for reward in rewards:
		if String(reward.get("type", "")) == "xp":
			total += int(reward.get("amount", 0))
	return total

static func reward_text(rewards: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for reward in rewards:
		var reward_type := String(reward.get("type", ""))
		var amount := int(reward.get("amount", 0))
		match reward_type:
			"xp":
				parts.append("XP +%d" % amount)
	if parts.is_empty():
		return "已控制"
	return ", ".join(parts)
