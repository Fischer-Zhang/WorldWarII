class_name Unit
extends Node2D

# A single unit on the battlefield. Visual is drawn programmatically (no sprite yet).

const RADIUS := 22.0
const HP_BAR_WIDTH := 36.0
const HP_BAR_HEIGHT := 4.0
const SHORT_LABELS := {
	"infantry": "步",
	"mg_team": "MG",
	"at_gun": "反",
	"light_tank": "輕",
	"medium_tank": "中",
	"artillery": "砲",
}

var type_id: String = ""
var display_name: String = ""
var faction_id: String = ""
var faction_color: Color = Color.WHITE
var coord: Vector2i = Vector2i.ZERO
var hp: int = 0
var max_hp: int = 0
var has_moved: bool = false
var has_attacked: bool = false

signal moved(new_coord: Vector2i)

func configure(_type_id: String, _faction_id: String, _faction_color: Color, _coord: Vector2i, _name: String = "") -> void:
	type_id = _type_id
	faction_id = _faction_id
	faction_color = _faction_color
	coord = _coord
	var def: Dictionary = DataLoader.get_unit_def(_type_id)
	max_hp = int(def.get("hp", 10))
	hp = max_hp
	display_name = _name if _name != "" else String(def.get("name_zh", _type_id))
	queue_redraw()

func is_alive() -> bool:
	return hp > 0

func is_done_for_turn() -> bool:
	return has_moved and has_attacked

func reset_for_new_turn() -> void:
	has_moved = false
	has_attacked = false
	queue_redraw()

func move_to(new_coord: Vector2i, world_pos: Vector2, duration: float = 0.0) -> void:
	coord = new_coord
	has_moved = true
	if duration > 0.0:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "position", world_pos, duration)
	else:
		position = world_pos
	moved.emit(new_coord)
	queue_redraw()

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	queue_redraw()

func _draw() -> void:
	# Faction-colored circle
	var fill_color := faction_color
	if is_done_for_turn():
		fill_color = fill_color.darkened(0.4)
	draw_circle(Vector2.ZERO, RADIUS, fill_color)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, Color(0, 0, 0, 0.7), 2.0)

	# Unit-type short label
	var label := String(SHORT_LABELS.get(type_id, "?"))
	var font := ThemeDB.fallback_font
	var font_size := 18
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-text_size.x / 2.0, text_size.y / 3.0), label,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1))

	# HP bar (only if damaged)
	if hp < max_hp:
		var bar_y := RADIUS + 6.0
		var pct := float(hp) / float(max_hp)
		draw_rect(Rect2(-HP_BAR_WIDTH / 2.0, bar_y, HP_BAR_WIDTH, HP_BAR_HEIGHT),
			Color(0.15, 0.15, 0.15))
		draw_rect(Rect2(-HP_BAR_WIDTH / 2.0, bar_y, HP_BAR_WIDTH * pct, HP_BAR_HEIGHT),
			_hp_color(pct))

func _hp_color(pct: float) -> Color:
	if pct > 0.6:
		return Color(0.4, 0.85, 0.4)
	if pct > 0.3:
		return Color(0.95, 0.85, 0.3)
	return Color(0.9, 0.3, 0.3)
