class_name HexMap
extends Node2D

# Renders a hex grid by spawning Polygon2D children for each tile.
# Coordinates are axial (q, r). Map data comes from a scenario's
# rectangular `tiles[row][col]` array, converted to axial on load.

# Explicit preloads so we don't depend on the global class_name registry,
# which Godot 4.6 sometimes drops on re-import.
const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const Unit := preload("res://scripts/units/unit.gd")

const HEX_SIZE := 40.0  # pointy-top, distance from center to vertex
const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.2, 0.55)
const RANGE_OVERLAY_COLOR := Color(0.3, 0.7, 1.0, 0.35)
const ATTACK_OVERLAY_COLOR := Color(1.0, 0.3, 0.25, 0.45)
const THREAT_OVERLAY_COLOR := Color(1.0, 0.45, 0.05, 0.25)
const OBJECTIVE_RGB := Color(1.0, 0.85, 0.2)
const FOG_COLOR := Color(0.04, 0.04, 0.07, 0.72)

var tiles: Dictionary = {}     # Vector2i (axial) -> terrain_id (String)
var polys: Dictionary = {}     # Vector2i (axial) -> Polygon2D node
var occupants: Dictionary = {} # Vector2i (axial) -> Unit
var bridges: Dictionary = {}   # Vector2i -> true: engineer bridges over impassable water
var highlight: Polygon2D
var range_overlays: Node2D
var threat_overlays: Node2D
var fog_overlays: Dictionary = {}  # Vector2i -> Polygon2D
var objective_overlays: Array[Polygon2D] = []
var _objective_phase: float = 0.0
var bounds_min := Vector2.ZERO
var bounds_max := Vector2.ZERO

signal hex_clicked(coord: Vector2i, terrain_id: String)
signal hex_hovered(coord: Vector2i, terrain_id: String)

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
	_spawn_threat_overlay_layer()
	_spawn_highlight()
	_spawn_fog_layer()
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
	# Above the fog layer (z=8) so the movement range stays clearly visible even on
	# fogged hexes you can move into; below the highlight (z=10) and units (z=20).
	range_overlays.z_index = 9
	add_child(range_overlays)

func _spawn_threat_overlay_layer() -> void:
	threat_overlays = Node2D.new()
	threat_overlays.name = "ThreatOverlays"
	threat_overlays.z_index = 4
	add_child(threat_overlays)

func _spawn_fog_layer() -> void:
	var layer := Node2D.new()
	layer.name = "FogLayer"
	layer.z_index = 8  # over wreckage + threat overlay; movement range (z=9) shows through, units (z=20) on top
	add_child(layer)
	for c in tiles.keys():
		var coord: Vector2i = c
		var p := Polygon2D.new()
		p.polygon = _hex_vertices(HEX_SIZE)
		p.color = FOG_COLOR
		p.position = HexCoord.to_pixel(coord, HEX_SIZE)
		p.visible = false  # default: no fog until apply_visibility called
		layer.add_child(p)
		fog_overlays[coord] = p

func apply_visibility(visible_hexes: Dictionary, viewer_faction: String) -> void:
	# Show fog over non-visible hexes; hide enemy units not on visible hexes.
	for c in fog_overlays.keys():
		fog_overlays[c].visible = not visible_hexes.has(c)
	for c in occupants.keys():
		var unit: Unit = occupants[c]
		if unit == null:
			continue
		if unit.faction_id == viewer_faction:
			unit.visible = true
		else:
			unit.visible = visible_hexes.has(c)

func show_movement_range(coords: Array) -> void:
	_paint_overlay(coords, RANGE_OVERLAY_COLOR)

func show_attack_targets(coords: Array) -> void:
	_paint_overlay(coords, ATTACK_OVERLAY_COLOR)

func show_threat_range(coords: Array) -> void:
	_paint_overlay_on_layer(threat_overlays, coords, THREAT_OVERLAY_COLOR, 0.92)

func clear_threat_range() -> void:
	_clear_overlay_layer(threat_overlays)

func clear_movement_range() -> void:
	_clear_overlay_layer(range_overlays)

func _paint_overlay(coords: Array, color: Color) -> void:
	clear_movement_range()
	_paint_overlay_on_layer(range_overlays, coords, color, 0.85)

func _paint_overlay_on_layer(layer: Node2D, coords: Array, color: Color, scale: float) -> void:
	if layer == null:
		return
	_clear_overlay_layer(layer)
	for c in coords:
		var coord: Vector2i = c
		var p := Polygon2D.new()
		p.polygon = _hex_vertices(HEX_SIZE * scale)
		p.color = color
		p.position = HexCoord.to_pixel(coord, HEX_SIZE)
		layer.add_child(p)

func _clear_overlay_layer(layer: Node2D) -> void:
	if layer == null:
		return
	for c in layer.get_children():
		c.queue_free()

func register_unit(unit: Unit) -> bool:
	var existing: Unit = occupants.get(unit.coord)
	if existing != null and existing != unit:
		push_error("[HexMap] Duplicate unit coordinate %s: %s conflicts with %s" % [
			unit.coord,
			unit.display_name,
			existing.display_name,
		])
		return false
	occupants[unit.coord] = unit
	add_child(unit)
	unit.z_index = 20
	return true

