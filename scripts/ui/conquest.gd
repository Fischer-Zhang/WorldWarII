extends Control

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const ConquestManager := preload("res://scripts/scenario/conquest_manager.gd")
const ConquestCatalog := preload("res://scripts/scenario/conquest_catalog.gd")
const ConquestRecruit := preload("res://scripts/scenario/conquest_recruit.gd")

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var country_option: OptionButton = $Margin/VBox/Header/CountryOption
@onready var turn_label: Label = $Margin/VBox/Header/TurnLabel
@onready var map_grid: GridContainer = $Margin/VBox/Body/MapPanel/MapGrid
@onready var detail_label: RichTextLabel = $Margin/VBox/Body/DetailPanel/Detail
@onready var recruit_list: VBoxContainer = $Margin/VBox/Body/DetailPanel/RecruitScroll/RecruitList
@onready var attack_button: Button = $Margin/VBox/Actions/AttackButton
@onready var transfer_button: Button = $Margin/VBox/Actions/TransferButton
@onready var end_turn_button: Button = $Margin/VBox/Actions/EndTurnButton
@onready var reset_button: Button = $Margin/VBox/Actions/ResetButton
@onready var back_button: Button = $Margin/VBox/Actions/BackButton

var state: Dictionary = {}
var selected_region_id := ""
var target_region_id := ""
var _selected_units: Dictionary = {}
var _refreshing_country := false
var _map_button_size := Vector2(116, 74)

