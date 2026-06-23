extends Control

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const ConquestManager := preload("res://scripts/scenario/conquest_manager.gd")

const FALLBACK_SCENARIO := "01_sedan_1940"
const REGION_SCENARIOS := {
	"north_america": "west_08_normandy_cobra_1944",
	"atlantic": "west_08_falaise_1944",
	"britain": "blitz_02_dunkirk_1940",
	"west_europe": "01_sedan_1940",
	"germany": "west_10_remagen_1945",
	"north_sea": "west_08_normandy_cobra_1944",
	"east_europe": "02_kiev_1941",
	"moscow": "blitz_03_moscow_1941",
	"siberia": "07_bagration_1944",
	"north_africa": "01_sedan_1940",
	"mediterranean": "west_11_colmar_1945",
	"middle_east": "east_05_kharkov_1943",
	"central_asia": "04_kursk_1943",
	"india": "06_market_garden_1944",
	"china": "07_bagration_1944",
	"manchuria": "east_09_seelow_1945",
	"japan_home": "east_10_berlin_1945",
	"southeast_asia": "06_market_garden_1944",
	"pacific": "06_market_garden_1944",
}
const COUNTRY_SIDE := {
	"germany": "axis",
	"soviet": "soviet",
	"britain": "allies",
	"usa": "allies",
	"china": "soviet",
	"japan": "axis",
}

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var country_option: OptionButton = $Margin/VBox/Header/CountryOption
@onready var turn_label: Label = $Margin/VBox/Header/TurnLabel
@onready var map_grid: GridContainer = $Margin/VBox/Body/MapPanel/MapGrid
@onready var detail_label: RichTextLabel = $Margin/VBox/Body/DetailPanel/Detail
@onready var attack_button: Button = $Margin/VBox/Actions/AttackButton
@onready var transfer_button: Button = $Margin/VBox/Actions/TransferButton
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
	var return_message := _apply_pending_battle_result()
	_build_country_options()
	attack_button.pressed.connect(_on_attack_pressed)
	transfer_button.pressed.connect(_on_transfer_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	country_option.item_selected.connect(_on_country_selected)
	_rebuild()
	if return_message != "":
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
		if selected_region_id == "" or selected_region_id == region_id:
			selected_region_id = region_id
			target_region_id = ""
		else:
			target_region_id = region_id
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
		var scenario_id := _scenario_for_attack(selected_region_id, target_region_id)
		if scenario_id != "":
			var battle_scenario := DataLoader.get_scenario(scenario_id)
			lines.append("戰術作戰: %s" % String(battle_scenario.get("title", scenario_id)))
	var can_attack := selected_region_id != "" \
			and target_region_id != "" \
			and ConquestManager.can_attack(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	var can_transfer := selected_region_id != "" \
			and target_region_id != "" \
			and ConquestManager.can_transfer(state, DataLoader.conquest_map, selected_region_id, target_region_id)
	attack_button.disabled = not can_attack or status != ""
	transfer_button.disabled = not can_transfer or status != ""
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
	var scenario_id := _scenario_for_attack(selected_region_id, target_region_id)
	if scenario_id == "":
		_update_detail("找不到可用的戰術作戰。")
		return
	CampaignManager.save_state(state)
	GameState.start_conquest_battle(selected_region_id, target_region_id, scenario_id)
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_transfer_pressed() -> void:
	var result := ConquestManager.transfer_strength(state, DataLoader.conquest_map, selected_region_id, target_region_id, 1)
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
	GameState.clear_conquest_battle()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _scenario_for_attack(from_id: String, to_id: String) -> String:
	if from_id == "" or to_id == "":
		return ""
	var conquest := ConquestManager.conquest_state(state, DataLoader.conquest_map)
	var source: Dictionary = conquest.get("regions", {}).get(from_id, {})
	if source.is_empty():
		return ""
	var player_country := String(conquest.get("player_country", ""))
	var side := String(COUNTRY_SIDE.get(player_country, "axis"))
	var preferred := String(REGION_SCENARIOS.get(to_id, FALLBACK_SCENARIO))
	if _scenario_player_faction(preferred) == side:
		return preferred
	for scenario in DataLoader.scenarios:
		var scenario_id := String(scenario.get("id", ""))
		if _scenario_player_faction(scenario_id) == side:
			return scenario_id
	return FALLBACK_SCENARIO

func _scenario_player_faction(scenario_id: String) -> String:
	var battle_scenario := DataLoader.get_scenario(scenario_id)
	for faction in battle_scenario.get("factions", []):
		var f: Dictionary = faction
		if String(f.get("controller", "")) == "player":
			return String(f.get("id", ""))
	return ""

func _apply_pending_battle_result() -> String:
	if not GameState.conquest_mode or GameState.pending_conquest_battle.is_empty():
		return ""
	var pending := GameState.pending_conquest_battle.duplicate(true)
	var from_id := String(pending.get("from", ""))
	var to_id := String(pending.get("to", ""))
	var scenario_id := String(pending.get("scenario_id", ""))
	var result: Dictionary = GameState.last_result
	var winner := String(result.get("winner", ""))
	var player_won := winner != "" and winner == _scenario_player_faction(scenario_id)
	var applied := ConquestManager.resolve_battle_result(
		state, DataLoader.conquest_map, from_id, to_id, player_won
	)
	GameState.clear_conquest_battle()
	target_region_id = ""
	selected_region_id = from_id
	if not bool(applied.get("ok", false)):
		GameState.last_result = {}
		return String(applied.get("message", "戰役結果無法套用。"))
	var message := String(applied.get("message", ""))
	GameState.last_result = {
		"winner": winner,
		"summary": result.get("summary", {}),
		"message": message,
	}
	return message
