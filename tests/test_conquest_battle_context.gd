extends SceneTree

const ConquestBattleContext := preload("res://scripts/scenario/conquest_battle_context.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	if _test_context_from_regions():
		pass_count += 1
	else:
		fail_count += 1

	if _test_apply_reserves_to_scenario():
		pass_count += 1
	else:
		fail_count += 1

	print("ConquestBattleContext tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _test_context_from_regions() -> bool:
	var source := {"strength": 7, "production": 5}
	var target := {"strength": 8, "production": 4}
	var context := ConquestBattleContext.from_regions(source, target)
	var reserves: Array = context.get("reserve_units", [])
	if int(context.get("attacker_power", 0)) == 12 \
			and int(context.get("defender_power", 0)) == 12 \
			and int(context.get("attacker_rank", 0)) == 2 \
			and int(context.get("defender_dig_in", 0)) == 2 \
			and reserves.size() == 1:
		return true
	printerr("FAIL: conquest context should derive power, ranks, dig-in, and reserves")
	return false

func _test_apply_reserves_to_scenario() -> bool:
	var scenario := {
		"units": [
			{"type": "infantry", "faction": "allies", "name": "A", "at": [3, 4]},
			{"type": "medium_tank", "faction": "axis", "name": "B", "at": [8, 4]},
		],
		"reinforcements": [
			{"at_turn": 5, "faction": "axis", "type": "infantry", "name": "Existing", "at": [8, 5]},
		],
	}
	var context := ConquestBattleContext.from_regions(
		{"strength": 9, "production": 6},
		{"strength": 3, "production": 2}
	)
	ConquestBattleContext.apply_to_scenario(scenario, "allies", context)
	var reinforcements: Array = scenario.get("reinforcements", [])
	if reinforcements.size() != 3:
		printerr("FAIL: high-production conquest attacker should add two reserve reinforcements")
		return false
	var first: Dictionary = reinforcements[1]
	var second: Dictionary = reinforcements[2]
	if int(first.get("at_turn", 0)) == ConquestBattleContext.RESERVE_TURN \
			and String(first.get("faction", "")) == "allies" \
			and String(first.get("type", "")) == "medium_tank" \
			and int(second.get("at_turn", 0)) == ConquestBattleContext.RESERVE_TURN \
			and String(second.get("type", "")) == "infantry":
		return true
	printerr("FAIL: conquest reserves should inherit player faction, turn, and unit types")
	return false
