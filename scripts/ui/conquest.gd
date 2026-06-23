extends Control

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const ConquestManager := preload("res://scripts/scenario/conquest_manager.gd")

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var country_option: OptionButton = $Margin/VBox/Header/CountryOption
@onready var turn_label: Label = $Margin/VBox/Header/TurnLabel
@onready var map_grid: GridContainer = $Margin/VBox/Body/MapPanel/MapGrid
@onready var detail_label: RichTextLabel = $Margin/VBox/Body/DetailPanel/Detail
@onready var attack_button: Button = $Margin/VBox/Actions/AttackButton
@onready var end_turn_button: Button = $Margin/VBox/Actions/EndTurnButton
@onready var reset_button: Button = $Margin/VBox/Actions/ResetButton
@onready var back_button: Button = $Margin/VBox/Actions/BackButton

var state: Dictionary = {}
var selected_region_id := ""
var target_region_id := ""
var _refreshing_country := false

func _ready() -> void:
	state = CampaignManager.load_state()
	ConquestManager.conquest_state(state, DataLoader.conquest_map)
	_build_country_options()
	attack_button.pressed.connect(_on_attack_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	country_option.item_selected.connect(_on_country_selected)
	_rebuild()

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
	for y in range(5):
		for x in range(9):
			var region := _region_at(regions, x, y)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(116, 74)
			btn.add_theme_font_size_override("font_size", 14)
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
				btn.modulate = Color(String(owner_def.get("color", "#777777")))
				var rid := String(region.get("id", ""))
				btn.disabled = false
				btn.pressed.connect(func(): _select_region(rid))
			map_grid.add_child(btn)
	_update_detail()

func _clear_map() -> void:
	for child in map_grid.get_children():
		child.queue_free()

func _region_at(regions: Dictionary, x: int, y: int) -> Dictionary:
	for region in regions.values():
		if int(region.get("x", -1)) == x and int(region.get("y", -1)) == y:
			return region
	return {}

func _select_region(region_id: String) -> void:
	var region := ConquestManager.region_state(state, DataLoader.conquest_map, region_id)
	var player_country := String(ConquestManager.conquest_state(state, DataLoader.conquest_map).get("player_country", ""))
	if String(region.get("owner", "")) == player_country:
		selected_region_id = region_id
		target_region_id = ""
	elif selected_region_id != "":
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
	var can_attack := selected_region_id != "" \
			and target_region_id != "" \
			and ConquestManager.can_attack(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	attack_button.disabled = not can_attack or status != ""
	end_turn_button.disabled = status != ""
	detail_label.text = "\n".join(lines)

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
	var result := ConquestManager.player_attack(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	target_region_id = ""
	_rebuild()
	_update_detail(String(result.get("message", "")))

func _on_end_turn_pressed() -> void:
	var messages := ConquestManager.end_turn(state, DataLoader.conquest_map)
	target_region_id = ""
	_rebuild()
	_update_detail("\n".join(messages))

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
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