func unregister_unit(unit: Unit) -> void:
	if occupants.get(unit.coord) == unit:
		occupants.erase(unit.coord)

func move_unit(unit: Unit, dest: Vector2i, animate_duration: float = 0.0) -> void:
	occupants.erase(unit.coord)
	occupants[dest] = unit
	unit.move_to(dest, HexCoord.to_pixel(dest, HEX_SIZE), animate_duration)

const PATH_STEP_DURATION := 0.12

func move_unit_along_path(unit: Unit, path: Array) -> void:
	# `path` is the full BFS path including start and goal. Animates the
	# unit hex-by-hex along the route; game state (coord, occupancy,
	# has_moved) is updated synchronously so callers can chain logic
	# immediately without waiting for the visual.
	if path.size() < 2:
		return
	var dest: Vector2i = path[-1]
	occupants.erase(unit.coord)
	occupants[dest] = unit
	unit.coord = dest
	unit.has_moved = true
	var tween := unit.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	for i in range(1, path.size()):
		var step: Vector2i = path[i]
		tween.tween_property(unit, "position", HexCoord.to_pixel(step, HEX_SIZE), PATH_STEP_DURATION)
	unit.moved.emit(dest)
	unit.queue_redraw()

func place_wreckage(coord: Vector2i, faction_color: Color) -> void:
	# Visual marker left when a unit dies on this hex.
	var holder := Node2D.new()
	holder.position = HexCoord.to_pixel(coord, HEX_SIZE)
	holder.z_index = 6  # above range overlays, below units
	add_child(holder)
	# Hex-shaped scorch
	var scorch := Polygon2D.new()
	scorch.polygon = _hex_vertices(HEX_SIZE * 0.55)
	scorch.color = Color(0.10, 0.08, 0.07, 0.65)
	holder.add_child(scorch)
	# Cross marks
	var dim: Color = Color(faction_color.r * 0.45, faction_color.g * 0.45, faction_color.b * 0.45, 0.95)
	for pts in [[Vector2(-11, -11), Vector2(11, 11)], [Vector2(11, -11), Vector2(-11, 11)]]:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = dim
		line.add_point(pts[0])
		line.add_point(pts[1])
		holder.add_child(line)
	# Persist a few seconds then fade away
	var tween := holder.create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(holder, "modulate:a", 0.0, 0.8)
	tween.tween_callback(holder.queue_free)

func unit_at(coord: Vector2i) -> Unit:
	return occupants.get(coord)

func set_objective_coords(coords: Array) -> void:
	for old in objective_overlays:
		old.queue_free()
	objective_overlays.clear()
	for c in coords:
		var coord: Vector2i = c
		if not tiles.has(coord):
			continue
		var p := Polygon2D.new()
		p.polygon = _hex_vertices(HEX_SIZE * 0.88)
		p.color = Color(OBJECTIVE_RGB.r, OBJECTIVE_RGB.g, OBJECTIVE_RGB.b, 0.35)
		p.position = HexCoord.to_pixel(coord, HEX_SIZE)
		p.z_index = 4
		add_child(p)
		objective_overlays.append(p)
	set_process(not objective_overlays.is_empty())

func _process(delta: float) -> void:
	if objective_overlays.is_empty():
		return
	_objective_phase += delta * 2.4
	var alpha: float = 0.28 + (sin(_objective_phase) + 1.0) * 0.18
	for p in objective_overlays:
		p.color = Color(OBJECTIVE_RGB.r, OBJECTIVE_RGB.g, OBJECTIVE_RGB.b, alpha)

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

func terrain_impassable(terrain_id: String) -> bool:
	if terrain_id == "":
		return true
	return bool(DataLoader.get_terrain_def(terrain_id).get("impassable", false))

func is_bridged(coord: Vector2i) -> bool:
	return bridges.has(coord)

func add_bridge(coord: Vector2i) -> void:
	bridges[coord] = true
	queue_redraw()

func blocks_los_at(coord: Vector2i) -> bool:
	var terrain_id: String = tiles.get(coord, "")
	if terrain_id == "":
		return false
	var def := DataLoader.get_terrain_def(terrain_id)
	return bool(def.get("blocks_los", false))

func _clear() -> void:
	for child in get_children():
		child.queue_free()
	tiles.clear()
	polys.clear()
	occupants.clear()
	objective_overlays.clear()
	fog_overlays.clear()
	highlight = null
	range_overlays = null
	threat_overlays = null
	set_process(false)

var _hover_coord: Vector2i = Vector2i(-9999, -9999)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var coord := coord_at_world(get_global_mouse_position())
			if tiles.has(coord):
				highlight_coord(coord)
				hex_clicked.emit(coord, tiles[coord])
	elif event is InputEventMouseMotion:
		var coord := coord_at_world(get_global_mouse_position())
		if coord != _hover_coord:
			_hover_coord = coord
			if tiles.has(coord):
				hex_hovered.emit(coord, tiles[coord])
			else:
				hex_hovered.emit(Vector2i(-9999, -9999), "")
