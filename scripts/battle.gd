extends Node2D

# Explicit preloads so we don't depend on the global class_name registry,
# which Godot 4.6 sometimes drops on re-import.
const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const HexMap := preload("res://scripts/grid/hex_map.gd")
const Unit := preload("res://scripts/units/unit.gd")
const CameraController := preload("res://scripts/ui/camera_controller.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const TurnManager := preload("res://scripts/turn/turn_manager.gd")
const VictoryChecker := preload("res://scripts/scenario/victory_checker.gd")
const AIController := preload("res://scripts/turn/ai_controller.gd")
const DamagePopup := preload("res://scripts/ui/damage_popup.gd")
const UnitFactory := preload("res://scripts/units/unit_factory.gd")

# Battle scene controller — owns the per-turn state machine.

const DEFAULT_SCENARIO_ID := "00_sandbox"

enum Phase { IDLE, UNIT_SELECTED, ATTACK_PHASE, GAME_OVER }

@onready var hex_map: HexMap = $HexMap
@onready var camera: CameraController = $Camera
@onready var info_label: Label = $UI/InfoLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var result_panel: Panel = $UI/ResultPanel
@onready var result_label: Label = $UI/ResultPanel/ResultLabel
@onready var menu_button: Button = $UI/ResultPanel/MenuButton
@onready var info_unit_name: Label = $UI/InfoPanel/VBox/UnitName
@onready var info_faction_label: Label = $UI/InfoPanel/VBox/FactionLabel
@onready var info_stats: RichTextLabel = $UI/InfoPanel/VBox/StatsLabel
@onready var info_terrain: RichTextLabel = $UI/InfoPanel/VBox/TerrainLabel
@onready var turn_banner: Label = $UI/TurnBanner

const AI_STEP_DELAY := 0.6
const MOVE_TWEEN_DURATION := 0.22

var scenario: Dictionary = {}
var factions: Dictionary = {}
var units: Array[Unit] = []
var turn_manager := TurnManager.new()

var phase: Phase = Phase.IDLE
var selected_unit: Unit = null
var movement_range: Dictionary = {}
var attack_targets: Array = []
var ai_running: bool = false

func _ready() -> void:
	var scenario_id := GameState.current_scenario_id
	if scenario_id == "":
		scenario_id = DEFAULT_SCENARIO_ID
	scenario = DataLoader.get_scenario(scenario_id)
	if scenario.is_empty():
		push_error("Scenario not found: " + scenario_id)
		return

	hex_map.load_from_scenario(scenario)
	hex_map.hex_clicked.connect(_on_hex_clicked)

	var built := UnitFactory.build(scenario, hex_map)
	factions = built["factions"]
	for u in built["units"]:
		var unit: Unit = u
		hex_map.register_unit(unit)
		units.append(unit)

	camera.position = hex_map.get_map_center()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	result_panel.visible = false
	_apply_player_objective_pulse()

	turn_manager.configure(factions)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.emit_initial()

	info_label.text = "%s — 點我方單位選取" % scenario.get("title", scenario_id)
	_update_status()

# ---------- TURN LIFECYCLE ----------

func _on_turn_started(faction_id: String, turn_number: int) -> void:
	for u in units:
		if u.faction_id == faction_id and u.is_alive():
			u.reset_for_new_turn()
	phase = Phase.IDLE
	_deselect()
	end_turn_button.text = "結束 %s 回合 (T%d)" % [factions[faction_id]["name"], turn_number]
	info_label.text = "▶ %s 的回合 (第 %d 回合)" % [factions[faction_id]["name"], turn_number]
	_show_turn_banner("%s — 第 %d 回合" % [factions[faction_id]["name"], turn_number])
	_update_status()

	var controller := String(factions[faction_id].get("controller", "player"))
	if controller == "ai":
		end_turn_button.disabled = true
		_run_ai_turn(faction_id)
	else:
		end_turn_button.disabled = false

func _run_ai_turn(faction_id: String) -> void:
	if ai_running:
		return
	ai_running = true
	var personality := String(factions[faction_id].get("ai", "aggressive"))
	var ai := AIController.new(self, personality)
	# Process units one at a time with a small delay so the player can see what's happening.
	var ai_units: Array[Unit] = []
	for u in units:
		if u.faction_id == faction_id and u.is_alive():
			ai_units.append(u)
	await _process_ai_units(ai, ai_units)
	ai_running = false
	if phase != Phase.GAME_OVER:
		_on_end_turn_pressed()

func _process_ai_units(ai: AIController, ai_units: Array[Unit]) -> void:
	for u in ai_units:
		if phase == Phase.GAME_OVER:
			return
		if not u.is_alive():
			continue
		var plan: Dictionary = ai.plan_for_unit(u)
		var dest: Vector2i = plan["move_to"]
		if dest != u.coord:
			hex_map.move_unit(u, dest, MOVE_TWEEN_DURATION)
			hex_map.highlight_coord(dest)
			info_label.text = "AI:%s → (%d, %d)" % [u.display_name, dest.x, dest.y]
			await get_tree().create_timer(AI_STEP_DELAY).timeout
		u.has_moved = true
		var target: Unit = plan.get("attack")
		if target != null and target.is_alive():
			_resolve_attack(u, target)
			await get_tree().create_timer(AI_STEP_DELAY).timeout
		else:
			u.has_attacked = true
			u.queue_redraw()

func _on_end_turn_pressed() -> void:
	if phase == Phase.GAME_OVER:
		return
	_deselect()
	var winner := VictoryChecker.evaluate(scenario, factions, units, turn_manager.turn_number)
	if winner != "":
		_handle_game_over(winner)
		return
	turn_manager.end_turn()

func _handle_game_over(winner: String) -> void:
	phase = Phase.GAME_OVER
	var winner_name := String(factions.get(winner, {}).get("name", winner))
	result_label.text = "%s 獲勝!" % winner_name
	result_panel.visible = true
	end_turn_button.disabled = true
	GameState.end_scenario(winner, {"turn": turn_manager.turn_number})

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

# ---------- INPUT / STATE MACHINE ----------

func _on_hex_clicked(coord: Vector2i, terrain_id: String) -> void:
	if phase == Phase.GAME_OVER:
		return
	var clicked_unit := hex_map.unit_at(coord)
	var current_faction := turn_manager.current_faction()

	match phase:
		Phase.IDLE:
			if clicked_unit != null and clicked_unit.faction_id == current_faction \
					and not clicked_unit.is_done_for_turn():
				_select_unit(clicked_unit)
			else:
				_show_terrain_info(coord, terrain_id, clicked_unit)
		Phase.UNIT_SELECTED:
			# Click own unit (different) → switch selection
			if clicked_unit != null and clicked_unit != selected_unit \
					and clicked_unit.faction_id == current_faction \
					and not clicked_unit.is_done_for_turn():
				_select_unit(clicked_unit)
				return
			# Click same unit → skip move, go straight to attack phase
			if clicked_unit == selected_unit:
				_enter_attack_phase()
				return
			# Click in movement range → move then attack
			if movement_range.has(coord) and clicked_unit == null:
				hex_map.move_unit(selected_unit, coord, MOVE_TWEEN_DURATION)
				_enter_attack_phase()
				return
			_deselect()
			_show_terrain_info(coord, terrain_id, clicked_unit)
		Phase.ATTACK_PHASE:
			if clicked_unit != null and clicked_unit in attack_targets:
				_resolve_attack(selected_unit, clicked_unit)
				return
			# Click anywhere else → wait (skip attack)
			selected_unit.has_attacked = true
			selected_unit.queue_redraw()
			_deselect()

func _select_unit(unit: Unit) -> void:
	if selected_unit != null and selected_unit != unit:
		selected_unit.set_selected(false)
	selected_unit = unit
	unit.set_selected(true)
	phase = Phase.UNIT_SELECTED
	_update_info_panel_for_unit(unit)
	if unit.has_moved:
		_enter_attack_phase()
		return
	var move_pts := int(DataLoader.get_unit_def(unit.type_id).get("move", 0))
	movement_range = Pathfinding.movement_range(unit.coord, move_pts, hex_map, hex_map.occupants)
	hex_map.show_movement_range(movement_range.keys())
	hex_map.highlight_coord(unit.coord)
	info_label.text = "選取:%s (HP %d/%d) — 點藍色 hex 移動,或再點自己原地待機" % [
		unit.display_name, unit.hp, unit.max_hp,
	]

func _enter_attack_phase() -> void:
	phase = Phase.ATTACK_PHASE
	hex_map.clear_movement_range()
	var atk_def := DataLoader.get_unit_def(selected_unit.type_id)
	var rng := int(atk_def.get("range", 1))
	attack_targets = CombatResolver.attack_targets_in_range(selected_unit, rng, units)
	hex_map.show_attack_targets(attack_targets.map(func(u): return u.coord))
	if attack_targets.is_empty():
		selected_unit.has_attacked = true
		info_label.text = "%s 已就位 — 周圍無敵人。回合可結束。" % selected_unit.display_name
		_deselect()
	else:
		info_label.text = "%s 可攻擊 %d 個目標 — 點目標,或點空地待機" % [
			selected_unit.display_name, attack_targets.size(),
		]

func _resolve_attack(attacker: Unit, defender: Unit) -> void:
	var distance := HexCoord.distance(attacker.coord, defender.coord)
	var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(attacker.coord))
	var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(defender.coord))
	var atk_def := DataLoader.get_unit_def(attacker.type_id)
	var def_def := DataLoader.get_unit_def(defender.type_id)
	var result := CombatResolver.resolve(
		atk_def, def_def, attacker.hp, defender.hp, atk_terr, def_terr, distance
	)

	attacker.play_attack_animation(defender.position)
	defender.take_damage(result.damage_to_defender)
	DamagePopup.spawn(hex_map, defender.position, result.damage_to_defender)
	var msg := "%s → %s 造成 %d" % [attacker.display_name, defender.display_name, result.damage_to_defender]
	if result.counter_damage > 0:
		attacker.take_damage(result.counter_damage)
		DamagePopup.spawn(hex_map, attacker.position, result.counter_damage, Color(1.0, 0.75, 0.4))
		msg += ",反擊 %d" % result.counter_damage

	if not defender.is_alive():
		hex_map.unregister_unit(defender)
		defender.play_death_animation()
		msg += " — %s 陣亡" % defender.display_name
	if not attacker.is_alive():
		hex_map.unregister_unit(attacker)
		attacker.play_death_animation()
		msg += " — %s 陣亡" % attacker.display_name
	else:
		attacker.has_attacked = true
		attacker.queue_redraw()

	# Garbage-collect dead units from our roster
	units = units.filter(func(u): return u.is_alive())

	info_label.text = msg
	_deselect()
	_update_status()

	var winner := VictoryChecker.evaluate(scenario, factions, units, turn_manager.turn_number)
	if winner != "":
		_handle_game_over(winner)

