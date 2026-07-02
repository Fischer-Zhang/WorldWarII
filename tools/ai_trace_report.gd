extends SceneTree

# Deterministic AI trace report generator.
# Run with: godot --headless --path . --script res://tools/ai_trace_report.gd

const AIController := preload("res://scripts/turn/ai_controller.gd")

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
	var fire_support_marks: Dictionary = {}
	var breach_support_marks: Dictionary = {}

	func get_known_enemies(faction_id: String) -> Array:
		var out: Array = []
		var visible: Dictionary = visibility_by_faction.get(faction_id, {})
		for u in units:
			if u.faction_id != faction_id and u.is_alive():
				out.append({"unit": u, "coord": u.coord, "visible": visible.has(u.coord)})
		return out

class StubUnit:
	var type_id: String
	var scenario_unit_id: String = ""
	var display_name: String = ""
	var faction_id: String
	var coord: Vector2i
	var hp: int
	var max_hp: int
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

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var data_loader = root.get_node_or_null("DataLoader")
	if data_loader == null:
		printerr("Could not find DataLoader autoload")
		quit(1)
		return
	var report := _generate_report(data_loader)
	var output_path := ProjectSettings.globalize_path("res://docs/progress/ai_trace_report.md")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write AI trace report: %s" % output_path)
		quit(1)
		return
	file.store_string(report)
	file.close()
	print("Wrote docs/progress/ai_trace_report.md")
	quit(0)

func _generate_report(data_loader) -> String:
	var sections: Array[String] = [
		"# AI Trace Report",
		"Deterministic diagnostic traces generated from `AIController.plan_trace_for_unit()` using focused synthetic situations. Scores are rounded for review; source decisions use the full GDScript values.",
	]
	for case_def in _case_defs(data_loader):
		sections.append(_case_report(case_def, data_loader))
	return "\n\n".join(sections) + "\n"

