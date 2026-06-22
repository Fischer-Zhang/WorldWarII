class_name CampaignManager
extends RefCounted

# Pure persistence layer for campaign mode. Reads/writes a single JSON file
# under user:// with a tiny schema:
#
# {
#   "version": 1,
#   "progress": 0,                              # number of completed scenarios
#   "roster": {                                 # surviving units per faction
#     "axis":   { "Pz.IV": { "xp": 3, "rank": 1, "general_id": "guderian" } },
#     "allies": { ... },
#     "soviet": { ... }
#   }
# }
#
# Fixed chronological campaign order — scenarios are progressed linearly.

const SAVE_PATH := "user://campaign_save.json"
const SCENARIO_ORDER := [
	"01_sedan_1940",
	"02_kiev_1941",
	"03_stalingrad_1942",
	"04_kursk_1943",
	"05_bastogne_1944",
]
const VERSION := 1

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _empty_state()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return _empty_state()
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _empty_state()
	# Normalise missing keys for forward compat.
	var d: Dictionary = parsed
	if not d.has("version"):
		d["version"] = VERSION
	if not d.has("progress"):
		d["progress"] = 0
	if not d.has("roster"):
		d["roster"] = {}
	return d

static func save_state(state: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("CampaignManager: could not open %s for write" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(state, "\t"))
	f.close()

static func reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

static func _empty_state() -> Dictionary:
	return {"version": VERSION, "progress": 0, "roster": {}}

static func is_complete(state: Dictionary) -> bool:
	return int(state.get("progress", 0)) >= SCENARIO_ORDER.size()

static func current_scenario_id(state: Dictionary) -> String:
	var p: int = int(state.get("progress", 0))
	if p >= SCENARIO_ORDER.size():
		return ""
	return SCENARIO_ORDER[p]

static func complete_scenario(state: Dictionary, scenario_id: String, surviving_units: Array) -> void:
	# Bump progress if this completion is in order. Snapshot survivors of
	# every faction into the roster (matched by display_name across runs).
	var expected_id: String = current_scenario_id(state)
	if expected_id == scenario_id:
		state["progress"] = int(state.get("progress", 0)) + 1
	# Snapshot surviving units — keyed by display_name to support re-runs.
	var roster: Dictionary = state.get("roster", {})
	for u in surviving_units:
		var unit = u
		if unit == null or not unit.is_alive():
			continue
		var fid := String(unit.faction_id)
		if not roster.has(fid):
			roster[fid] = {}
		roster[fid][String(unit.display_name)] = {
			"xp": int(unit.xp),
			"rank": int(unit.rank),
			"general_id": String(unit.general_id),
		}
	state["roster"] = roster
	save_state(state)

static func apply_roster_to_units(state: Dictionary, units: Array) -> void:
	# For each unit, if its display_name matches an entry in the saved
	# roster (for that faction), restore xp / rank / general_id. Units
	# new to this scenario (no roster entry) start fresh.
	var roster: Dictionary = state.get("roster", {})
	for u in units:
		var unit = u
		if unit == null:
			continue
		var faction_roster: Dictionary = roster.get(String(unit.faction_id), {})
		var saved: Dictionary = faction_roster.get(String(unit.display_name), {})
		if saved.is_empty():
			continue
		unit.xp = int(saved.get("xp", 0))
		unit.rank = int(saved.get("rank", 0))
		# Only restore general_id if the scenario didn't already assign one
		# (scenario assignments take precedence — they encode the narrative).
		if unit.general_id == "":
			unit.general_id = String(saved.get("general_id", ""))
		unit.queue_redraw()
