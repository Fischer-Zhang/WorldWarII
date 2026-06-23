extends Control

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const LoungeManager := preload("res://scripts/scenario/lounge_manager.gd")

@onready var points_label: Label = $Margin/VBox/Points
@onready var status_label: Label = $Margin/VBox/Status
@onready var generals_list: VBoxContainer = $Margin/VBox/Body/GeneralsPanel/GeneralsScroll/GeneralsList
@onready var tech_list: VBoxContainer = $Margin/VBox/Body/TechPanel/TechScroll/TechList
@onready var back_button: Button = $Margin/VBox/BackButton

var state: Dictionary = {}

func _ready() -> void:
	state = CampaignManager.load_state()
	LoungeManager.lounge_state(state)
	back_button.pressed.connect(_on_back_pressed)
	_rebuild()

func _rebuild() -> void:
	_clear_list(generals_list)
	_clear_list(tech_list)
	points_label.text = "資源點 %d / %d" % [
		LoungeManager.available_points(state),
		LoungeManager.total_points(state),
	]
	_rebuild_generals()
	_rebuild_techs()

func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

func _rebuild_generals() -> void:
	var ids := DataLoader.generals.keys()
	ids.sort()
	for general_id in ids:
		var gid := String(general_id)
		var general_def := DataLoader.get_general_def(gid)
		var level := LoungeManager.general_level(state, gid)
		var cost := LoungeManager.general_upgrade_cost(level)
		var mods := LoungeManager.general_upgrade_mods(general_def, min(level + 1, LoungeManager.MAX_GENERAL_LEVEL))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 76)
		btn.add_theme_font_size_override("font_size", 16)
		btn.text = "%s「%s」  Lv %d/%d\n%s\n%s" % [
			String(general_def.get("name_zh", gid)),
			String(general_def.get("title_zh", "")),
			level,
			LoungeManager.MAX_GENERAL_LEVEL,
			"滿級" if level >= LoungeManager.MAX_GENERAL_LEVEL else "升級消耗 %d" % cost,
			"下一級: %s" % LoungeManager.describe_mods(mods) if level < LoungeManager.MAX_GENERAL_LEVEL else "加成已達上限",
		]
		btn.disabled = level >= LoungeManager.MAX_GENERAL_LEVEL or LoungeManager.available_points(state) < cost
		btn.pressed.connect(func(): _upgrade_general(gid))
		generals_list.add_child(btn)

func _rebuild_techs() -> void:
	var ids := DataLoader.tech_tree.keys()
	ids.sort()
	for tech_id in ids:
		var tid := String(tech_id)
		var tech_def := DataLoader.get_tech_def(tid)
		var levels: Array = tech_def.get("levels", [])
		var level := LoungeManager.tech_level(state, tid)
		var cost := LoungeManager.tech_upgrade_cost(tech_def, level)
		var next_mods: Dictionary = levels[level] if level < levels.size() else {}
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 86)
		btn.add_theme_font_size_override("font_size", 16)
		btn.text = "%s  Lv %d/%d\n%s\n%s" % [
			String(tech_def.get("name_zh", tid)),
			level,
			levels.size(),
			String(tech_def.get("description_zh", "")),
			"滿級" if level >= levels.size() else "升級消耗 %d · 下一級: %s" % [cost, LoungeManager.describe_mods(next_mods)],
		]
		btn.disabled = level >= levels.size() or LoungeManager.available_points(state) < cost
		btn.pressed.connect(func(): _upgrade_tech(tid))
		tech_list.add_child(btn)

func _upgrade_general(general_id: String) -> void:
	if LoungeManager.upgrade_general(state, general_id):
		status_label.text = "將領已升級。"
	else:
		status_label.text = "資源不足或已達上限。"
	_rebuild()

func _upgrade_tech(tech_id: String) -> void:
	if LoungeManager.upgrade_tech(state, tech_id, DataLoader.get_tech_def(tech_id)):
		status_label.text = "科技已升級。"
	else:
		status_label.text = "資源不足或已達上限。"
	_rebuild()

func _on_back_pressed() -> void:
	CampaignManager.save_state(state)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
