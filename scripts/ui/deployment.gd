extends Node2D

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const HexMap := preload("res://scripts/grid/hex_map.gd")
const Unit := preload("res://scripts/units/unit.gd")
const UnitFactory := preload("res://scripts/units/unit_factory.gd")
const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const DeploymentOverrides := preload("res://scripts/scenario/deployment_overrides.gd")
const LoungeManager := preload("res://scripts/scenario/lounge_manager.gd")

const DEPLOY_RADIUS := 2

@onready var hex_map: HexMap = $HexMap
@onready var camera: Camera2D = $Camera
@onready var title_label: Label = $UI/Root/TopBar/Title
@onready var status_label: Label = $UI/Root/TopBar/Status
@onready var unit_list: VBoxContainer = $UI/Root/Body/LeftPanel/UnitScroll/UnitList
@onready var general_option: OptionButton = $UI/Root/Body/RightPanel/GeneralOption
@onready var detail_label: RichTextLabel = $UI/Root/Body/RightPanel/Detail
@onready var begin_button: Button = $UI/Root/BottomBar/BeginButton
@onready var reset_button: Button = $UI/Root/BottomBar/ResetButton
@onready var back_button: Button = $UI/Root/BottomBar/BackButton

var scenario: Dictionary = {}
var factions: Dictionary = {}
var units: Array[Unit] = []
var player_units: Array[Unit] = []
var player_faction_id: String = ""
var selected_unit: Unit = null
var original_coords: Dictionary = {}
var original_generals: Dictionary = {}
var deployment_zone: Dictionary = {}
var unit_deployment_zones: Dictionary = {}
var general_pool: Array[String] = []
var _refreshing_general_option := false

func _ready() -> void:
	var scenario_id := GameState.current_scenario_id
	scenario = DataLoader.get_scenario(scenario_id)
	if scenario.is_empty():
		title_label.text = "找不到戰役"
		status_label.text = scenario_id
		return
	title_label.text = "編成: %s" % String(scenario.get("title", scenario_id))

	hex_map.load_from_scenario(scenario)
	hex_map.hex_clicked.connect(_on_hex_clicked)
	hex_map.hex_hovered.connect(_on_hex_hovered)
	camera.position = hex_map.get_map_center()

	var built := UnitFactory.build(scenario, hex_map)
	factions = built["factions"]
	for u in built["units"]:
		var unit: Unit = u
		hex_map.register_unit(unit)
		units.append(unit)

	if GameState.campaign_mode:
		var camp_state := CampaignManager.load_state()
		var campaign := DataLoader.get_campaign(GameState.current_campaign_id)
		var scenario_order: Array = campaign.get("scenario_order", [])
		CampaignManager.apply_roster_to_units(camp_state, GameState.current_campaign_id, scenario_order, units)

	for fid in factions.keys():
		if String(factions[fid].get("controller", "")) == "player":
			player_faction_id = fid
			break

	LoungeManager.apply_upgrades_to_units(units, factions, DataLoader.tech_tree)

	for u in units:
		var unit: Unit = u
		if unit.faction_id == player_faction_id:
			player_units.append(unit)
			var key := _unit_key(unit)
			original_coords[key] = unit.coord
			original_generals[key] = unit.general_id

	_build_general_pool()
	_build_deployment_zone()
	hex_map.show_movement_range(deployment_zone.keys())
	_rebuild_unit_list()
	if not player_units.is_empty():
		_select_unit(player_units[0])

	general_option.item_selected.connect(_on_general_selected)
	begin_button.pressed.connect(_on_begin_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _build_general_pool() -> void:
	var found := {}
	for u in player_units:
		var unit: Unit = u
		if unit.general_id != "":
			found[unit.general_id] = true
	if GameState.campaign_mode and player_faction_id != "":
		var state := CampaignManager.load_state()
		var campaign := DataLoader.get_campaign(GameState.current_campaign_id)
		var scenario_order: Array = campaign.get("scenario_order", [])
		var cstate := CampaignManager.campaign_state(state, GameState.current_campaign_id, scenario_order)
		var roster: Dictionary = cstate.get("roster", {})
		var faction_roster: Dictionary = roster.get(player_faction_id, {})
		for name in faction_roster.keys():
			var saved: Dictionary = faction_roster[name]
			var gid := String(saved.get("general_id", ""))
			if gid != "":
				found[gid] = true
	general_pool.clear()
	for gid in found.keys():
		if not DataLoader.get_general_def(String(gid)).is_empty():
			general_pool.append(String(gid))
	general_pool.sort()

func _build_deployment_zone() -> void:
	deployment_zone.clear()
	unit_deployment_zones.clear()
	for u in player_units:
		var unit: Unit = u
		var unit_zone := {}
		for coord in hex_map.tiles.keys():
			var c: Vector2i = coord
			if HexCoord.distance(unit.coord, c) > DEPLOY_RADIUS:
				continue
			var occupant := hex_map.unit_at(c)
			if occupant != null and occupant.faction_id != player_faction_id:
				continue
			deployment_zone[c] = true
			unit_zone[c] = true
		unit_deployment_zones[_unit_key(unit)] = unit_zone

func _rebuild_unit_list() -> void:
	for child in unit_list.get_children():
		child.queue_free()
	for u in player_units:
		var unit: Unit = u
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 38)
		btn.text = _unit_button_text(unit)
		btn.disabled = unit == selected_unit
		btn.pressed.connect(func(): _select_unit(unit))
		unit_list.add_child(btn)

