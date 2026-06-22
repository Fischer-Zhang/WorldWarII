extends Control

@onready var begin_button: Button = $VBox/BeginButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	print("[MainMenu] _ready fired. begin_button=", begin_button, " quit_button=", quit_button)
	if begin_button == null:
		push_error("[MainMenu] begin_button is NULL — node path $VBox/BeginButton did not resolve")
		return
	begin_button.pressed.connect(_on_begin_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	begin_button.mouse_entered.connect(func(): print("[MainMenu] hover on BeginButton"))
	print("[MainMenu] signals connected; click 開始戰役 now")

func _on_begin_pressed() -> void:
	print("[MainMenu] BeginButton pressed — changing to scenario_select")
	var err := get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")
	if err != OK:
		push_error("change_scene_to_file failed with code %d" % err)

func _on_quit_pressed() -> void:
	print("[MainMenu] QuitButton pressed")
	get_tree().quit()
