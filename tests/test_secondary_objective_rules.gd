extends SceneTree

const SecondaryObjectiveRules := preload("res://scripts/scenario/secondary_objective_rules.gd")

class StubUnit:
	var scenario_unit_id: String = ""
	var display_name: String = ""
	var faction_id: String = ""
	var coord: Vector2i = Vector2i.ZERO
	var hp: int = 1

	func _init(_id: String, _name: String, _faction: String, _coord: Vector2i) -> void:
		scenario_unit_id = _id
		display_name = _name
		faction_id = _faction
		coord = _coord

	func is_alive() -> bool:
		return hp > 0

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	var coord_value: Variant = SecondaryObjectiveRules.coord_from_offset_array([5, 3])
	if coord_value == Vector2i(4, 3):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: odd-r coord conversion expected (4,3), got %s" % str(coord_value))

	var objective := {
		"type": "destroy_unit",
		"target_unit": "axis:Ammo Truck",
		"xp_reward": 2,
	}
	if SecondaryObjectiveRules.key(objective, 3) == "secondary_3":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: objective without id should use stable indexed key")

	var rewards := SecondaryObjectiveRules.rewards(objective)
	if SecondaryObjectiveRules.xp_reward(rewards) == 2 and SecondaryObjectiveRules.reward_text(rewards) == "XP +2":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: legacy xp_reward should be normalized into reward list, got %s" % str(rewards))

	var combo_rewards := SecondaryObjectiveRules.rewards({
		"rewards": [
			{"type": "xp", "amount": 1},
			{"type": "recover_suppression", "amount": 2},
			{"type": "repair_hp", "amount": 3},
			{"type": "advance_reinforcements", "amount": 2},
			{"type": "suppress_enemies", "amount": 1, "radius": 2},
			{"type": "strip_enemy_dig_in", "amount": 1, "radius": 3},
		],
	})
	var combo_text := SecondaryObjectiveRules.reward_text(combo_rewards)
	if SecondaryObjectiveRules.xp_reward(combo_rewards) == 1 \
			and combo_text == "XP +1, 壓制 -2, 修復 +3, 援軍提前 2T, 敵壓制 +1 R2, 敵構工 -1 R3" \
			and int(combo_rewards[4].get("radius", 0)) == 2 \
			and int(combo_rewards[5].get("radius", 0)) == 3:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: reward text should describe all secondary reward types, got %s" % combo_text)

	var reward_value := SecondaryObjectiveRules.tactical_reward_value(combo_rewards)
	var xp_only_value := SecondaryObjectiveRules.tactical_reward_value([{"type": "xp", "amount": 1}])
	if reward_value > xp_only_value and xp_only_value > 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: tactical reward value should rank combined tactical rewards above XP-only")

	var target := StubUnit.new("ammo_truck", "Ammo Truck", "axis", Vector2i(2, 1))
	if SecondaryObjectiveRules.target_matches_unit({"target_unit": "ammo_truck"}, target) \
			and SecondaryObjectiveRules.target_matches_unit({"target_unit": "Ammo Truck"}, target) \
			and SecondaryObjectiveRules.target_matches_unit({"target_unit": "axis:Ammo Truck"}, target):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: destroy target matching should support id, name, and faction:name")

	var target_coord: Variant = SecondaryObjectiveRules.target_coord(objective, [target])
	if target_coord == target.coord:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: destroy objective target coord should follow live target, got %s" % str(target_coord))

	if SecondaryObjectiveRules.applies_to_faction({}, "allies", "allies") \
			and SecondaryObjectiveRules.applies_to_faction({"faction": ""}, "allies", "axis") \
			and not SecondaryObjectiveRules.applies_to_faction({"faction": "axis"}, "allies", "allies"):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: faction applicability should honor defaults, explicit all, and mismatches")

	print("SecondaryObjectiveRules tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
