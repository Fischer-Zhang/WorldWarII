extends SceneTree

# Standalone tests for AI role-shaping heuristics.
# Run with: godot --headless --script res://tests/test_ai_controller.gd

const AIController := preload("res://scripts/turn/ai_controller.gd")
const AT_DEF := {
	"hp": 6, "attack": 5, "defense": 1, "range": 1, "move": 1,
	"vision": 2, "vs_armor": 6, "armor": 0,
}
const ARTILLERY_DEF := {
	"id": "artillery", "hp": 8, "attack": 7, "defense": 1, "range": 3, "move": 2,
	"vision": 5, "vs_armor": 1, "armor": 0, "indirect": true,
}
const LIGHT_TANK_DEF := {
	"hp": 12, "attack": 5, "defense": 4, "range": 1, "move": 5,
	"vision": 5, "vs_armor": 2, "armor": 2,
}

class StubHexMap:
	var terrain_overrides: Dictionary = {}
	var occupants: Dictionary = {}
	func terrain_at(coord: Vector2i) -> String:
		return terrain_overrides.get(coord, "plain")
	func blocks_los_at(coord: Vector2i) -> bool:
		return terrain_at(coord) in ["forest", "mountain"]
	func move_cost_at(_coord: Vector2i) -> int:
		return 1

class StubBattle:
	var hex_map := StubHexMap.new()
	var visibility_by_faction: Dictionary = {}
	var units: Array = []
	var factions: Dictionary = {}
	var scenario: Dictionary = {}
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
		"medium_tank": {"hp": 16, "attack": 7, "defense": 5, "range": 1, "move": 4, "vision": 4, "vs_armor": 4, "armor": 4},
		"at_gun": AT_DEF,
		"artillery": ARTILLERY_DEF,
		"light_tank": LIGHT_TANK_DEF,
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
	func _init(_type_id: String, _faction: String, _coord: Vector2i, _hp: int) -> void:
		type_id = _type_id
		faction_id = _faction
		coord = _coord
		hp = _hp
		max_hp = _hp
	func is_alive() -> bool:
		return hp > 0

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

	# 7) A pinned unit with no profitable contact should choose Rally in place.
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

	# 8) AI should focus an already damaged/suppressed target when raw matchups tie.
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

	# 9) Artillery should prefer a light-tank-spotted target when raw damage ties.
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

	print("AIController tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
