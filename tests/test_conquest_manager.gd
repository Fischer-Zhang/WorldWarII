extends SceneTree

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const ConquestManager := preload("res://scripts/scenario/conquest_manager.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	if _test_initial_state_and_attack():
		pass_count += 1
	else:
		fail_count += 1

	if _test_end_turn_and_country_switch():
		pass_count += 1
	else:
		fail_count += 1

	if _test_transfer_units():
		pass_count += 1
	else:
		fail_count += 1

	if _test_conquest_state_survives_campaign_normalise():
		pass_count += 1
	else:
		fail_count += 1

	if _test_resolve_real_battle_result():
		pass_count += 1
	else:
		fail_count += 1

	if _test_defense_result():
		pass_count += 1
	else:
		fail_count += 1

	if _test_ai_multi_attack_favorable():
		pass_count += 1
	else:
		fail_count += 1

	if _test_ai_consolidate():
		pass_count += 1
	else:
		fail_count += 1

	print("ConquestManager tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _test_initial_state_and_attack() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	var conquest := ConquestManager.conquest_state(state, map_data)
	if int(conquest.get("turn", 0)) != 1 or String(conquest.get("player_country", "")) != "a":
		printerr("FAIL: conquest initial state")
		return false
	# An empty garrison cannot attack — you must recruit an army first.
	if ConquestManager.can_attack(state, map_data, "alpha", "bravo"):
		printerr("FAIL: empty garrison should not be able to attack")
		return false
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "步兵 #1"},
	]
	if not ConquestManager.can_attack(state, map_data, "alpha", "bravo"):
		printerr("FAIL: garrisoned alpha should be able to attack bravo")
		return false
	# A won battle captures bravo; the survivor (with gained xp) garrisons it.
	var result := ConquestManager.resolve_battle_result(
		state, map_data, "alpha", "bravo", true, [{"roster_id": 1, "xp": 3, "rank": 1}]
	)
	var bravo := ConquestManager.region_state(state, map_data, "bravo")
	var garrison: Array = bravo.get("garrison", [])
	if bool(result.get("ok", false)) \
			and String(bravo.get("owner", "")) == "a" \
			and garrison.size() == 1 \
			and int((garrison[0] as Dictionary).get("xp", 0)) == 3:
		return true
	printerr("FAIL: won battle should capture bravo and garrison it with the survivor")
	return false

func _test_end_turn_and_country_switch() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	ConquestManager.set_player_country(state, map_data, "b")
	if String(ConquestManager.conquest_state(state, map_data).get("player_country", "")) != "b":
		printerr("FAIL: conquest player country switch")
		return false
	ConquestManager.set_player_country(state, map_data, "a")
	# AI b owns bravo and attacks alpha (player a): end_turn regens, then pauses
	# for a player-fought defensive battle.
	var before := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	var step := ConquestManager.end_turn(state, map_data)
	var after := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	if String(step.get("status", "")) != "defend" or after <= before:
		printerr("FAIL: AI attack on a player region should regen then pause for defense")
		return false
	if String(step.get("to", "")) != "alpha" or String(step.get("attacker_country", "")) != "b":
		printerr("FAIL: defense step should target player's alpha, attacker b")
		return false
	# No enemy-owned regions: the phase finishes and the turn advances.
	state = {"version": 2, "campaigns": {}}
	var conquest := ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["bravo"]["owner"] = "a"
	var done := ConquestManager.end_turn(state, map_data)
	if String(done.get("status", "")) == "done" \
			and int(ConquestManager.conquest_state(state, map_data).get("turn", 0)) == 2:
		return true
	printerr("FAIL: with no enemy targets end_turn should finish and advance the turn")
	return false

