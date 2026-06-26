extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var pass_count := 0
	var fail_count := 0

	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		printerr("FAIL: GameState autoload missing")
		quit(1)
		return

	var deployment := await _instantiate_deployment("tut_03_suppression_digin_engineer")
	var pinned = _unit_named(deployment, "被壓制步兵")
	var dug_in = _unit_named(deployment, "構工守軍")
	if pinned != null and int(pinned.suppression) == 4 and dug_in != null and int(dug_in.dig_in_level) == 3:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: tutorial initial suppression/dig-in not applied")
	await _free_scene(deployment)

	var veteran_deploy := await _instantiate_deployment("tut_04_armor_at_veteran_general")
	var veteran = _unit_named(veteran_deploy, "老兵 Sherman")
	if veteran != null and int(veteran.rank) == 2 and int(veteran.xp) == 6 and String(veteran.general_id) == "patton":
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: tutorial initial veteran/general state not applied")
	await _free_scene(veteran_deploy)

	print("UnitFactory initial state tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _instantiate_deployment(scenario_id: String) -> Node:
	var game_state := root.get_node_or_null("GameState")
	game_state.current_scenario_id = scenario_id
	game_state.current_campaign_id = ""
	game_state.campaign_mode = false
	game_state.conquest_mode = false
	game_state.clear_conquest_battle()
	var packed := load("res://scenes/deployment.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene

func _free_scene(scene: Node) -> void:
	if scene != null:
		scene.queue_free()
		await process_frame

func _unit_named(scene: Node, name: String):
	if scene == null:
		return null
	for unit in scene.units:
		if String(unit.display_name) == name:
			return unit
	return null
