extends Node2D

# Explicit preloads so we don't depend on the global class_name registry,
# which Godot 4.6 sometimes drops on re-import.
const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const HexMap := preload("res://scripts/grid/hex_map.gd")
const Unit := preload("res://scripts/units/unit.gd")
const CameraController := preload("res://scripts/ui/camera_controller.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const Visibility := preload("res://scripts/grid/visibility.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const CombatRules := preload("res://scripts/combat/combat_rules.gd")
const CombatModifiers := preload("res://scripts/combat/combat_modifiers.gd")
const CombatEffects := preload("res://scripts/combat/combat_effects.gd")
const DamagePreview := preload("res://scripts/ui/damage_preview.gd")
const UnitDetailFormatter := preload("res://scripts/ui/unit_detail_formatter.gd")
const TurnManager := preload("res://scripts/turn/turn_manager.gd")
const VictoryChecker := preload("res://scripts/scenario/victory_checker.gd")
const ReinforcementSpawner := preload("res://scripts/scenario/reinforcement_spawner.gd")
const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const LoungeManager := preload("res://scripts/scenario/lounge_manager.gd")
const DeploymentOverrides := preload("res://scripts/scenario/deployment_overrides.gd")
const ConquestBattleContext := preload("res://scripts/scenario/conquest_battle_context.gd")
const ActionLog := preload("res://scripts/scenario/action_log.gd")
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
@onready var overwatch_button: Button = $UI/OverwatchButton
@onready var rally_button: Button = $UI/RallyButton
@onready var skill_button: Button = $UI/SkillButton
@onready var result_panel: Panel = $UI/ResultPanel
@onready var result_label: Label = $UI/ResultPanel/ResultLabel
@onready var result_summary: RichTextLabel = $UI/ResultPanel/ResultSummary
@onready var menu_button: Button = $UI/ResultPanel/MenuButton
@onready var lounge_button: Button = $UI/ResultPanel/LoungeButton
@onready var next_button: Button = $UI/ResultPanel/NextButton
@onready var info_unit_name: Label = $UI/InfoPanel/VBox/UnitName
@onready var info_faction_label: Label = $UI/InfoPanel/VBox/FactionLabel
@onready var info_stats: RichTextLabel = $UI/InfoPanel/VBox/StatsLabel
@onready var info_terrain: RichTextLabel = $UI/InfoPanel/VBox/TerrainLabel
@onready var turn_banner: Label = $UI/TurnBanner
@onready var damage_preview_panel: Panel = $UI/DamagePreviewPanel
@onready var damage_preview_content: RichTextLabel = $UI/DamagePreviewPanel/Content

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
var spawned_reinforcements: Dictionary = {}  # reinforcement index -> true
var player_faction_id: String = ""
# Per-faction visibility + memory (symmetric fog model)
var visibility_by_faction: Dictionary = {}   # faction_id -> Dictionary[Vector2i, true]
var last_known_positions: Dictionary = {}    # faction_id -> Dictionary[Unit, Vector2i]
var action_log: ActionLog = ActionLog.new()
var next_campaign_scenario_id: String = ""
var campaign_reward_points: int = 0

func _ready() -> void:
	var scenario_id := GameState.current_scenario_id
	if scenario_id == "":
		scenario_id = DEFAULT_SCENARIO_ID
	scenario = DataLoader.get_scenario(scenario_id)
	if scenario.is_empty():
		push_error("Scenario not found: " + scenario_id)
		return
	scenario = scenario.duplicate(true)
	action_log.scenario_id = scenario_id

	hex_map.load_from_scenario(scenario)
	hex_map.hex_clicked.connect(_on_hex_clicked)
	hex_map.hex_hovered.connect(_on_hex_hovered)

	var built := UnitFactory.build(scenario, hex_map)
	factions = built["factions"]
	for u in built["units"]:
		var unit: Unit = u
		if hex_map.register_unit(unit):
			units.append(unit)
		else:
			push_warning("Skipping stacked scenario unit: %s at %s" % [unit.display_name, unit.coord])

	# Campaign mode: restore each unit's xp/rank/general from the saved roster
	# (matched by display_name within faction). New units stay fresh.
	if GameState.campaign_mode:
		var camp_state := CampaignManager.load_state()
		var campaign := DataLoader.get_campaign(GameState.current_campaign_id)
		var scenario_order: Array = campaign.get("scenario_order", [])
		CampaignManager.apply_roster_to_units(camp_state, GameState.current_campaign_id, scenario_order, units)

	LoungeManager.apply_upgrades_to_units(units, factions, DataLoader.tech_tree)

	_apply_deployment_overrides(scenario_id)

	# Identify the player's faction once; visibility & objective pulse use it.
	for fid in factions.keys():
		if String(factions[fid].get("controller", "")) == "player":
			player_faction_id = fid
			break
	ConquestBattleContext.apply_to_scenario(
		scenario,
		player_faction_id,
		GameState.pending_conquest_battle if GameState.conquest_mode else {}
	)
	_apply_conquest_battle_modifiers()

	# Seed initial enemy memory: every faction starts with intel on
	# where their opponents are deployed (briefing-table knowledge).
	# Memory becomes stale as units move out of view.
	for fid in factions.keys():
		last_known_positions[fid] = {}
		for u in units:
			var unit: Unit = u
			if unit.faction_id != fid:
				last_known_positions[fid][unit] = unit.coord

	camera.position = hex_map.get_map_center()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	lounge_button.pressed.connect(_on_lounge_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	overwatch_button.pressed.connect(_on_overwatch_pressed)
	rally_button.pressed.connect(_on_rally_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	result_panel.visible = false
	_apply_player_objective_pulse()
	_recompute_visibility()

	turn_manager.configure(factions)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.emit_initial()

	info_label.text = "%s — 點我方單位選取" % scenario.get("title", scenario_id)
	_update_status()

func _apply_deployment_overrides(scenario_id: String) -> void:
	var overrides := GameState.get_deployment_overrides(scenario_id)
	if overrides.is_empty():
		return
	DeploymentOverrides.apply(units, hex_map, overrides, HexMap.HEX_SIZE)
	GameState.clear_deployment_overrides()

func _apply_conquest_battle_modifiers() -> void:
	if not GameState.conquest_mode or GameState.pending_conquest_battle.is_empty():
		return
	var pending: Dictionary = GameState.pending_conquest_battle
	var attacker_strength := int(pending.get("attacker_strength", 0))
	var defender_strength := int(pending.get("defender_strength", 0))
	var attacker_power := attacker_strength + int(pending.get("attacker_production", 0))
	var defender_power := defender_strength + int(pending.get("defender_production", 0))
	var attacker_rank := _conquest_attacker_rank(attacker_power)
	var defender_dig_in := _conquest_defender_dig_in(defender_power)
	if attacker_rank <= 0 and defender_dig_in <= 0:
		return

	var attacker_vanguard := 1 if attacker_power < 12 else 2
	var ranked := 0
	for u in units:
		var unit: Unit = u
		if unit.faction_id == player_faction_id and unit.is_alive() and attacker_rank > 0:
			unit.xp = max(unit.xp, int(CombatModifiers.RANK_THRESHOLDS[attacker_rank]))
			unit.rank = max(unit.rank, attacker_rank)
			unit.queue_redraw()
			ranked += 1
			if ranked >= attacker_vanguard:
				break

	if defender_dig_in <= 0:
		return
	for u in units:
		var unit: Unit = u
		if unit.faction_id != player_faction_id and unit.is_alive():
			unit.dig_in_level = max(unit.dig_in_level, defender_dig_in)
			unit.queue_redraw()

func _conquest_attacker_rank(strength: int) -> int:
	if strength >= 12:
		return 2
	if strength >= 8:
		return 1
	return 0

func _conquest_defender_dig_in(strength: int) -> int:
	if strength >= 12:
		return 2
	if strength >= 8:
		return 1
	return 0

# ---------- TURN LIFECYCLE ----------

func _on_turn_started(faction_id: String, turn_number: int) -> void:
	action_log.record_turn_change(faction_id, turn_number)
	for u in units:
		if u.faction_id == faction_id and u.is_alive():
			u.reset_for_new_turn()
			# Drop expired active effects (general's skill buffs).
			u.tick_active_effects(turn_number)
	phase = Phase.IDLE
	_deselect()
	end_turn_button.text = "結束 %s 回合 (T%d)" % [factions[faction_id]["name"], turn_number]
	info_label.text = "▶ %s 的回合 (第 %d 回合)" % [factions[faction_id]["name"], turn_number]
	_show_turn_banner("%s — 第 %d 回合" % [factions[faction_id]["name"], turn_number])
	# Spawn after the standard turn UI so the reinforcement message overrides
	# the "X's turn" text and the player notices it immediately.
	_spawn_reinforcements_for_turn(faction_id, turn_number)
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
	var ai := AIController.new(self, personality, GameState.difficulty)
	ai._data_loader = DataLoader
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
			var reachable: Dictionary = plan.get("reachable", {})
			var path := Pathfinding.reconstruct_path(
				u.coord, dest, reachable, hex_map, hex_map.occupants, u.faction_id
			)
			var survived := _move_with_overwatch(u, path)
			hex_map.highlight_coord(dest)
			info_label.text = "AI:%s → (%d, %d)" % [u.display_name, dest.x, dest.y]
			await get_tree().create_timer(AI_STEP_DELAY).timeout
			if not survived:
				continue
		u.has_moved = true
		var action := String(plan.get("action", "attack"))
		match action:
			"attack":
				var target: Unit = plan.get("attack")
				# Target may have died between planning and execution — a prior
				# AI unit on this turn could have killed it. Re-check liveness.
				if target != null and target.is_alive() and _can_attack_target(u, target):
					_resolve_attack(u, target)
					await get_tree().create_timer(AI_STEP_DELAY).timeout
				else:
					u.has_attacked = true
					u.queue_redraw()
			"overwatch":
				u.on_overwatch = true
				u.has_attacked = true
				u.queue_redraw()
				info_label.text = "AI:%s 進入警戒" % u.display_name
				await get_tree().create_timer(AI_STEP_DELAY * 0.5).timeout
			"rally":
				var recovered := _rally_unit(u)
				info_label.text = "AI:%s 整隊,壓制 -%d" % [u.display_name, recovered]
				await get_tree().create_timer(AI_STEP_DELAY * 0.5).timeout
			_:  # "wait" or anything else
				u.has_attacked = true
				u.queue_redraw()

func _on_end_turn_pressed() -> void:
	if phase == Phase.GAME_OVER:
		return
	_deselect()
	AudioBank.play("end_turn")
	_update_dig_in_for_current_faction()
	var winner := VictoryChecker.evaluate(scenario, factions, units, turn_manager.turn_number)
	if winner != "":
		_handle_game_over(winner)
		return
	turn_manager.end_turn()

func _update_dig_in_for_current_faction() -> void:
	# Units that ended turn without moving, attacking or going on overwatch
	# entrench themselves: +1 defense, stacking up to MAX_DIG_IN.
	var current := turn_manager.current_faction()
	for u in units:
		var unit: Unit = u
		if not unit.is_alive() or unit.faction_id != current:
			continue
		if CombatEffects.is_pinned(unit.suppression):
			unit.dig_in_level = 0
			unit.queue_redraw()
			continue
		if unit.has_moved or unit.has_attacked or unit.on_overwatch:
			unit.dig_in_level = 0
		else:
			unit.dig_in_level = min(Unit.MAX_DIG_IN, unit.dig_in_level + 1)
		unit.queue_redraw()

func _handle_game_over(winner: String) -> void:
	phase = Phase.GAME_OVER
	# Tear down any in-flight interaction state so late tween callbacks
	# and stray clicks during the result panel don't dereference units.
	_deselect()
	if overwatch_button != null:
		overwatch_button.visible = false
	if rally_button != null:
		rally_button.visible = false
	var winner_name := String(factions.get(winner, {}).get("name", winner))
	result_label.text = "%s 獲勝!" % winner_name
	result_panel.visible = true
	lounge_button.visible = false
	next_button.visible = false
	next_campaign_scenario_id = ""
	campaign_reward_points = 0
	end_turn_button.disabled = true
	# Play victory/defeat from the player's perspective
	var player_won := false
	for fid in factions.keys():
		if String(factions[fid].get("controller", "")) == "player" and fid == winner:
			player_won = true
			break
	AudioBank.play("victory" if player_won else "defeat")
	GameState.end_scenario(winner, {"turn": turn_manager.turn_number})
	# Persist the battle's action log to disk + populate the result panel
	# with a per-unit summary aggregated from the recorded events.
	action_log.record_game_over(winner, turn_manager.turn_number)
	action_log.save_to_disk()
	_populate_battle_summary()
	# Campaign progression: only advance + persist roster on player victory.
	# A defeat still saves the survivor snapshot so the player can re-play
	# the same scenario without losing previously accumulated experience.
	if GameState.campaign_mode:
		var camp_state := CampaignManager.load_state()
		var campaign := DataLoader.get_campaign(GameState.current_campaign_id)
		var scenario_order: Array = campaign.get("scenario_order", [])
		var scenario_id := String(scenario.get("id", ""))
		var survivors: Array = units.filter(func(u): return u.is_alive())
		var progress_before := int(CampaignManager.campaign_state(
			camp_state, GameState.current_campaign_id, scenario_order
		).get("progress", 0))
		if player_won:
			CampaignManager.complete_scenario(
				camp_state, GameState.current_campaign_id, scenario_order, scenario_id, survivors
			)
			var progress_after := int(CampaignManager.campaign_state(
				camp_state, GameState.current_campaign_id, scenario_order
			).get("progress", 0))
			campaign_reward_points = 2 if progress_after > progress_before else 0
			next_campaign_scenario_id = CampaignManager.current_scenario_id(
				camp_state, GameState.current_campaign_id, scenario_order
			)
		else:
			# Defeat: snapshot survivors but don't advance progress.
			CampaignManager.complete_scenario(
				camp_state, GameState.current_campaign_id, scenario_order, "__no_advance__", survivors
			)
		# Steer the Back button to the campaign scene rather than scenario_select.
		menu_button.text = "返回戰役地圖"
		lounge_button.visible = true
		next_button.visible = player_won and next_campaign_scenario_id != ""
		_populate_battle_summary()
	elif GameState.conquest_mode:
		menu_button.text = "返回征服地圖"

func _populate_battle_summary() -> void:
	# Build a compact battle-log card for the result panel:
	#   - 1 line: total events / turns
	#   - up to 8 top performers by damage dealt with kills + overwatch hits
	#   - log file path on disk
	var rows: Array = action_log.summary_by_unit()
	if rows.is_empty():
		var empty_lines: Array[String] = []
		if campaign_reward_points > 0:
			empty_lines.append("[color=#ffd84a]戰役獎勵: 資源點 +%d。可前往休息室升級。[/color]" % campaign_reward_points)
		empty_lines.append("[i]無戰鬥行動紀錄[/i]")
		result_summary.text = "\n".join(empty_lines)
		return
	var lines: Array[String] = []
	lines.append("[b]戰場日誌(前 %d 名)[/b]" % min(8, rows.size()))
	if campaign_reward_points > 0:
		lines.append("[color=#ffd84a]戰役獎勵: 資源點 +%d。可前往休息室升級。[/color]" % campaign_reward_points)
	lines.append("")
	# Per-unit rows
	var shown := 0
	for r in rows:
		if shown >= 8:
			break
		var row: Dictionary = r
		var color := "#ffd84a" if int(row.damage_dealt) > 0 else "#888888"
		var parts: Array[String] = []
		if int(row.attacks) > 0:
			parts.append("攻 %d×" % int(row.attacks))
		if int(row.damage_dealt) > 0:
			parts.append("傷 %d" % int(row.damage_dealt))
		if int(row.damage_taken) > 0:
			parts.append("受 %d" % int(row.damage_taken))
		if int(row.kills) > 0:
			parts.append("殺 %d" % int(row.kills))
		if int(row.overwatch_hits) > 0:
			parts.append("警戒 %d" % int(row.overwatch_hits))
		if int(row.skills_used) > 0:
			parts.append("技能 %d" % int(row.skills_used))
		lines.append("[color=%s]%s[/color] · %s" % [
			color,
			String(row.unit),
			"  ".join(parts) if not parts.is_empty() else "未行動",
		])
		shown += 1
	lines.append("")
	lines.append("[color=#888888]完整紀錄已存於 user://last_replay.json[/color]")
	result_summary.text = "\n".join(lines)

func _on_menu_button_pressed() -> void:
	if GameState.campaign_mode:
		get_tree().change_scene_to_file("res://scenes/campaign.tscn")
	elif GameState.conquest_mode:
		get_tree().change_scene_to_file("res://scenes/conquest.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_lounge_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lounge.tscn")

func _on_next_button_pressed() -> void:
	if next_campaign_scenario_id == "":
		return
	GameState.current_scenario_id = next_campaign_scenario_id
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

# ---------- INPUT / STATE MACHINE ----------

func _on_hex_hovered(coord: Vector2i, _terrain_id: String) -> void:
	# Damage preview only fires when we're in attack phase with a selected
	# unit and the hovered hex contains an enemy in attack_targets.
	if phase != Phase.ATTACK_PHASE or selected_unit == null:
		damage_preview_panel.visible = false
		return
	var hovered_unit := hex_map.unit_at(coord)
	if hovered_unit == null or hovered_unit.faction_id == selected_unit.faction_id:
		damage_preview_panel.visible = false
		return
	# Only preview valid targets (in attack_targets list)
	if not (hovered_unit in attack_targets):
		damage_preview_panel.visible = false
		return
	_show_damage_preview(selected_unit, hovered_unit)

func _show_damage_preview(attacker: Unit, defender: Unit) -> void:
	var atk_def := DataLoader.get_unit_def(attacker.type_id)
	var def_def := DataLoader.get_unit_def(defender.type_id)
	var atk_general := DataLoader.get_general_def(attacker.general_id)
	var def_general := DataLoader.get_general_def(defender.general_id)
	var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(attacker.coord))
	var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(defender.coord))
	var visible: Dictionary = visibility_by_faction.get(attacker.faction_id, {})
	var preview: Dictionary = DamagePreview.preview(
		attacker, defender, atk_def, def_def,
		atk_general, def_general, atk_terr, def_terr,
		visible, hex_map,
	)
	if not preview.legal:
		damage_preview_content.text = "[color=#ff8080]無法攻擊:%s[/color]" % preview.reason
		damage_preview_panel.visible = true
		return

	# Build a compact preview card
	var lines: Array[String] = []
	lines.append("[b]%s → %s[/b]" % [attacker.display_name, defender.display_name])
	var dmg_color := "#9aff7a" if preview.defender_dies else "#ffd84a"
	var dmg_tag := "  [color=#ff7a7a](致命)[/color]" if preview.defender_dies else ""
	lines.append("造成 [color=%s][b]%d[/b][/color] 傷害%s" % [dmg_color, preview.dmg, dmg_tag])
	# Remaining HP after damage
	var def_hp_after: int = max(0, defender.hp - int(preview.dmg))
	lines.append("敵 HP %d → [color=#cccccc]%d[/color] / %d" % [defender.hp, def_hp_after, defender.max_hp])
	if int(preview.counter) > 0:
		var ctr_tag: String = "  [color=#ff7a7a](致命)[/color]" if preview.attacker_dies else ""
		lines.append("反擊 [color=#ff9a4a]%d[/color]%s" % [int(preview.counter), ctr_tag])
		var atk_hp_after: int = max(0, attacker.hp - int(preview.counter))
		lines.append("我 HP %d → [color=#cccccc]%d[/color] / %d" % [attacker.hp, atk_hp_after, attacker.max_hp])
	else:
		lines.append("[color=#9aff7a]無反擊[/color]")
	# Modifier breakdown (only shown if non-zero)
	var atk_mods: Dictionary = preview.mods.atk
	var def_mods: Dictionary = preview.mods.def
	var mod_bits: Array[String] = []
	if int(atk_mods.get("attack", 0)) != 0:
		mod_bits.append("我攻 %+d" % int(atk_mods.attack))
	if int(def_mods.get("defense", 0)) != 0:
		mod_bits.append("敵防 %+d" % int(def_mods.defense))
	if int(atk_mods.get("vs_armor", 0)) != 0:
		mod_bits.append("反裝甲 %+d" % int(atk_mods.vs_armor))
	if defender.dig_in_level > 0:
		mod_bits.append("構工 +%d" % defender.dig_in_level)
	if not mod_bits.is_empty():
		lines.append("[color=#88aaff]修正: %s[/color]" % " · ".join(mod_bits))
	damage_preview_content.text = "\n".join(lines)
	damage_preview_panel.visible = true

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
				var path := Pathfinding.reconstruct_path(
					selected_unit.coord, coord, movement_range, hex_map,
					hex_map.occupants, selected_unit.faction_id
				)
				var survived := _move_with_overwatch(selected_unit, path)
				if not survived:
					_deselect()
					_update_status()
					return
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
	AudioBank.play("select")
	_update_info_panel_for_unit(unit)
	if unit.has_moved:
		_enter_attack_phase()
		return
	var unit_def: Dictionary = DataLoader.get_unit_def(unit.type_id)
	var general_def: Dictionary = DataLoader.get_general_def(unit.general_id)
	var move_pts: int = unit.effective_move(unit_def, general_def)
	movement_range = Pathfinding.movement_range(
		unit.coord, move_pts, hex_map, hex_map.occupants, unit.faction_id
	)
	hex_map.show_movement_range(movement_range.keys())
	hex_map.show_threat_range(_enemy_threat_hexes(unit.faction_id))
	hex_map.highlight_coord(unit.coord)
	info_label.text = "選取:%s (HP %d/%d) — 點藍色 hex 移動,或再點自己原地待機" % [
		unit.display_name, unit.hp, unit.max_hp,
	]

func _enter_attack_phase() -> void:
	phase = Phase.ATTACK_PHASE
	hex_map.clear_movement_range()
	var atk_def := DataLoader.get_unit_def(selected_unit.type_id)
	attack_targets = _visible_attack_targets(selected_unit, atk_def)
	hex_map.show_attack_targets(attack_targets.map(func(u): return u.coord))
	# Overwatch button: enabled whenever a unit has finished its move and
	# is making the attack-or-skip decision.
	overwatch_button.visible = not CombatEffects.is_pinned(selected_unit.suppression)
	rally_button.visible = selected_unit.suppression > 0
	# Skill button: only if attached general has a skill and cooldown is ready.
	_refresh_skill_button(selected_unit)
	if attack_targets.is_empty():
		if CombatEffects.is_pinned(selected_unit.suppression):
			info_label.text = "%s 被壓制 — 可整隊,或點空地待機" % selected_unit.display_name
		else:
			var idle_text := "點「警戒」進入警戒,或結束回合待機"
			if selected_unit.suppression > 0:
				idle_text = "點「整隊」恢復壓制,點「警戒」,或待機"
			info_label.text = "%s 已就位 — %s" % [selected_unit.display_name, idle_text]
	else:
		var preview := _attack_preview(selected_unit, attack_targets[0])
		var action_text := "點目標 / 點「警戒」/ 點空地待機"
		if CombatEffects.is_pinned(selected_unit.suppression):
			action_text = "點目標 / 點「整隊」/ 點空地待機"
		elif selected_unit.suppression > 0:
			action_text = "點目標 / 點「警戒」/ 點「整隊」/ 點空地待機"
		info_label.text = "%s 可攻擊 %d 個目標 — %s。首目標預覽:%s" % [
			selected_unit.display_name, attack_targets.size(), action_text, preview,
		]

func _resolve_active_skill(unit: Unit) -> Dictionary:
	# Returns the active skill available to this unit, preferring the unit's
	# own kit (engineer's Fortify) over the attached general's skill.
	if unit == null:
		return {}
	var unit_def := DataLoader.get_unit_def(unit.type_id)
	var unit_skill: Dictionary = unit_def.get("skill", {})
	if not unit_skill.is_empty():
		return unit_skill
	if unit.general_id != "":
		return DataLoader.get_general_def(unit.general_id).get("skill", {})
	return {}

func _refresh_skill_button(unit: Unit) -> void:
	var skill: Dictionary = _resolve_active_skill(unit)
	if skill.is_empty():
		skill_button.visible = false
		return
	var skill_id := String(skill.get("id", ""))
	var ready: bool = unit.skill_ready(skill_id, turn_manager.turn_number)
	if ready:
		skill_button.text = "技能: %s" % String(skill.get("name_zh", skill_id))
		skill_button.disabled = false
		skill_button.tooltip_text = String(skill.get("description_zh", ""))
		skill_button.visible = true
	else:
		var cd_left: int = int(unit.skill_cooldowns.get(skill_id, 0)) - turn_manager.turn_number
		skill_button.text = "技能 (CD %d)" % max(0, cd_left)
		skill_button.disabled = true
		skill_button.visible = true

func _on_skill_pressed() -> void:
	if phase != Phase.ATTACK_PHASE or selected_unit == null:
		return
	var skill: Dictionary = _resolve_active_skill(selected_unit)
	if skill.is_empty():
		return
	var skill_id := String(skill.get("id", ""))
	if not selected_unit.skill_ready(skill_id, turn_manager.turn_number):
		return
	# Special instant effects (e.g. engineer's Fortify) are applied
	# immediately, in addition to recording the active_effect entry so the
	# cooldown is tracked uniformly.
	var instant_dig: int = int(skill.get("instant_dig_in", 0))
	if instant_dig > 0:
		selected_unit.dig_in_level = min(Unit.MAX_DIG_IN, selected_unit.dig_in_level + instant_dig)
	# Apply self_mods / no_counter via the normal active-effect path.
	selected_unit.use_skill(skill, turn_manager.turn_number)
	action_log.record_skill(selected_unit, skill_id, turn_manager.turn_number)
	# Aura propagation to adjacent same-faction units.
	var aura: Dictionary = skill.get("aura_mods", {})
	if not aura.is_empty():
		if not selected_unit.active_effects.is_empty():
			selected_unit.active_effects[-1]["source_of_aura"] = true
		var duration: int = int(skill.get("duration", 1))
		var aura_effect := {
			"skill_id": skill_id,
			"expires_at_turn": turn_manager.turn_number + duration,
			"self_mods": {},
			"aura_mods": aura,
			"no_counter": false,
		}
		for nb in HexCoord.neighbors(selected_unit.coord):
			var u := hex_map.unit_at(nb)
			if u != null and u.is_alive() and u.faction_id == selected_unit.faction_id:
				u.receive_aura(aura_effect)
	info_label.text = "★ %s 發動「%s」" % [
		selected_unit.display_name,
		String(skill.get("name_zh", skill_id)),
	]
	AudioBank.play("select")
	skill_button.visible = false
	selected_unit.has_attacked = true
	selected_unit.queue_redraw()
	_deselect()
	_update_status()

func _on_overwatch_pressed() -> void:
	if phase != Phase.ATTACK_PHASE or selected_unit == null:
		return
	if CombatEffects.is_pinned(selected_unit.suppression):
		info_label.text = "%s 被壓制,無法進入警戒" % selected_unit.display_name
		overwatch_button.visible = false
		return
	selected_unit.on_overwatch = true
	selected_unit.has_attacked = true
	selected_unit.queue_redraw()
	info_label.text = "%s 進入警戒 — 進入射程的敵人會被自動射擊" % selected_unit.display_name
	overwatch_button.visible = false
	_deselect()

func _on_rally_pressed() -> void:
	if phase != Phase.ATTACK_PHASE or selected_unit == null:
		return
	if selected_unit.suppression <= 0:
		rally_button.visible = false
		return
	var unit := selected_unit
	var recovered := _rally_unit(unit)
	info_label.text = "%s 整隊 — 壓制 -%d" % [unit.display_name, recovered]
	_deselect()

func _rally_unit(unit: Unit) -> int:
	var terrain_def := DataLoader.get_terrain_def(hex_map.terrain_at(unit.coord))
	var recovered := unit.rally(terrain_def)
	unit.dig_in_level = 0
	unit.queue_redraw()
	return recovered

func _resolve_attack(attacker: Unit, defender: Unit) -> void:
	var distance := HexCoord.distance(attacker.coord, defender.coord)
	var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(attacker.coord))
	var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(defender.coord))
	var atk_def := DataLoader.get_unit_def(attacker.type_id)
	var def_def := DataLoader.get_unit_def(defender.type_id)
	var atk_general := DataLoader.get_general_def(attacker.general_id)
	var def_general := DataLoader.get_general_def(defender.general_id)
	var atk_mods: Dictionary = CombatModifiers.for_unit(attacker, atk_general)
	var def_mods: Dictionary = CombatModifiers.for_unit(defender, def_general)
	atk_mods.attack -= CombatEffects.attack_penalty(attacker.suppression)
	var suppress_counter: bool = attacker.has_no_counter_active()
	var result := CombatResolver.resolve(
		atk_def, def_def, attacker.hp, defender.hp,
		atk_terr, def_terr, distance, defender.dig_in_level,
		atk_mods, def_mods, suppress_counter,
	)
	var spotter_bonus := _spotter_suppression_bonus(
		attacker, defender, atk_def, result.damage_to_defender, result.defender_dies
	)
	result.suppression_to_defender += spotter_bonus

	attacker.play_attack_animation(defender.position)
	AudioBank.play("attack")
	defender.take_damage(result.damage_to_defender)
	defender.add_suppression(result.suppression_to_defender)
	defender.reduce_dig_in(result.defender_dig_in_loss)
	DamagePopup.spawn(hex_map, defender.position, result.damage_to_defender)
	var msg := "%s → %s 造成 %d" % [attacker.display_name, defender.display_name, result.damage_to_defender]
	if result.suppression_to_defender > 0:
		msg += ",壓制 +%d" % result.suppression_to_defender
	if spotter_bonus > 0:
		msg += ",偵察校射 +%d" % spotter_bonus
	if result.defender_dig_in_loss > 0:
		msg += ",構工 -%d" % result.defender_dig_in_loss
	if result.counter_damage > 0:
		attacker.take_damage(result.counter_damage)
		DamagePopup.spawn(hex_map, attacker.position, result.counter_damage, Color(1.0, 0.75, 0.4))
		msg += ",反擊 %d" % result.counter_damage

	# Veteran XP: kill = +3, damage-without-kill = +1 per damage dealt.
	# Defender also earns XP for surviving + landing counter damage.
	if attacker.is_alive():
		if result.defender_dies:
			attacker.gain_xp(3)
		elif result.damage_to_defender > 0:
			attacker.gain_xp(1)
	if defender.is_alive() and result.counter_damage > 0:
		if not attacker.is_alive():
			defender.gain_xp(3)
		else:
			defender.gain_xp(1)

	if not defender.is_alive():
		hex_map.unregister_unit(defender)
		hex_map.place_wreckage(defender.coord, defender.faction_color)
		defender.play_death_animation()
		AudioBank.play("death")
		msg += " — %s 陣亡" % defender.display_name
	if not attacker.is_alive():
		hex_map.unregister_unit(attacker)
		hex_map.place_wreckage(attacker.coord, attacker.faction_color)
		attacker.play_death_animation()
		AudioBank.play("death")
		msg += " — %s 陣亡" % attacker.display_name
	else:
		attacker.has_attacked = true
		attacker.queue_redraw()

	# Garbage-collect dead units from our roster
	units = units.filter(func(u): return u.is_alive())

	action_log.record_attack(
		attacker, defender,
		result.damage_to_defender, result.counter_damage,
		result.defender_dies, result.attacker_dies,
		turn_manager.turn_number,
	)
	_recompute_visibility()
	info_label.text = msg
	_deselect()
	_update_status()

	var winner := VictoryChecker.evaluate(scenario, factions, units, turn_manager.turn_number)
	if winner != "":
		_handle_game_over(winner)

