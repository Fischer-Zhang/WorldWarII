extends Node2D

# Entry point for the Battle scene.
# Week 1 scope: load the sandbox scenario, render the hex grid, show coord/terrain on click.

const DEFAULT_SCENARIO_ID := "00_sandbox"

@onready var hex_map: HexMap = $HexMap
@onready var camera: CameraController = $Camera
@onready var info_label: Label = $UI/InfoLabel

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
	camera.position = hex_map.get_map_center()
	info_label.text = "%s — 點擊 hex 看資訊 | WASD 平移 | 滾輪縮放 | 中鍵拖曳" % scenario.get("title", scenario_id)

func _on_hex_clicked(coord: Vector2i, terrain_id: String) -> void:
	var def: Dictionary = DataLoader.get_terrain_def(terrain_id)
	var name_zh := String(def.get("name_zh", terrain_id))
	var move_cost := int(def.get("move_cost", 0))
	var defense := int(def.get("defense", 0))
	info_label.text = "(%d, %d) %s — 移動消耗 %d, 防禦修正 %+d" % [
		coord.x, coord.y, name_zh, move_cost, defense,
	]
