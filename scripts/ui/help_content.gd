class_name HelpContent
extends RefCounted

# Single source for the "如何遊玩" page (scripts/ui/help.gd) and the in-battle
# 圖例 panel (scripts/battle.gd). Rule numbers live as authored copy in
# data/help.json; the terrain and unit tables are generated from DataLoader so
# they never drift from the actual catalogs. Consumers preload this script (the
# project does not rely on the global class_name registry — see battle.gd).

const HELP_PATH := "res://data/help.json"

# Overlay colours mirror scripts/grid/hex_map.gd so the legend matches the map.
const COLOR_MOVE := "#4db3ff"        # RANGE_OVERLAY_COLOR
const COLOR_ATTACK := "#ff4d40"      # ATTACK_OVERLAY_COLOR
const COLOR_THREAT := "#ff730d"      # THREAT_OVERLAY_COLOR
const COLOR_OBJECTIVE := "#ffd933"   # OBJECTIVE_RGB

const _HEADING := "#e6c84d"
const _TERM := "#9ad0ff"
const _COLOR_BY_KEY := {
	"move": COLOR_MOVE,
	"attack": COLOR_ATTACK,
	"threat": COLOR_THREAT,
	"objective": COLOR_OBJECTIVE,
}

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(HELP_PATH):
		push_error("Missing help data: " + HELP_PATH)
		return {}
	var f := FileAccess.open(HELP_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid help JSON: " + HELP_PATH)
		return {}
	return parsed

# Full BBCode document for the How-to-Play screen. The terrain/unit catalogs are
# passed in (DataLoader.terrains / DataLoader.units) because static functions
# cannot reach autoload singletons by name in Godot 4.2.
static func full_bbcode(terrains: Dictionary, units: Dictionary) -> String:
	var data := load_data()
	var blocks := PackedStringArray()

	var intro := String(data.get("intro", ""))
	if intro != "":
		blocks.append(intro)

	for section in data.get("sections", []):
		blocks.append(_heading(String(section.get("heading", ""))))
		blocks.append(String(section.get("body", "")))

	var mechanics: Array = data.get("mechanics", [])
	if not mechanics.is_empty():
		blocks.append(_heading("狀態與機制"))
		for m in mechanics:
			blocks.append("[b][color=%s]%s[/color][/b]\n%s" % [
				_TERM, String(m.get("term", "")), String(m.get("body", "")),
			])

	blocks.append(_heading("地形"))
	blocks.append(_terrain_table(terrains))

	blocks.append(_heading("單位"))
	blocks.append(_unit_table(units))

	var controls: Array = data.get("controls", [])
	if not controls.is_empty():
		blocks.append(_heading("操作"))
		var lines := PackedStringArray()
		for c in controls:
			lines.append("[b]%s[/b] — %s" % [String(c.get("input", "")), String(c.get("action", ""))])
		blocks.append("\n".join(lines))

	var tips: Array = data.get("tips", [])
	if not tips.is_empty():
		blocks.append(_heading("戰術提示"))
		var tip_lines := PackedStringArray()
		for t in tips:
			tip_lines.append("• " + String(t))
		blocks.append("\n".join(tip_lines))

	return "\n\n".join(blocks)

# Compact BBCode for the in-battle 圖例 panel.
static func legend_bbcode() -> String:
	var data := load_data()
	var legend: Dictionary = data.get("legend", {})
	var blocks := PackedStringArray()

	blocks.append(_heading("戰場圖例"))
	var color_lines := PackedStringArray()
	for c in legend.get("colors", []):
		var hex_color := String(_COLOR_BY_KEY.get(String(c.get("key", "")), "#ffffff"))
		color_lines.append("[color=%s]■[/color]  %s" % [hex_color, String(c.get("label", ""))])
	blocks.append("\n".join(color_lines))

	var status: Array = legend.get("status_short", [])
	if not status.is_empty():
		blocks.append(_heading("狀態與機制"))
		var status_lines := PackedStringArray()
		for s in status:
			status_lines.append("[b][color=%s]%s[/color][/b]  %s" % [
				_TERM, String(s.get("term", "")), String(s.get("body", "")),
			])
		blocks.append("\n".join(status_lines))

	var controls_short := String(legend.get("controls_short", ""))
	if controls_short != "":
		blocks.append(_heading("操作"))
		blocks.append(controls_short)

	return "\n\n".join(blocks)

static func _heading(text: String) -> String:
	return "[b][color=%s]%s[/color][/b]" % [_HEADING, text]

# Generated from the live terrain catalog so the table never drifts from data.
static func _terrain_table(terrains: Dictionary) -> String:
	var lines := PackedStringArray()
	for tid in terrains:
		var t: Dictionary = terrains[tid]
		var parts := PackedStringArray()
		var move_cost := int(t.get("move_cost", 1))
		if move_cost >= 9:
			parts.append("不可通行")
		else:
			parts.append("移動 %d" % move_cost)
		var df := int(t.get("defense", 0))
		parts.append("防禦 %s" % (("+%d" % df) if df > 0 else str(df)))
		if bool(t.get("blocks_los", false)):
			parts.append("遮蔽視線")
		if bool(t.get("capturable", false)):
			parts.append("可佔領")
		lines.append("[b]%s[/b] — %s" % [String(t.get("name_zh", tid)), "・".join(parts)])
	return "\n".join(lines)

# Generated from the live unit catalog.
static func _unit_table(units: Dictionary) -> String:
	var lines := PackedStringArray()
	for uid in units:
		var u: Dictionary = units[uid]
		var parts := PackedStringArray()
		parts.append("HP %d" % int(u.get("hp", 0)))
		parts.append("攻 %d" % int(u.get("attack", 0)))
		parts.append("防 %d" % int(u.get("defense", 0)))
		parts.append("射程 %d" % int(u.get("range", 1)))
		parts.append("移動 %d" % int(u.get("move", 0)))
		if int(u.get("vs_armor", 0)) > 0:
			parts.append("反裝甲 %d" % int(u.get("vs_armor", 0)))
		if int(u.get("armor", 0)) > 0:
			parts.append("裝甲 %d" % int(u.get("armor", 0)))
		if bool(u.get("indirect", false)):
			parts.append("間接")
		if bool(u.get("airdrop", false)):
			parts.append("空降")
		lines.append("[b]%s[/b] — %s" % [String(u.get("name_zh", uid)), "・".join(parts)])
	return "\n".join(lines)
