extends SceneTree

# Deterministic AI self-play report generator.
# Runs full headless battles with every faction driven by AIController
# (via tools/selfplay_runner.gd) across representative scenarios and
# difficulty matchups, then writes docs/progress/ai_selfplay_report.md.
#
# Slow (full battles) — run on demand after AI scoring or balance changes,
# NOT part of the validate gate. The committed report is structure-checked
# by tools/check_ai_selfplay_report.py in validate_fast.sh.
#
# Run with: godot --headless --path . --script res://tools/ai_selfplay_report.gd

const SelfPlayRunner := preload("res://tools/selfplay_runner.gd")

# Matchup matrix. "tag" groups runs for the derived sections:
#   canary    — driver smoke on the smallest scenario
#   symmetric — both sides at the same difficulty (balance per difficulty)
#   ladder    — hard vs easy in both orientations (difficulty strength)
const RUNS := [
	{"scenario": "tut_00_basic_turn", "diffs": {"allies": "normal", "axis": "normal"}, "tag": "canary"},
	{"scenario": "north_00_gazala_1942", "diffs": {"axis": "easy", "allies": "easy"}, "tag": "symmetric"},
	{"scenario": "north_00_gazala_1942", "diffs": {"axis": "normal", "allies": "normal"}, "tag": "symmetric"},
	{"scenario": "north_00_gazala_1942", "diffs": {"axis": "hard", "allies": "hard"}, "tag": "symmetric"},
	{"scenario": "pacific_01_guadalcanal_1942", "diffs": {"allies": "easy", "axis": "easy"}, "tag": "symmetric"},
	{"scenario": "pacific_01_guadalcanal_1942", "diffs": {"allies": "normal", "axis": "normal"}, "tag": "symmetric"},
	{"scenario": "pacific_01_guadalcanal_1942", "diffs": {"allies": "hard", "axis": "hard"}, "tag": "symmetric"},
	{"scenario": "east_06_dnieper_1943", "diffs": {"soviet": "normal", "axis": "normal"}, "tag": "symmetric"},
	{"scenario": "03_stalingrad_1942", "diffs": {"soviet": "normal", "axis": "normal"}, "tag": "symmetric"},
	{"scenario": "04_kursk_1943", "diffs": {"axis": "normal", "soviet": "normal"}, "tag": "symmetric"},
	{"scenario": "01_sedan_1940", "diffs": {"axis": "normal", "allies": "normal"}, "tag": "symmetric"},
	{"scenario": "05_bastogne_1944", "diffs": {"allies": "normal", "axis": "normal"}, "tag": "symmetric"},
	{"scenario": "north_00_gazala_1942", "diffs": {"axis": "hard", "allies": "easy"}, "tag": "ladder"},
	{"scenario": "north_00_gazala_1942", "diffs": {"axis": "easy", "allies": "hard"}, "tag": "ladder"},
	{"scenario": "pacific_01_guadalcanal_1942", "diffs": {"allies": "hard", "axis": "easy"}, "tag": "ladder"},
	{"scenario": "pacific_01_guadalcanal_1942", "diffs": {"allies": "easy", "axis": "hard"}, "tag": "ladder"},
	{"scenario": "01_sedan_1940", "diffs": {"axis": "hard", "allies": "easy"}, "tag": "ladder"},
	{"scenario": "01_sedan_1940", "diffs": {"axis": "easy", "allies": "hard"}, "tag": "ladder"},
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var data_loader = root.get_node_or_null("DataLoader")
	if data_loader == null:
		printerr("Could not find DataLoader autoload")
		quit(1)
		return

	Engine.time_scale = 1000.0
	var records: Array[Dictionary] = []
	var failed := false
	for run_def in RUNS:
		var scenario_id := String(run_def["scenario"])
		var diffs: Dictionary = run_def["diffs"]
		var order: Array = _faction_order(data_loader, scenario_id)
		print("self-play: %s (%s)..." % [scenario_id, _matchup_label(order, diffs)])
		var result: Dictionary = await SelfPlayRunner.run_battle(self, scenario_id, diffs)
		result["diffs"] = diffs
		result["tag"] = String(run_def["tag"])
		result["order"] = order
		result["title"] = String(data_loader.get_scenario(scenario_id).get("title", scenario_id))
		records.append(result)
		if bool(result.get("stalled", false)) or bool(result.get("turn_capped", false)):
			printerr("self-play: %s did not resolve cleanly: %s" % [scenario_id, str(result)])
			failed = true
	Engine.time_scale = 1.0

	var report := _render_report(records)
	var output_path := ProjectSettings.globalize_path("res://docs/progress/ai_selfplay_report.md")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write AI self-play report: %s" % output_path)
		quit(1)
		return
	file.store_string(report)
	file.close()
	print("Wrote docs/progress/ai_selfplay_report.md")
	quit(1 if failed else 0)

func _faction_order(data_loader, scenario_id: String) -> Array:
	var out: Array = []
	for f in data_loader.get_scenario(scenario_id).get("factions", []):
		out.append(String(f.get("id", "")))
	return out

func _matchup_label(order: Array, diffs: Dictionary) -> String:
	var parts: Array[String] = []
	for fid in order:
		parts.append("%s:%s" % [fid, String(diffs.get(fid, "normal"))])
	return " vs ".join(parts)

func _exchange(record: Dictionary, fid: String) -> int:
	# HP the seat destroyed minus HP it lost. Zero-sum per run.
	var factions: Dictionary = record.get("factions", {})
	var own: Dictionary = factions.get(fid, {})
	var enemy_destroyed := 0
	for other_fid in factions.keys():
		if other_fid != fid:
			enemy_destroyed += int(factions[other_fid].get("destroyed_hp", 0))
	return enemy_destroyed - int(own.get("destroyed_hp", 0))

func _render_report(records: Array[Dictionary]) -> String:
	var lines: Array[String] = [
		"# AI Self-Play Report",
		"",
		"Deterministic full-battle self-play: every faction is driven by the live"
		+ " `AIController` through the real battle scene (`tools/selfplay_runner.gd`),"
		+ " so combat, morale, overwatch, reinforcements and victory all execute"
		+ " through game code. The engine has no RNG, so rerunning the generator"
		+ " yields byte-identical output until AI scoring, unit stats or scenario"
		+ " data change — regenerate it then with:",
		"",
		"`godot --headless --path . --script res://tools/ai_selfplay_report.gd`",
		"",
		"## Run matrix",
		"",
		"HP lost = hit points destroyed from that side's pool (reinforcements counted"
		+ " at full strength). A exchange = B hp lost - A hp lost, from side A's seat.",
		"",
		"| # | scenario | matchup | winner | end turn | A alive/start | A hp | B alive/start | B hp | A hp lost | B hp lost | A exchange |",
		"| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
	]
	var index := 0
	for record in records:
		index += 1
		var order: Array = record["order"]
		var a := String(order[0])
		var b := String(order[1])
		var factions: Dictionary = record.get("factions", {})
		var fa: Dictionary = factions.get(a, {})
		var fb: Dictionary = factions.get(b, {})
		var winner := String(record.get("winner", ""))
		if bool(record.get("stalled", false)):
			winner = "(stalled)"
		elif bool(record.get("turn_capped", false)):
			winner = "(turn-cap)"
		lines.append("| %d | %s | %s | %s | %d | %d/%d | %d | %d/%d | %d | %d | %d | %d |" % [
			index,
			String(record["scenario_id"]),
			_matchup_label(order, record["diffs"]),
			winner,
			int(record.get("end_turn", 0)),
			int(fa.get("alive_units", 0)), int(fa.get("start_units", 0)), int(fa.get("remaining_hp", 0)),
			int(fb.get("alive_units", 0)), int(fb.get("start_units", 0)), int(fb.get("remaining_hp", 0)),
			int(fa.get("destroyed_hp", 0)),
			int(fb.get("destroyed_hp", 0)),
			_exchange(record, a),
		])

	lines.append_array([
		"",
		"## Difficulty ladder",
		"",
		"For each scenario the attacking seat plays hard-vs-easy and easy-vs-hard."
		+ " The seat's HP exchange must not get worse when it is the stronger side"
		+ " (exchange is zero-sum, so one comparison covers both seats).",
		"",
		"| scenario | seat | exchange @ hard | exchange @ easy | delta | verdict |",
		"| --- | --- | --- | --- | --- | --- |",
	])
	var ladder_by_scenario: Dictionary = {}
	for record in records:
		if String(record.get("tag", "")) != "ladder":
			continue
		var scenario_id := String(record["scenario_id"])
		var seat := String(record["order"][0])  # first faction = attacking seat
		var seat_diff := String(record["diffs"].get(seat, "normal"))
		var entry: Dictionary = ladder_by_scenario.get(scenario_id, {"seat": seat})
		entry[seat_diff] = _exchange(record, seat)
		ladder_by_scenario[scenario_id] = entry
	for scenario_id in ladder_by_scenario.keys():
		var entry: Dictionary = ladder_by_scenario[scenario_id]
		var hard_x := int(entry.get("hard", 0))
		var easy_x := int(entry.get("easy", 0))
		lines.append("| %s | %s | %d | %d | %d | %s |" % [
			scenario_id, String(entry["seat"]), hard_x, easy_x, hard_x - easy_x,
			"PASS" if hard_x >= easy_x else "FAIL",
		])

	lines.append_array([
		"",
		"## Symmetric balance summary",
		"",
		"Mirror matches (both sides at the same difficulty). Attacker = the scenario's"
		+ " first faction (capture/eliminate objective); defender wins by surviving.",
		"",
		"| difficulty | runs | attacker wins | defender wins | mean attacker exchange |",
		"| --- | --- | --- | --- | --- |",
	])
	for diff_level in ["easy", "normal", "hard"]:
		var runs := 0
		var attacker_wins := 0
		var defender_wins := 0
		var exchange_sum := 0
		for record in records:
			var tag := String(record.get("tag", ""))
			if tag != "symmetric" and tag != "canary":
				continue
			var a := String(record["order"][0])
			if String(record["diffs"].get(a, "")) != diff_level:
				continue
			runs += 1
			exchange_sum += _exchange(record, a)
			if String(record.get("winner", "")) == a:
				attacker_wins += 1
			else:
				defender_wins += 1
		if runs == 0:
			continue
		lines.append("| %s | %d | %d | %d | %.1f |" % [
			diff_level, runs, attacker_wins, defender_wins, float(exchange_sum) / float(runs),
		])

	lines.append_array([
		"",
		"## Morale activity",
		"",
		"Distinct units routed and reform events (a routed unit recovering back over"
		+ " the reform threshold), read from live battle state. At least one must fire"
		+ " across the whole suite, or the morale/rout layer has silently stopped"
		+ " engaging.",
		"",
		"| # | scenario | matchup | routs | reforms |",
		"| --- | --- | --- | --- | --- |",
	])
	var total_routs := 0
	var total_reforms := 0
	var morale_index := 0
	for record in records:
		morale_index += 1
		var r_routs := int(record.get("routs", 0))
		var r_reforms := int(record.get("reforms", 0))
		total_routs += r_routs
		total_reforms += r_reforms
		lines.append("| %d | %s | %s | %d | %d |" % [
			morale_index, String(record["scenario_id"]),
			_matchup_label(record["order"], record["diffs"]), r_routs, r_reforms,
		])
	lines.append("")
	lines.append("Across all runs: %d routs, %d reforms." % [total_routs, total_reforms])

	lines.append_array(["", "## Notes", ""])
	var notes: Array[String] = []
	var note_index := 0
	for record in records:
		note_index += 1
		if bool(record.get("stalled", false)):
			notes.append("- Run %d (%s) STALLED — driver watchdog tripped." % [note_index, record["scenario_id"]])
		if bool(record.get("turn_capped", false)):
			notes.append("- Run %d (%s) hit the hard turn cap without a winner." % [note_index, record["scenario_id"]])
		var factions: Dictionary = record.get("factions", {})
		for fid in factions.keys():
			if int(factions[fid].get("destroyed_hp", 0)) == 0:
				notes.append("- Run %d (%s): %s took zero damage — possible no-contact pattern." % [
					note_index, record["scenario_id"], fid,
				])
	if notes.is_empty():
		notes.append("- No pathologies detected: every run resolved with a winner and two-sided contact.")
	lines.append_array(notes)
	return "\n".join(lines) + "\n"