func _test_transfer_units() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	var conquest := ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["bravo"]["owner"] = "a"
	# An empty source garrison has no troops to move.
	if ConquestManager.can_transfer(state, map_data, "alpha", "bravo"):
		printerr("FAIL: empty garrison should not be transferable")
		return false
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "a1"},
		{"id": 2, "type": "infantry", "xp": 0, "rank": 0, "name": "a2"},
	]
	if not ConquestManager.can_transfer(state, map_data, "alpha", "bravo"):
		printerr("FAIL: garrisoned alpha should transfer troops to adjacent friendly bravo")
		return false
	# Move a single unit first (partial transfer).
	var one := ConquestManager.transfer_units(state, map_data, "alpha", "bravo", [1])
	if not bool(one.get("ok", false)) \
			or (ConquestManager.region_state(state, map_data, "alpha").get("garrison", []) as Array).size() != 1 \
			or (ConquestManager.region_state(state, map_data, "bravo").get("garrison", []) as Array).size() != 1:
		printerr("FAIL: single-unit transfer should move exactly one unit")
		return false
	# Move the remaining army.
	var result := ConquestManager.transfer_units(state, map_data, "alpha", "bravo")
	var alpha := ConquestManager.region_state(state, map_data, "alpha")
	var bravo := ConquestManager.region_state(state, map_data, "bravo")
	if bool(result.get("ok", false)) \
			and (alpha.get("garrison", []) as Array).is_empty() \
			and (bravo.get("garrison", []) as Array).size() == 2:
		return true
	printerr("FAIL: transfer should move troops (one then the rest) from alpha to bravo")
	return false

func _test_conquest_state_survives_campaign_normalise() -> bool:
	var state := {
		"version": 2,
		"campaigns": {},
		"conquest": {
			"turn": 4,
			"player_country": "b",
			"regions": {"alpha": {"owner": "b"}},
		},
	}
	var normalised := CampaignManager._normalise_state(state)
	var conquest: Dictionary = normalised.get("conquest", {})
	if int(conquest.get("turn", 0)) == 4 \
			and String(conquest.get("player_country", "")) == "b" \
			and String(conquest.get("regions", {}).get("alpha", {}).get("owner", "")) == "b":
		return true
	printerr("FAIL: conquest state should survive campaign normalise")
	return false

func _test_resolve_real_battle_result() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	var conquest := ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "a1"},
		{"id": 2, "type": "infantry", "xp": 0, "rank": 0, "name": "a2"},
	]
	# Win: only the survivor advances into the captured region; source emptied.
	var win := ConquestManager.resolve_battle_result(
		state, map_data, "alpha", "bravo", true, [{"roster_id": 1, "xp": 2, "rank": 0}]
	)
	var bravo := ConquestManager.region_state(state, map_data, "bravo")
	var alpha := ConquestManager.region_state(state, map_data, "alpha")
	if not bool(win.get("ok", false)) \
			or String(bravo.get("owner", "")) != "a" \
			or (bravo.get("garrison", []) as Array).size() != 1 \
			or not (alpha.get("garrison", []) as Array).is_empty():
		printerr("FAIL: conquest win should move survivor into target and empty the source")
		return false
	# Loss: survivors retreat to source, target stays enemy and is weakened.
	state = {"version": 2, "campaigns": {}}
	conquest = ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "a1"},
		{"id": 2, "type": "infantry", "xp": 0, "rank": 0, "name": "a2"},
	]
	var before := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	var loss := ConquestManager.resolve_battle_result(
		state, map_data, "alpha", "bravo", false, [{"roster_id": 2, "xp": 1, "rank": 0}]
	)
	bravo = ConquestManager.region_state(state, map_data, "bravo")
	alpha = ConquestManager.region_state(state, map_data, "alpha")
	if bool(loss.get("ok", false)) \
			and String(bravo.get("owner", "")) == "b" \
			and int(bravo.get("strength", 0)) < before \
			and (alpha.get("garrison", []) as Array).size() == 1:
		return true
	printerr("FAIL: conquest loss should retreat survivors and weaken the enemy target")
	return false

func _test_defense_result() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	var conquest := ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "d1"},
		{"id": 2, "type": "infantry", "xp": 0, "rank": 0, "name": "d2"},
	]
	# Held: region stays ours, only the surviving defender remains.
	var held := ConquestManager.resolve_defense_result(
		state, map_data, "b", "bravo", "alpha", true, [{"roster_id": 1, "xp": 2, "rank": 0}]
	)
	var alpha := ConquestManager.region_state(state, map_data, "alpha")
	if not bool(held.get("ok", false)) \
			or String(alpha.get("owner", "")) != "a" \
			or (alpha.get("garrison", []) as Array).size() != 1:
		printerr("FAIL: held defense should keep the region and surviving defenders")
		return false
	# Fell: region captured by the attacker, defenders wiped.
	state = {"version": 2, "campaigns": {}}
	conquest = ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["alpha"]["garrison"] = [
		{"id": 1, "type": "infantry", "xp": 0, "rank": 0, "name": "d1"},
	]
	var fell := ConquestManager.resolve_defense_result(
		state, map_data, "b", "bravo", "alpha", false, []
	)
	alpha = ConquestManager.region_state(state, map_data, "alpha")
	if bool(fell.get("ok", false)) \
			and String(alpha.get("owner", "")) == "b" \
			and (alpha.get("garrison", []) as Array).is_empty():
		return true
	printerr("FAIL: lost defense should hand the region to the attacker")
	return false

