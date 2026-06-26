extends Control

const DIFFICULTY_HINTS := {
	"easy":   "AI 較被動,攻擊與獵殺權重低",
	"normal": "標準難度,平衡權重,無 lookahead",
	"hard":   "啟用 1 步 lookahead,AI 會評估「我走這步後玩家最強反擊」",
}

const CATEGORY_ALL := "all"
const CATEGORY_SANDBOX := "sandbox"
const CATEGORY_LABELS := {
	CATEGORY_ALL: "全部",
	"blitzkrieg_early_war": "早期",
	"eastern_front": "東線",
	"western_front": "西線",
	CATEGORY_SANDBOX: "沙盒",
}

@onready var category_row: HBoxContainer = $Margin/VBox/CategoryRow
@onready var list: VBoxContainer = $Margin/VBox/ListScroll/List
@onready var back_button: Button = $Margin/VBox/BackButton
@onready var easy_btn: Button = $Margin/VBox/DifficultyRow/EasyButton
@onready var normal_btn: Button = $Margin/VBox/DifficultyRow/NormalButton
@onready var hard_btn: Button = $Margin/VBox/DifficultyRow/HardButton
@onready var diff_hint: Label = $Margin/VBox/DifficultyRow/DifficultyHint

var active_category: String = CATEGORY_ALL
var category_scenarios: Dictionary = {}
var category_buttons: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_categories()
	_build_category_buttons()
	_rebuild_scenario_list()
	# Difficulty buttons act as a radio group
	easy_btn.pressed.connect(func(): _set_difficulty("easy"))
	normal_btn.pressed.connect(func(): _set_difficulty("normal"))
	hard_btn.pressed.connect(func(): _set_difficulty("hard"))
	_refresh_difficulty_buttons()

func _build_categories() -> void:
	category_scenarios = {
		CATEGORY_ALL: {},
		CATEGORY_SANDBOX: {"00_sandbox": true},
	}
	for campaign in DataLoader.campaigns:
		var c: Dictionary = campaign
		var campaign_id := String(c.get("id", ""))
		category_scenarios[campaign_id] = {}
		for scenario_id in c.get("scenario_order", []):
			category_scenarios[campaign_id][String(scenario_id)] = true

func _build_category_buttons() -> void:
	for child in category_row.get_children():
		child.queue_free()
	category_buttons.clear()

	var category_order: Array[String] = [CATEGORY_ALL]
	for campaign in DataLoader.campaigns:
		category_order.append(String(campaign.get("id", "")))
	category_order.append(CATEGORY_SANDBOX)

	for category_id in category_order:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(104, 34)
		btn.text = _category_label(category_id)
		btn.pressed.connect(func(): _set_category(category_id))
		category_row.add_child(btn)
		category_buttons[category_id] = btn
	_refresh_category_buttons()

func _rebuild_scenario_list() -> void:
	for child in list.get_children():
		child.queue_free()
	for s in DataLoader.scenarios:
		var scenario: Dictionary = s
		var scenario_id := String(scenario.get("id", ""))
		if not _scenario_in_active_category(scenario_id):
			continue
		var btn := Button.new()
		btn.text = "%s — %s" % [scenario.get("id", ""), scenario.get("title", "(無標題)")]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _on_scenario_picked(scenario_id))
		list.add_child(btn)

func _set_category(category_id: String) -> void:
	active_category = category_id
	_refresh_category_buttons()
	_rebuild_scenario_list()

func _refresh_category_buttons() -> void:
	for category_id in category_buttons.keys():
		var btn: Button = category_buttons[category_id]
		btn.button_pressed = category_id == active_category
		btn.disabled = category_id == active_category

func _scenario_in_active_category(scenario_id: String) -> bool:
	if active_category == CATEGORY_ALL:
		return true
	var ids: Dictionary = category_scenarios.get(active_category, {})
	return ids.has(scenario_id)

func _category_label(category_id: String) -> String:
	var label := String(CATEGORY_LABELS.get(category_id, ""))
	if label == "":
		var campaign := DataLoader.get_campaign(category_id)
		label = String(campaign.get("title", category_id))
	var count := _category_count(category_id)
	return "%s %d" % [label, count]

func _category_count(category_id: String) -> int:
	if category_id == CATEGORY_ALL:
		return DataLoader.scenarios.size()
	var ids: Dictionary = category_scenarios.get(category_id, {})
	return ids.size()

func _set_difficulty(d: String) -> void:
	GameState.difficulty = d
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	var d := GameState.difficulty
	easy_btn.button_pressed = (d == "easy")
	normal_btn.button_pressed = (d == "normal")
	hard_btn.button_pressed = (d == "hard")
	diff_hint.text = DIFFICULTY_HINTS.get(d, "")

func _on_scenario_picked(scenario_id: String) -> void:
	GameState.current_scenario_id = scenario_id
	GameState.current_campaign_id = ""
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
