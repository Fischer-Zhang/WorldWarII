extends Control

@onready var battle_button: Button = $VBox/BattleButton
@onready var war_button: Button = $VBox/WarButton
@onready var lounge_button: Button = $VBox/LoungeButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	battle_button.pressed.connect(_on_battle_pressed)
	war_button.pressed.connect(_on_war_pressed)
	lounge_button.pressed.connect(_on_lounge_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	battle_button.grab_focus()

func _on_battle_pressed() -> void:
	GameState.campaign_mode = false
	GameState.current_campaign_id = ""
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_war_pressed() -> void:
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://scenes/campaign.tscn")

func _on_lounge_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lounge.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
