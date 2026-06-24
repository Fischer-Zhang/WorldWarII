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

	if _test_transfer_strength():
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
	var before := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	var messages := ConquestManager.end_turn(state, map_data)
	var after := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	if int(ConquestManager.conquest_state(state, map_data).get("turn", 0)) == 2 \
			and after > before \
			and not messages.is_empty():
		return true
	printerr("FAIL: conquest end turn should reinforce and advance turn")
	return false

func _test_transfer_strength() -> bool:
	var state := {"version": 2, "campaigns": {}}
	var map_data := _test_map()
	var conquest := ConquestManager.conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	regions["bravo"]["owner"] = "a"
	regions["bravo"]["strength"] = 2
	conquest["regions"] = regions
	state["conquest"] = conquest
	var before_alpha := int(ConquestManager.region_state(state, map_data, "alpha").get("strength", 0))
	var before_bravo := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	if not ConquestManager.can_transfer(state, map_data, "alpha", "bravo"):
		printerr("FAIL: expected alpha to transfer to adjacent friendly bravo")
		return false
	var result := ConquestManager.transfer_strength(state, map_data, "alpha", "bravo", 2)
	var after_alpha := int(ConquestManager.region_state(state, map_data, "alpha").get("strength", 0))
	var after_bravo := int(ConquestManager.region_state(state, map_data, "bravo").get("strength", 0))
	if bool(result.get("ok", false)) \
			and after_alpha == before_alpha - 2 \
			and after_bravo == before_bravo + 2:
		return true
	printerr("FAIL: conquest transfer should move strength between adjacent friendly regions")
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
