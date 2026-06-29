extends SceneTree

# Standalone tests for AI role-shaping heuristics.
# Run with: godot --headless --script res://tests/test_ai_controller.gd

const AIController := preload("res://scripts/turn/ai_controller.gd")
const CombatEffects := preload("res://scripts/combat/combat_effects.gd")
const AT_DEF := {
	"hp": 6, "attack": 5, "defense": 1, "range": 1, "move": 1,
	"vision": 2, "vs_armor": 6, "armor": 0,
}
const ARTILLERY_DEF := {
	"id": "artillery", "hp": 8, "attack": 7, "defense": 1, "range": 4, "move": 2,
	"vision": 5, "vs_armor": 1, "armor": 0, "indirect": true,
}
const LIGHT_TANK_DEF := {
	"hp": 12, "attack": 5, "defense": 4, "range": 1, "move": 5,
	"vision": 5, "vs_armor": 2, "armor": 2,
	"skill": {
		"id": "fire_support_mark",
		"cooldown": 2,
		"duration": 0,
		"fire_support_range": 5,
	},
}
const ENGINEER_DEF := {
	"id": "engineer", "hp": 8, "attack": 3, "defense": 2, "range": 1, "move": 3,
	"vision": 3, "vs_armor": 1, "armor": 0,
	"skills": [{
		"id": "breach_support",
		"cooldown": 2,
		"duration": 0,
		"breach_support_range": 2,
	}],
}
const MG_DEF := {
	"id": "mg_team", "hp": 8, "attack": 6, "defense": 1, "range": 1, "move": 2,
	"vision": 3, "vs_armor": 0, "armor": 0, "overwatch_damage_pct": 100,
	"skill": {
		"id": "suppressive_fire",
		"cooldown": 2,
		"duration": 0,
		"suppressive_fire_range": 2,
		"suppressive_fire_amount": 2,
	},
}
const TANK_DESTROYER_DEF := {
	"id": "tank_destroyer", "hp": 12, "attack": 5, "defense": 4, "range": 2, "move": 3,
	"vision": 3, "vs_armor": 7, "armor": 3,
	"armor_standoff_min_range": 2, "armor_standoff_vs_armor_bonus": 2,
}

class StubHexMap:
	var terrain_overrides: Dictionary = {}
	var occupants: Dictionary = {}
	func terrain_at(coord: Vector2i) -> String:
		return terrain_overrides.get(coord, "plain")
	func blocks_los_at(coord: Vector2i) -> bool:
		return terrain_at(coord) in ["forest", "mountain"]
	func terrain_impassable(terrain: String) -> bool:
		return terrain in ["river", "sea", "mountain"]
	func move_cost_at(_coord: Vector2i) -> int:
		return 1

class StubBattle:
	var hex_map := StubHexMap.new()
	var visibility_by_faction: Dictionary = {}
	var units: Array = []
	var factions: Dictionary = {}
	var scenario: Dictionary = {}
	var captured_secondary_objectives: Dictionary = {}
	func get_known_enemies(faction_id: String) -> Array:
		var out: Array = []
		var visible: Dictionary = visibility_by_faction.get(faction_id, {})
		for u in units:
			if u.faction_id != faction_id and u.is_alive():
				out.append({"unit": u, "coord": u.coord, "visible": visible.has(u.coord)})
		return out

class StubDataLoader:
	var defs: Dictionary = {
		"infantry": {"hp": 10, "attack": 4, "defense": 2, "range": 1, "move": 3, "vision": 3, "vs_armor": 1, "armor": 0},
		"mg_team": MG_DEF,
		"medium_tank": {"hp": 16, "attack": 7, "defense": 5, "range": 1, "move": 4, "vision": 4, "vs_armor": 4, "armor": 4},
		"tank_destroyer": TANK_DESTROYER_DEF,
		"at_gun": AT_DEF,
		"artillery": ARTILLERY_DEF,
		"light_tank": LIGHT_TANK_DEF,
		"engineer": ENGINEER_DEF,
	}
	var terrains: Dictionary = {
		"plain": {"defense": 0},
		"town": {"defense": 3},
	}
	func get_unit_def(type_id: String) -> Dictionary:
		return defs[type_id]
	func get_terrain_def(terrain_id: String) -> Dictionary:
		return terrains.get(terrain_id, terrains["plain"])
	func get_general_def(general_id: String) -> Dictionary:
		return {}  # tests don't exercise generals — empty disables bonuses

class StubUnit:
	var type_id: String
	var scenario_unit_id: String = ""
	var display_name: String = ""
	var faction_id: String
	var coord: Vector2i
	var hp: int
	var max_hp: int
	# Fields read by CombatModifiers / AI's general+rank pipeline
	var rank: int = 0
	var xp: int = 0
	var general_id: String = ""
	var dig_in_level: int = 0
	var suppression: int = 0
	var has_attacked: bool = false
	var skill_cooldowns: Dictionary = {}
	func _init(_type_id: String, _faction: String, _coord: Vector2i, _hp: int) -> void:
		type_id = _type_id
		display_name = _type_id
		faction_id = _faction
		coord = _coord
		hp = _hp
		max_hp = _hp
	func is_alive() -> bool:
		return hp > 0
	func is_done_for_turn() -> bool:
		return has_attacked
	func skill_ready(skill_id: String, current_turn: int) -> bool:
		return int(skill_cooldowns.get(skill_id, 0)) <= current_turn

