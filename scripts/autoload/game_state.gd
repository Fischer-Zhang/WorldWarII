extends Node

# Autoload singleton (registered as GameState).
# Holds inter-scene state: current scenario, results, settings.

var current_scenario_id: String = ""
var current_campaign_id: String = ""
var last_result: Dictionary = {}
var difficulty: String = "normal"  # "easy" | "normal" | "hard"
# Campaign mode: when true, the battle reads/writes campaign_save.json
# (unit roster carryover, progress advancement on victory).
var campaign_mode: bool = false
var deployment_scenario_id: String = ""
var deployment_overrides: Dictionary = {}

signal scenario_started(scenario_id: String)
signal scenario_ended(winner: String, summary: Dictionary)

func start_scenario(id: String) -> void:
	current_scenario_id = id
	scenario_started.emit(id)

func end_scenario(winner: String, summary: Dictionary) -> void:
	last_result = {"winner": winner, "summary": summary}
	scenario_ended.emit(winner, summary)

func set_deployment_overrides(scenario_id: String, overrides: Dictionary) -> void:
	deployment_scenario_id = scenario_id
	deployment_overrides = overrides.duplicate(true)

func get_deployment_overrides(scenario_id: String) -> Dictionary:
	if deployment_scenario_id != scenario_id:
		return {}
	return deployment_overrides

func clear_deployment_overrides() -> void:
	deployment_scenario_id = ""
	deployment_overrides.clear()
