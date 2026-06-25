extends SceneTree

# Regression test for the one-action-per-turn rule. A ranged unit (e.g. artillery)
# can attack before moving, leaving has_attacked=true / has_moved=false so it stays
# re-selectable to move — but it must NOT get a second attack. We place a player
# unit next to an enemy so it WOULD have a target, then verify that once it has
# acted, _enter_attack_phase offers no targets and hides the action buttons.

const HexCoord := preload("res://scripts/grid/hex_coord.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		printerr("FAIL: missing GameState autoload")
		quit(1)
		return
	game_state.current_scenario_id = "00_sandbox"
	game_state.campaign_mode = false
	game_state.clear_conquest_battle()

	var battle: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	var pass_count := 0
	var fail_count := 0

	var player_unit = null
	for u in battle.units:
		if u.faction_id == battle.player_faction_id:
			player_unit = u
			break

	# Place the player unit on a free land hex next to any enemy, so a fresh unit
	# genuinely has an attack target to find.
	var placed := false
	if player_unit != null:
		for e in battle.units:
			if e.faction_id == battle.player_faction_id:
				continue
			for nb in HexCoord.neighbors(e.coord):
				var terrain: String = battle.hex_map.terrain_at(nb)
				if terrain != "" and terrain != "sea" and battle.hex_map.unit_at(nb) == null:
					battle.hex_map.move_unit(player_unit, nb, 0.0)
					placed = true
					break
			if placed:
				break

	if player_unit == null or not placed:
		printerr("FAIL: could not stage a player unit adjacent to an enemy")
		fail_count += 1
	else:
		battle._recompute_visibility()
		battle.selected_unit = player_unit

		# Fresh unit: it can attack the adjacent enemy.
		player_unit.has_moved = false
		player_unit.has_attacked = false
		battle._enter_attack_phase()
		if not battle.attack_targets.is_empty():
			pass_count += 1
		else:
			printerr("FAIL: a fresh adjacent unit found no attack target (test setup)")
			fail_count += 1

		# Same unit after it has already acted: no second attack, no action buttons.
		player_unit.has_attacked = true
		battle._enter_attack_phase()
		if battle.attack_targets.is_empty():
			pass_count += 1
		else:
			printerr("FAIL: an already-attacked unit was still offered attack targets")
			fail_count += 1
		if not battle.overwatch_button.visible and not battle.rally_button.visible and not battle.skill_button.visible:
			pass_count += 1
		else:
			printerr("FAIL: action buttons still visible after the unit has acted")
			fail_count += 1

	battle.queue_free()
	await process_frame
	print("Battle action economy tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
