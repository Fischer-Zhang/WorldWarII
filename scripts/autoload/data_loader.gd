extends Node

# Autoload singleton (registered in project.godot as DataLoader).
# Loads JSON catalogs once at startup; everything else reads from here.

const UNITS_PATH := "res://data/units.json"
const TERRAINS_PATH := "res://data/terrains.json"
const SCENARIOS_DIR := "res://data/scenarios/"

var units: Dictionary = {}
var terrains: Dictionary = {}
var scenarios: Array[Dictionary] = []

func _ready() -> void:
	units = _load_json(UNITS_PATH)
	terrains = _load_json(TERRAINS_PATH)
	scenarios = _load_scenarios()
	print("[DataLoader] loaded %d unit types, %d terrains, %d scenarios" % [
		units.size(), terrains.size(), scenarios.size(),
	])

func get_unit_def(type_id: String) -> Dictionary:
	if not units.has(type_id):
		push_error("Unknown unit type: " + type_id)
		return {}
	return units[type_id]

func get_terrain_def(terrain_id: String) -> Dictionary:
	if not terrains.has(terrain_id):
		push_error("Unknown terrain: " + terrain_id)
		return {}
	return terrains[terrain_id]

func get_scenario(scenario_id: String) -> Dictionary:
	for s in scenarios:
		if s.get("id", "") == scenario_id:
			return s
	push_error("Unknown scenario: " + scenario_id)
	return {}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON dict: " + path)
		return {}
	return parsed

func _load_scenarios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(SCENARIOS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			var data := _load_json(SCENARIOS_DIR + name)
			if not data.is_empty():
				out.append(data)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return a.get("id", "") < b.get("id", ""))
	return out