func _visible_attack_targets(attacker: Unit, atk_def: Dictionary) -> Array:
	var visible: Dictionary = visibility_by_faction.get(attacker.faction_id, {})
	return CombatRules.targets_for_attacker(attacker, atk_def, units, hex_map, visible)

func _can_attack_target(attacker: Unit, target: Unit) -> bool:
	var atk_def := DataLoader.get_unit_def(attacker.type_id)
	var visible: Dictionary = visibility_by_faction.get(attacker.faction_id, {})
	return CombatRules.can_attack_target(attacker, target, atk_def, hex_map, visible)

func _attack_preview(attacker: Unit, defender: Unit) -> String:
	var distance := HexCoord.distance(attacker.coord, defender.coord)
	var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(attacker.coord))
	var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(defender.coord))
	var atk_def := DataLoader.get_unit_def(attacker.type_id)
	var def_def := DataLoader.get_unit_def(defender.type_id)
	var atk_general := DataLoader.get_general_def(attacker.general_id)
	var def_general := DataLoader.get_general_def(defender.general_id)
	var atk_mods: Dictionary = CombatModifiers.for_unit(attacker, atk_general)
	var def_mods: Dictionary = CombatModifiers.for_unit(defender, def_general)
	atk_mods.attack -= CombatEffects.attack_penalty(attacker.suppression)
	var suppress_counter: bool = attacker.has_no_counter_active()
	var result := CombatResolver.resolve(
		atk_def, def_def, attacker.hp, defender.hp,
		atk_terr, def_terr, distance, defender.dig_in_level,
		atk_mods, def_mods, suppress_counter,
	)
	var spotter_bonus := _spotter_suppression_bonus(
		attacker, defender, atk_def, result.damage_to_defender, result.defender_dies
	)
	var total_suppression := result.suppression_to_defender + spotter_bonus
	var parts: Array[String] = ["傷害 %d" % result.damage_to_defender]
	if result.counter_damage > 0:
		parts.append("反擊 %d" % result.counter_damage)
	if total_suppression > 0:
		parts.append("壓制 +%d" % total_suppression)
	if spotter_bonus > 0:
		parts.append("偵察校射 +%d壓制" % spotter_bonus)
	if result.defender_dig_in_loss > 0:
		parts.append("構工 -%d" % result.defender_dig_in_loss)
	var future_suppression := CombatEffects.apply_suppression(defender.suppression, total_suppression)
	if future_suppression != defender.suppression:
		parts.append("目標壓制 %d→%d" % [defender.suppression, future_suppression])
		if CombatEffects.is_pinned(future_suppression):
			parts.append("釘住")
	return " / ".join(parts)