func _deselect() -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
	selected_unit = null
	movement_range.clear()
	attack_targets.clear()
	hex_map.clear_movement_range()
	if phase != Phase.GAME_OVER:
		phase = Phase.IDLE

func _show_terrain_info(coord: Vector2i, terrain_id: String, unit_here: Unit) -> void:
	var def := DataLoader.get_terrain_def(terrain_id)
	var suffix := ""
	if unit_here != null:
		suffix = "  [%s 的 %s,HP %d/%d]" % [
			factions[unit_here.faction_id]["name"], unit_here.display_name,
			unit_here.hp, unit_here.max_hp,
		]
		_update_info_panel_for_unit(unit_here)
	else:
		_update_info_panel_terrain_only(coord, terrain_id)
	info_label.text = "(%d, %d) %s — 移動消耗 %d, 防禦 %+d%s" % [
		coord.x, coord.y, String(def.get("name_zh", terrain_id)),
		int(def.get("move_cost", 0)), int(def.get("defense", 0)), suffix,
	]

func _update_info_panel_for_unit(unit: Unit) -> void:
	var u_def := DataLoader.get_unit_def(unit.type_id)
	info_unit_name.text = unit.display_name
	var faction_color: Color = factions[unit.faction_id]["color"]
	info_faction_label.add_theme_color_override("font_color", faction_color)
	info_faction_label.text = String(factions[unit.faction_id]["name"])
	var lines := [
		"[b]HP[/b]      %d / %d" % [unit.hp, unit.max_hp],
		"[b]攻擊[/b]    %d" % int(u_def.get("attack", 0)),
		"[b]防禦[/b]    %d" % int(u_def.get("defense", 0)),
		"[b]射程[/b]    %d" % int(u_def.get("range", 1)),
		"[b]移動[/b]    %d" % int(u_def.get("move", 0)),
		"[b]反裝甲[/b]  %d" % int(u_def.get("vs_armor", 0)),
		"[b]裝甲[/b]    %d" % int(u_def.get("armor", 0)),
	]
	if u_def.get("indirect", false):
		lines.append("[i]間接射擊 — 不被反擊[/i]")
	if unit.has_moved:
		lines.append("[color=#aaaaaa](本回合已行動)[/color]")
	info_stats.text = "\n".join(lines)
	_update_info_panel_terrain_only(unit.coord, hex_map.terrain_at(unit.coord))