func _unit_button_text(unit: Unit) -> String:
	var general_name := "無將軍"
	if unit.general_id != "":
		var g := DataLoader.get_general_def(unit.general_id)
		general_name = String(g.get("name_zh", unit.general_id))
	var off := _axial_to_offset(unit.coord)
	return "%s  (%d,%d)  %s" % [unit.display_name, off.x, off.y, general_name]

func _select_unit(unit: Unit) -> void:
	if unit == null:
		selected_unit = null
		return
	if selected_unit != null:
		selected_unit.set_selected(false)
	selected_unit = unit
	selected_unit.set_selected(true)
	hex_map.highlight_coord(unit.coord)
	_refresh_general_option()
	_update_detail()
	_rebuild_unit_list()

func _refresh_general_option() -> void:
	_refreshing_general_option = true
	general_option.clear()
	general_option.add_item("無將軍")
	general_option.set_item_metadata(0, "")
	var selected_index := 0
	for gid in general_pool:
		var g := DataLoader.get_general_def(gid)
		var label := "%s「%s」" % [String(g.get("name_zh", gid)), String(g.get("title_zh", ""))]
		var owner := _general_owner(gid)
		if owner != null and owner != selected_unit:
			label += "  - 目前:%s" % owner.display_name
		if selected_unit != null and not _general_applies_to(gid, selected_unit.type_id):
			label += "  - 不適配"
		general_option.add_item(label)
		var idx := general_option.item_count - 1
		general_option.set_item_metadata(idx, gid)
		if selected_unit != null and selected_unit.general_id == gid:
			selected_index = idx
	general_option.selected = selected_index
	general_option.disabled = selected_unit == null or general_pool.is_empty()
	_refreshing_general_option = false

func _update_detail() -> void:
	if selected_unit == null:
		detail_label.text = "選取單位後配置將軍與部署位置。"
		return
	var unit_def := DataLoader.get_unit_def(selected_unit.type_id)
	var off := _axial_to_offset(selected_unit.coord)
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % selected_unit.display_name)
	lines.append("%s · HP %d/%d · 部署 (%d,%d)" % [
		String(unit_def.get("name_zh", selected_unit.type_id)),
		selected_unit.hp,
		selected_unit.max_hp,
		off.x,
		off.y,
	])
	if selected_unit.general_id == "":
		lines.append("將軍: 無")
	else:
		var g := DataLoader.get_general_def(selected_unit.general_id)
		var applies := _general_applies_to(selected_unit.general_id, selected_unit.type_id)
		lines.append("將軍: %s「%s」%s" % [
			String(g.get("name_zh", selected_unit.general_id)),
			String(g.get("title_zh", "")),
			"" if applies else " [color=#ff8a6a](不適配此兵種)[/color]",
		])
		lines.append("加成: 攻 %+d / 防 %+d / 反裝甲 %+d / 移動 %+d / 視野 %+d" % [
			int(g.get("attack_bonus", 0)),
			int(g.get("defense_bonus", 0)),
			int(g.get("vs_armor_bonus", 0)),
			int(g.get("move_bonus", 0)),
			int(g.get("vision_bonus", 0)),
		])
		var level := int(selected_unit.general_upgrade_levels.get(selected_unit.general_id, 0))
		if level > 0:
			lines.append("將領升級 Lv %d: %s" % [
				level,
				LoungeManager.describe_mods(LoungeManager.general_upgrade_mods(g, level)),
			])
	if not selected_unit.tech_mods.is_empty():
		lines.append("科技加成: %s" % LoungeManager.describe_mods(selected_unit.tech_mods))
	lines.append("")
	lines.append("藍色格為可部署區。選取單位只能在原部署點附近移動; 點我方單位切換; 點已佔用格可交換。")
	status_label.text = "部署區半徑 %d · 可重派 %d 名將軍" % [DEPLOY_RADIUS, general_pool.size()]
	detail_label.text = "\n".join(lines)