func _spotter_suppression_bonus(
	attacker: Unit, defender: Unit, atk_def: Dictionary, damage: int, defender_dies: bool
) -> int:
	return CombatEffects.spotter_suppression_bonus(
		atk_def,
		_has_light_tank_spotter(attacker.faction_id, defender.coord),
		damage,
		defender_dies,
	)

func _has_light_tank_spotter(faction_id: String, target_coord: Vector2i) -> bool:
	var visible: Dictionary = visibility_by_faction.get(faction_id, {})
	if not visible.has(target_coord):
		return false
	for u in units:
		var spotter: Unit = u
		if not spotter.is_alive() or spotter.faction_id != faction_id:
			continue
		if spotter.type_id != "light_tank":
			continue
		var spotter_def := DataLoader.get_unit_def(spotter.type_id)
		var spotter_general := DataLoader.get_general_def(spotter.general_id)
		var vision := spotter.effective_vision(spotter_def, spotter_general)
		if HexCoord.distance(spotter.coord, target_coord) <= vision \
				and Visibility.has_los(spotter.coord, target_coord, hex_map):
			return true
	return false

func _deselect() -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
	selected_unit = null
	movement_range.clear()
	attack_targets.clear()
	hex_map.clear_movement_range()
	hex_map.clear_threat_range()
	overwatch_button.visible = false
	rally_button.visible = false
	if skill_button != null:
		skill_button.visible = false
	if damage_preview_panel != null:
		damage_preview_panel.visible = false
	if phase != Phase.GAME_OVER:
		phase = Phase.IDLE

