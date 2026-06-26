extends SceneTree

# Regression test for the one-action-per-turn rule. A ranged unit (e.g. artillery)
# can attack before moving, leaving has_attacked=true / has_moved=false so it stays
# re-selectable to move — but it must NOT get a second attack. We place a player
# unit next to an enemy so it WOULD have a target, then verify that once it has
# acted, _enter_attack_phase offers no targets and hides the action buttons.

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const CombatEffects := preload("res://scripts/combat/combat_effects.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		printerr("FAIL: missing GameState autoload")
		quit(1)
		return
	var data_loader := root.get_node_or_null("DataLoader")
	if data_loader == null:
		printerr("FAIL: missing DataLoader autoload")
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
				"rewards": [{"type": "xp", "amount": 1}],
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

		# Hold-turn secondary objectives progress at faction end-turn, reset when
		# the point is empty, and pay out only once when the required hold is met.
		var hold_coord := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) == null:
				hold_coord = c
				break
		if hold_coord == Vector2i(-999, -999):
			fail_count += 1
			printerr("FAIL: could not stage an empty hold objective hex")
		else:
			var original_scenario_hold: Dictionary = battle.scenario.duplicate(true)
			var hold_offset := _axial_to_offset(hold_coord)
			battle.scenario["secondary_objectives"] = [{
				"id": "test_hold",
				"type": "hold_turns",
				"label": "守備點",
				"faction": battle.player_faction_id,
				"target": [hold_offset.x, hold_offset.y],
				"required_turns": 2,
				"rewards": [{"type": "xp", "amount": 1}],
			}]
			battle.captured_secondary_objectives.clear()
			battle.secondary_objective_progress.clear()
			var hold_before_xp := int(player_unit.xp)
			battle._check_secondary_objective_hold_turns(battle.player_faction_id)
			if int(battle.secondary_objective_progress.get("test_hold", -1)) == -1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: empty hold objective should not start progress")
			battle.hex_map.move_unit(player_unit, hold_coord, 0.0)
			player_unit.has_moved = false
			var first_hold: Array[String] = battle._check_secondary_objective_hold_turns(battle.player_faction_id)
			if int(battle.secondary_objective_progress.get("test_hold", 0)) == 1 \
					and not battle.captured_secondary_objectives.has("test_hold") \
					and first_hold.size() == 1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: first held turn should track progress 1/2")
			battle._apply_player_objective_pulse()
			var hold_labels: Array[String] = []
			for overlay in battle.hex_map.objective_overlays:
				for child in overlay.get_children():
					if child.name == "ObjectiveLabel":
						hold_labels.append(String(child.text))
			battle._update_status()
			if _labels_contain(hold_labels, "守備:守備點 1/2") \
					and battle.status_label.text.find("守備:守備點 1/2") != -1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: hold objective progress should be visible; labels=%s status=%s" % [
					str(hold_labels), battle.status_label.text,
				])
			var clear_coord := Vector2i(-999, -999)
			for c in battle.hex_map.tiles.keys():
				if battle.hex_map.unit_at(c) == null and c != hold_coord:
					clear_coord = c
					break
			if clear_coord == Vector2i(-999, -999):
				fail_count += 1
				printerr("FAIL: could not stage a clear hex for hold reset")
			else:
				battle.hex_map.move_unit(player_unit, clear_coord, 0.0)
				player_unit.has_moved = false
				battle._check_secondary_objective_hold_turns(battle.player_faction_id)
				if int(battle.secondary_objective_progress.get("test_hold", -1)) == 0:
					pass_count += 1
				else:
					fail_count += 1
					printerr("FAIL: leaving hold objective should reset progress to 0")
			battle.hex_map.move_unit(player_unit, hold_coord, 0.0)
			player_unit.has_moved = false
			battle._check_secondary_objective_hold_turns(battle.player_faction_id)
			battle._check_secondary_objective_hold_turns(battle.player_faction_id)
			battle._check_secondary_objective_hold_turns(battle.player_faction_id)
			var hold_events := 0
			for event in battle.action_log.events:
				if String(event.get("type", "")) == "secondary_objective" and String(event.get("objective_id", "")) == "test_hold":
					hold_events += 1
			if int(player_unit.xp) == hold_before_xp + 1 and hold_events == 1 \
					and battle.captured_secondary_objectives.has("test_hold"):
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: hold objective should grant XP once; xp %d->%d events=%d captured=%s" % [
					hold_before_xp, int(player_unit.xp), hold_events, battle.captured_secondary_objectives.has("test_hold"),
				])
			battle.scenario = original_scenario_hold
			battle.captured_secondary_objectives.clear()
			battle.secondary_objective_progress.clear()

		var original_scenario_rewards: Dictionary = battle.scenario.duplicate(true)
		var original_spawned_reinforcements: Dictionary = battle.spawned_reinforcements.duplicate(true)
		var original_turn_number: int = battle.turn_manager.turn_number
		var original_hp: int = player_unit.hp
		var original_suppression: int = player_unit.suppression
		battle.scenario["reinforcements"] = [
			{"at_turn": 6, "faction": player_unit.faction_id, "type": "infantry", "name": "Friendly Future", "at": [0, 0]},
			{"at_turn": 2, "faction": player_unit.faction_id, "type": "infantry", "name": "Friendly Soon", "at": [0, 0]},
			{"at_turn": 6, "faction": "enemy_test", "type": "infantry", "name": "Enemy Future", "at": [0, 0]},
		]
		battle.spawned_reinforcements.clear()
		battle.turn_manager.turn_number = 2
		player_unit.suppression = 4
		player_unit.hp = max(1, player_unit.max_hp - 3)
		var reward_before_xp := int(player_unit.xp)
		var reward_text: String = battle._complete_secondary_objective(player_unit, {
			"id": "reward_combo",
			"label": "戰地補給",
			"rewards": [
				{"type": "xp", "amount": 1},
				{"type": "recover_suppression", "amount": 2},
				{"type": "repair_hp", "amount": 3},
				{"type": "advance_reinforcements", "amount": 2},
			],
		}, "reward_combo", "完成")
		var reward_reinforcements: Array = battle.scenario.get("reinforcements", [])
		if int(player_unit.xp) == reward_before_xp + 1 \
				and int(player_unit.suppression) == 2 \
				and int(player_unit.hp) == player_unit.max_hp \
				and int(reward_reinforcements[0].get("at_turn", 0)) == 4 \
				and int(reward_reinforcements[1].get("at_turn", 0)) == 2 \
				and int(reward_reinforcements[2].get("at_turn", 0)) == 6 \
				and reward_text.find("戰地補給") != -1 \
				and reward_text.find("援軍提前 2T") != -1:
			pass_count += 1
		else:
			fail_count += 1
			printerr("FAIL: secondary reward effects should apply deterministically; text=%s xp %d->%d hp=%d suppression=%d reinforcements=%s" % [
				reward_text, reward_before_xp, int(player_unit.xp), int(player_unit.hp),
				int(player_unit.suppression), str(reward_reinforcements),
			])
		battle.scenario = original_scenario_rewards
		battle.spawned_reinforcements = original_spawned_reinforcements
		battle.turn_manager.turn_number = original_turn_number
		player_unit.hp = original_hp
		player_unit.suppression = original_suppression
		battle.captured_secondary_objectives.clear()
		battle.secondary_objective_progress.clear()

		# Light tanks can spend their action to mark a visible LOS target; the next
		# same-faction active non-lethal hit consumes the mark and adds suppression.
		var mark_spotter = player_unit
		var mark_attacker = null
		for u in battle.units:
			if u != mark_spotter and u.faction_id == battle.player_faction_id:
				mark_attacker = u
				break
		var mark_target = null
		for u in battle.units:
			if u.faction_id != battle.player_faction_id:
				mark_target = u
				break
		if mark_attacker == null or mark_target == null:
			fail_count += 1
			printerr("FAIL: could not stage units for fire-support mark test")
		else:
			mark_spotter.type_id = "light_tank"
			mark_spotter.has_moved = false
			mark_spotter.has_attacked = false
			mark_spotter.skill_cooldowns.clear()
			mark_attacker.type_id = "infantry"
			mark_attacker.has_attacked = false
			mark_attacker.suppression = 0
			mark_target.type_id = "infantry"
			mark_target.hp = mark_target.max_hp
			mark_target.suppression = 0
			mark_target.dig_in_level = 0
			var target_coord := Vector2i(-999, -999)
			var spotter_coord := Vector2i(-999, -999)
			var attacker_coord := Vector2i(-999, -999)
			var staged := false
			for c in battle.hex_map.tiles.keys():
				var center_terrain: String = battle.hex_map.terrain_at(c)
				if center_terrain == "" or battle.hex_map.terrain_impassable(center_terrain):
					continue
				if battle.hex_map.unit_at(c) != null and battle.hex_map.unit_at(c) != mark_target:
					continue
				var open_neighbors: Array = []
				for nb in HexCoord.neighbors(c):
					var terrain: String = battle.hex_map.terrain_at(nb)
					if terrain != "" and not battle.hex_map.terrain_impassable(terrain) \
							and battle.hex_map.unit_at(nb) == null:
						open_neighbors.append(nb)
				if open_neighbors.size() >= 2:
					target_coord = c
					spotter_coord = open_neighbors[0]
					attacker_coord = open_neighbors[1]
					staged = true
					break
			if not staged:
				fail_count += 1
				printerr("FAIL: could not stage adjacent open hexes for fire-support mark test")
			else:
				battle.hex_map.move_unit(mark_target, target_coord, 0.0)
				battle.hex_map.move_unit(mark_spotter, spotter_coord, 0.0)
				battle.hex_map.move_unit(mark_attacker, attacker_coord, 0.0)
				mark_target.has_moved = false
				mark_spotter.has_moved = false
				mark_attacker.has_moved = false
				battle._recompute_visibility()
				var mark_skill: Dictionary = battle._resolve_skill_by_id(mark_spotter, "fire_support_mark")
				var mark_targets: Array = battle._fire_support_targets(mark_spotter, mark_skill)
				battle.selected_unit = mark_spotter
				battle.phase = battle.Phase.UNIT_SELECTED
				battle.fire_support_return_phase = battle.Phase.UNIT_SELECTED
				battle.fire_support_targets = mark_targets
				battle._cancel_fire_support_mark()
				if battle.phase == battle.Phase.UNIT_SELECTED \
						and battle.selected_unit == mark_spotter \
						and not battle.movement_range.is_empty():
					pass_count += 1
				else:
					fail_count += 1
					printerr("FAIL: cancelling fire-support from selection should restore movement phase")
				mark_targets = battle._fire_support_targets(mark_spotter, mark_skill)
				battle.fire_support_skill = mark_skill
				battle._do_fire_support_mark(mark_spotter, mark_target)
				var mark_key: int = battle._fire_support_mark_key(mark_target)
				if mark_target in mark_targets \
						and mark_spotter.has_attacked \
						and mark_spotter.skill_cooldowns.has("fire_support_mark") \
						and battle.fire_support_marks.has(mark_key):
					pass_count += 1
				else:
					fail_count += 1
					printerr("FAIL: fire-support mark should target, spend action and start cooldown")
				var base_suppression := CombatEffects.suppression_for_attack(
					data_loader.get_unit_def(mark_attacker.type_id), 1, false
				)
				var preview_bonus: int = battle._fire_support_preview_bonus(mark_attacker, mark_target, 1, false)
				var support_bonus: int = battle._fire_support_suppression_bonus(mark_attacker, mark_target, 1, false)
				if preview_bonus == CombatEffects.FIRE_SUPPORT_SUPPRESSION_BONUS \
						and support_bonus == CombatEffects.FIRE_SUPPORT_SUPPRESSION_BONUS \
						and not battle.fire_support_marks.has(mark_key) \
						and base_suppression + support_bonus == 2:
					pass_count += 1
				else:
					fail_count += 1
					printerr("FAIL: fire-support bonus should preview, apply once and consume; preview=%d bonus=%d marked=%s" % [
						preview_bonus, support_bonus, battle.fire_support_marks.has(mark_key),
					])

		# Destroy-unit and recon secondary objectives complete from combat and visibility events.
		var unit_script: Script = player_unit.get_script()
		var destroy_target = unit_script.new()
		var destroy_enemy_faction := ""
		var destroy_enemy_color := Color(0.2, 0.4, 0.8)
		for fid in battle.factions.keys():
			if String(fid) != player_unit.faction_id:
				destroy_enemy_faction = String(fid)
				destroy_enemy_color = battle.factions[fid].get("color", destroy_enemy_color)
				break
		var destroy_coord := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) == null:
				destroy_coord = c
				break
		destroy_target.configure("infantry", destroy_enemy_faction, destroy_enemy_color, destroy_coord, "Target Truck")
		destroy_target.scenario_unit_id = "target_truck"
		var original_scenario_destroy: Dictionary = battle.scenario.duplicate(true)
		battle.scenario["secondary_objectives"] = [{
			"id": "destroy_truck",
			"type": "destroy_unit",
			"label": "摧毀補給車",
			"faction": battle.player_faction_id,
			"target_unit": "target_truck",
			"rewards": [{"type": "xp", "amount": 1}],
		}]
		battle.captured_secondary_objectives.clear()
		battle.units.append(destroy_target)
		if destroy_coord == Vector2i(-999, -999) or not battle.hex_map.register_unit(destroy_target):
			fail_count += 1
			printerr("FAIL: could not stage a destroy-unit objective target")
		else:
			battle._apply_player_objective_pulse()
			battle._update_status()
			var destroy_labels: Array[String] = []
			for overlay in battle.hex_map.objective_overlays:
				for child in overlay.get_children():
					if child.name == "ObjectiveLabel":
						destroy_labels.append(String(child.text))
			if _labels_contain(destroy_labels, "殲滅:摧毀補給車") \
					and battle.status_label.text.find("殲滅:摧毀補給車") != -1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: destroy objective marker/status should be explicit; labels=%s status=%s" % [
					str(destroy_labels), battle.status_label.text,
				])
		var destroy_before_xp := int(player_unit.xp)
		var destroy_text: String = battle._check_secondary_objective_destroy_unit(player_unit, destroy_target)
		var destroy_repeat: String = battle._check_secondary_objective_destroy_unit(player_unit, destroy_target)
		var destroy_events := 0
		for event in battle.action_log.events:
			if String(event.get("type", "")) == "secondary_objective" and String(event.get("objective_id", "")) == "destroy_truck":
				destroy_events += 1
		if destroy_text.find("摧毀補給車") != -1 and destroy_repeat == "" \
				and int(player_unit.xp) == destroy_before_xp + 1 and destroy_events == 1:
			pass_count += 1
		else:
			fail_count += 1
			printerr("FAIL: destroy-unit secondary objective should complete once; text=%s repeat=%s xp %d->%d events=%d" % [
				destroy_text, destroy_repeat, destroy_before_xp, int(player_unit.xp), destroy_events,
			])
		battle.hex_map.unregister_unit(destroy_target)
		battle.units.erase(destroy_target)
		destroy_target.queue_free()

		var splash_attacker_coord := Vector2i(-999, -999)
		var splash_primary_coord := Vector2i(-999, -999)
		var splash_target_coord := Vector2i(-999, -999)
		for c in battle.hex_map.tiles.keys():
			if battle.hex_map.unit_at(c) != null:
				continue
			for nb in HexCoord.neighbors(c):
				if battle.hex_map.terrain_at(nb) == "" or battle.hex_map.unit_at(nb) != null:
					continue
				for nb2 in HexCoord.neighbors(nb):
					if nb2 == c:
						continue
					if battle.hex_map.terrain_at(nb2) != "" and battle.hex_map.unit_at(nb2) == null:
						splash_attacker_coord = c
						splash_primary_coord = nb
						splash_target_coord = nb2
						break
				if splash_target_coord != Vector2i(-999, -999):
					break
			if splash_target_coord != Vector2i(-999, -999):
				break
		if splash_target_coord == Vector2i(-999, -999):
			fail_count += 1
			printerr("FAIL: could not stage splash destroy-unit objective")
		else:
			battle.hex_map.tiles[splash_attacker_coord] = "plain"
			battle.hex_map.tiles[splash_primary_coord] = "plain"
			battle.hex_map.tiles[splash_target_coord] = "plain"
			var splash_attacker = unit_script.new()
			splash_attacker.configure("rocket_artillery", player_unit.faction_id, player_unit.faction_color, splash_attacker_coord, "Test Rocket")
			var splash_primary = unit_script.new()
			splash_primary.configure("infantry", destroy_enemy_faction, destroy_enemy_color, splash_primary_coord, "Splash Primary")
			var splash_target = unit_script.new()
			splash_target.configure("infantry", destroy_enemy_faction, destroy_enemy_color, splash_target_coord, "Splash Target")
			splash_target.scenario_unit_id = "splash_target"
			splash_primary.hp = 1
			splash_target.hp = 1
			battle.hex_map.register_unit(splash_attacker)
			battle.hex_map.register_unit(splash_primary)
			battle.hex_map.register_unit(splash_target)
			battle.units.append(splash_attacker)
			battle.units.append(splash_primary)
			battle.units.append(splash_target)
			battle.scenario["secondary_objectives"] = [{
				"id": "destroy_splash_target",
				"type": "destroy_unit",
				"label": "濺射目標",
				"faction": battle.player_faction_id,
				"target_unit": "splash_target",
				"rewards": [{"type": "xp", "amount": 1}],
			}]
			battle.captured_secondary_objectives.clear()
			var splash_before_xp := int(splash_attacker.xp)
			var splash_result: Dictionary = battle._apply_splash(
				splash_attacker,
				data_loader.get_unit_def("rocket_artillery"),
				splash_primary.coord,
				splash_primary
			)
			var splash_events := 0
			for event in battle.action_log.events:
				if String(event.get("type", "")) == "secondary_objective" and String(event.get("objective_id", "")) == "destroy_splash_target":
					splash_events += 1
			var splash_destroy_messages: Array = splash_result.get("destroy_messages", [])
			if int(splash_result.get("hit", 0)) == 1 \
					and splash_destroy_messages.size() == 1 \
					and String(splash_destroy_messages[0]).find("濺射目標") != -1 \
					and battle.captured_secondary_objectives.has("destroy_splash_target") \
					and int(splash_attacker.xp) == splash_before_xp + 4 \
					and splash_events == 1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: splash kill should complete destroy objective; result=%s xp %d->%d events=%d captured=%s" % [
					str(splash_result), splash_before_xp, int(splash_attacker.xp), splash_events,
					battle.captured_secondary_objectives.has("destroy_splash_target"),
				])
			battle.hex_map.unregister_unit(splash_attacker)
			battle.hex_map.unregister_unit(splash_primary)
			battle.hex_map.unregister_unit(splash_target)
			battle.units.erase(splash_attacker)
			battle.units.erase(splash_primary)
			battle.units.erase(splash_target)
			splash_attacker.queue_free()
			splash_primary.queue_free()
			splash_target.queue_free()

		battle._recompute_visibility()
		var recon_coord: Vector2i = player_unit.coord
		if battle.hex_map.terrain_at(recon_coord) == "":
			fail_count += 1
			printerr("FAIL: could not stage a visible recon objective hex")
		else:
			var recon_offset := _axial_to_offset(recon_coord)
			battle.scenario["secondary_objectives"] = [{
				"id": "recon_crossroad",
				"type": "recon_hex",
				"label": "偵察路口",
				"faction": battle.player_faction_id,
				"target": [recon_offset.x, recon_offset.y],
				"rewards": [{"type": "xp", "amount": 1}],
			}]
			battle.captured_secondary_objectives.clear()
			var recon_before_xp := int(player_unit.xp)
			var recon_messages: Array[String] = battle._check_secondary_objective_recon_hex(battle.player_faction_id)
			var recon_repeat: Array[String] = battle._check_secondary_objective_recon_hex(battle.player_faction_id)
			if recon_messages.size() == 1 and recon_messages[0].find("偵察路口") != -1 \
					and recon_repeat.is_empty() and int(player_unit.xp) == recon_before_xp + 1:
				pass_count += 1
			else:
				fail_count += 1
				printerr("FAIL: recon secondary objective should complete once; messages=%s repeat=%s xp %d->%d" % [
					str(recon_messages), str(recon_repeat), recon_before_xp, int(player_unit.xp),
				])
		battle.scenario = original_scenario_destroy
		battle.captured_secondary_objectives.clear()

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

func _labels_contain(labels: Array[String], needle: String) -> bool:
	for label in labels:
		if label.find(needle) != -1:
			return true
	return false
