extends Control

@onready var list: VBoxContainer = $Margin/VBox/List
@onready var back_button: Button = $Margin/VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	for s in DataLoader.scenarios:
		var scenario: Dictionary = s
		var btn := Button.new()
		btn.text = "%s — %s" % [scenario.get("id", ""), scenario.get("title", "(無標題)")]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 18)
		var scenario_id := String(scenario.get("id", ""))
		btn.pressed.connect(func(): _on_scenario_picked(scenario_id))
		list.add_child(btn)

func _on_scenario_picked(scenario_id: String) -> void:
	GameState.current_scenario_id = scenario_id
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