func _enemy_threat_hexes(faction_id: String) -> Array:
	var out: Dictionary = {}
	var viewer_visible: Dictionary = visibility_by_faction.get(faction_id, {})
	for u in units:
		var enemy: Unit = u
		if not enemy.is_alive() or enemy.faction_id == faction_id:
			continue
		if not viewer_visible.has(enemy.coord):
			continue
		var enemy_def := DataLoader.get_unit_def(enemy.type_id)
		var enemy_general := DataLoader.get_general_def(enemy.general_id)
		var enemy_range := int(enemy_def.get("range", 1))
		var enemy_move := enemy.effective_move(enemy_def, enemy_general)
		for c in hex_map.tiles.keys():
			var coord: Vector2i = c
			if HexCoord.distance(enemy.coord, coord) <= enemy_move + enemy_range:
				out[coord] = true
	return out.keys()

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
	var general_def := DataLoader.get_general_def(unit.general_id)
	info_unit_name.text = unit.display_name
	var faction_color: Color = factions[unit.faction_id]["color"]
	info_faction_label.add_theme_color_override("font_color", faction_color)
	info_faction_label.text = String(factions[unit.faction_id]["name"])
	var lines := [
		"[b]HP[/b]  %d / %d" % [unit.hp, unit.max_hp],
		"[b]基礎[/b]  攻%d 防%d 反%d" % [
			int(u_def.get("attack", 0)),
			int(u_def.get("defense", 0)),
			int(u_def.get("vs_armor", 0)),
		],
		"[b]機動[/b]  射程%d 移%d 視%d 裝%d" % [
			int(u_def.get("range", 1)),
			int(u_def.get("move", 0)),
			int(u_def.get("vision", 3)),
			int(u_def.get("armor", 0)),
		],
	]
	lines.append_array(UnitDetailFormatter.battle_upgrade_lines(unit, u_def, general_def))
	if u_def.get("indirect", false):
		lines.append("[i]間接射擊 — 可越過視線阻擋,但不能反擊[/i]")
	# General attached to this unit
	if not general_def.is_empty():
		var q := String(general_def.get("quality", "bronze"))
		var q_color: String = {"gold": "#ffd84a", "silver": "#d8d8e0", "bronze": "#cc8a4a"}.get(q, "#ffffff")
		lines.append("[color=%s]★ %s「%s」[/color]" % [
			q_color,
			String(general_def.get("name_zh", unit.general_id)),
			String(general_def.get("title_zh", "")),
		])
	# Veteran rank + XP progress
	if unit.rank > 0 or unit.xp > 0:
		var stars := "★".repeat(unit.rank) + "☆".repeat(CombatModifiers.MAX_RANK - unit.rank)
		var next := CombatModifiers.xp_for_next_rank(unit.rank)
		if next < 0:
			lines.append("[color=#ffd84a]老兵 %s (XP %d - max)[/color]" % [stars, unit.xp])
		else:
			lines.append("[color=#ffd84a]老兵 %s (XP %d/%d)[/color]" % [stars, unit.xp, next])
	if unit.on_overwatch:
		lines.append("[color=#ff8a6a]⌖ 警戒中[/color]")
	if unit.dig_in_level > 0:
		lines.append("[color=#d6a060]⛤ 構工 +%d 防禦[/color]" % unit.dig_in_level)
	if unit.suppression > 0:
		var effect_text := _suppression_effect_text(unit.suppression)
		var terrain_def := DataLoader.get_terrain_def(hex_map.terrain_at(unit.coord))
		var after_rally := CombatEffects.rally_suppression(unit.suppression, terrain_def)
		lines.append("[color=#79aaff]壓制 %d: %s; 整隊後 %d[/color]" % [
			unit.suppression, effect_text, after_rally,
		])
	if unit.has_moved:
		lines.append("[color=#aaaaaa](本回合已行動)[/color]")
	info_stats.text = "\n".join(lines)
	_update_info_panel_terrain_only(unit.coord, hex_map.terrain_at(unit.coord))