func _test_ai_multi_attack_favorable() -> bool:
	var map_data := {
		"start_country": "p",
		"countries": {"p": {"name_zh": "P"}, "c": {"name_zh": "C"}, "d": {"name_zh": "D"}, "neutral": {"name_zh": "N"}},
		"regions": [
			{"id": "home", "owner": "c", "x": 0, "y": 0, "production": 5, "neighbors": ["w1", "w2", "citadel"]},
			{"id": "w1", "owner": "d", "x": 1, "y": 0, "production": 1, "neighbors": ["home"]},
			{"id": "w2", "owner": "d", "x": 2, "y": 0, "production": 1, "neighbors": ["home"]},
			{"id": "citadel", "owner": "neutral", "x": 3, "y": 0, "production": 5, "neighbors": ["home"]},
			{"id": "cap", "owner": "p", "x": 4, "y": 0, "production": 3, "neighbors": []},
		],
	}
	var state := {"version": 2, "campaigns": {}}
	ConquestManager.set_player_country(state, map_data, "p")
	var conquest := ConquestManager.conquest_state(state, map_data)
	conquest["regions"]["home"]["strength"] = 30
	conquest["regions"]["w1"]["strength"] = 1
	conquest["regions"]["w2"]["strength"] = 1
	conquest["regions"]["citadel"]["strength"] = 60
	var step := ConquestManager.end_turn(state, map_data)
	if String(step.get("status", "")) != "done":
		printerr("FAIL: AI turn with no player-adjacent attack should complete, got %s" % str(step))
		return false
	var w1 := ConquestManager.region_state(state, map_data, "w1")
	var w2 := ConquestManager.region_state(state, map_data, "w2")
	var citadel := ConquestManager.region_state(state, map_data, "citadel")
	# Takes both weak neighbours in one turn (multi-attack); leaves the too-strong
	# citadel alone (only winnable attacks).
	if String(w1.get("owner", "")) == "c" \
			and String(w2.get("owner", "")) == "c" \
			and String(citadel.get("owner", "")) == "neutral":
		return true
	printerr("FAIL: strong AI should take both weak neighbours and skip the too-strong citadel")
	return false

func _test_ai_consolidate() -> bool:
	var regions := {
		"interior": {"id": "interior", "owner": "c", "strength": 11, "production": 2, "neighbors": ["front"]},
		"front": {"id": "front", "owner": "c", "strength": 2, "production": 2, "neighbors": ["interior", "enemyR"]},
		"enemyR": {"id": "enemyR", "owner": "d", "strength": 5, "production": 2, "neighbors": ["front"]},
	}
	ConquestManager._ai_consolidate(regions, "p")
	if int(regions["interior"]["strength"]) == 7 and int(regions["front"]["strength"]) == 6:
		return true
	printerr("FAIL: consolidation should ship spare interior strength to the border (interior=%d front=%d)" % [
		int(regions["interior"]["strength"]), int(regions["front"]["strength"]),
	])
	return false

func _test_map() -> Dictionary:
	return {
		"start_country": "a",
		"countries": {
			"a": {"name_zh": "A", "color": "#ff0000"},
			"b": {"name_zh": "B", "color": "#0000ff"},
		},
		"regions": [
			{
				"id": "alpha",
				"name_zh": "Alpha",
				"owner": "a",
				"x": 0,
				"y": 0,
				"production": 5,
				"neighbors": ["bravo"],
			},
			{
				"id": "bravo",
				"name_zh": "Bravo",
				"owner": "b",
				"x": 1,
				"y": 0,
				"production": 1,
				"neighbors": ["alpha"],
			},
		],
	}
