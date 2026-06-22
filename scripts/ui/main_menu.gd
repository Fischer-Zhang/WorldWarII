extends Control

@onready var begin_button: Button = $VBox/BeginButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	begin_button.pressed.connect(_on_begin_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_begin_pressed() -> void:
	print("[MainMenu] BeginButton pressed — changing to scenario_select")
	var err := get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")
	if err != OK:
		push_error("change_scene_to_file failed with code %d" % err)

func _on_quit_pressed() -> void:
	print("[MainMenu] QuitButton pressed")
	get_tree().quit()
