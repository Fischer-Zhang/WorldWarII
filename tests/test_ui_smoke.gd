extends SceneTree

const SCENE_CASES := [
	{
		"name": "main_menu",
		"path": "res://scenes/main_menu.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["VBox", "VBox/SingleBattleButton", "VBox/CampaignButton", "VBox/ConquestButton", "VBox/HelpButton"],
	},
	{
		"name": "help",
		"path": "res://scenes/help.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["Margin/VBox/Title", "Margin/VBox/HelpScroll/HelpText", "Margin/VBox/BackButton"],
	},
	{
		"name": "scenario_select",
		"path": "res://scenes/scenario_select.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["Margin/VBox/CategoryRow", "Margin/VBox/DifficultyRow", "Margin/VBox/ListScroll/List"],
	},
	{
		"name": "briefing",
		"path": "res://scenes/briefing.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["Margin/VBox/Title", "Margin/VBox/BriefingScroll/Briefing", "Margin/VBox/Buttons/BeginButton"],
	},
	{
		"name": "deployment",
		"path": "res://scenes/deployment.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["UI/Root/Body/LeftPanel/UnitScroll/UnitList", "UI/Root/Body/RightPanel/Detail", "UI/Root/BottomBar/BeginButton"],
	},
	{
		"name": "battle",
		"path": "res://scenes/battle.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["UI/InfoPanel", "UI/EndTurnButton", "UI/ResultPanel", "UI/LegendButton", "UI/LegendPanel/LegendScroll/LegendText"],
	},
	{
		"name": "campaign",
		"path": "res://scenes/campaign.tscn",
		"scenario_id": "",
		"campaign_mode": true,
		"conquest_mode": false,
		"required": ["Margin/VBox/ListScroll/List", "Margin/VBox/Buttons/ContinueButton", "Margin/VBox/Buttons/BackButton"],
	},
	{
		"name": "lounge",
		"path": "res://scenes/lounge.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
		"required": ["Margin/VBox/Body/GeneralsPanel/GeneralsScroll/GeneralsList", "Margin/VBox/Body/TechPanel/TechScroll/TechList", "Margin/VBox/BackButton"],
	},
	{
		"name": "conquest",
		"path": "res://scenes/conquest.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": true,
		"required": ["Margin/VBox/Body/MapPanel/MapGrid", "Margin/VBox/Actions/AttackButton", "Margin/VBox/Actions/EndTurnButton"],
	},
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var pass_count := 0
	var fail_count := 0

	for scene_case in SCENE_CASES:
		var result := await _run_scene_case(scene_case)
		if result:
			pass_count += 1
		else:
			fail_count += 1

	print("UI smoke tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _run_scene_case(scene_case: Dictionary) -> bool:
	var game_state := _game_state()
	if game_state == null:
		printerr("FAIL: UI smoke missing GameState autoload")
		return false
	game_state.current_scenario_id = String(scene_case.get("scenario_id", ""))
	game_state.current_campaign_id = "blitzkrieg_early_war" if bool(scene_case.get("campaign_mode", false)) else ""
	game_state.campaign_mode = bool(scene_case.get("campaign_mode", false))
	game_state.clear_conquest_battle()
	if bool(scene_case.get("conquest_mode", false)):
		game_state.conquest_mode = true

	var packed := load(String(scene_case.get("path", "")))
	if packed == null:
		printerr("FAIL: UI smoke missing scene %s" % scene_case.get("path", ""))
		return false
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var ok := _validate_scene(scene, scene_case)
	scene.queue_free()
	await process_frame
	return ok

func _game_state() -> Node:
	return root.get_node_or_null("GameState")

func _validate_scene(scene: Node, scene_case: Dictionary) -> bool:
	var name := String(scene_case.get("name", "scene"))
	for path in scene_case.get("required", []):
		if scene.get_node_or_null(String(path)) == null:
			printerr("FAIL: %s missing node %s" % [name, path])
			return false

	var bad_controls := _bad_visible_controls(scene)
	if not bad_controls.is_empty():
		printerr("FAIL: %s has collapsed visible controls: %s" % [name, ", ".join(bad_controls)])
		return false
	return true

func _bad_visible_controls(node: Node) -> Array[String]:
	var bad: Array[String] = []
	_collect_bad_visible_controls(node, bad)
	return bad

func _collect_bad_visible_controls(node: Node, bad: Array[String]) -> void:
	if node is Control:
		var control := node as Control
		if control.visible and not control.is_queued_for_deletion() and _needs_visible_rect(control):
			var rect := control.get_global_rect()
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				bad.append(String(control.get_path()))
	for child in node.get_children():
		_collect_bad_visible_controls(child, bad)

func _needs_visible_rect(control: Control) -> bool:
	return control is Label \
			or control is Button \
			or control is RichTextLabel \
			or control is OptionButton \
			or control is ScrollContainer \
			or control is Panel \
			or control is ColorRect