func _on_general_selected(_index: int) -> void:
	if _refreshing_general_option or selected_unit == null:
		return
	var gid := String(general_option.get_selected_metadata())
	if gid != "":
		var owner := _general_owner(gid)
		if owner != null and owner != selected_unit:
			owner.general_id = ""
			owner.queue_redraw()
	selected_unit.general_id = gid
	selected_unit.queue_redraw()
	_refresh_general_option()
	_update_detail()
	_rebuild_unit_list()

func _on_hex_clicked(coord: Vector2i, _terrain_id: String) -> void:
	var occupant := hex_map.unit_at(coord)
	if occupant != null and occupant.faction_id == player_faction_id:
		if selected_unit != null and selected_unit != occupant and _can_place_selected_at(coord) and _can_place_unit_at(occupant, selected_unit.coord):
			_swap_units(selected_unit, occupant)
			return
		_select_unit(occupant)
		return
	if selected_unit == null:
		return
	if not _can_place_selected_at(coord):
		status_label.text = "只能部署在該單位原始位置附近。"
		return
	if occupant != null:
		status_label.text = "該位置已被敵軍佔用。"
		return
	_move_unit_to(selected_unit, coord)

func _on_hex_hovered(coord: Vector2i, terrain_id: String) -> void:
	if terrain_id == "":
		return
	var label := "可部署" if deployment_zone.has(coord) else "部署區外"
	var off := _axial_to_offset(coord)
	status_label.text = "%s (%d,%d) · %s" % [
		String(DataLoader.get_terrain_def(terrain_id).get("name_zh", terrain_id)),
		off.x,
		off.y,
		label,
	]

func _move_unit_to(unit: Unit, coord: Vector2i) -> void:
	if hex_map.occupants.get(unit.coord) == unit:
		hex_map.occupants.erase(unit.coord)
	hex_map.occupants[coord] = unit
	_reposition_unit(unit, coord)
	hex_map.highlight_coord(coord)
	_update_detail()
	_rebuild_unit_list()

func _swap_units(a: Unit, b: Unit) -> void:
	var a_coord := a.coord
	var b_coord := b.coord
	hex_map.occupants.erase(a_coord)
	hex_map.occupants.erase(b_coord)
	hex_map.occupants[b_coord] = a
	hex_map.occupants[a_coord] = b
	_reposition_unit(a, b_coord)
	_reposition_unit(b, a_coord)
	hex_map.highlight_coord(a.coord)
	_update_detail()
	_rebuild_unit_list()

func _can_place_selected_at(coord: Vector2i) -> bool:
	if selected_unit == null:
		return false
	return _can_place_unit_at(selected_unit, coord)

func _can_place_unit_at(unit: Unit, coord: Vector2i) -> bool:
	var zone: Dictionary = unit_deployment_zones.get(_unit_key(unit), {})
	return zone.has(coord)

func _reposition_unit(unit: Unit, coord: Vector2i) -> void:
	unit.coord = coord
	unit.position = HexCoord.to_pixel(coord, HexMap.HEX_SIZE)
	unit.has_moved = false
	unit.has_attacked = false
	unit.queue_redraw()

func _on_begin_pressed() -> void:
	var overrides := {}
	for u in player_units:
		var unit: Unit = u
		overrides[_unit_key(unit)] = {
			"q": unit.coord.x,
			"r": unit.coord.y,
			"general_id": unit.general_id,
		}
	GameState.set_deployment_overrides(String(scenario.get("id", "")), overrides)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_reset_pressed() -> void:
	for u in player_units:
		var unit: Unit = u
		var key := _unit_key(unit)
		unit.general_id = String(original_generals.get(key, ""))
		var coord: Vector2i = original_coords.get(key, unit.coord)
		if hex_map.occupants.get(unit.coord) == unit:
			hex_map.occupants.erase(unit.coord)
		unit.coord = coord
		unit.position = HexCoord.to_pixel(coord, HexMap.HEX_SIZE)
	for u in player_units:
		var unit: Unit = u
		hex_map.occupants[unit.coord] = unit
		unit.queue_redraw()
	_select_unit(player_units[0] if not player_units.is_empty() else null)

func _on_back_pressed() -> void:
	GameState.clear_deployment_overrides()
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _general_owner(general_id: String) -> Unit:
	for u in player_units:
		var unit: Unit = u
		if unit.general_id == general_id:
			return unit
	return null

func _general_applies_to(general_id: String, type_id: String) -> bool:
	var g := DataLoader.get_general_def(general_id)
	var applies: Array = g.get("applies_to", [])
	return applies.has(type_id)

func _unit_key(unit: Unit) -> String:
	return DeploymentOverrides.unit_key(unit)

func _axial_to_offset(coord: Vector2i) -> Vector2i:
	return Vector2i(coord.x + (coord.y >> 1), coord.y)
