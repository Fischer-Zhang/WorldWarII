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
	# Force keyboard focus so Tab/Enter work even if mouse routing is broken.
	begin_button.grab_focus()
	print("[MainMenu] signals connected. begin_button.global_rect=", begin_button.get_global_rect())
	# Window focus probe: WSL2/WSLg sometimes deliver no input until the
	# game window is explicitly clicked on its title bar.
	var win := get_window()
	win.focus_entered.connect(func(): print("[Window] focus_entered (window now receives input)"))
	win.focus_exited.connect(func(): print("[Window] focus_exited (window will NOT receive input)"))
	print("[Window] has_focus=", win.has_focus())

func _input(event: InputEvent) -> void:
	# Global low-level probe: confirms the window is receiving ANY input at all.
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		print("[MainMenu._input] mouse-down at ", mb.position, " button=", mb.button_index)
	elif event is InputEventKey and (event as InputEventKey).pressed:
		var ke := event as InputEventKey
		print("[MainMenu._input] key-down ", ke.as_text())

func _on_begin_pressed() -> void:
	print("[MainMenu] BeginButton pressed — changing to scenario_select")
	var err := get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")
	if err != OK:
		push_error("change_scene_to_file failed with code %d" % err)

func _on_quit_pressed() -> void:
	print("[MainMenu] QuitButton pressed")
	get_tree().quit()
