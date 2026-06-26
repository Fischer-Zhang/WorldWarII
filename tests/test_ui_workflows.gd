extends SceneTree

var pass_count := 0
var fail_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await _check_main_menu()
	await _check_help()
	await _check_scenario_select()
	await _check_briefing()
	await _check_deployment()
	await _check_battle()
	await _check_campaign()
	await _check_lounge()
	await _check_conquest()
	print("UI workflow tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _instantiate_scene(path: String, setup: Dictionary = {}) -> Node:
	var game_state := _game_state()
	game_state.current_scenario_id = String(setup.get("scenario_id", ""))
	game_state.current_campaign_id = String(setup.get("campaign_id", ""))
	game_state.campaign_mode = bool(setup.get("campaign_mode", false))
	game_state.clear_conquest_battle()
	game_state.conquest_mode = bool(setup.get("conquest_mode", false))
	var packed := load(path)
	if packed == null:
		_fail("load scene", path)
		return null
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

func _game_state() -> Node:
	return root.get_node_or_null("GameState")

func _pass(name: String, detail: String = "") -> void:
	pass_count += 1
	if detail == "":
		print("PASS: %s" % name)
	else:
		print("PASS: %s - %s" % [name, detail])

func _fail(name: String, detail: String = "") -> void:
	fail_count += 1
	if detail == "":
		printerr("FAIL: %s" % name)
	else:
		printerr("FAIL: %s - %s" % [name, detail])

func _expect(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		_pass(name, detail)
	else:
		_fail(name, detail)

func _list_has_prefix(list: VBoxContainer, prefix: String) -> bool:
	for child in list.get_children():
		if String(child.text).begins_with(prefix):
			return true
	return false

func _check_main_menu() -> void:
	var scene := await _instantiate_scene("res://scenes/main_menu.tscn")
	_expect("main menu starts on campaign focus", scene.get_node("VBox/CampaignButton").has_focus())
	_expect(
		"main menu exposes core modes",
		scene.get_node_or_null("VBox/SingleBattleButton") != null
				and scene.get_node_or_null("VBox/ConquestButton") != null
				and scene.get_node_or_null("VBox/HelpButton") != null
	)
	await _free_scene(scene)

func _check_help() -> void:
	var scene := await _instantiate_scene("res://scenes/help.tscn")
	var text := String(scene.get_node("Margin/VBox/HelpScroll/HelpText").text)
	_expect("help renders core mechanics", text.contains("壓制") and text.contains("警戒") and text.contains("操作"))
	await _free_scene(scene)

func _check_scenario_select() -> void:
	var scene := await _instantiate_scene("res://scenes/scenario_select.tscn")
	var list: VBoxContainer = scene.get_node("Margin/VBox/ListScroll/List")
	_expect("scenario select list populated", list.get_child_count() >= 20, "count=%d" % list.get_child_count())
	_expect("scenario select hides tutorials", not _list_has_prefix(list, "tut_"))
	_expect("scenario select hides tutorial campaign category", not scene.category_buttons.has("00_tutorial"))
	_expect(
		"scenario select all count matches visible list",
		String(scene.category_buttons["all"].text).ends_with(" %d" % list.get_child_count()),
		"label=%s list=%d" % [String(scene.category_buttons["all"].text), list.get_child_count()]
	)
	scene._set_difficulty("hard")
	_expect(
		"scenario select hard difficulty",
		_game_state().difficulty == "hard" and scene.get_node("Margin/VBox/DifficultyRow/HardButton").button_pressed
	)
	scene._set_category("sandbox")
	await process_frame
	_expect("scenario select category filter", list.get_child_count() == 1, "sandbox count=%d" % list.get_child_count())
	await _free_scene(scene)

func _check_briefing() -> void:
	var scene := await _instantiate_scene("res://scenes/briefing.tscn", {"scenario_id": "01_sedan_1940"})
	var title := String(scene.get_node("Margin/VBox/Title").text)
	var body := String(scene.get_node("Margin/VBox/BriefingScroll/Briefing").text)
	_expect("briefing scenario content", title != "(找不到作戰)" and body.length() > 20)
	_expect("briefing begin tooltip", String(scene.get_node("Margin/VBox/Buttons/BeginButton").tooltip_text) != "")
	await _free_scene(scene)

	scene = await _instantiate_scene(
		"res://scenes/briefing.tscn",
		{"scenario_id": "tut_00_basic_turn", "campaign_mode": true, "campaign_id": "00_tutorial"}
	)
	scene.get_node("Margin/VBox/Buttons/BeginButton").pressed.emit()
	await process_frame
	await process_frame
	var current: Node = current_scene
	_expect(
		"campaign briefing skips deployment",
		current != null and String(current.scene_file_path) == "res://scenes/battle.tscn",
		String(current.scene_file_path) if current != null else "no current scene"
	)
	if current != null:
		await _free_scene(current)
	if is_instance_valid(scene) and scene.get_parent() != null:
		await _free_scene(scene)

func _check_deployment() -> void:
	var scene := await _instantiate_scene("res://scenes/deployment.tscn", {"scenario_id": "01_sedan_1940"})
	_expect(
		"deployment selects first unit",
		scene.selected_unit != null and scene.player_units.size() > 0,
		"units=%d" % scene.player_units.size()
	)
	var detail := String(scene.get_node("UI/Root/Body/RightPanel/Detail").text)
	_expect("deployment next step copy", detail.contains("下一步") and detail.contains("藍色格"))
	_expect("deployment begin tooltip", String(scene.get_node("UI/Root/BottomBar/BeginButton").tooltip_text) != "")
	await _free_scene(scene)

func _check_battle() -> void:
	var scene := await _instantiate_scene("res://scenes/battle.tscn", {"scenario_id": "01_sedan_1940"})
	_expect("battle loaded playable faction", scene.player_faction_id != "" and scene.units.size() > 0)
	_expect("battle legend starts closed", not scene.get_node("UI/LegendPanel").visible)
	scene._toggle_legend()
	_expect("battle legend toggles open", scene.get_node("UI/LegendPanel").visible)
	var unit = null
	for u in scene.units:
		if u.faction_id == scene.player_faction_id and u.is_alive() and not u.is_done_for_turn():
			unit = u
			break
	scene._select_unit(unit)
	_expect(
		"battle selection presents movement",
		scene.selected_unit == unit and not scene.movement_range.is_empty(),
		"move hexes=%d" % scene.movement_range.size()
	)
	var info := String(scene.get_node("UI/InfoLabel").text)
	_expect("battle prompt has step prefix", info.contains(":"))
	await _free_scene(scene)

func _check_campaign() -> void:
	var scene := await _instantiate_scene("res://scenes/campaign.tscn", {"campaign_mode": true})
	var list: VBoxContainer = scene.get_node("Margin/VBox/ListScroll/List")
	_expect("campaign lists campaigns", list.get_child_count() >= 1)
	_expect("campaign starts with tutorial campaign", list.get_child_count() > 0 and String(list.get_child(0).text).contains("教學戰役 0"))
	if list.get_child_count() > 0:
		var first: Button = list.get_child(0)
		first.pressed.emit()
		await process_frame
	_expect(
		"campaign tutorial starts at scenario zero",
		scene.selected_campaign_id == "00_tutorial" and scene.selected_scenario_id == "tut_00_basic_turn"
	)
	_expect(
		"campaign continue tooltip",
		String(scene.get_node("Margin/VBox/Buttons/ContinueButton").tooltip_text).contains("簡報")
				and not String(scene.get_node("Margin/VBox/Buttons/ContinueButton").tooltip_text).contains("部署")
	)
	await _free_scene(scene)

func _check_lounge() -> void:
	var scene := await _instantiate_scene("res://scenes/lounge.tscn")
	var generals: VBoxContainer = scene.get_node("Margin/VBox/Body/GeneralsPanel/GeneralsScroll/GeneralsList")
	var techs: VBoxContainer = scene.get_node("Margin/VBox/Body/TechPanel/TechScroll/TechList")
	_expect(
		"lounge upgrade lists populated",
		generals.get_child_count() > 0 and techs.get_child_count() > 0,
		"g=%d t=%d" % [generals.get_child_count(), techs.get_child_count()]
	)
	_expect("lounge next step status", String(scene.get_node("Margin/VBox/Status").text).contains("下一步"))
	await _free_scene(scene)

func _check_conquest() -> void:
	var scene := await _instantiate_scene("res://scenes/conquest.tscn", {"conquest_mode": true})
	var conquest: Dictionary = scene.state.get("conquest", {})
	var player := String(conquest.get("player_country", ""))
	var regions: Dictionary = conquest.get("regions", {})
	var own_id := ""
	var enemy_id := ""
	for rid in regions.keys():
		var region: Dictionary = regions[rid]
		if String(region.get("owner", "")) != player:
			continue
		for nb in region.get("neighbors", []):
			var target: Dictionary = regions.get(String(nb), {})
			if not target.is_empty() and String(target.get("owner", "")) != player:
				own_id = String(rid)
				enemy_id = String(nb)
				break
		if own_id != "":
			break
	if own_id == "" or enemy_id == "":
		_fail("conquest adjacent setup", "no own/enemy neighbor found")
		await _free_scene(scene)
		return
	scene._select_region(enemy_id)
	scene._select_region(own_id)
	var detail := String(scene.get_node("Margin/VBox/Body/DetailPanel/Detail").text)
	_expect("conquest order-independent selection", scene.selected_region_id == own_id and scene.target_region_id == enemy_id)
	_expect("conquest tactical preview", detail.contains("戰術作戰") or detail.contains("出擊地沒有駐軍"))
	_expect("conquest attack tooltip", String(scene.get_node("Margin/VBox/Actions/AttackButton").tooltip_text) != "")
	await _free_scene(scene)
