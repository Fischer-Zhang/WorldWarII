extends SceneTree

const VIEWPORT_CASES := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
]

const SCENE_CASES := [
	{
		"name": "main_menu",
		"path": "res://scenes/main_menu.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "help",
		"path": "res://scenes/help.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "scenario_select",
		"path": "res://scenes/scenario_select.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "briefing",
		"path": "res://scenes/briefing.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "deployment",
		"path": "res://scenes/deployment.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "battle",
		"path": "res://scenes/battle.tscn",
		"scenario_id": "01_sedan_1940",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "campaign",
		"path": "res://scenes/campaign.tscn",
		"scenario_id": "",
		"campaign_mode": true,
		"conquest_mode": false,
	},
	{
		"name": "lounge",
		"path": "res://scenes/lounge.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": false,
	},
	{
		"name": "conquest",
		"path": "res://scenes/conquest.tscn",
		"scenario_id": "",
		"campaign_mode": false,
		"conquest_mode": true,
	},
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var pass_count := 0
	var fail_count := 0
	for viewport in VIEWPORT_CASES:
		root.size = viewport
		DisplayServer.window_set_size(viewport)
		await process_frame
		for scene_case in SCENE_CASES:
			var result := await _run_scene_case(scene_case, viewport)
			if result:
				pass_count += 1
			else:
				fail_count += 1
	print("UI layout tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _run_scene_case(scene_case: Dictionary, viewport: Vector2i) -> bool:
	var game_state := _game_state()
	if game_state == null:
		printerr("FAIL: UI layout missing GameState autoload")
		return false
	game_state.current_scenario_id = String(scene_case.get("scenario_id", ""))
	game_state.current_campaign_id = "blitzkrieg_early_war" if bool(scene_case.get("campaign_mode", false)) else ""
	game_state.campaign_mode = bool(scene_case.get("campaign_mode", false))
	game_state.clear_conquest_battle()
	game_state.conquest_mode = bool(scene_case.get("conquest_mode", false))

	var packed := load(String(scene_case.get("path", "")))
	if packed == null:
		printerr("FAIL: UI layout missing scene %s" % scene_case.get("path", ""))
		return false
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var issues := _visible_control_issues(scene, Rect2(Vector2.ZERO, Vector2(viewport)))
	scene.queue_free()
	await process_frame
	if not issues.is_empty():
		printerr("FAIL: %s at %dx%d has out-of-bounds controls: %s" % [
			String(scene_case.get("name", "scene")),
			viewport.x,
			viewport.y,
			", ".join(issues),
		])
		return false
	return true

func _game_state() -> Node:
	return root.get_node_or_null("GameState")

func _visible_control_issues(scene: Node, viewport_rect: Rect2) -> Array[String]:
	var issues: Array[String] = []
	_collect_visible_control_issues(scene, viewport_rect, issues, false)
	return issues

func _collect_visible_control_issues(
	node: Node, viewport_rect: Rect2, issues: Array[String], inside_scroll: bool
) -> void:
	var next_inside_scroll := inside_scroll
	if node is Control:
		var control := node as Control
		if control is ScrollContainer:
			next_inside_scroll = true
		if control.visible and not control.is_queued_for_deletion() \
				and _needs_visible_rect(control) \
				and not (inside_scroll and not (control is ScrollContainer)):
			var rect := control.get_global_rect()
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				issues.append("%s collapsed" % control.get_path())
			elif _rect_outside_viewport(rect, viewport_rect):
				issues.append("%s %s" % [control.get_path(), str(rect)])
	for child in node.get_children():
		_collect_visible_control_issues(child, viewport_rect, issues, next_inside_scroll)

func _rect_outside_viewport(rect: Rect2, viewport_rect: Rect2) -> bool:
	var margin := 1.0
	return rect.position.x < -margin \
			or rect.position.y < -margin \
			or rect.end.x > viewport_rect.end.x + margin \
			or rect.end.y > viewport_rect.end.y + margin

func _needs_visible_rect(control: Control) -> bool:
	return control is Label \
			or control is Button \
			or control is RichTextLabel \
			or control is OptionButton \
			or control is ScrollContainer \
			or control is Panel \
			or control is ColorRect