func _case_defs(data_loader) -> Array[Dictionary]:
	return [
		{
			"id": "scout_memory",
			"title": "Light tank scout memory",
			"difficulty": "normal",
			"attacker": _unit("light_tank", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(5, 0), data_loader), "visible": false},
			],
			"notes": "No visible enemies; the scout should move toward the last-known contact band instead of idling.",
		},
		{
			"id": "engineer_urban_breach",
			"title": "Engineer urban breach setup",
			"difficulty": "normal",
			"attacker": _unit("engineer", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(-4, 0), data_loader), "visible": true},
				{"unit": _dug_in_unit("infantry", "allies", Vector2i(4, 0), 3, data_loader), "visible": true, "terrain": "town"},
			],
			"notes": "Visible high-cover dig-in target should create breach movement pressure before contact.",
		},
		{
			"id": "engineer_breach_support",
			"title": "Engineer breach support mark",
			"difficulty": "normal",
			"attacker": _unit("engineer", "axis", Vector2i(0, 0), data_loader),
			"allies": [
				_unit("artillery", "axis", Vector2i(0, -1), data_loader),
			],
			"enemies": [
				{"unit": _dug_in_unit("infantry", "allies", Vector2i(2, 0), 3, data_loader), "visible": true, "terrain": "town"},
			],
			"terrain": {
				Vector2i(1, 0): "river",
				Vector2i(1, 1): "river",
				Vector2i(2, -1): "river",
				Vector2i(3, -1): "river",
				Vector2i(3, 0): "river",
				Vector2i(2, 1): "river",
			},
			"notes": "An engineer near an entrenched target should mark it when artillery can immediately exploit the breach.",
		},
		{
			"id": "light_tank_fire_support",
			"title": "Light tank fire-support mark",
			"difficulty": "normal",
			"attacker": _unit("light_tank", "axis", Vector2i(0, 0), data_loader),
			"allies": [
				_unit("artillery", "axis", Vector2i(0, -1), data_loader),
			],
			"enemies": [
				{"unit": _suppressed_unit("infantry", "allies", Vector2i(3, 0), 1, data_loader), "visible": true},
			],
			"terrain": {
				Vector2i(1, 0): "river",
				Vector2i(1, -1): "river",
				Vector2i(0, 1): "river",
				Vector2i(-1, 1): "river",
				Vector2i(-1, 0): "river",
				Vector2i(0, -1): "plain",
				Vector2i(2, 0): "river",
				Vector2i(2, -1): "river",
				Vector2i(1, 1): "river",
				Vector2i(0, 2): "river",
				Vector2i(-1, 2): "river",
				Vector2i(-2, 1): "river",
				Vector2i(-2, 0): "river",
				Vector2i(-1, -1): "river",
			},
			"notes": "A light tank with no clean assault lane should spend its action marking a visible target when friendly artillery can follow up.",
		},
		{
			"id": "hard_lookahead",
			"title": "Hard lookahead exposure",
			"difficulty": "hard",
			"attacker": _unit_with_hp("medium_tank", "axis", Vector2i(0, 0), 4, data_loader),
			"enemies": [
				{"unit": _unit("medium_tank", "allies", Vector2i(0, 2), data_loader), "visible": true},
			],
			"notes": "The net-exchange retaliation discount runs at all difficulties; Hard weights it most heavily.",
		},
		{
			"id": "normal_lookahead_exchange",
			"title": "Normal lookahead exchange",
			"difficulty": "normal",
			"attacker": _unit_with_hp("at_gun", "axis", Vector2i(0, 0), 4, data_loader),
			"enemies": [
				{"unit": _unit("medium_tank", "allies", Vector2i(0, 2), data_loader), "visible": true},
			],
			"notes": "A slow AT gun caught inside a tank's reach shows the retaliation discount on every candidate at Normal weight.",
		},
		{
			"id": "focus_fire_convergence",
			"title": "Focus fire convergence",
			"difficulty": "normal",
			"attacker": _unit("medium_tank", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(2, 0), data_loader), "visible": true},
				{"unit": _unit("infantry", "allies", Vector2i(-2, 0), data_loader), "visible": true},
			],
			"pre_engaged": [1],
			"notes": "Two symmetric targets; an earlier unit already engaged the second one, so the tank should converge on it instead of the tie-break default.",
		},
		{
			"id": "fire_support_followup",
			"title": "Fire support mark follow-up",
			"difficulty": "normal",
			"attacker": _unit("artillery", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(3, 0), data_loader), "visible": true},
				{"unit": _unit("infantry", "allies", Vector2i(-3, 0), data_loader), "visible": true},
			],
			"fire_support_marked": [1],
			"notes": "A spotter already marked the second target this turn; the artillery should convert the mark instead of the tie-break default.",
		},
		{
			"id": "wounded_veteran_withdraw",
			"title": "Wounded veteran withdrawal",
			"difficulty": "hard",
			"attacker": _veteran_unit("medium_tank", "axis", Vector2i(0, 0), 3, 2, data_loader),
			"enemies": [
				{"unit": _unit("medium_tank", "allies", Vector2i(4, 0), data_loader), "visible": true},
			],
			"notes": "A low-HP veteran with no kill on offer should show a positive preservation pull toward safer hexes instead of trading itself away.",
		},
		{
			"id": "rally_vs_action",
			"title": "Suppressed rally choice",
			"difficulty": "normal",
			"attacker": _suppressed_unit("infantry", "axis", Vector2i(0, 0), 4, data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(1, 0), data_loader), "visible": true},
			],
			"terrain": {
				Vector2i(0, 0): "town",
			},
			"notes": "Pinned unit in cover should show rally value competing with the attack plan.",
		},
		{
			"id": "mg_overwatch",
			"title": "MG overwatch lane",
			"difficulty": "normal",
			"attacker": _unit("mg_team", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(2, 0), data_loader), "visible": true},
			],
			"notes": "MG reaction-fire profile should appear in overwatch candidate scores.",
		},
		{
			"id": "mg_suppressive_fire",
			"title": "MG suppressive-fire choice",
			"difficulty": "normal",
			"attacker": _unit("mg_team", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _suppressed_unit("infantry", "allies", Vector2i(4, 0), 1, data_loader), "visible": true, "terrain": "town"},
			],
			"notes": "A visible target outside direct attack range but inside the MG's suppressive-fire setup should produce an active control action.",
		},
		{
			"id": "tank_destroyer_standoff",
			"title": "Tank destroyer standoff",
			"difficulty": "normal",
			"attacker": _unit("tank_destroyer", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("medium_tank", "allies", Vector2i(3, 0), data_loader), "visible": true},
			],
			"notes": "Tank destroyers should prefer the authored anti-armor standoff band over adjacent armor contact.",
		},
		{
			"id": "secondary_objective_pull",
			"title": "Secondary objective pull",
			"difficulty": "normal",
			"attacker": _unit("light_tank", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(5, 0), data_loader), "visible": false},
			],
			"scenario": {
				"victory": {"axis": {"type": "capture", "target": [6, 0]}},
				"secondary_objectives": [
					{
						"id": "forward_cache",
						"label": "Forward Cache",
						"type": "recon_hex",
						"faction": "axis",
						"target": [3, 0],
						"rewards": [{"type": "xp", "amount": 1}],
					},
					{
						"id": "forward_battery",
						"label": "Forward Battery",
						"type": "hold_turns",
						"faction": "axis",
						"target": [5, 0],
						"required_turns": 2,
						"rewards": [{"type": "suppress_enemies", "amount": 1, "radius": 2}],
						"requires": ["forward_cache"],
					},
				],
			},
			"notes": "Primary, secondary and locked follow-up objective pressure should be split so reviewers can see which target shaped the move.",
		},
		{
			"id": "objective_denial_guard",
			"title": "Objective denial guard",
			"difficulty": "normal",
			"attacker": _unit("infantry", "axis", Vector2i(0, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(6, 0), data_loader), "visible": false},
			],
			"scenario": {
				"victory": {
					"axis": {"type": "survive", "by_turn": 12},
					"allies": {
						"type": "control_count",
						"targets": [[2, 0], [4, 0], [2, 2]],
						"required": 2,
					},
				},
			},
			"notes": "Defenders should value blocking opponent control objectives even when they only have a survival objective.",
		},
		{
			"id": "victory_point_guard_hold",
			"title": "Victory point guard hold",
			"difficulty": "normal",
			"attacker": _unit("infantry", "axis", Vector2i(2, 0), data_loader),
			"enemies": [
				{"unit": _unit("infantry", "allies", Vector2i(6, 0), data_loader), "visible": true},
			],
			"scenario": {
				"victory": {
					"axis": {"type": "survive", "by_turn": 12},
					"allies": {"type": "capture", "target": [2, 0], "by_turn": 12},
				},
			},
			"notes": "A survival defender already on the attacker's victory hex should not abandon it for a distant visible lure.",
		},
	]

