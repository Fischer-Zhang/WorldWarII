class_name HexMap
extends Node2D

# Renders a hex grid by spawning Polygon2D children for each tile.
# Coordinates are axial (q, r). Map data comes from a scenario's
# rectangular `tiles[row][col]` array, converted to axial on load.

const HEX_SIZE := 40.0  # pointy-top, distance from center to vertex
const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.2, 0.55)
const RANGE_OVERLAY_COLOR := Color(0.3, 0.7, 1.0, 0.35)

var tiles: Dictionary = {}     # Vector2i (axial) -> terrain_id (String)
var polys: Dictionary = {}     # Vector2i (axial) -> Polygon2D node
var occupants: Dictionary = {} # Vector2i (axial) -> Unit
var highlight: Polygon2D
var range_overlays: Node2D
var bounds_min := Vector2.ZERO
var bounds_max := Vector2.ZERO

signal hex_clicked(coord: Vector2i, terrain_id: String)

func load_from_scenario(scenario: Dictionary) -> void:
	_clear()
	var map: Dictionary = scenario.get("map", {})
	var rows: Array = map.get("tiles", [])
	for row_idx in range(rows.size()):
		var row: Array = rows[row_idx]
		for col_idx in range(row.size()):
			var terrain_id := String(row[col_idx])
			# odd-r offset -> axial
			var q := col_idx - (row_idx >> 1)
			var r := row_idx
			var coord := Vector2i(q, r)
			tiles[coord] = terrain_id
			_spawn_tile(coord, terrain_id)
	_spawn_range_overlay_layer()
	_spawn_highlight()
	_recompute_bounds()

func _spawn_tile(coord: Vector2i, terrain_id: String) -> void:
	var def: Dictionary = DataLoader.get_terrain_def(terrain_id)
	var color_str := String(def.get("color", "#888888"))
	var poly := Polygon2D.new()
	poly.polygon = _hex_vertices(HEX_SIZE)
	poly.color = Color(color_str)
	poly.position = HexCoord.to_pixel(coord, HEX_SIZE)
	# Outline
	var outline := Line2D.new()
	var verts := _hex_vertices(HEX_SIZE)
	verts.append(verts[0])
	outline.points = verts
	outline.width = 1.5
	outline.default_color = Color(0, 0, 0, 0.4)
	poly.add_child(outline)
	add_child(poly)
	polys[coord] = poly

func _spawn_highlight() -> void:
	highlight = Polygon2D.new()
	highlight.polygon = _hex_vertices(HEX_SIZE * 0.95)
	highlight.color = HIGHLIGHT_COLOR
	highlight.visible = false
	highlight.z_index = 10
	add_child(highlight)

func _spawn_range_overlay_layer() -> void:
	range_overlays = Node2D.new()
	range_overlays.name = "RangeOverlays"
	range_overlays.z_index = 5
	add_child(range_overlays)

func show_movement_range(coords: Array) -> void:
	clear_movement_range()
	for c in coords:
		var coord: Vector2i = c
		var p := Polygon2D.new()
		p.polygon = _hex_vertices(HEX_SIZE * 0.85)
		p.color = RANGE_OVERLAY_COLOR
		p.position = HexCoord.to_pixel(coord, HEX_SIZE)
		range_overlays.add_child(p)

func clear_movement_range() -> void:
	if range_overlays == null:
		return
	for c in range_overlays.get_children():
		c.queue_free()

func register_unit(unit: Unit) -> void:
	occupants[unit.coord] = unit
	add_child(unit)
	unit.z_index = 20

func unregister_unit(unit: Unit) -> void:
	if occupants.get(unit.coord) == unit:
		occupants.erase(unit.coord)

func move_unit(unit: Unit, dest: Vector2i) -> void:
	occupants.erase(unit.coord)
	occupants[dest] = unit
	unit.move_to(dest, HexCoord.to_pixel(dest, HEX_SIZE))

func unit_at(coord: Vector2i) -> Unit:
	return occupants.get(coord)

func _hex_vertices(size: float) -> PackedVector2Array:
	# Pointy-top: vertex angles at 30, 90, 150, 210, 270, 330 degrees.
	var pts := PackedVector2Array()
	for i in range(6):
		var angle_deg := 60.0 * i - 30.0
		var angle_rad := deg_to_rad(angle_deg)
		pts.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return pts

func _recompute_bounds() -> void:
	if polys.is_empty():
		return
	var first := true
	for coord in polys.keys():
		var p: Polygon2D = polys[coord]
		var pos := p.position
		if first:
			bounds_min = pos
			bounds_max = pos
			first = false
		else:
			bounds_min.x = min(bounds_min.x, pos.x)
			bounds_min.y = min(bounds_min.y, pos.y)
			bounds_max.x = max(bounds_max.x, pos.x)
			bounds_max.y = max(bounds_max.y, pos.y)

func get_map_center() -> Vector2:
	return (bounds_min + bounds_max) * 0.5

func coord_at_world(world_pos: Vector2) -> Vector2i:
	var local := world_pos - global_position
	return HexCoord.from_pixel(local, HEX_SIZE)

func highlight_coord(coord: Vector2i) -> void:
	if not tiles.has(coord):
		highlight.visible = false
		return
	highlight.position = HexCoord.to_pixel(coord, HEX_SIZE)
	highlight.visible = true

func terrain_at(coord: Vector2i) -> String:
	return tiles.get(coord, "")

func move_cost_at(coord: Vector2i) -> int:
	var terrain_id: String = tiles.get(coord, "")
	if terrain_id == "":
		return 999
	var def := DataLoader.get_terrain_def(terrain_id)
	return int(def.get("move_cost", 1))

func _clear() -> void:
	for child in get_children():
		child.queue_free()
	tiles.clear()
	polys.clear()
	occupants.clear()
	highlight = null
	range_overlays = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var coord := coord_at_world(get_global_mouse_position())
			if tiles.has(coord):
				highlight_coord(coord)
				hex_clicked.emit(coord, tiles[coord])