func _update_info_panel_terrain_only(coord: Vector2i, terrain_id: String) -> void:
	if terrain_id == "":
		info_terrain.text = ""
		return
	var t_def := DataLoader.get_terrain_def(terrain_id)
	var lines := [
		"[b]位置[/b]    (%d, %d)" % [coord.x, coord.y],
		"[b]地形[/b]    %s" % String(t_def.get("name_zh", terrain_id)),
		"[b]移動消耗[/b] %d" % int(t_def.get("move_cost", 0)),
		"[b]地形防禦[/b] %+d" % int(t_def.get("defense", 0)),
	]
	if t_def.get("blocks_los", false):
		lines.append("[i]遮擋視線[/i]")
	if t_def.get("capturable", false):
		lines.append("[i]可佔領[/i]")
	info_terrain.text = "\n".join(lines)


func _update_status() -> void:
	var counts := {}
	for u in units:
		if not u.is_alive():
			continue
		counts[u.faction_id] = int(counts.get(u.faction_id, 0)) + 1
	var parts: Array[String] = []
	for fid in factions.keys():
		parts.append("%s %d" % [factions[fid]["name"], int(counts.get(fid, 0))])
	status_label.text = "  |  ".join(parts) + "    回合 %d" % turn_manager.turn_number

func _apply_player_objective_pulse() -> void:
	# Highlights the hex the *player* needs to capture, if their victory is type=capture.
	var victory_cfg: Dictionary = scenario.get("victory", {})
	for fid in factions.keys():
		if String(factions[fid].get("controller", "")) != "player":
			continue
		var v: Dictionary = victory_cfg.get(fid, {})
		if String(v.get("type", "")) != "capture":
			return
		var target = v.get("target", [0, 0])
		if typeof(target) != TYPE_ARRAY or target.size() < 2:
			return
		var col := int(target[0])
		var row := int(target[1])
		var coord := Vector2i(col - (row >> 1), row)
		hex_map.set_objective_coords([coord])
		return

func _show_turn_banner(text: String) -> void:
	turn_banner.text = text
	turn_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(turn_banner, "modulate:a", 1.0, 0.22)
	tween.tween_interval(0.7)
	tween.tween_property(turn_banner, "modulate:a", 0.0, 0.35)
