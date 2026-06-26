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
		if not battle.overwatch_button.visible and not battle.rally_button.visible and battle.skill_buttons.is_empty():
			pass_count += 1
		else:
			printerr("FAIL: action buttons still visible after the unit has acted")
			fail_count += 1

		# A unit that has fired (even without moving) is done — it cannot move after.
		player_unit.has_moved = false
		if player_unit.is_done_for_turn():
			pass_count += 1
		else:
			printerr("FAIL: a unit that has fired should be done (no move after firing)")
			fail_count += 1

		# Backing out of the attack menu (clicking empty) must NOT spend the action.
		player_unit.has_moved = false
		player_unit.has_attacked = false
		battle.selected_unit = player_unit
		battle._enter_attack_phase()
		var empty_hex := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) == null:
				empty_hex = c
				break
		battle._on_hex_clicked(empty_hex, battle.hex_map.terrain_at(empty_hex))
		if not player_unit.has_attacked:
			pass_count += 1
		else:
			printerr("FAIL: backing out of the attack menu spent the unit's action")
			fail_count += 1

		# Engineer bridge: an adjacent water hex becomes passable; bridging is the action.
		player_unit.type_id = "engineer"
		player_unit.has_attacked = false
		var water := Vector2i(-999, -999)
		for nb in HexCoord.neighbors(player_unit.coord):
			if battle.hex_map.terrain_at(nb) != "" and battle.hex_map.unit_at(nb) == null:
				water = nb
				break
		if water != Vector2i(-999, -999):
			battle.hex_map.tiles[water] = "river"  # force an adjacent impassable water hex
			var btargets: Array = battle._engineer_bridge_targets(player_unit)
			battle._do_bridge(player_unit, water)
			if water in btargets and battle.hex_map.is_bridged(water) and player_unit.has_attacked:
				pass_count += 1
			else:
				printerr("FAIL: engineer bridge: in_targets=%s bridged=%s acted=%s" % [
					water in btargets, battle.hex_map.is_bridged(water), player_unit.has_attacked,
				])
				fail_count += 1
		else:
			printerr("FAIL: could not stage an adjacent hex for the bridge test")
			fail_count += 1

		# Secondary objectives highlight alongside the primary target and grant their one-time XP reward.
		var secondary_coord := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) == null:
				secondary_coord = c
				break
		if secondary_coord == Vector2i(-999, -999):
			fail_count += 1
			printerr("FAIL: could not stage an empty secondary objective hex")
		else:
			var original_scenario: Dictionary = battle.scenario.duplicate(true)
			var primary_offset := _axial_to_offset(Vector2i(0, 0))
			var secondary_offset := _axial_to_offset(secondary_coord)
			battle.scenario["victory"] = {
				battle.player_faction_id: {
					"type": "capture",
					"target": [primary_offset.x, primary_offset.y],
					"by_turn": 9,
				}
			}
			battle.scenario["secondary_objectives"] = [{
				"id": "test_cache",
				"label": "Test Cache",
				"faction": battle.player_faction_id,
				"target": [secondary_offset.x, secondary_offset.y],
				"xp_reward": 1,
			}]
			battle._apply_player_objective_pulse()
			if battle.hex_map.objective_overlays.size() == 2:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: primary + secondary objective overlays expected 2 got %d" % battle.hex_map.objective_overlays.size())
			var before_xp := int(player_unit.xp)
			battle.hex_map.move_unit(player_unit, secondary_coord, 0.0)
			player_unit.has_moved = false
			battle._check_secondary_objective_capture(player_unit)
			battle._check_secondary_objective_capture(player_unit)
			var secondary_events := 0
			for event in battle.action_log.events:
				if String(event.get("type", "")) == "secondary_objective" and String(event.get("objective_id", "")) == "test_cache":
					secondary_events += 1
			if int(player_unit.xp) == before_xp + 1 and secondary_events == 1 \
					and battle.hex_map.objective_overlays.size() == 1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: secondary objective should grant XP once and clear overlay; xp %d->%d events=%d overlays=%d" % [
					before_xp, int(player_unit.xp), secondary_events, battle.hex_map.objective_overlays.size(),
				])
			battle.scenario = original_scenario

		# MG overwatch uses its unit-data reaction-fire profile: full damage instead of the default half hit.
		var mg_coord := Vector2i(-999, -999)
		var target_coord := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) != null:
				continue
			for nb in HexCoord.neighbors(c):
				if battle.hex_map.terrain_at(nb) != "" and battle.hex_map.unit_at(nb) == null:
					mg_coord = c
					target_coord = nb
					break
			if mg_coord != Vector2i(-999, -999):
				break
		if mg_coord == Vector2i(-999, -999):
			fail_count += 1
			printerr("FAIL: could not stage adjacent empty hexes for MG overwatch test")
		else:
			battle.hex_map.tiles[mg_coord] = "plain"
			battle.hex_map.tiles[target_coord] = "plain"
			var unit_script: Script = player_unit.get_script()
			var mg = unit_script.new()
			mg.configure("mg_team", player_unit.faction_id, player_unit.faction_color, mg_coord, "Test MG")
			var target = unit_script.new()
			var enemy_faction := ""
			var enemy_color := Color(0.2, 0.4, 0.8)
			for fid in battle.factions.keys():
				if String(fid) != player_unit.faction_id:
					enemy_faction = String(fid)
					enemy_color = battle.factions[fid].get("color", enemy_color)
					break
			target.configure("infantry", enemy_faction, enemy_color, target_coord, "Test Target")
			battle.hex_map.register_unit(mg)
			battle.hex_map.register_unit(target)
			battle.units.append(mg)
			battle.units.append(target)
			var mg_overwatch_damage: int = battle._compute_overwatch_damage(mg, target, target.coord)
			if mg_overwatch_damage == 4:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: MG overwatch should deal full 4 damage, got %d" % mg_overwatch_damage)
			battle.hex_map.unregister_unit(mg)
			battle.hex_map.unregister_unit(target)
			battle.units.erase(mg)
			battle.units.erase(target)
			mg.queue_free()
			target.queue_free()

	battle.queue_free()
	await process_frame
	print("Battle action economy tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _axial_to_offset(coord: Vector2i) -> Vector2i:
	return Vector2i(coord.x + (coord.y >> 1), coord.y)