func _case_report(case_def: Dictionary, data_loader) -> String:
	var battle := StubBattle.new()
	var attacker = case_def["attacker"]
	battle.scenario = case_def.get("scenario", {})
	battle.units.append(attacker)
	battle.hex_map.occupants[attacker.coord] = attacker
	for coord in case_def.get("terrain", {}).keys():
		battle.hex_map.terrain_overrides[coord] = case_def["terrain"][coord]
	for ally in case_def.get("allies", []):
		battle.units.append(ally)
		battle.hex_map.occupants[ally.coord] = ally
	var visible: Dictionary = {}
	for enemy_def in case_def["enemies"]:
		var enemy = enemy_def["unit"]
		battle.units.append(enemy)
		battle.hex_map.occupants[enemy.coord] = enemy
		if bool(enemy_def.get("visible", false)):
			visible[enemy.coord] = true
		if enemy_def.has("terrain"):
			battle.hex_map.terrain_overrides[enemy.coord] = String(enemy_def["terrain"])
	battle.visibility_by_faction = {attacker.faction_id: visible}

	var ai := AIController.new(battle, "aggressive", String(case_def.get("difficulty", "normal")))
	ai._data_loader = data_loader
	for enemy_index in case_def.get("pre_engaged", []):
		var engaged = case_def["enemies"][int(enemy_index)]["unit"]
		ai.notify_plan_executed(null, {"action": "attack", "attack": engaged})
	for enemy_index in case_def.get("fire_support_marked", []):
		var marked = case_def["enemies"][int(enemy_index)]["unit"]
		battle.fire_support_marks[marked.get_instance_id()] = {"faction": attacker.faction_id}
	var trace: Dictionary = ai.plan_trace_for_unit(attacker)
	var plan: Dictionary = trace.get("plan", {})
	var candidates: Array = trace.get("candidates", [])

	var lines: Array[String] = [
		"## %s" % String(case_def["title"]),
		String(case_def.get("notes", "")),
		"",
		"Plan: `%s` to `%s`, target `%s`, score `%s`." % [
			String(plan.get("action", "wait")),
			_coord_text(plan.get("move_to", attacker.coord)),
			_unit_text(_plan_target(plan)),
			_score(plan.get("score", 0.0)),
		],
		"",
		"| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination |",
		"| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
	]
	var limit: int = min(5, candidates.size())
	for i in range(limit):
		var row: Dictionary = candidates[i]
		var c: Dictionary = row.get("components", {})
		lines.append("| %d | `%s` | `%s` | `%s` | `%s` | `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | `%s` | %s | %s | %s | %s |" % [
			i + 1,
			_coord_text(row.get("coord", Vector2i.ZERO)),
			_unit_text(row.get("target", null)),
			_unit_text(row.get("fire_support_target", null)),
			_unit_text(row.get("breach_support_target", null)),
			_unit_text(row.get("suppressive_fire_target", null)),
			_score(row.get("base_score", 0.0)),
			_score(row.get("overwatch_score", 0.0)),
			_score(row.get("fire_support_score", 0.0)),
			_score(row.get("breach_support_score", 0.0)),
			_score(row.get("suppressive_fire_score", 0.0)),
			_score(row.get("rally_score", 0.0)),
			_score(c.get("distance", 0.0)),
			_score(c.get("attack", 0.0)),
			_score(c.get("exposure", 0.0)),
			_score(c.get("terrain", 0.0)),
			_score(c.get("role", 0.0)),
			_score(c.get("primary_objective", 0.0)),
			_score(c.get("secondary_objective", 0.0)),
			_score(c.get("denial_objective", 0.0)),
			_score(c.get("guard_objective", 0.0)),
			_score(c.get("objective", 0.0)),
			_objective_detail_text(c.get("objective_detail", {})),
			_score(c.get("lookahead", 0.0)),
			_score(c.get("preservation", 0.0)),
			_score(c.get("encirclement", 0.0)),
			_score(c.get("coordination", 0.0)),
		])
	return "\n".join(lines)