func _suppression_effect_text(value: int) -> String:
	var parts: Array[String] = []
	if CombatEffects.is_pinned(value):
		parts.append("無法警戒/構工")
	if CombatEffects.move_penalty(value) > 0:
		parts.append("移動 -%d" % CombatEffects.move_penalty(value))
	if CombatEffects.attack_penalty(value) > 0:
		parts.append("攻擊 -%d" % CombatEffects.attack_penalty(value))
	if parts.is_empty():
		return "輕度"
	return ", ".join(parts)

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

func _trigger_overwatch_along_path(mover: Unit, path: Array) -> int:
	# As `mover` passes through each hex along `path`, every watcher that
	# sees the hex and has it in attack range snap-shots the mover. Each
	# watcher fires at most once (on_overwatch consumed). Returns the
	# path index at which the mover died, or -1 if it survived.
	for i in range(1, path.size()):
		if not mover.is_alive():
			return i - 1
		var step: Vector2i = path[i]
		var step_world := HexCoord.to_pixel(step, HexMap.HEX_SIZE)
		for u in units:
			var watcher: Unit = u
			if not watcher.is_alive() or not watcher.on_overwatch:
				continue
			if watcher.faction_id == mover.faction_id:
				continue
			var w_vis: Dictionary = visibility_by_faction.get(watcher.faction_id, {})
			if not w_vis.has(step):
				continue
			var w_def := DataLoader.get_unit_def(watcher.type_id)
			var w_rng := int(w_def.get("range", 1))
			if HexCoord.distance(watcher.coord, step) > w_rng:
				continue
			var dmg: int = _compute_overwatch_damage(watcher, mover, step)
			watcher.play_attack_animation(step_world)
			AudioBank.play("attack")
			mover.take_damage(dmg)
			var w_def_for_effect := DataLoader.get_unit_def(watcher.type_id)
			var suppression := CombatEffects.suppression_for_attack(w_def_for_effect, dmg, not mover.is_alive())
			mover.add_suppression(suppression)
			DamagePopup.spawn(hex_map, step_world, dmg, Color(1.0, 0.85, 0.4))
			action_log.record_overwatch(watcher, mover, dmg, turn_manager.turn_number)
			watcher.on_overwatch = false
			watcher.queue_redraw()
			info_label.text = "⌖ %s 警戒射擊 %s @(%d,%d) → -%d" % [
				watcher.display_name, mover.display_name, step.x, step.y, dmg,
			]
			if not mover.is_alive():
				return i
	return -1

