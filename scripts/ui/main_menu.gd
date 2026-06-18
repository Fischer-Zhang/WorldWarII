extends Control

@onready var begin_button: Button = $VBox/BeginButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	begin_button.pressed.connect(_on_begin_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_begin_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
