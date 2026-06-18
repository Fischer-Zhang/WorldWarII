extends Node

# Autoload singleton (registered as GameState).
# Holds inter-scene state: current scenario, results, settings.

var current_scenario_id: String = ""
var last_result: Dictionary = {}

signal scenario_started(scenario_id: String)
signal scenario_ended(winner: String, summary: Dictionary)

func start_scenario(id: String) -> void:
	current_scenario_id = id
	scenario_started.emit(id)

func end_scenario(winner: String, summary: Dictionary) -> void:
	last_result = {"winner": winner, "summary": summary}
	scenario_ended.emit(winner, summary)