func _unit(type_id: String, faction: String, coord: Vector2i, data_loader) -> StubUnit:
	var unit_def: Dictionary = data_loader.get_unit_def(type_id)
	return StubUnit.new(type_id, faction, coord, int(unit_def.get("hp", 1)))

func _unit_with_hp(type_id: String, faction: String, coord: Vector2i, hp: int, data_loader) -> StubUnit:
	var unit := _unit(type_id, faction, coord, data_loader)
	unit.hp = hp
	return unit

func _veteran_unit(type_id: String, faction: String, coord: Vector2i, hp: int, rank: int, data_loader) -> StubUnit:
	var unit := _unit(type_id, faction, coord, data_loader)
	unit.hp = hp
	unit.rank = rank
	return unit

func _dug_in_unit(type_id: String, faction: String, coord: Vector2i, dig_in: int, data_loader) -> StubUnit:
	var unit := _unit(type_id, faction, coord, data_loader)
	unit.dig_in_level = dig_in
	return unit

func _suppressed_unit(type_id: String, faction: String, coord: Vector2i, suppression: int, data_loader) -> StubUnit:
	var unit := _unit(type_id, faction, coord, data_loader)
	unit.suppression = suppression
	return unit

func _coord_text(value: Variant) -> String:
	if value is Vector2i:
		return "%d,%d" % [value.x, value.y]
	return "n/a"

func _unit_text(value: Variant) -> String:
	if value == null:
		return "none"
	return "%s@%s" % [String(value.type_id), _coord_text(value.coord)]

func _plan_target(plan: Dictionary):
	if String(plan.get("action", "")) == "fire_support_mark":
		return plan.get("fire_support_target", null)
	if String(plan.get("action", "")) == "breach_support":
		return plan.get("breach_support_target", null)
	if String(plan.get("action", "")) == "suppressive_fire":
		return plan.get("suppressive_fire_target", null)
	return plan.get("attack", null)

func _score(value: Variant) -> String:
	var score := float(value)
	if score <= -INF / 2.0:
		return "-inf"
	return "%.2f" % score

func _objective_detail_text(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "none"
	var detail: Dictionary = value
	var parts: Array[String] = []
	var primary: Dictionary = detail.get("primary_info", {})
	if primary.has("target"):
		parts.append("primary:%s d%d" % [
			_coord_text(primary.get("target", Vector2i.ZERO)),
			int(primary.get("distance", 0)),
		])
	var secondary: Dictionary = detail.get("secondary_info", {})
	if secondary.has("key"):
		parts.append("secondary:%s %s d%d w%.2f rv%.2f rp%.2f fv%.2f fp%.2f" % [
			String(secondary.get("key", "secondary")),
			_coord_text(secondary.get("target", Vector2i.ZERO)),
			int(secondary.get("distance", 0)),
			float(secondary.get("weight", 0.0)),
			float(secondary.get("reward_value", 0.0)),
			float(secondary.get("reward_pull", 0.0)),
			float(secondary.get("future_value", 0.0)),
			float(secondary.get("future_pull", 0.0)),
		])
	var denial: Dictionary = detail.get("denial_info", {})
	if denial.has("target"):
		parts.append("denial:%s %s d%d w%.2f" % [
			String(denial.get("type", "objective")),
			_coord_text(denial.get("target", Vector2i.ZERO)),
			int(denial.get("distance", 0)),
			float(denial.get("weight", 0.0)),
		])
	var guard: Dictionary = detail.get("guard_info", {})
	if guard.has("target"):
		parts.append("guard:%s %s d%d w%.2f" % [
			String(guard.get("type", "guard")),
			_coord_text(guard.get("target", Vector2i.ZERO)),
			int(guard.get("distance", 0)),
			float(guard.get("weight", 0.0)),
		])
	if parts.is_empty():
		return "none"
	return "; ".join(parts)