func _compute_overwatch_damage(watcher: Unit, target: Unit, target_step: Vector2i) -> int:
	var w_def := DataLoader.get_unit_def(watcher.type_id)
	var t_def := DataLoader.get_unit_def(target.type_id)
	var w_terr := DataLoader.get_terrain_def(hex_map.terrain_at(watcher.coord))
	var t_terr := DataLoader.get_terrain_def(hex_map.terrain_at(target_step))
	var d := HexCoord.distance(watcher.coord, target_step)
	var w_general := DataLoader.get_general_def(watcher.general_id)
	var t_general := DataLoader.get_general_def(target.general_id)
	var w_mods: Dictionary = CombatModifiers.for_unit(watcher, w_general)
	var t_mods: Dictionary = CombatModifiers.for_unit(target, t_general)
	w_mods.attack -= CombatEffects.attack_penalty(watcher.suppression)
	var result := CombatResolver.resolve(
		w_def, t_def, watcher.hp, target.hp,
		w_terr, t_terr, d, target.dig_in_level,
		w_mods, t_mods,
	)
	return int(ceil(float(result.damage_to_defender) / 2.0))

func _move_with_overwatch(mover: Unit, path: Array) -> bool:
	# Resolves overwatch along the path; truncates the move if the mover
	# dies en route; performs the actual hex_map move + death effects.
	# Returns true if the mover survived to its destination.
	if path.size() < 2:
		return mover.is_alive()
	var death_idx := _trigger_overwatch_along_path(mover, path)
	var effective_path: Array = path if death_idx < 0 else path.slice(0, death_idx + 1)
	hex_map.move_unit_along_path(mover, effective_path)
	AudioBank.play("move")
	if death_idx >= 0:
		# Defensive bounds: _trigger_overwatch_along_path may return an index
		# past the last hex if the watcher loop drifts. Clamp to the truncated path.
		var safe_idx: int = clampi(death_idx, 0, effective_path.size() - 1)
		var death_coord: Vector2i = effective_path[safe_idx]
		hex_map.unregister_unit(mover)
		hex_map.place_wreckage(death_coord, mover.faction_color)
		mover.play_death_animation()
		AudioBank.play("death")
		units = units.filter(func(u): return u.is_alive())
	_recompute_visibility()
	return death_idx < 0

