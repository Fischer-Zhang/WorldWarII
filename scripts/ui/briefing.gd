extends Control

@onready var title_label: Label = $Margin/VBox/Title
@onready var briefing_label: RichTextLabel = $Margin/VBox/BriefingScroll/Briefing
@onready var begin_button: Button = $Margin/VBox/Buttons/BeginButton
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton

func _ready() -> void:
	var scenario := DataLoader.get_scenario(GameState.current_scenario_id)
	if scenario.is_empty():
		title_label.text = "(找不到戰役)"
		briefing_label.text = "Scenario id 無效:" + GameState.current_scenario_id
	else:
		title_label.text = String(scenario.get("title", scenario.get("id", "")))
		briefing_label.text = String(scenario.get("briefing", "(無簡報)"))
	begin_button.pressed.connect(_on_begin_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_begin_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/deployment.tscn")

func _on_back_pressed() -> void:
	if GameState.campaign_mode:
		get_tree().change_scene_to_file("res://scenes/campaign.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")
