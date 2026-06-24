class_name ConquestBattleSetup
extends RefCounted

# Builds a Conquest battle on a region's themed map. The terrain comes from the
# themed scenario, but factions, unit rosters and victory are OVERRIDDEN so the
# conquest player fights its own recruited army (attacker) against a
# strength-generated force (defender), always controlling its own side —
# regardless of which faction the scenario was originally authored for.
#
# `pending` is GameState.pending_conquest_battle, carrying:
#   player_faction / enemy_faction (country ids), player_color / enemy_color,
#   player_name / enemy_name, attacker_garrison (records), defender_types (ids),
#   role ("attack" | "defend").

const DEFENDER_SURVIVE_TURNS := 12

static func apply(scenario: Dictionary, pending: Dictionary) -> void:
	var player_faction := String(pending.get("player_faction", ""))
	var enemy_faction := String(pending.get("enemy_faction", ""))
	if player_faction == "" or enemy_faction == "" or player_faction == enemy_faction:
		return

	# Player is the attacker on an "attack", the defender on a "defend"; the
	# garrison the player actually owns always spawns on the protagonist slots.
	var role := String(pending.get("role", "attack"))
	var pools := _spawn_pools(scenario)
	var player_pool: Array = pools["attacker"] if role == "attack" else pools["defender"]
	var enemy_pool: Array = pools["defender"] if role == "attack" else pools["attacker"]

	var occupied := {}
	for arr in pools.values():
		for at in arr:
			occupied[_key(at)] = true

	var player_entries := _roster_entries(
		pending.get("attacker_garrison", []), player_faction, player_pool, occupied
	)
	var enemy_entries := _type_entries(
		pending.get("defender_types", []), enemy_faction, enemy_pool, occupied
	)

	scenario["factions"] = [
		{
			"id": player_faction,
			"name": String(pending.get("player_name", player_faction)),
			"controller": "player",
			"color": String(pending.get("player_color", "#cccccc")),
		},
		{
			"id": enemy_faction,
			"name": String(pending.get("enemy_name", enemy_faction)),
			"controller": "ai",
			"ai": "defensive" if role == "attack" else "aggressive",
			"color": String(pending.get("enemy_color", "#cccccc")),
		},
	]
	scenario["units"] = player_entries + enemy_entries
	scenario["reinforcements"] = []
	# Player (attacker) must wipe the defenders; the AI side "wins" by holding
	# out to the turn limit.
	scenario["victory"] = {
		player_faction: {"type": "eliminate"},
		enemy_faction: {"type": "survive", "by_turn": DEFENDER_SURVIVE_TURNS},
	}

# --- helpers ---

static func _spawn_pools(scenario: Dictionary) -> Dictionary:
	# attacker pool = positions of the authored player faction (the scenario's
	# offensive start); defender pool = everyone else. Falls back to a half/half
	# split of all authored positions if no player faction is marked.
	var player_fid := ""
	for f in scenario.get("factions", []):
		var faction: Dictionary = f
		if String(faction.get("controller", "")) == "player":
			player_fid = String(faction.get("id", ""))
			break
	var attacker: Array = []
	var defender: Array = []
	for u in scenario.get("units", []):
		var unit: Dictionary = u
		var at: Array = unit.get("at", [])
		if at.size() < 2:
			continue
		if player_fid != "" and String(unit.get("faction", "")) == player_fid:
			attacker.append([int(at[0]), int(at[1])])
		else:
			defender.append([int(at[0]), int(at[1])])
	if attacker.is_empty() and not defender.is_empty():
		var half := int(defender.size() / 2)
		attacker = defender.slice(0, half)
		defender = defender.slice(half)
	return {"attacker": attacker, "defender": defender}

static func _roster_entries(garrison: Array, faction_id: String, slots: Array, occupied: Dictionary) -> Array:
	var entries: Array = []
	for i in range(garrison.size()):
		var record: Dictionary = garrison[i]
		var entry := {
			"type": String(record.get("type", "infantry")),
			"faction": faction_id,
			"name": String(record.get("name", "")),
			"at": _slot_or_free(slots, i, occupied),
			"roster_id": int(record.get("id", -1)),
		}
		entries.append(entry)
	return entries

static func _type_entries(types: Array, faction_id: String, slots: Array, occupied: Dictionary) -> Array:
	var entries: Array = []
	for i in range(types.size()):
		entries.append({
			"type": String(types[i]),
			"faction": faction_id,
			"at": _slot_or_free(slots, i, occupied),
		})
	return entries

static func _slot_or_free(slots: Array, idx: int, occupied: Dictionary) -> Array:
	if idx < slots.size():
		return slots[idx]
	# Overflow beyond the authored slots: search outward from the last slot.
	var seed: Array = slots[slots.size() - 1] if not slots.is_empty() else [0, 0]
	for off in _offsets():
		var cand: Array = [int(seed[0]) + int(off[0]), int(seed[1]) + int(off[1])]
		if cand[0] < 0 or cand[1] < 0:
			continue
		if occupied.has(_key(cand)):
			continue
		occupied[_key(cand)] = true
		return cand
	return seed

static func _offsets() -> Array:
	return [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [2, 0], [-2, 0], [0, 2], [0, -2]]

static func _key(at: Array) -> String:
	return "%d,%d" % [int(at[0]), int(at[1])]
