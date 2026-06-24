extends Control

@onready var title_label: Label = $Margin/VBox/Title
@onready var briefing_label: RichTextLabel = $Margin/VBox/BriefingScroll/Briefing
@onready var begin_button: Button = $Margin/VBox/Buttons/BeginButton
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton

func _ready() -> void:
	if GameState.campaign_mode:
		back_button.text = "返回戰役地圖"
	elif GameState.conquest_mode:
		back_button.text = "返回征服地圖"
	else:
		back_button.text = "返回作戰列表"
	var scenario := DataLoader.get_scenario(GameState.current_scenario_id)
	if scenario.is_empty():
		title_label.text = "(找不到作戰)"
		briefing_label.text = "Scenario id 無效:" + GameState.current_scenario_id
	elif GameState.conquest_mode and not GameState.pending_conquest_battle.is_empty():
		# Conquest battles reuse a historical map but not its narrative — show a
		# briefing that matches the actual attacker/defender matchup instead.
		_show_conquest_briefing(scenario)
	else:
		title_label.text = String(scenario.get("title", scenario.get("id", "")))
		briefing_label.text = String(scenario.get("briefing", "(無簡報)"))
	begin_button.pressed.connect(_on_begin_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _show_conquest_briefing(scenario: Dictionary) -> void:
	var p := GameState.pending_conquest_battle
	var loc := String(p.get("battle_location", scenario.get("title", "")))
	var attacker := String(p.get("player_name", "我軍"))
	var defender := String(p.get("enemy_name", "敵軍"))
	var my_n: int = (p.get("attacker_garrison", []) as Array).size()
	var enemy_n: int = (p.get("defender_types", []) as Array).size()
	title_label.text = "%s 進攻 %s" % [attacker, defender]
	briefing_label.text = "戰場:%s\n\n%s 出動 %d 支部隊,向 %s 的守軍發起進攻;敵軍約 %d 支部隊據守地形。\n\n殲滅所有守軍即可佔領該地。若守軍撐過 12 回合,你的攻勢將被擊退。" % [
		loc, attacker, my_n, defender, enemy_n,
	]

func _on_begin_pressed() -> void:
	# Conquest battles field a fixed recruited army, so they skip the pre-battle
	# deployment editor (which operates on the themed scenario's authored units).
	if GameState.conquest_mode:
		get_tree().change_scene_to_file("res://scenes/battle.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/deployment.tscn")

func _on_back_pressed() -> void:
	if GameState.campaign_mode:
		get_tree().change_scene_to_file("res://scenes/campaign.tscn")
	elif GameState.conquest_mode:
		GameState.clear_conquest_battle()
		get_tree().change_scene_to_file("res://scenes/conquest.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")
