class_name CampaignManager
extends RefCounted

# Pure persistence layer for campaign mode. Reads/writes a single JSON file
# under user:// with a tiny schema:
#
# {
#   "version": 2,
#   "campaigns": {
#     "eastern_front": {
#       "progress": 0,
#       "roster": {
#         "soviet": { "T-34": { "xp": 3, "rank": 1, "general_id": "konev" } }
#       }
#     }
#   }
# }
#
# Each campaign series keeps independent progress and roster carryover.

const SAVE_PATH := "user://campaign_save.json"
const LEGACY_SCENARIO_ORDER := [
	"01_sedan_1940",
	"02_kiev_1941",
	"03_stalingrad_1942",
	"04_kursk_1943",
	"05_bastogne_1944",
	"06_market_garden_1944",
	"07_bagration_1944",
]
const VERSION := 2

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
	var d: Dictionary = parsed
	return _normalise_state(d)

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

static func reset_campaign(campaign_id: String) -> void:
	var state := load_state()
	var campaigns: Dictionary = state.get("campaigns", {})
	campaigns.erase(campaign_id)
	state["campaigns"] = campaigns
	save_state(state)

static func _empty_state() -> Dictionary:
	return {"version": VERSION, "campaigns": {}}

static func _normalise_state(state: Dictionary) -> Dictionary:
	# v1 saves had a single chronological progress/roster. Migrate by
	# deriving per-series progress from the old completed prefix when callers
	# first touch each campaign; keep the old roster as a fallback snapshot.
	if not state.has("campaigns"):
		var old_progress := int(state.get("progress", 0))
		var old_roster: Dictionary = state.get("roster", {})
		return {
			"version": VERSION,
			"campaigns": {},
			"legacy_progress": old_progress,
			"legacy_roster": old_roster,
		}
	state["version"] = VERSION
	if not state.has("campaigns"):
		state["campaigns"] = {}
	return state

static func campaign_state(state: Dictionary, campaign_id: String, scenario_order: Array) -> Dictionary:
	var campaigns: Dictionary = state.get("campaigns", {})
	if not campaigns.has(campaign_id):
		campaigns[campaign_id] = _empty_campaign_state(state, scenario_order)
		state["campaigns"] = campaigns
	var cstate: Dictionary = campaigns[campaign_id]
	if not cstate.has("progress"):
		cstate["progress"] = 0
	if not cstate.has("roster"):
		cstate["roster"] = {}
	return cstate

static func _empty_campaign_state(state: Dictionary, scenario_order: Array) -> Dictionary:
	var progress := 0
	if state.has("legacy_progress"):
		var completed := {}
		var legacy_progress := int(state.get("legacy_progress", 0))
		for i in range(min(legacy_progress, LEGACY_SCENARIO_ORDER.size())):
			completed[LEGACY_SCENARIO_ORDER[i]] = true
		for sid in scenario_order:
			if completed.has(String(sid)):
				progress += 1
			else:
				break
	return {
		"progress": progress,
		"roster": state.get("legacy_roster", {}).duplicate(true),
	}

static func is_complete(state: Dictionary, campaign_id: String, scenario_order: Array) -> bool:
	var cstate := campaign_state(state, campaign_id, scenario_order)
	return int(cstate.get("progress", 0)) >= scenario_order.size()

static func current_scenario_id(state: Dictionary, campaign_id: String, scenario_order: Array) -> String:
	var cstate := campaign_state(state, campaign_id, scenario_order)
	var p: int = int(cstate.get("progress", 0))
	if p >= scenario_order.size():
		return ""
	return String(scenario_order[p])

static func complete_scenario(
	state: Dictionary,
	campaign_id: String,
	scenario_order: Array,
	scenario_id: String,
	surviving_units: Array
) -> void:
	# Bump progress if this completion is in order. Snapshot survivors of
	# every faction into the roster (matched by display_name across runs).
	var cstate := campaign_state(state, campaign_id, scenario_order)
	var expected_id: String = current_scenario_id(state, campaign_id, scenario_order)
	if expected_id == scenario_id:
		cstate["progress"] = int(cstate.get("progress", 0)) + 1
	# Snapshot surviving units — keyed by display_name to support re-runs.
	var roster: Dictionary = cstate.get("roster", {})
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
	cstate["roster"] = roster
	save_state(state)

static func apply_roster_to_units(state: Dictionary, campaign_id: String, scenario_order: Array, units: Array) -> void:
	# For each unit, if its display_name matches an entry in the saved
	# roster (for that faction), restore xp / rank / general_id. Units
	# new to this scenario (no roster entry) start fresh.
	var cstate := campaign_state(state, campaign_id, scenario_order)
	var roster: Dictionary = cstate.get("roster", {})
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
