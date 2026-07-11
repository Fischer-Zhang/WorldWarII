extends RefCounted

# Headless AI-vs-AI battle driver shared by tools/ai_selfplay_report.gd and
# tests/test_ai_selfplay_smoke.gd.
#
# Drives the REAL battle.tscn so every rule (combat, morale, overwatch,
# reinforcements, victory) executes through the game's own code — nothing is
# re-implemented here. All factions are flipped to controller "player" so the
# scene never auto-runs a turn; the driver kicks each faction with
# battle._run_ai_turn(), setting GameState.difficulty per faction immediately
# before the kick (AIController reads it at construction), which makes
# asymmetric matchups (hard vs easy) possible.
#
# The whole game is RNG-free, so a run's outcome is a pure function of
# (scenario_id, per-faction difficulty) — reruns are bit-identical.

# Frames to wait for a single AI turn before declaring the run stalled.
# Planning is synchronous between timer awaits, so frames only tick during
# the (time_scale-collapsed) step delays — this is a generous ceiling.
const AI_TURN_WATCHDOG_FRAMES := 120000

static func run_battle(
	tree: SceneTree,
	scenario_id: String,
	diff_for: Dictionary,  # faction_id -> "easy"|"normal"|"hard"
	turn_cutoff_cap: int = 40,
) -> Dictionary:
	var game_state = tree.root.get_node("GameState")
	var data_loader = tree.root.get_node("DataLoader")

	# Reset inter-scene state so the battle boots as a plain single battle.
	game_state.current_scenario_id = scenario_id
	game_state.campaign_mode = false
	game_state.clear_conquest_battle()
	game_state.clear_deployment_overrides()
	game_state.last_result = {}
	# emit_initial() fires during _ready; make sure the first faction's turn
	# (in case it is AI-controlled) already runs at its assigned difficulty.
	var scenario: Dictionary = data_loader.get_scenario(scenario_id)
	var faction_defs: Array = scenario.get("factions", [])
	if not faction_defs.is_empty():
		var first_id := String(faction_defs[0].get("id", ""))
		game_state.difficulty = String(diff_for.get(first_id, "normal"))

	var battle: Node = load("res://scenes/battle.tscn").instantiate()
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame

	# If the scene auto-started an AI faction, let that turn finish first.
	var frames := 0
	while battle.ai_running and frames < AI_TURN_WATCHDOG_FRAMES:
		frames += 1
		await tree.process_frame

	# Take over every faction: no _on_turn_started branch auto-runs again.
	for fid in battle.factions.keys():
		battle.factions[fid]["controller"] = "player"

	# HP pool per faction: starting units at current hp, reinforcements
	# absorbed at max_hp as they appear. destroyed = pool - remaining.
	var seen_units: Dictionary = {}  # instance id -> true
	var hp_pool: Dictionary = {}  # faction_id -> int
	var start_units: Dictionary = {}  # faction_id -> int
	for fid in battle.factions.keys():
		hp_pool[fid] = 0
		start_units[fid] = 0
	for u in battle.units:
		seen_units[u.get_instance_id()] = true
		hp_pool[u.faction_id] = int(hp_pool.get(u.faction_id, 0)) + int(u.hp)
		start_units[u.faction_id] = int(start_units.get(u.faction_id, 0)) + 1

	var turn_cutoff := turn_cutoff_cap
	var victory: Dictionary = battle.scenario.get("victory", {})
	var max_by_turn := 0
	for fid in victory.keys():
		max_by_turn = max(max_by_turn, int(victory[fid].get("by_turn", 0)))
	if max_by_turn > 0:
		turn_cutoff = min(turn_cutoff_cap, max_by_turn + 3)

	# Morale/rout activity, straight from live battle state, as a regression
	# tripwire: the morale layer must actually engage somewhere in the suite.
	var ever_routed: Dictionary = {}  # instance id -> true (distinct units routed)
	var prev_routed: Dictionary = {}  # instance id -> bool (for reform detection)
	var routs := 0
	var reforms := 0

	var stalled := false
	while battle.phase != battle.Phase.GAME_OVER \
			and battle.turn_manager.turn_number <= turn_cutoff:
		var fid: String = battle.turn_manager.current_faction()
		var kick_key := [fid, battle.turn_manager.turn_number]
		game_state.difficulty = String(diff_for.get(fid, "normal"))
		battle._run_ai_turn(fid)  # fire-and-forget, same shape as battle.gd's own call
		frames = 0
		while battle.ai_running and frames < AI_TURN_WATCHDOG_FRAMES:
			frames += 1
			await tree.process_frame
		if battle.ai_running:
			stalled = true  # watchdog tripped mid-turn
			break
		# Reinforcements may have spawned this turn — absorb them into the pool.
		for u in battle.units:
			var key: int = u.get_instance_id()
			if not seen_units.has(key):
				seen_units[key] = true
				hp_pool[u.faction_id] = int(hp_pool.get(u.faction_id, 0)) + int(u.max_hp)
		# Tally rout/reform activity from the current state.
		for u in battle.units:
			var iid: int = u.get_instance_id()
			var now_routed: bool = bool(u.routed)
			if now_routed and not ever_routed.has(iid):
				ever_routed[iid] = true
				routs += 1
			elif prev_routed.get(iid, false) and not now_routed and u.is_alive():
				reforms += 1
			prev_routed[iid] = now_routed
		if battle.phase != battle.Phase.GAME_OVER \
				and kick_key == [battle.turn_manager.current_faction(), battle.turn_manager.turn_number]:
			stalled = true  # kick was swallowed; avoid an infinite loop
			break

	var turn_capped: bool = battle.phase != battle.Phase.GAME_OVER and not stalled
	var last_result: Dictionary = game_state.last_result
	var summary: Dictionary = last_result.get("summary", {})
	var end_turn: int = int(summary.get("turn", battle.turn_manager.turn_number))

	var factions_out: Dictionary = {}
	for fid in battle.factions.keys():
		var alive := 0
		var remaining_hp := 0
		for u in battle.units:
			if u.faction_id == fid and u.is_alive():
				alive += 1
				remaining_hp += int(u.hp)
		factions_out[fid] = {
			"start_units": int(start_units.get(fid, 0)),
			"alive_units": alive,
			"hp_pool": int(hp_pool.get(fid, 0)),
			"remaining_hp": remaining_hp,
			"destroyed_hp": int(hp_pool.get(fid, 0)) - remaining_hp,
		}

	battle.queue_free()
	await tree.process_frame
	await tree.process_frame

	return {
		"scenario_id": scenario_id,
		"winner": String(last_result.get("winner", "")),
		"end_turn": end_turn,
		"turn_capped": turn_capped,
		"stalled": stalled,
		"factions": factions_out,
		"routs": routs,
		"reforms": reforms,
	}
