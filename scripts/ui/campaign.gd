extends Control

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")

@onready var list: VBoxContainer = $Margin/VBox/List
@onready var status_label: Label = $Margin/VBox/Status
@onready var continue_button: Button = $Margin/VBox/Buttons/ContinueButton
@onready var reset_button: Button = $Margin/VBox/Buttons/ResetButton
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton

var state: Dictionary = {}

func _ready() -> void:
	state = CampaignManager.load_state()
	_rebuild_list()
	continue_button.pressed.connect(_on_continue_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _rebuild_list() -> void:
	for child in list.get_children():
		child.queue_free()
	var progress: int = int(state.get("progress", 0))
	var ordered := CampaignManager.SCENARIO_ORDER
	for i in range(ordered.size()):
		var sid: String = ordered[i]
		var scenario: Dictionary = DataLoader.get_scenario(sid)
		var title := String(scenario.get("title", sid))
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 18)
		var prefix := "[?]"
		var color := Color(0.6, 0.6, 0.6)
		if i < progress:
			prefix = "[✓]"
			color = Color(0.5, 0.85, 0.5)
		elif i == progress:
			prefix = "[▶]"
			color = Color(1.0, 0.85, 0.3)
		label.add_theme_color_override("font_color", color)
		label.text = "%s  %s — %s" % [prefix, sid, title]
		list.add_child(label)
	var roster: Dictionary = state.get("roster", {})
	var roster_summary: Array[String] = []
	for fid in roster.keys():
		var roster_for_faction: Dictionary = roster[fid]
		roster_summary.append("%s %d 名老兵" % [fid, roster_for_faction.size()])
	if CampaignManager.is_complete(state):
		status_label.text = "戰役全通!可重置重新開始。"
		continue_button.text = "已完成"
		continue_button.disabled = true
	else:
		status_label.text = "進度 %d / %d  ·  %s" % [
			progress, ordered.size(),
			"  ".join(roster_summary) if not roster_summary.is_empty() else "尚無老兵",
		]
		continue_button.text = "下一場戰役" if progress > 0 else "開始戰役"
		continue_button.disabled = false

func _on_continue_pressed() -> void:
	var sid := CampaignManager.current_scenario_id(state)
	if sid == "":
		return
	GameState.current_scenario_id = sid
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://scenes/briefing.tscn")

func _on_reset_pressed() -> void:
	CampaignManager.reset()
	state = CampaignManager.load_state()
	_rebuild_list()

func _on_back_pressed() -> void:
	GameState.campaign_mode = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