func _show_turn_banner(text: String) -> void:
	turn_banner.text = text
	turn_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(turn_banner, "modulate:a", 1.0, 0.22)
	tween.tween_interval(0.7)
	tween.tween_property(turn_banner, "modulate:a", 0.0, 0.35)

func _recompute_visibility() -> void:
	# Symmetric fog: compute visibility for every faction. Player's set
	# drives the rendered fog overlay; AI factions consume their set
	# (plus stale memory) via `get_known_enemies`.
	for fid in factions.keys():
		visibility_by_faction[fid] = Visibility.compute_visible_hexes(units, fid, hex_map, DataLoader.units)
	# Update each faction's last-known-position memory:
	#   - Drop entries for dead units.
	#   - Refresh entry for any currently-visible enemy.
	#   - Keep stale entries untouched (the "memory" of where they were).
	for viewer_fid in factions.keys():
		var viewer_vis: Dictionary = visibility_by_faction[viewer_fid]
		var memory: Dictionary = last_known_positions.get(viewer_fid, {})
		var stale_keys: Array = []
		for key in memory.keys():
			if not (key as Unit).is_alive():
				stale_keys.append(key)
		for k in stale_keys:
			memory.erase(k)
		for u in units:
			var unit: Unit = u
			if not unit.is_alive() or unit.faction_id == viewer_fid:
				continue
			if viewer_vis.has(unit.coord):
				memory[unit] = unit.coord
	# Render only the player's fog overlay.
	if player_faction_id != "":
		hex_map.apply_visibility(visibility_by_faction[player_faction_id], player_faction_id)