func _ready() -> void:
	state = CampaignManager.load_state()
	ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var return_message := _apply_pending_battle_result()
	_build_country_options()
	attack_button.pressed.connect(_on_attack_pressed)
	transfer_button.pressed.connect(_on_transfer_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	country_option.item_selected.connect(_on_country_selected)
	_rebuild()
	# If we returned from a defensive battle mid-enemy-phase, resume the AI queue.
	if ConquestManager.is_enemy_phase(state, DataLoader.conquest_map):
		_advance_enemy_turn(return_message)
	elif return_message != "":
		_update_detail(return_message)

func _build_country_options() -> void:
	_refreshing_country = true
	country_option.clear()
	var countries: Dictionary = DataLoader.conquest_map.get("countries", {})
	var selected_country := String(ConquestManager.conquest_state(state, DataLoader.conquest_map).get("player_country", ""))
	var selected_index := 0
	var ids := countries.keys()
	ids.sort()
	for country_id in ids:
		var cid := String(country_id)
		if cid == "neutral":
			continue
		var def: Dictionary = countries[cid]
		country_option.add_item(String(def.get("name_zh", cid)))
		var idx := country_option.item_count - 1
		country_option.set_item_metadata(idx, cid)
		if cid == selected_country:
			selected_index = idx
	country_option.selected = selected_index
	_refreshing_country = false

func _rebuild() -> void:
	_clear_map()
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var countries: Dictionary = DataLoader.conquest_map.get("countries", {})
	var player_country := String(conquest.get("player_country", ""))
	title_label.text = "征服"
	turn_label.text = "第 %d 回合 · %s 控制 %d 區" % [
		int(conquest.get("turn", 1)),
		String(countries.get(player_country, {}).get("name_zh", player_country)),
		ConquestManager.owned_region_count(state, DataLoader.conquest_map, player_country),
	]
	var regions: Dictionary = conquest.get("regions", {})
	map_grid.columns = 9
	_update_map_button_size()
	for y in range(5):
		for x in range(9):
			var region := _region_at(regions, x, y)
			var btn := Button.new()
			btn.custom_minimum_size = _map_button_size
			btn.add_theme_font_size_override("font_size", 12 if _map_button_size.x < 100.0 else 14)
			if region.is_empty():
				btn.text = ""
				btn.disabled = true
			else:
				var owner := String(region.get("owner", ""))
				var owner_def: Dictionary = countries.get(owner, {})
				btn.text = "%s\n%s 兵:%d 產:%d" % [
					String(region.get("name_zh", "")),
					String(owner_def.get("name_zh", owner)),
					int(region.get("strength", 0)),
					int(region.get("production", 0)),
				]
				var gsize: int = (region.get("garrison", []) as Array).size()
				if gsize > 0:
					btn.text += "\n守:%d" % gsize
				btn.modulate = Color(String(owner_def.get("color", "#777777")))
				var rid := String(region.get("id", ""))
				if rid == selected_region_id:
					btn.text = "▶ " + btn.text
				elif rid == target_region_id:
					btn.text = "◎ " + btn.text
				btn.disabled = false
				btn.pressed.connect(func(): _select_region(rid))
			map_grid.add_child(btn)
	_update_detail()

func _update_map_button_size() -> void:
	var body_width: float = max(720.0, $Margin/VBox/Body.size.x)
	var detail_width: float = 330.0
	var body_sep: float = 18.0
	var grid_gap: float = 8.0
	var available_width: float = body_width - detail_width - body_sep - grid_gap * 8.0
	var cell_width: float = clamp(floor(available_width / 9.0), 72.0, 116.0)
	_map_button_size = Vector2(cell_width, clamp(floor(cell_width * 0.64), 48.0, 74.0))

func _clear_map() -> void:
	for child in map_grid.get_children():
		child.queue_free()

func _region_at(regions: Dictionary, x: int, y: int) -> Dictionary:
	for region in regions.values():
		if int(region.get("x", -1)) == x and int(region.get("y", -1)) == y:
			return region
	return {}

func _select_region(region_id: String) -> void:
	# Order-independent selection. Tap a region to set the source (出擊地);
	# tap any other region to set the target. Choosing the source does NOT
	# clear an already-picked target, so "tap the enemy, then tap my region"
	# works exactly like the reverse order. Tapping the current source again
	# clears the whole selection so you can start over.
	var player_country := String(ConquestManager.conquest_state(state, DataLoader.conquest_map).get("player_country", ""))
	var region := ConquestManager.region_state(state, DataLoader.conquest_map, region_id)
	var is_own := String(region.get("owner", "")) == player_country
	if region_id == selected_region_id:
		selected_region_id = ""
		target_region_id = ""
		_selected_units.clear()
	elif selected_region_id == "":
		# No source yet. An own region becomes the source (keeping any target
		# the player already tapped); an enemy region is remembered as target.
		if is_own:
			selected_region_id = region_id
			_selected_units.clear()
			if target_region_id == region_id:
				target_region_id = ""
		else:
			target_region_id = region_id
	else:
		target_region_id = region_id
	_update_detail()

func _update_detail(message: String = "") -> void:
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var countries: Dictionary = DataLoader.conquest_map.get("countries", {})
	var lines: Array[String] = []
	var status := ConquestManager.victory_status(state, DataLoader.conquest_map)
	if status != "":
		lines.append("[b]%s[/b]" % status)
	if message != "":
		lines.append(message)
	if selected_region_id == "":
		lines.append("選擇己方地區作為出擊點。")
	else:
		lines.append("[b]出擊點[/b]")
		lines.append(_region_detail(ConquestManager.region_state(state, DataLoader.conquest_map, selected_region_id), countries))
	if target_region_id != "":
		lines.append("")
		lines.append("[b]目標[/b]")
		lines.append(_region_detail(ConquestManager.region_state(state, DataLoader.conquest_map, target_region_id), countries))
		var scenario_id := _scenario_for_attack(selected_region_id, target_region_id)
		if scenario_id != "":
			var battle_scenario := DataLoader.get_scenario(scenario_id)
			lines.append("戰術作戰: %s" % String(battle_scenario.get("title", scenario_id)))
			var src := ConquestManager.region_state(state, DataLoader.conquest_map, selected_region_id)
			var tgt := ConquestManager.region_state(state, DataLoader.conquest_map, target_region_id)
			var my_force: int = (src.get("garrison", []) as Array).size()
			var enemy_force: int = ConquestRecruit.generate_force(int(tgt.get("strength", 0))).size()
			lines.append("我軍 %d 部隊 vs 敵軍約 %d 部隊" % [my_force, enemy_force])
			if my_force == 0:
				lines.append("[color=#d88]此地無駐軍 — 請先徵兵再出擊。[/color]")
	var can_attack := selected_region_id != "" \
			and target_region_id != "" \
			and ConquestManager.can_attack(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	var can_transfer := selected_region_id != "" \
			and target_region_id != "" \
			and ConquestManager.can_transfer(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	attack_button.disabled = not can_attack or status != ""
	transfer_button.disabled = not can_transfer or status != ""
	_refresh_transfer_button_label()
	end_turn_button.disabled = status != ""
	# Tell the player what to do next / why the action is greyed out, so a
	# disabled Attack button never looks like a dead end.
	if status == "":
		if selected_region_id != "" and target_region_id == "":
			lines.append("")
			lines.append("[color=#9bd]再點選目標:敵方相鄰地區 → 進攻,己方相鄰地區 → 調動。[/color]")
		elif selected_region_id != "" and target_region_id != "" and not can_attack and not can_transfer:
			lines.append("")
			lines.append("[color=#d88]%s[/color]" % _unavailable_reason())
	detail_label.text = "\n".join(lines)
	_rebuild_recruit_panel()

func _unavailable_reason() -> String:
	var player_country := String(ConquestManager.conquest_state(state, DataLoader.conquest_map).get("player_country", ""))
	var source := ConquestManager.region_state(state, DataLoader.conquest_map, selected_region_id)
	var target := ConquestManager.region_state(state, DataLoader.conquest_map, target_region_id)
	if String(source.get("owner", "")) != player_country:
		return "出擊地必須是己方地區。"
	if (source.get("garrison", []) as Array).is_empty():
		return "出擊地沒有駐軍,請先徵兵。"
	var neighbors: Array = source.get("neighbors", [])
	if not neighbors.has(target_region_id):
		return "目標與出擊地不相鄰。"
	if String(target.get("owner", "")) == player_country:
		return "目標為己方地區:可改用調動,或選敵區進攻。"
	return "此目標目前無法行動。"

func _rebuild_recruit_panel() -> void:
	for child in recruit_list.get_children():
		child.queue_free()
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var player_country := String(conquest.get("player_country", ""))
	if selected_region_id == "":
		_add_recruit_hint("選擇己方地區以徵召部隊。")
		return
	var region: Dictionary = conquest.get("regions", {}).get(selected_region_id, {})
	if region.is_empty() or String(region.get("owner", "")) != player_country:
		_add_recruit_hint("(僅能在己方地區徵兵)")
		return
	var header := Label.new()
	header.text = "徵兵 — %s (兵力 %d)" % [String(region.get("name_zh", "")), int(region.get("strength", 0))]
	header.add_theme_font_size_override("font_size", 15)
	recruit_list.add_child(header)
	var type_ids := DataLoader.units.keys()
	type_ids.sort()
	for tid in type_ids:
		var type_id := String(tid)
		var def: Dictionary = DataLoader.units[type_id]
		var cost := ConquestRecruit.unit_cost(DataLoader.units, type_id)
		var btn := Button.new()
		btn.text = "徵 %s (%d)" % [String(def.get("name_zh", type_id)), cost]
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not ConquestRecruit.can_recruit(region, DataLoader.units, type_id)
		btn.pressed.connect(_on_recruit_pressed.bind(type_id))
		recruit_list.add_child(btn)
	var garrison: Array = region.get("garrison", [])
	var ghdr := Label.new()
	ghdr.text = "守備軍 (%d/%d)" % [garrison.size(), ConquestRecruit.GARRISON_CAP]
	ghdr.add_theme_font_size_override("font_size", 14)
	recruit_list.add_child(ghdr)
	for rec in garrison:
		var record: Dictionary = rec
		var uid := int(record.get("id", -1))
		var rank := int(record.get("rank", 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var cb := CheckBox.new()
		cb.button_pressed = _selected_units.has(uid)
		cb.add_theme_font_size_override("font_size", 12)
		cb.toggled.connect(_on_unit_check_toggled.bind(uid))
		row.add_child(cb)
		var name_lbl := Label.new()
		name_lbl.text = "%s%s" % [String(record.get("name", "")), " ★".repeat(rank)]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)
		var dis_btn := Button.new()
		dis_btn.text = "解散"
		dis_btn.add_theme_font_size_override("font_size", 11)
		dis_btn.pressed.connect(_on_disband_pressed.bind(uid))
		row.add_child(dis_btn)
		recruit_list.add_child(row)
	if not garrison.is_empty():
		var tip := Label.new()
		tip.text = "勾選後選相鄰己方目標,按「調動」送選取(未勾=全部)"
		tip.add_theme_font_size_override("font_size", 11)
		recruit_list.add_child(tip)

func _add_recruit_hint(text: String) -> void:
	var hint := Label.new()
	hint.text = text
	hint.add_theme_font_size_override("font_size", 13)
	recruit_list.add_child(hint)

func _on_recruit_pressed(type_id: String) -> void:
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var region: Dictionary = conquest.get("regions", {}).get(selected_region_id, {})
	if region.is_empty():
		return
	var next_id := int(conquest.get("next_unit_id", 1))
	var result := ConquestRecruit.recruit(region, DataLoader.units, type_id, next_id)
	if bool(result.get("ok", false)):
		conquest["next_unit_id"] = next_id + 1
		CampaignManager.save_state(state)
		_rebuild()
	_update_detail(String(result.get("message", "")))

func _on_disband_pressed(unit_id: int) -> void:
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var region: Dictionary = conquest.get("regions", {}).get(selected_region_id, {})
	if region.is_empty():
		return
	var result := ConquestRecruit.disband(region, DataLoader.units, unit_id)
	if bool(result.get("ok", false)):
		CampaignManager.save_state(state)
		_rebuild()
	_update_detail(String(result.get("message", "")))

func _region_detail(region: Dictionary, countries: Dictionary) -> String:
	if region.is_empty():
		return "未選取"
	var owner := String(region.get("owner", ""))
	var neighbors: Array = region.get("neighbors", [])
	return "%s · %s · 兵力 %d · 產能 %d\n相鄰: %s" % [
		String(region.get("name_zh", "")),
		String(countries.get(owner, {}).get("name_zh", owner)),
		int(region.get("strength", 0)),
		int(region.get("production", 0)),
		", ".join(neighbors),
	]

func _on_attack_pressed() -> void:
	var scenario_id := _scenario_for_attack(selected_region_id, target_region_id)
	if scenario_id == "":
		_update_detail("找不到可用的戰術作戰。")
		return
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions.get(selected_region_id, {})
	var target: Dictionary = regions.get(target_region_id, {})
	var attacker_garrison: Array = (source.get("garrison", []) as Array).duplicate(true)
	if attacker_garrison.is_empty():
		_update_detail("此地區沒有駐軍可出擊,請先徵兵。")
		return
	var player_country := String(conquest.get("player_country", ""))
	var enemy_country := String(target.get("owner", ""))
	var countries: Dictionary = DataLoader.conquest_map.get("countries", {})
	var context := {
		"player_faction": player_country,
		"enemy_faction": enemy_country,
		"player_color": String(countries.get(player_country, {}).get("color", "#cccccc")),
		"enemy_color": String(countries.get(enemy_country, {}).get("color", "#cccccc")),
		"player_name": String(countries.get(player_country, {}).get("name_zh", player_country)),
		"enemy_name": String(countries.get(enemy_country, {}).get("name_zh", enemy_country)),
		"battle_location": String(target.get("name_zh", "")),
		"attacker_garrison": attacker_garrison,
		"defender_types": ConquestRecruit.generate_force(int(target.get("strength", 0))),
		"role": "attack",
	}
	CampaignManager.save_state(state)
	GameState.start_conquest_battle(selected_region_id, target_region_id, scenario_id, context)
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_unit_check_toggled(toggled_on: bool, unit_id: int) -> void:
	if toggled_on:
		_selected_units[unit_id] = true
	else:
		_selected_units.erase(unit_id)
	_refresh_transfer_button_label()

func _refresh_transfer_button_label() -> void:
	var n := _selected_units.size()
	transfer_button.text = "調動 (%d)" % n if n > 0 else "調動"

func _on_transfer_pressed() -> void:
	# Move the ticked units, or the whole garrison if none are ticked.
	var ids: Array = _selected_units.keys()
	var result := ConquestManager.transfer_units(state, DataLoader.conquest_map, selected_region_id, target_region_id, ids)
	_selected_units.clear()
	_refresh_transfer_button_label()
	target_region_id = ""
	_rebuild()
	_update_detail(String(result.get("message", "")))

func _on_end_turn_pressed() -> void:
	_advance_enemy_turn()

func _advance_enemy_turn(prefix: String = "") -> void:
	# Drives the re-entrant enemy phase: keeps processing AI actions until the
	# phase finishes, or an AI attack on one of our regions needs a defensive
	# battle (which we launch and resume from afterwards).
	var step := ConquestManager.end_turn(state, DataLoader.conquest_map)
	if String(step.get("status", "")) == "defend":
		_launch_defense_battle(step)
		return
	target_region_id = ""
	_rebuild()
	var lines: Array[String] = []
	if prefix != "":
		lines.append(prefix)
	for m in step.get("messages", []):
		lines.append(String(m))
	_update_detail("\n".join(lines))

func _launch_defense_battle(step: Dictionary) -> void:
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var regions: Dictionary = conquest.get("regions", {})
	var from_id := String(step.get("from", ""))            # enemy attacker region
	var to_id := String(step.get("to", ""))                # our region under attack
	var attacker_country := String(step.get("attacker_country", ""))
	var atk_region: Dictionary = regions.get(from_id, {})
	var def_region: Dictionary = regions.get(to_id, {})
	var player_country := String(conquest.get("player_country", ""))
	var countries: Dictionary = DataLoader.conquest_map.get("countries", {})
	# Defend with the region's garrison; if it has none, a militia turns out.
	var defenders: Array = (def_region.get("garrison", []) as Array).duplicate(true)
	if defenders.is_empty():
		for t in ConquestRecruit.generate_force(int(def_region.get("strength", 0))):
			defenders.append({"id": -1, "type": String(t), "xp": 0, "rank": 0, "name": "民兵"})
	var context := {
		"player_faction": player_country,
		"enemy_faction": attacker_country,
		"player_color": String(countries.get(player_country, {}).get("color", "#cccccc")),
		"enemy_color": String(countries.get(attacker_country, {}).get("color", "#cccccc")),
		"player_name": String(countries.get(player_country, {}).get("name_zh", player_country)),
		"enemy_name": String(countries.get(attacker_country, {}).get("name_zh", attacker_country)),
		"battle_location": String(def_region.get("name_zh", "")),
		"attacker_garrison": defenders,
		"defender_types": ConquestRecruit.generate_force(int(atk_region.get("strength", 0))),
		"role": "defend",
	}
	CampaignManager.save_state(state)
	GameState.start_conquest_battle(from_id, to_id, _scenario_for_attack(from_id, to_id), context)
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_reset_pressed() -> void:
	ConquestManager.reset_conquest(state, DataLoader.conquest_map)
	selected_region_id = ""
	target_region_id = ""
	_build_country_options()
	_rebuild()

func _on_country_selected(_index: int) -> void:
	if _refreshing_country:
		return
	ConquestManager.set_player_country(
		state,
		DataLoader.conquest_map,
		String(country_option.get_selected_metadata())
	)
	selected_region_id = ""
	target_region_id = ""
	_rebuild()

func _on_back_pressed() -> void:
	CampaignManager.save_state(state)
	GameState.clear_conquest_battle()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _scenario_for_attack(_from_id: String, to_id: String) -> String:
	if to_id == "":
		return ""
	# The battlefield is fixed per region (terrain only). Forces and the player's
	# controlled side are assigned by ConquestBattleSetup, so the scenario's
	# authored player-faction no longer matters.
	return String(ConquestCatalog.REGION_SCENARIOS.get(to_id, ConquestCatalog.FALLBACK_SCENARIO))

func _apply_pending_battle_result() -> String:
	if not GameState.conquest_mode or GameState.pending_conquest_battle.is_empty():
		return ""
	var pending := GameState.pending_conquest_battle.duplicate(true)
	var from_id := String(pending.get("from", ""))
	var to_id := String(pending.get("to", ""))
	var player_faction := String(pending.get("player_faction", ""))
	var role := String(pending.get("role", "attack"))
	var result: Dictionary = GameState.last_result
	var winner := String(result.get("winner", ""))
	var player_won := winner != "" and winner == player_faction
	var survivors: Array = result.get("conquest_survivors", [])
	GameState.clear_conquest_battle()
	GameState.last_result = {}
	target_region_id = ""
	if role == "defend":
		var attacker_country := String(pending.get("enemy_faction", ""))
		var applied_def := ConquestManager.resolve_defense_result(
			state, DataLoader.conquest_map, attacker_country, from_id, to_id, player_won, survivors
		)
		selected_region_id = to_id if player_won else ""
		return String(applied_def.get("message", ""))
	# Attack: surviving army holds the captured region on a win, retreats on loss.
	var applied := ConquestManager.resolve_battle_result(
		state, DataLoader.conquest_map, from_id, to_id, player_won, survivors
	)
	selected_region_id = to_id if player_won else from_id
	if not bool(applied.get("ok", false)):
		return String(applied.get("message", "戰役結果無法套用。"))
	return String(applied.get("message", ""))
