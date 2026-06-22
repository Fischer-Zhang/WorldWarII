extends Control

@onready var begin_button: Button = $VBox/BeginButton
@onready var campaign_button: Button = $VBox/CampaignButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	begin_button.pressed.connect(_on_begin_pressed)
	campaign_button.pressed.connect(_on_campaign_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	begin_button.grab_focus()

func _on_begin_pressed() -> void:
	GameState.campaign_mode = false
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_campaign_pressed() -> void:
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://scenes/campaign.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
