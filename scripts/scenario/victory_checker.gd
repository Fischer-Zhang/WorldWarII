class_name VictoryChecker
extends RefCounted

const Unit := preload("res://scripts/units/unit.gd")

# Evaluates scenario victory conditions after each turn end.
# Returns winner faction_id, or "" if no resolution yet.
#
# Supported condition types:
#   "eliminate": this faction wins when target faction has 0 living units.
#                target defaults to "all enemies".
#   "capture":   this faction wins by having one of its units on `target` hex (axial Vector2i)
#                by turn `by_turn` (inclusive).
#   "survive":   this faction wins if it still has living units by `by_turn`.

static func evaluate(
	scenario: Dictionary,
	factions: Dictionary,
	units: Array,
	turn_number: int,
) -> String:
	var victory_cfg: Dictionary = scenario.get("victory", {})

	# Survival: any faction with 0 units immediately loses (their opponents win).
	var alive_per_faction := {}
	for fid in factions.keys():
		alive_per_faction[fid] = 0
	for u in units:
		var unit: Unit = u
		if unit.is_alive():
			alive_per_faction[unit.faction_id] = alive_per_faction.get(unit.faction_id, 0) + 1

	for fid in factions.keys():
		var cond: Dictionary = victory_cfg.get(fid, {})
		var cond_type := String(cond.get("type", "eliminate"))
		match cond_type:
			"eliminate":
				if _all_enemies_eliminated(fid, alive_per_faction):
					return fid
			"capture":
				if turn_number > int(cond.get("by_turn", 999)):
					continue  # turn-limit expired; not their win
				var target := _coord_from_array(cond.get("target", [0, 0]))
				if _faction_holds(units, fid, target):
					return fid
			"survive":
				if turn_number >= int(cond.get("by_turn", 999)) and alive_per_faction.get(fid, 0) > 0:
					return fid

	# Turn-limit losses (a faction with `by_turn` for capture that has passed and didn't capture)
	# Treat as: if exactly one faction is still alive, they win.
	var living_factions: Array[String] = []
	for fid in alive_per_faction.keys():
		if alive_per_faction[fid] > 0:
			living_factions.append(fid)
	if living_factions.size() == 1:
		return living_factions[0]

	return ""

static func _all_enemies_eliminated(faction_id: String, alive: Dictionary) -> bool:
	for fid in alive.keys():
		if fid == faction_id:
			continue
		if alive[fid] > 0:
			return false
	return true

static func _faction_holds(units: Array, faction_id: String, target: Vector2i) -> bool:
	for u in units:
		var unit: Unit = u
		if unit.is_alive() and unit.faction_id == faction_id and unit.coord == target:
			return true
	return false

static func _coord_from_array(arr) -> Vector2i:
	if typeof(arr) != TYPE_ARRAY or arr.size() < 2:
		return Vector2i.ZERO
	# scenario JSON uses odd-r offset [col, row]; convert to axial
	var col := int(arr[0])
	var row := int(arr[1])
	return Vector2i(col - (row >> 1), row)