func get_known_enemies(faction_id: String) -> Array:
	# Returns Array of {unit: Unit, coord: Vector2i, visible: bool}.
	# `coord` is the unit's CURRENT coord if visible, otherwise the
	# last-known coord from memory.
	var out: Array = []
	var visible: Dictionary = visibility_by_faction.get(faction_id, {})
	var memory: Dictionary = last_known_positions.get(faction_id, {})
	for u in units:
		var unit: Unit = u
		if not unit.is_alive() or unit.faction_id == faction_id:
			continue
		if visible.has(unit.coord):
			out.append({"unit": unit, "coord": unit.coord, "visible": true})
		elif memory.has(unit):
			out.append({"unit": unit, "coord": memory[unit], "visible": false})
	return out

func _spawn_reinforcements_for_turn(faction_id: String, turn_number: int) -> void:
	# Spawns any reinforcements scheduled for `turn_number` belonging to
	# `faction_id`. Already-spawned entries are skipped.
	var fresh: Array = ReinforcementSpawner.spawn_for_turn(
		scenario, factions, hex_map, units, spawned_reinforcements, faction_id, turn_number
	)
	if fresh.is_empty():
		return
	var names := []
	for u in fresh:
		names.append(u.display_name)
	info_label.text = "★ 援軍抵達:%s" % ", ".join(names)
	AudioBank.play("victory")  # fanfare borrow — replace with a dedicated SFX later if added
	_recompute_visibility()
