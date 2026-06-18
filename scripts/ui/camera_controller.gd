class_name CameraController
extends Camera2D

# WASD / arrow-key pan, mouse-drag pan, wheel zoom.

@export var pan_speed: float = 600.0
@export var zoom_min: float = 0.5
@export var zoom_max: float = 2.5
@export var zoom_step: float = 0.1

var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_pos := Vector2.ZERO

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_action_strength("ui_camera_pan_right") - Input.get_action_strength("ui_camera_pan_left")
	input_vec.y = Input.get_action_strength("ui_camera_pan_down") - Input.get_action_strength("ui_camera_pan_up")
	if input_vec != Vector2.ZERO:
		position += input_vec.normalized() * pan_speed * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(zoom_step)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(-zoom_step)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_dragging = true
				_drag_start_mouse = mb.position
				_drag_start_pos = position
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		position = _drag_start_pos - (mm.position - _drag_start_mouse) / zoom.x

func _apply_zoom(delta_zoom: float) -> void:
	var new_zoom_v := clamp(zoom.x + delta_zoom, zoom_min, zoom_max)
	zoom = Vector2(new_zoom_v, new_zoom_v)
