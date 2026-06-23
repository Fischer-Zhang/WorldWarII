extends Control

@onready var campaign_button: Button = $VBox/CampaignButton
@onready var conquest_button: Button = $VBox/ConquestButton
@onready var lounge_button: Button = $VBox/LoungeButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	campaign_button.pressed.connect(_on_campaign_pressed)
	conquest_button.pressed.connect(_on_conquest_pressed)
	lounge_button.pressed.connect(_on_lounge_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	campaign_button.grab_focus()

func _on_campaign_pressed() -> void:
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://scenes/campaign.tscn")

func _on_conquest_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/conquest.tscn")

func _on_lounge_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lounge.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
