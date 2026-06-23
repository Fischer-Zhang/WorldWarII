extends Control

const DIFFICULTY_HINTS := {
	"easy":   "AI 較被動,攻擊與獵殺權重低",
	"normal": "標準難度,平衡權重,無 lookahead",
	"hard":   "啟用 1 步 lookahead,AI 會評估「我走這步後玩家最強反擊」",
}

@onready var list: VBoxContainer = $Margin/VBox/ListScroll/List
@onready var back_button: Button = $Margin/VBox/BackButton
@onready var easy_btn: Button = $Margin/VBox/DifficultyRow/EasyButton
@onready var normal_btn: Button = $Margin/VBox/DifficultyRow/NormalButton
@onready var hard_btn: Button = $Margin/VBox/DifficultyRow/HardButton
@onready var diff_hint: Label = $Margin/VBox/DifficultyRow/DifficultyHint

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	# Build the scenario list
	for s in DataLoader.scenarios:
		var scenario: Dictionary = s
		var btn := Button.new()
		btn.text = "%s — %s" % [scenario.get("id", ""), scenario.get("title", "(無標題)")]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 18)
		var scenario_id := String(scenario.get("id", ""))
		btn.pressed.connect(func(): _on_scenario_picked(scenario_id))
		list.add_child(btn)
	# Difficulty buttons act as a radio group
	easy_btn.pressed.connect(func(): _set_difficulty("easy"))
	normal_btn.pressed.connect(func(): _set_difficulty("normal"))
	hard_btn.pressed.connect(func(): _set_difficulty("hard"))
	_refresh_difficulty_buttons()

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