func make_unit(type_id: String, faction: String, coord: Vector2i, hp: int) -> StubUnit:
	return StubUnit.new(type_id, faction, coord, hp)

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	var battle := StubBattle.new()
	var ai := AIController.new(battle, "aggressive", "normal")
	ai._data_loader = StubDataLoader.new()

	# 1) AT gun should prefer armor over a soft target when raw damage is close.
	var at_gun := make_unit("at_gun", "axis", Vector2i(0, 0), 6)
	var infantry := make_unit("infantry", "allies", Vector2i(1, 0), 10)
	var tank := make_unit("medium_tank", "allies", Vector2i(0, 1), 16)
	battle.hex_map.terrain_overrides[tank.coord] = "town"
	var at_def := AT_DEF
	var visible := {infantry.coord: true, tank.coord: true}
	var target = ai._best_attack_from(
		at_gun.coord, at_gun.faction_id, at_gun.type_id, [infantry, tank], at_def, visible
	)
	if target == tank:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: AT gun should prefer armored target when role score breaks tie")

	# 2) Artillery should score adjacent known-enemy positions below standoff positions.
	var artillery := make_unit("artillery", "axis", Vector2i(0, 0), 8)
	var art_def := ARTILLERY_DEF
	var known := [{"coord": Vector2i(0, 0), "visible": false}]
	var close_score: float = ai._score_position(
		artillery, Vector2i(0, 1), known, [], battle.hex_map, art_def, {}
	)
	var far_score: float = ai._score_position(
		artillery, Vector2i(0, 3), known, [], battle.hex_map, art_def, {}
	)
	if far_score > close_score:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: artillery standoff score expected far %.2f > close %.2f" % [far_score, close_score])

	# 3) Light tanks should prefer the scouting band around last-known enemy positions.
	var light_tank := make_unit("light_tank", "axis", Vector2i(0, 0), 12)
	var light_def := LIGHT_TANK_DEF
	var scout_known := [{"coord": Vector2i(5, 0), "visible": false}]
	var too_far_score: float = ai._score_position(
		light_tank, Vector2i(0, 0), scout_known, [], battle.hex_map, light_def, {}
	)
	var scout_score: float = ai._score_position(
		light_tank, Vector2i(2, 0), scout_known, [], battle.hex_map, light_def, {}
	)
	if scout_score > too_far_score:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: light tank scout score expected scout %.2f > far %.2f" % [scout_score, too_far_score])

	# 4) Hard AI should apply 1-ply lookahead as a counter-damage penalty.
	var hard_ai := AIController.new(battle, "aggressive", "hard")
	hard_ai._data_loader = ai._data_loader
	var normal_ai := AIController.new(battle, "aggressive", "normal")
	normal_ai._data_loader = ai._data_loader
	battle.hex_map.occupants.clear()
	var wounded_tank := make_unit("medium_tank", "axis", Vector2i(0, 0), 4)
	var player_tank := make_unit("medium_tank", "allies", Vector2i(0, 2), 16)
	var visible_enemies := [player_tank]
	var tank_def: Dictionary = hard_ai._get_unit_def(wounded_tank.type_id)
	var normal_exposed_score: float = normal_ai._score_position(
		wounded_tank, Vector2i(0, 1), [{"coord": player_tank.coord, "visible": true}], visible_enemies, battle.hex_map, tank_def, {}
	)
	var hard_exposed_score: float = hard_ai._score_position(
		wounded_tank, Vector2i(0, 1), [{"coord": player_tank.coord, "visible": true}], visible_enemies, battle.hex_map, tank_def, {}
	)
	var counter_damage: int = hard_ai._lookahead_counter_damage(
		wounded_tank, Vector2i(0, 1), visible_enemies, battle.hex_map, tank_def
	)
	if counter_damage > 0 and hard_exposed_score < normal_exposed_score:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: hard lookahead expected counter penalty, normal %.2f hard %.2f counter %d" % [normal_exposed_score, hard_exposed_score, counter_damage])

	# 5) Artillery should prefer breaking an entrenched target when damage is otherwise comparable.
	battle.hex_map.terrain_overrides.clear()
	var dug_infantry := make_unit("infantry", "allies", Vector2i(2, -1), 10)
	var exposed_infantry := make_unit("infantry", "allies", Vector2i(1, -1), 10)
	dug_infantry.dig_in_level = 1
	var artillery_target = ai._best_attack_from(
		artillery.coord, artillery.faction_id, artillery.type_id,
		[exposed_infantry, dug_infantry], art_def,
		{exposed_infantry.coord: true, dug_infantry.coord: true}
	)
	if artillery_target == dug_infantry:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: artillery should prefer entrenched target when suppression/dig-in break adds value")

	# 6) Capture factions should bias movement toward their objective hex.
	battle.scenario = {"victory": {"axis": {"type": "capture", "target": [5, 0]}}}
	var objective_far: float = ai._score_position(
		light_tank, Vector2i(0, 0), scout_known, [], battle.hex_map, light_def, {}
	)
	var objective_near: float = ai._score_position(
		light_tank, Vector2i(4, 0), scout_known, [], battle.hex_map, light_def, {}
	)
	if objective_near > objective_far:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: capture objective score expected near %.2f > far %.2f" % [objective_near, objective_far])
	battle.scenario = {}

	# 6b) Unfinished secondary objectives should also pull AI movement, but completed ones stop scoring.
	battle.scenario = {
		"secondary_objectives": [{
			"id": "forward_cache",
			"type": "hold_turns",
			"faction": "axis",
			"target": [4, 0],
			"required_turns": 2,
			"rewards": [{"type": "xp", "amount": 1}],
		}]
	}
	battle.captured_secondary_objectives.clear()
	var secondary_far: float = ai._secondary_objective_position_score("axis", Vector2i(0, 0))
	var secondary_near: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	battle.captured_secondary_objectives["forward_cache"] = true
	var completed_score: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	if secondary_near > secondary_far and completed_score == 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: unfinished secondary objective should score near, completed should stop; near %.2f far %.2f completed %.2f" % [
			secondary_near, secondary_far, completed_score,
		])
	battle.scenario["secondary_objectives"][0]["requires"] = ["recon_cache"]
	battle.captured_secondary_objectives.clear()
	var locked_secondary_score: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	battle.captured_secondary_objectives["recon_cache"] = true
	var unlocked_secondary_score: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	if locked_secondary_score == 0.0 and unlocked_secondary_score == secondary_near:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: locked secondary objective should not score until prerequisite completes; locked %.2f unlocked %.2f expected %.2f" % [
			locked_secondary_score, unlocked_secondary_score, secondary_near,
		])
	battle.scenario = {}
	battle.captured_secondary_objectives.clear()

	# 6c) Prerequisite objectives should inherit a small future pull from valuable locked follow-ups.
	battle.scenario = {
		"secondary_objectives": [
			{
				"id": "spot_battery",
				"type": "recon_hex",
				"faction": "axis",
				"target": [3, 0],
				"rewards": [{"type": "xp", "amount": 1}],
			},
			{
				"id": "silence_battery",
				"type": "hold_turns",
				"faction": "axis",
				"target": [5, 0],
				"required_turns": 2,
				"rewards": [{"type": "suppress_enemies", "amount": 1, "radius": 2}],
				"requires": ["spot_battery"],
			},
		]
	}
	battle.captured_secondary_objectives.clear()
	var chain_prereq: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(3, 0))
	battle.scenario["secondary_objectives"][1]["requires"] = ["other_objective"]
	var plain_prereq: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(3, 0))
	battle.scenario["secondary_objectives"][1]["requires"] = ["spot_battery", "other_objective"]
	var blocked_multi_prereq: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(3, 0))
	battle.captured_secondary_objectives["other_objective"] = true
	var ready_multi_prereq: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(3, 0))
	battle.captured_secondary_objectives.clear()
	battle.scenario["secondary_objectives"][1]["requires"] = ["spot_battery"]
	battle.captured_secondary_objectives["spot_battery"] = true
	var unlocked_followup: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(5, 0))
	battle.captured_secondary_objectives["silence_battery"] = true
	var completed_chain: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(5, 0))
	if String(chain_prereq.get("key", "")) == "spot_battery" \
			and float(chain_prereq.get("future_value", 0.0)) > 0.0 \
			and float(chain_prereq.get("future_pull", 0.0)) > 0.0 \
			and float(chain_prereq.get("score", 0.0)) > float(plain_prereq.get("score", 0.0)) \
			and float(blocked_multi_prereq.get("future_pull", 0.0)) == 0.0 \
			and float(ready_multi_prereq.get("future_pull", 0.0)) > 0.0 \
			and String(unlocked_followup.get("key", "")) == "silence_battery" \
			and float(completed_chain.get("score", 0.0)) == 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: prerequisite secondary should score locked follow-up future value; chain=%s plain=%s blocked=%s ready=%s unlocked=%s completed=%s" % [
			str(chain_prereq), str(plain_prereq), str(blocked_multi_prereq), str(ready_multi_prereq), str(unlocked_followup), str(completed_chain),
		])
	battle.scenario = {}
	battle.captured_secondary_objectives.clear()

	# 6d) Tactical secondary rewards should increase objective pull without bypassing completion guards.
	battle.scenario = {
		"secondary_objectives": [{
			"id": "xp_cache",
			"type": "recon_hex",
			"faction": "axis",
			"target": [3, 0],
			"rewards": [{"type": "xp", "amount": 1}],
		}]
	}
	var xp_secondary: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(0, 0))
	battle.scenario["secondary_objectives"] = [{
		"id": "breach_cache",
		"type": "recon_hex",
		"faction": "axis",
		"target": [3, 0],
		"rewards": [
			{"type": "xp", "amount": 1},
			{"type": "strip_enemy_dig_in", "amount": 1, "radius": 2},
		],
	}]
	var breach_secondary: Dictionary = ai._secondary_objective_position_breakdown("axis", Vector2i(0, 0))
	if float(breach_secondary.get("score", 0.0)) > float(xp_secondary.get("score", 0.0)) \
			and float(breach_secondary.get("reward_value", 0.0)) > float(xp_secondary.get("reward_value", 0.0)) \
			and float(breach_secondary.get("reward_pull", 0.0)) > float(xp_secondary.get("reward_pull", 0.0)):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: tactical secondary reward should increase pull; xp=%s breach=%s" % [
			str(xp_secondary), str(breach_secondary),
		])
	battle.scenario = {}
	battle.captured_secondary_objectives.clear()

	# 7) Destroy secondary objectives should bias attack choice toward the marked unit.
	var destroy_target := make_unit("infantry", "allies", Vector2i(1, 0), 10)
	destroy_target.scenario_unit_id = "ammo_truck"
	destroy_target.display_name = "Ammo Truck"
	var ordinary_target := make_unit("infantry", "allies", Vector2i(0, 1), 10)
	battle.units = [light_tank, destroy_target, ordinary_target]
	battle.scenario = {
		"secondary_objectives": [{
			"id": "destroy_ammo",
			"type": "destroy_unit",
			"faction": "axis",
			"target_unit": "ammo_truck",
			"rewards": [{"type": "xp", "amount": 1}],
		}]
	}
	battle.captured_secondary_objectives.clear()
	var destroy_choice = ai._best_attack_from(
		light_tank.coord, light_tank.faction_id, light_tank.type_id,
		[ordinary_target, destroy_target],
		LIGHT_TANK_DEF,
		{ordinary_target.coord: true, destroy_target.coord: true},
		light_tank
	)
	if destroy_choice == destroy_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: destroy secondary objective should bias attack toward marked target")
	battle.captured_secondary_objectives["destroy_ammo"] = true
	var completed_destroy_score: float = ai._secondary_destroy_target_score("axis", destroy_target)
	if completed_destroy_score == 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: completed destroy secondary objective should stop attack bonus, got %.2f" % completed_destroy_score)
	battle.scenario["secondary_objectives"][0]["requires"] = ["spot_ammo"]
	battle.captured_secondary_objectives.clear()
	var locked_destroy_score: float = ai._secondary_destroy_target_score("axis", destroy_target)
	battle.captured_secondary_objectives["spot_ammo"] = true
	var unlocked_destroy_score: float = ai._secondary_destroy_target_score("axis", destroy_target)
	if locked_destroy_score == 0.0 and unlocked_destroy_score == AIController.SECONDARY_DESTROY_TARGET_BONUS:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: locked destroy objective should not bias target score; locked %.2f unlocked %.2f" % [
			locked_destroy_score, unlocked_destroy_score,
		])

	# 8) Recon secondary objectives should bias movement toward the recon hex.
	battle.scenario = {
		"secondary_objectives": [{
			"id": "recon_crossroad",
			"type": "recon_hex",
			"faction": "axis",
			"target": [4, 0],
			"rewards": [{"type": "xp", "amount": 1}],
		}]
	}
	battle.captured_secondary_objectives.clear()
	var recon_far: float = ai._secondary_objective_position_score("axis", Vector2i(0, 0))
	var recon_near: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	battle.captured_secondary_objectives["recon_crossroad"] = true
	var recon_completed: float = ai._secondary_objective_position_score("axis", Vector2i(4, 0))
	if recon_near > recon_far and recon_completed == 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: recon secondary objective should score near, completed should stop; near %.2f far %.2f completed %.2f" % [
			recon_near, recon_far, recon_completed,
		])
	battle.scenario = {}
	battle.captured_secondary_objectives.clear()

	# 9) A pinned unit with no profitable contact should choose Rally in place.
	var pinned_mg := make_unit("infantry", "axis", Vector2i(0, 0), 10)
	pinned_mg.suppression = 4
	var distant_enemy := make_unit("infantry", "allies", Vector2i(5, 0), 10)
	battle.units = [pinned_mg, distant_enemy]
	battle.visibility_by_faction = {"axis": {}}
	var rally_plan: Dictionary = ai.plan_for_unit(pinned_mg)
	if String(rally_plan.get("action", "")) == "rally" and rally_plan.get("move_to") == pinned_mg.coord:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: pinned unit expected rally plan got %s" % str(rally_plan))

	# 10) AI should focus an already damaged/suppressed target when raw matchups tie.
	battle.hex_map.terrain_overrides.clear()
	var focus_attacker := make_unit("infantry", "axis", Vector2i(0, 0), 10)
	var fresh_target := make_unit("infantry", "allies", Vector2i(1, 0), 10)
	var focus_target := make_unit("infantry", "allies", Vector2i(0, 1), 6)
	focus_target.suppression = 2
	var focus_choice = ai._best_attack_from(
		focus_attacker.coord, focus_attacker.faction_id, focus_attacker.type_id,
		[fresh_target, focus_target],
		ai._get_unit_def(focus_attacker.type_id),
		{fresh_target.coord: true, focus_target.coord: true}
	)
	if focus_choice == focus_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: AI should focus damaged/suppressed target")

	# 11) Artillery should prefer a light-tank-spotted target when raw damage ties.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	var spotter_artillery := make_unit("artillery", "axis", Vector2i(0, 0), 8)
	var spotter := make_unit("light_tank", "axis", Vector2i(-3, 0), 12)
	var unspotted_target := make_unit("infantry", "allies", Vector2i(3, 0), 10)
	var spotted_target := make_unit("infantry", "allies", Vector2i(0, 1), 10)
	battle.units = [spotter_artillery, spotter, unspotted_target, spotted_target]
	battle.visibility_by_faction = {
		"axis": {unspotted_target.coord: true, spotted_target.coord: true},
	}
	var spotter_choice = ai._best_attack_from(
		spotter_artillery.coord, spotter_artillery.faction_id, spotter_artillery.type_id,
		[unspotted_target, spotted_target],
		art_def,
		battle.visibility_by_faction["axis"]
	)
	if spotter_choice == spotted_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: artillery should prefer light-tank-spotted target")

	# 12) Light tanks should mark a target when a follow-up attacker can use the bonus.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var marker := make_unit("light_tank", "axis", Vector2i(0, 0), 12)
	var followup_artillery := make_unit("artillery", "axis", Vector2i(0, -1), 8)
	var mark_target := make_unit("infantry", "allies", Vector2i(3, 0), 10)
	mark_target.suppression = 1
	battle.units = [marker, followup_artillery, mark_target]
	battle.hex_map.occupants[marker.coord] = marker
	battle.hex_map.occupants[followup_artillery.coord] = followup_artillery
	battle.hex_map.occupants[mark_target.coord] = mark_target
	for river_hex in [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 1),
		Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(2, 0),
		Vector2i(2, -1), Vector2i(1, 1), Vector2i(0, 2),
		Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 0),
		Vector2i(-1, -1),
	]:
		battle.hex_map.terrain_overrides[river_hex] = "river"
	battle.visibility_by_faction = {"axis": {mark_target.coord: true}}
	var mark_plan: Dictionary = ai.plan_for_unit(marker)
	if String(mark_plan.get("action", "")) == "fire_support_mark" \
			and mark_plan.get("fire_support_target") == mark_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: light tank should mark for artillery follow-up, got %s" % str(mark_plan))

	marker.skill_cooldowns["fire_support_mark"] = 99
	var cooldown_plan: Dictionary = ai.plan_for_unit(marker)
	if String(cooldown_plan.get("action", "")) != "fire_support_mark":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: light tank should not mark while fire-support skill is on cooldown")

	marker.skill_cooldowns.clear()
	followup_artillery.has_attacked = true
	var no_followup_plan: Dictionary = ai.plan_for_unit(marker)
	if String(no_followup_plan.get("action", "")) != "fire_support_mark":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: light tank should not mark when no ready follow-up attacker can use it")

	# 13) Target selection must use the attacker's live HP, not base HP.
	# At 1/10 HP infantry deals 1 damage, so only the one-HP target is killable.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	var wounded_attacker := make_unit("infantry", "axis", Vector2i(0, 0), 1)
	var one_hp_target := make_unit("infantry", "allies", Vector2i(1, 0), 1)
	var two_hp_target := make_unit("infantry", "allies", Vector2i(0, 1), 2)
	battle.units = [wounded_attacker, one_hp_target, two_hp_target]
	battle.hex_map.occupants[wounded_attacker.coord] = wounded_attacker
	var wounded_choice = ai._best_attack_from(
		wounded_attacker.coord, wounded_attacker.faction_id, wounded_attacker.type_id,
		[two_hp_target, one_hp_target],
		ai._get_unit_def(wounded_attacker.type_id),
		{one_hp_target.coord: true, two_hp_target.coord: true},
		wounded_attacker
	)
	if wounded_choice == one_hp_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: wounded attacker should only apply kill bonus to the target killed by live-HP damage")

	# 14) Engineers should prefer breaching entrenched urban defenders over easier soft damage.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	var engineer := make_unit("engineer", "axis", Vector2i(0, 0), 8)
	var exposed_soft := make_unit("infantry", "allies", Vector2i(1, 0), 4)
	var entrenched_urban := make_unit("infantry", "allies", Vector2i(0, 1), 10)
	entrenched_urban.dig_in_level = 3
	battle.hex_map.terrain_overrides[entrenched_urban.coord] = "town"
	var engineer_choice = ai._best_attack_from(
		engineer.coord, engineer.faction_id, engineer.type_id,
		[exposed_soft, entrenched_urban],
		ENGINEER_DEF,
		{exposed_soft.coord: true, entrenched_urban.coord: true},
		engineer
	)
	if engineer_choice == entrenched_urban:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: engineer should prefer breaching entrenched urban target")

	# 15) MG teams should value overwatch more than equal-position infantry because they use full reaction damage.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	var overwatch_enemy := make_unit("infantry", "allies", Vector2i(2, 0), 10)
	var overwatch_infantry := make_unit("infantry", "axis", Vector2i(0, 0), 10)
	var overwatch_mg := make_unit("mg_team", "axis", Vector2i(0, 0), 8)
	var infantry_ow_score: float = ai._overwatch_score(
		overwatch_infantry, overwatch_infantry.coord, [overwatch_enemy],
		battle.hex_map, ai._get_unit_def("infantry"), 1
	)
	var mg_ow_score: float = ai._overwatch_score(
		overwatch_mg, overwatch_mg.coord, [overwatch_enemy],
		battle.hex_map, MG_DEF, 1
	)
	var default_mg_def := MG_DEF.duplicate(true)
	default_mg_def.erase("overwatch_damage_pct")
	var default_mg_ow_score: float = ai._overwatch_score(
		overwatch_mg, overwatch_mg.coord, [overwatch_enemy],
		battle.hex_map, default_mg_def, 1
	)
	var expected_default_mg_score: float = float(CombatEffects.overwatch_damage(4, default_mg_def)) * ai._attack_w * 0.6
	var expected_full_mg_score: float = float(CombatEffects.overwatch_damage(4, MG_DEF)) * ai._attack_w * 0.6
	if mg_ow_score > infantry_ow_score \
			and mg_ow_score > default_mg_ow_score \
			and abs(default_mg_ow_score - expected_default_mg_score) < 0.001 \
			and abs(mg_ow_score - expected_full_mg_score) < 0.001:
		pass_count += 1
	else:
		fail_count += 1
		printerr(
			"FAIL: overwatch score should follow unit reaction-fire percent, mg %.2f default %.2f infantry %.2f expected %.2f/%.2f"
			% [mg_ow_score, default_mg_ow_score, infantry_ow_score, expected_full_mg_score, expected_default_mg_score]
		)

	# 16) Engineers should approach entrenched urban defenders before they are in attack range.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	var assault_engineer := make_unit("engineer", "axis", Vector2i(0, 0), 8)
	var plain_enemy := make_unit("infantry", "allies", Vector2i(-4, 0), 10)
	var urban_enemy := make_unit("infantry", "allies", Vector2i(4, 0), 10)
	urban_enemy.dig_in_level = 3
	battle.hex_map.terrain_overrides[urban_enemy.coord] = "town"
	var engineer_known := [
		{"coord": plain_enemy.coord, "visible": true, "unit": plain_enemy},
		{"coord": urban_enemy.coord, "visible": true, "unit": urban_enemy},
	]
	var visible_assault_targets := [plain_enemy, urban_enemy]
	var toward_plain: float = ai._score_position(
		assault_engineer, Vector2i(-1, 0), engineer_known, visible_assault_targets,
		battle.hex_map, ENGINEER_DEF, {plain_enemy.coord: true, urban_enemy.coord: true}
	)
	var toward_urban: float = ai._score_position(
		assault_engineer, Vector2i(1, 0), engineer_known, visible_assault_targets,
		battle.hex_map, ENGINEER_DEF, {plain_enemy.coord: true, urban_enemy.coord: true}
	)
	if toward_urban > toward_plain:
		pass_count += 1
	else:
		fail_count += 1
		printerr(
			"FAIL: engineer should approach entrenched urban target, urban %.2f plain %.2f"
			% [toward_urban, toward_plain]
		)

	# 17) Tank destroyers should preserve authored standoff range against armor.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var td := make_unit("tank_destroyer", "axis", Vector2i(0, 0), 12)
	var armor_target := make_unit("medium_tank", "allies", Vector2i(3, 0), 16)
	var td_known := [{"coord": armor_target.coord, "visible": true, "unit": armor_target}]
	var td_visible := [armor_target]
	var adjacent_score: float = ai._score_position(
		td, Vector2i(2, 0), td_known, td_visible,
		battle.hex_map, TANK_DESTROYER_DEF, {armor_target.coord: true}
	)
	var standoff_score: float = ai._score_position(
		td, Vector2i(1, 0), td_known, td_visible,
		battle.hex_map, TANK_DESTROYER_DEF, {armor_target.coord: true}
	)
	if standoff_score > adjacent_score:
		pass_count += 1
	else:
		fail_count += 1
		printerr(
			"FAIL: tank destroyer should prefer standoff range, standoff %.2f adjacent %.2f"
			% [standoff_score, adjacent_score]
		)

	# 18) Engineers should prepare a breach when a follow-up attacker can use the extra dig-in loss.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var breach_engineer := make_unit("engineer", "axis", Vector2i(0, 0), 8)
	var breach_artillery := make_unit("artillery", "axis", Vector2i(0, -1), 8)
	var breach_target := make_unit("infantry", "allies", Vector2i(2, 0), 10)
	breach_target.dig_in_level = 3
	battle.hex_map.terrain_overrides[breach_target.coord] = "town"
	for river_hex in [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, -1),
		Vector2i(3, -1), Vector2i(3, 0), Vector2i(2, 1),
	]:
		battle.hex_map.terrain_overrides[river_hex] = "river"
	battle.units = [breach_engineer, breach_artillery, breach_target]
	battle.hex_map.occupants[breach_engineer.coord] = breach_engineer
	battle.hex_map.occupants[breach_artillery.coord] = breach_artillery
	battle.hex_map.occupants[breach_target.coord] = breach_target
	battle.visibility_by_faction = {"axis": {breach_target.coord: true}}
	var breach_plan: Dictionary = ai.plan_for_unit(breach_engineer)
	if String(breach_plan.get("action", "")) == "breach_support" \
			and breach_plan.get("breach_support_target") == breach_target:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: engineer should mark breach for artillery follow-up, got %s" % str(breach_plan))
	breach_engineer.skill_cooldowns["breach_support"] = 99
	var breach_cooldown_plan: Dictionary = ai.plan_for_unit(breach_engineer)
	if String(breach_cooldown_plan.get("action", "")) != "breach_support":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: engineer should not mark breach while skill is on cooldown")

	# 19) MG teams should use suppressive fire against visible targets just outside attack range.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var suppress_mg := make_unit("mg_team", "axis", Vector2i(0, 0), 8)
	var suppress_enemy := make_unit("infantry", "allies", Vector2i(4, 0), 10)
	suppress_enemy.suppression = 1
	battle.hex_map.terrain_overrides[suppress_enemy.coord] = "town"
	battle.units = [suppress_mg, suppress_enemy]
	battle.hex_map.occupants[suppress_mg.coord] = suppress_mg
	battle.hex_map.occupants[suppress_enemy.coord] = suppress_enemy
	battle.visibility_by_faction = {"axis": {suppress_enemy.coord: true}}
	var suppress_plan: Dictionary = ai.plan_for_unit(suppress_mg)
	if String(suppress_plan.get("action", "")) == "suppressive_fire" \
			and suppress_plan.get("suppressive_fire_target") == suppress_enemy:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: MG should use suppressive fire at range 2, got %s" % str(suppress_plan))
	suppress_mg.skill_cooldowns["suppressive_fire"] = 99
	var suppress_cooldown_plan: Dictionary = ai.plan_for_unit(suppress_mg)
	if String(suppress_cooldown_plan.get("action", "")) != "suppressive_fire":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: MG should not use suppressive fire while skill is on cooldown")

	# 20) Plan trace should explain the same selected plan without changing the decision.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var trace_attacker := make_unit("infantry", "axis", Vector2i(0, 0), 10)
	var trace_target := make_unit("infantry", "allies", Vector2i(1, 0), 10)
	battle.units = [trace_attacker, trace_target]
	battle.hex_map.occupants[trace_attacker.coord] = trace_attacker
	battle.hex_map.occupants[trace_target.coord] = trace_target
	battle.visibility_by_faction = {"axis": {trace_target.coord: true}}
	battle.scenario = {
		"victory": {"axis": {"type": "capture", "target": [4, 0]}},
		"secondary_objectives": [{
			"id": "trace_cache",
			"type": "recon_hex",
			"faction": "axis",
			"target": [2, 0],
			"rewards": [{"type": "xp", "amount": 1}],
		}]
	}
	var trace: Dictionary = ai.plan_trace_for_unit(trace_attacker)
	var traced_plan: Dictionary = trace.get("plan", {})
	var direct_plan: Dictionary = ai.plan_for_unit(trace_attacker)
	var candidates: Array = trace.get("candidates", [])
	var top: Dictionary = candidates[0] if not candidates.is_empty() else {}
	var components: Dictionary = top.get("components", {})
	var objective_detail: Dictionary = components.get("objective_detail", {})
	var primary_info: Dictionary = objective_detail.get("primary_info", {})
	var secondary_info: Dictionary = objective_detail.get("secondary_info", {})
	if traced_plan.get("move_to") == direct_plan.get("move_to") \
			and traced_plan.get("action") == direct_plan.get("action") \
			and traced_plan.get("attack") == direct_plan.get("attack") \
			and traced_plan.get("fire_support_target") == direct_plan.get("fire_support_target") \
			and traced_plan.get("breach_support_target") == direct_plan.get("breach_support_target") \
			and traced_plan.get("suppressive_fire_target") == direct_plan.get("suppressive_fire_target") \
			and not candidates.is_empty() \
			and top.has("coord") \
			and components.has("distance") \
			and components.has("attack") \
			and components.has("primary_objective") \
			and components.has("secondary_objective") \
			and components.has("total") \
			and top.has("fire_support_score") \
			and top.has("breach_support_score") \
			and top.has("suppressive_fire_score") \
			and abs(float(components.get("objective", 0.0)) - (
				float(components.get("primary_objective", 0.0))
				+ float(components.get("secondary_objective", 0.0))
			)) < 0.001 \
			and primary_info.has("target") \
			and secondary_info.get("key", "") == "trace_cache" \
			and secondary_info.has("reward_value") \
			and secondary_info.has("reward_pull") \
			and secondary_info.has("weight") \
			and abs(float(traced_plan.get("score", 0.0)) - ai._trace_sort_score(top)) < 0.001:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: plan trace should mirror direct plan and expose score components, trace=%s direct=%s" % [
			str(trace), str(direct_plan),
		])

	# 21) Hard lookahead should treat concentrated fire as worse than one attacker (anti gang-up).
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var gang_ai := AIController.new(battle, "aggressive", "hard")
	gang_ai._data_loader = ai._data_loader
	var lone_tank := make_unit("medium_tank", "axis", Vector2i(0, 0), 16)
	var gang_p1 := make_unit("infantry", "allies", Vector2i(1, 0), 10)
	var gang_p2 := make_unit("infantry", "allies", Vector2i(-1, 0), 10)
	var gang_p3 := make_unit("infantry", "allies", Vector2i(0, 1), 10)
	var lone_def: Dictionary = gang_ai._get_unit_def("medium_tank")
	var single_threat: int = gang_ai._lookahead_counter_damage(
		lone_tank, Vector2i(0, 0), [gang_p1], battle.hex_map, lone_def
	)
	var triple_threat: int = gang_ai._lookahead_counter_damage(
		lone_tank, Vector2i(0, 0), [gang_p1, gang_p2, gang_p3], battle.hex_map, lone_def
	)
	if triple_threat > single_threat:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: gang-up lookahead should exceed single attacker, single %d triple %d" % [single_threat, triple_threat])

	# 22) Preservation need is 0 for healthy units and rises (amplified by rank) for wounded ones.
	var healthy_vet := make_unit("medium_tank", "axis", Vector2i(0, 0), 16)
	healthy_vet.rank = 3
	var hurt_green := make_unit("medium_tank", "axis", Vector2i(0, 0), 3)
	hurt_green.max_hp = 16
	var hurt_vet := make_unit("medium_tank", "axis", Vector2i(0, 0), 3)
	hurt_vet.max_hp = 16
	hurt_vet.rank = 2
	if gang_ai._preservation_need(healthy_vet, lone_def) == 0.0 \
			and gang_ai._preservation_need(hurt_vet, lone_def) > gang_ai._preservation_need(hurt_green, lone_def) \
			and gang_ai._preservation_need(hurt_green, lone_def) > 0.0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: preservation need expected 0 healthy, vet>green>0 wounded; healthy %.2f green %.2f vet %.2f" % [
			gang_ai._preservation_need(healthy_vet, lone_def),
			gang_ai._preservation_need(hurt_green, lone_def),
			gang_ai._preservation_need(hurt_vet, lone_def),
		])

	# 22b) A wounded veteran on Hard with no kill available should prefer a safe hex over advancing.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var withdraw_vet := make_unit("medium_tank", "axis", Vector2i(0, 0), 3)
	withdraw_vet.max_hp = 16
	withdraw_vet.rank = 2
	var standoff_threat := make_unit("medium_tank", "allies", Vector2i(6, 0), 16)
	var withdraw_known := [{"coord": standoff_threat.coord, "visible": true, "unit": standoff_threat}]
	var withdraw_visible := [standoff_threat]
	var advance_score: float = gang_ai._score_position(
		withdraw_vet, Vector2i(4, 0), withdraw_known, withdraw_visible, battle.hex_map, lone_def, {standoff_threat.coord: true}
	)
	var safe_score: float = gang_ai._score_position(
		withdraw_vet, Vector2i(0, 0), withdraw_known, withdraw_visible, battle.hex_map, lone_def, {standoff_threat.coord: true}
	)
	# Same situation, full HP: preservation should NOT fire, so the inward pull dominates.
	var healthy_mover := make_unit("medium_tank", "axis", Vector2i(0, 0), 16)
	var healthy_advance: float = gang_ai._score_position(
		healthy_mover, Vector2i(4, 0), withdraw_known, withdraw_visible, battle.hex_map, lone_def, {standoff_threat.coord: true}
	)
	var healthy_safe: float = gang_ai._score_position(
		healthy_mover, Vector2i(0, 0), withdraw_known, withdraw_visible, battle.hex_map, lone_def, {standoff_threat.coord: true}
	)
	# Preservation should make the wounded vet favor safety much more strongly than a
	# healthy unit in the identical spot (Hard's lookahead already nudges both back).
	if safe_score > advance_score \
			and (safe_score - advance_score) > (healthy_safe - healthy_advance):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: preservation should widen the wounded vet's safety preference; wounded gap %.2f (safe %.2f adv %.2f) healthy gap %.2f (safe %.2f adv %.2f)" % [
			safe_score - advance_score, safe_score, advance_score,
			healthy_safe - healthy_advance, healthy_safe, healthy_advance,
		])

	# 23) A clean kill must override preservation — no cowardly retreat from a free kill.
	battle.units = []
	battle.visibility_by_faction = {}
	battle.hex_map.terrain_overrides.clear()
	battle.hex_map.occupants.clear()
	battle.scenario = {}
	var wounded_killer := make_unit("medium_tank", "axis", Vector2i(0, 0), 3)
	wounded_killer.max_hp = 16
	wounded_killer.rank = 2
	var killable_prey := make_unit("infantry", "allies", Vector2i(1, 0), 1)
	battle.units = [wounded_killer, killable_prey]
	battle.hex_map.occupants[wounded_killer.coord] = wounded_killer
	battle.hex_map.occupants[killable_prey.coord] = killable_prey
	battle.visibility_by_faction = {"axis": {killable_prey.coord: true}}
	var kill_plan: Dictionary = gang_ai.plan_for_unit(wounded_killer)
	if String(kill_plan.get("action", "")) == "attack" and kill_plan.get("attack") == killable_prey:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: wounded unit should still take a free kill over retreating, got %s" % str(kill_plan))

	# 24) Difficulty ladder: Easy gets deterministic jitter + no preservation; Normal/Hard don't blunder.
	var easy_ai := AIController.new(battle, "aggressive", "easy")
	easy_ai._data_loader = ai._data_loader
	var jitter_unit := make_unit("infantry", "axis", Vector2i(0, 0), 10)
	var j1: float = easy_ai._mistake_jitter(jitter_unit, Vector2i(2, 1))
	var j1_again: float = easy_ai._mistake_jitter(jitter_unit, Vector2i(2, 1))
	var j2: float = easy_ai._mistake_jitter(jitter_unit, Vector2i(40, 37))
	var normal_jitter: float = ai._mistake_jitter(jitter_unit, Vector2i(2, 1))
	if j1 == j1_again and j1 != j2 and normal_jitter == 0.0 \
			and easy_ai._preservation_w == 0.0 and easy_ai._mistake_rate > 0 \
			and ai._mistake_rate == 0 and gang_ai._preservation_w > ai._preservation_w:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: difficulty ladder expected easy jitter deterministic+varied, normal none; j1 %.3f again %.3f j2 %.3f normal %.3f" % [
			j1, j1_again, j2, normal_jitter,
		])

	print("AIController tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
