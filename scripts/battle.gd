extends Node2D

# Entry point for the Battle scene.
# Week 2 scope: load scenario, spawn units, click-to-select, BFS movement range, move.

const DEFAULT_SCENARIO_ID := "00_sandbox"

@onready var hex_map: HexMap = $HexMap
@onready var camera: CameraController = $Camera
@onready var info_label: Label = $UI/InfoLabel
@onready var status_label: Label = $UI/StatusLabel

var factions: Dictionary = {}        # faction_id -> Dictionary
var units: Array[Unit] = []
var selected_unit: Unit = null
var movement_range: Dictionary = {}  # coord -> cost (when a unit is selected)
var player_faction_id: String = ""

func _ready() -> void:
	var scenario_id := GameState.current_scenario_id
	if scenario_id == "":
		scenario_id = DEFAULT_SCENARIO_ID
	var scenario := DataLoader.get_scenario(scenario_id)
	if scenario.is_empty():
		push_error("Scenario not found: " + scenario_id)
		return

	hex_map.load_from_scenario(scenario)
	hex_map.hex_clicked.connect(_on_hex_clicked)

	var built := UnitFactory.build(scenario, hex_map)
	factions = built["factions"]
	for f_id in factions:
		if factions[f_id]["controller"] == "player":
			player_faction_id = f_id
			break
	if player_faction_id == "" and not factions.is_empty():
		player_faction_id = factions.keys()[0]

	for u in built["units"]:
		var unit: Unit = u
		hex_map.register_unit(unit)
		units.append(unit)

	camera.position = hex_map.get_map_center()
	info_label.text = "%s — 點擊我方單位選取,再點亮藍色 hex 進行移動" % scenario.get("title", scenario_id)
	_update_status()

func _on_hex_clicked(coord: Vector2i, terrain_id: String) -> void:
	var clicked_unit := hex_map.unit_at(coord)

	# Case 1: a unit was already selected, and clicked hex is in its move range -> move
	if selected_unit != null and movement_range.has(coord) and clicked_unit == null:
		hex_map.move_unit(selected_unit, coord)
		_deselect()
		_update_status()
		return

	# Case 2: clicked on a selectable own unit -> select
	if clicked_unit != null and clicked_unit.faction_id == player_faction_id and not clicked_unit.has_moved:
		_select(clicked_unit)
		return

	# Case 3: clicked elsewhere -> show terrain info, deselect
	_deselect()
	var def := DataLoader.get_terrain_def(terrain_id)
	info_label.text = "(%d, %d) %s — 移動消耗 %d, 防禦修正 %+d%s" % [
		coord.x, coord.y,
		String(def.get("name_zh", terrain_id)),
		int(def.get("move_cost", 0)),
		int(def.get("defense", 0)),
		"  [此格有 " + clicked_unit.display_name + "]" if clicked_unit != null else "",
	]

func _select(unit: Unit) -> void:
	selected_unit = unit
	var move_pts := int(DataLoader.get_unit_def(unit.type_id).get("move", 0))
	movement_range = Pathfinding.movement_range(unit.coord, move_pts, hex_map, hex_map.occupants)
	hex_map.show_movement_range(movement_range.keys())
	hex_map.highlight_coord(unit.coord)
	info_label.text = "選取:%s (%s) — HP %d/%d,可移動範圍已標示" % [
		unit.display_name, factions[unit.faction_id]["name"], unit.hp, unit.max_hp,
	]

func _deselect() -> void:
	selected_unit = null
	movement_range.clear()
	hex_map.clear_movement_range()

func _update_status() -> void:
	var counts := {}
	for u in units:
		if not u.is_alive():
			continue
		counts[u.faction_id] = int(counts.get(u.faction_id, 0)) + 1
	var parts: Array[String] = []
	for fid in counts:
		parts.append("%s %d" % [factions[fid]["name"], counts[fid]])
	status_label.text = "  |  ".join(parts)
