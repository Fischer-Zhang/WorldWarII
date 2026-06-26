extends SceneTree

# Tests for ConquestBattleSetup — overriding a themed scenario so the conquest
# player fights its recruited roster on the region's terrain.
# Run: godot --headless --script res://tests/test_conquest_battle_setup.gd

const ConquestBattleSetup := preload("res://scripts/scenario/conquest_battle_setup.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0
	if _test_attack_setup(): pass_count += 1
	else: fail_count += 1
	if _test_overflow_slots_unique(): pass_count += 1
	else: fail_count += 1
	if _test_duplicate_roster_names_become_unique(): pass_count += 1
	else: fail_count += 1
	print("ConquestBattleSetup tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _themed() -> Dictionary:
	return {
		"id": "themed",
		"map": {"width": 6, "height": 1, "tiles": [["plain", "plain", "plain", "plain", "plain", "plain"]]},
		"factions": [
			{"id": "soviet", "controller": "player", "color": "#00ff00"},
			{"id": "axis", "controller": "ai", "color": "#ff0000"},
		],
		"units": [
			{"faction": "soviet", "type": "infantry", "at": [0, 0]},
			{"faction": "soviet", "type": "infantry", "at": [1, 0]},
			{"faction": "axis", "type": "infantry", "at": [4, 0]},
			{"faction": "axis", "type": "infantry", "at": [5, 0]},
		],
		"victory": {},
	}

func _test_attack_setup() -> bool:
	var scenario := _themed()
	var pending := {
		"player_faction": "germany",
		"enemy_faction": "soviet",
		"player_color": "#aabbcc",
		"enemy_color": "#ddeeff",
		"player_name": "德國",
		"enemy_name": "蘇聯",
		"attacker_garrison": [
			{"id": 7, "type": "medium_tank", "xp": 5, "rank": 2, "name": "T #7"},
			{"id": 8, "type": "infantry", "xp": 0, "rank": 0, "name": "I #8"},
		],
		"defender_types": ["infantry", "at_gun"],
		"role": "attack",
	}
	ConquestBattleSetup.apply(scenario, pending)

	var facs: Array = scenario["factions"]
	if facs.size() != 2:
		printerr("FAIL: expected 2 factions, got %d" % facs.size())
		return false
	var by_id := {}
	for f in facs:
		by_id[String((f as Dictionary).get("id", ""))] = f
	if String((by_id.get("germany", {}) as Dictionary).get("controller", "")) != "player":
		printerr("FAIL: player faction (germany) should be player-controlled")
		return false
	if String((by_id.get("soviet", {}) as Dictionary).get("controller", "")) != "ai":
		printerr("FAIL: enemy faction (soviet) should be ai-controlled")
		return false

	var units: Array = scenario["units"]
	var pcount := 0
	var ecount := 0
	var tank_roster_ok := false
	for u in units:
		var unit: Dictionary = u
		if String(unit.get("faction", "")) == "germany":
			pcount += 1
			if int(unit.get("roster_id", -1)) == 7 and String(unit.get("type", "")) == "medium_tank":
				tank_roster_ok = true
		elif String(unit.get("faction", "")) == "soviet":
			ecount += 1
	if pcount != 2 or ecount != 2:
		printerr("FAIL: expected 2 player + 2 enemy units, got p%d e%d" % [pcount, ecount])
		return false
	if not tank_roster_ok:
		printerr("FAIL: player tank should carry its roster_id for writeback")
		return false

	var victory: Dictionary = scenario["victory"]
	if String((victory.get("germany", {}) as Dictionary).get("type", "")) != "eliminate":
		printerr("FAIL: attacker victory should be eliminate")
		return false
	if String((victory.get("soviet", {}) as Dictionary).get("type", "")) != "survive":
		printerr("FAIL: defender victory should be survive")
		return false
	return true

func _test_overflow_slots_unique() -> bool:
	# More units than authored slots: overflow must place every unit on a unique
	# on-map hex without crashing.
	var scenario := _themed()
	var garrison: Array = []
	for i in range(6):
		garrison.append({"id": i, "type": "infantry", "xp": 0, "rank": 0, "name": "u%d" % i})
	var pending := {
		"player_faction": "germany",
		"enemy_faction": "soviet",
		"attacker_garrison": garrison,
		"defender_types": [],
		"role": "attack",
	}
	ConquestBattleSetup.apply(scenario, pending)
	var units: Array = scenario["units"]
	if units.size() != 6:
		printerr("FAIL: expected 6 placed player units, got %d" % units.size())
		return false
	var seen := {}
	for u in units:
		var at: Array = (u as Dictionary).get("at", [])
		var key := "%d,%d" % [int(at[0]), int(at[1])]
		if seen.has(key):
			printerr("FAIL: duplicate spawn coord %s" % key)
			return false
		seen[key] = true
	return true

func _test_duplicate_roster_names_become_unique() -> bool:
	var scenario := _themed()
	var pending := {
		"player_faction": "germany",
		"enemy_faction": "soviet",
		"attacker_garrison": [
			{"id": -1, "type": "infantry", "xp": 0, "rank": 0, "name": "民兵"},
			{"id": -1, "type": "infantry", "xp": 0, "rank": 0, "name": "民兵"},
		],
		"defender_types": [],
		"role": "defend",
	}
	ConquestBattleSetup.apply(scenario, pending)
	var seen := {}
	for u in scenario["units"]:
		var unit: Dictionary = u
		if String(unit.get("faction", "")) != "germany":
			continue
		var name := String(unit.get("name", ""))
		if seen.has(name):
			printerr("FAIL: duplicate conquest roster display name %s" % name)
			return false
		seen[name] = true
	if seen.size() != 2:
		printerr("FAIL: expected two player roster entries, got %d" % seen.size())
		return false
	return true
