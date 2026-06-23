class_name ConquestManager
extends RefCounted

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")

static func conquest_state(state: Dictionary, map_data: Dictionary) -> Dictionary:
	var conquest: Dictionary = state.get("conquest", {})
	if not conquest.has("turn"):
		conquest["turn"] = 1
	if not conquest.has("player_country"):
		conquest["player_country"] = String(map_data.get("start_country", "germany"))
	if not conquest.has("regions"):
		conquest["regions"] = _initial_regions(map_data)
	state["conquest"] = conquest
	return conquest

static func reset_conquest(state: Dictionary, map_data: Dictionary) -> void:
	state["conquest"] = {
		"turn": 1,
		"player_country": String(map_data.get("start_country", "germany")),
		"regions": _initial_regions(map_data),
	}
	CampaignManager.save_state(state)

static func set_player_country(state: Dictionary, map_data: Dictionary, country_id: String) -> void:
	var conquest := conquest_state(state, map_data)
	if map_data.get("countries", {}).has(country_id):
		conquest["player_country"] = country_id
	state["conquest"] = conquest
	CampaignManager.save_state(state)

static func region_state(state: Dictionary, map_data: Dictionary, region_id: String) -> Dictionary:
	var regions: Dictionary = conquest_state(state, map_data).get("regions", {})
	return regions.get(region_id, {})

static func can_attack(state: Dictionary, map_data: Dictionary, from_id: String, to_id: String) -> bool:
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions.get(from_id, {})
	var target: Dictionary = regions.get(to_id, {})
	if source.is_empty() or target.is_empty():
		return false
	if String(source.get("owner", "")) != String(conquest.get("player_country", "")):
		return false
	if String(target.get("owner", "")) == String(conquest.get("player_country", "")):
		return false
	if int(source.get("strength", 0)) <= 1:
		return false
	var neighbors: Array = source.get("neighbors", [])
	return neighbors.has(to_id)

static func player_attack(state: Dictionary, map_data: Dictionary, from_id: String, to_id: String) -> Dictionary:
	if not can_attack(state, map_data, from_id, to_id):
		return {"ok": false, "message": "無法攻擊:需從己方且兵力大於 1 的相鄰地區出擊。"}
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions[from_id]
	var target: Dictionary = regions[to_id]
	var attacker_strength := int(source.get("strength", 0))
	var defender_strength := int(target.get("strength", 0))
	var attack_power := attacker_strength + int(source.get("production", 0))
	var defense_power := defender_strength + int(target.get("production", 0))
	source["strength"] = max(1, attacker_strength - 1)
	if attack_power >= defense_power:
		target["owner"] = String(conquest.get("player_country", ""))
		target["strength"] = max(1, attacker_strength - defender_strength + 1)
		regions[from_id] = source
		regions[to_id] = target
		conquest["regions"] = regions
		state["conquest"] = conquest
		CampaignManager.save_state(state)
		return {"ok": true, "message": "%s 攻佔 %s。" % [_region_name(source), _region_name(target)]}
	target["strength"] = max(1, defender_strength - max(1, int(attacker_strength / 2)))
	regions[from_id] = source
	regions[to_id] = target
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	return {"ok": true, "message": "%s 進攻受挫,%s 守軍削弱。" % [_region_name(source), _region_name(target)]}

static func end_turn(state: Dictionary, map_data: Dictionary) -> Array[String]:
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var messages: Array[String] = []
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		region["strength"] = int(region.get("strength", 0)) + max(1, int(region.get("production", 0)) / 2)
		regions[region_id] = region
	var countries: Dictionary = map_data.get("countries", {})
	var player_country := String(conquest.get("player_country", ""))
	for country_id in countries.keys():
		var cid := String(country_id)
		if cid == player_country:
			continue
		var attack := _best_ai_attack(regions, cid)
		if attack.is_empty():
			continue
		var source: Dictionary = regions[attack["from"]]
		var target: Dictionary = regions[attack["to"]]
		var attack_power := int(source.get("strength", 0)) + int(source.get("production", 0))
		var defense_power := int(target.get("strength", 0)) + int(target.get("production", 0))
		source["strength"] = max(1, int(source.get("strength", 0)) - 1)
		if attack_power > defense_power:
			target["owner"] = cid
			target["strength"] = max(1, int(source.get("strength", 0)) - int(target.get("strength", 0)) + 1)
			messages.append("%s 佔領 %s。" % [
				String(countries.get(cid, {}).get("name_zh", cid)),
				_region_name(target),
			])
		regions[attack["from"]] = source
		regions[attack["to"]] = target
	conquest["turn"] = int(conquest.get("turn", 1)) + 1
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	if messages.is_empty():
		messages.append("各國整補兵力,戰線暫無重大變化。")
	return messages

static func victory_status(state: Dictionary, map_data: Dictionary) -> String:
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var player_country := String(conquest.get("player_country", ""))
	var player_regions := 0
	var enemy_regions := 0
	for region in regions.values():
		if String(region.get("owner", "")) == player_country:
			player_regions += 1
		else:
			enemy_regions += 1
	if enemy_regions == 0:
		return "已征服全世界"
	if player_regions == 0:
		return "國家已滅亡"
	return ""

static func owned_region_count(state: Dictionary, map_data: Dictionary, country_id: String) -> int:
	var count := 0
	var regions: Dictionary = conquest_state(state, map_data).get("regions", {})
	for region in regions.values():
		if String(region.get("owner", "")) == country_id:
			count += 1
	return count

static func _initial_regions(map_data: Dictionary) -> Dictionary:
	var out := {}
	for item in map_data.get("regions", []):
		var region: Dictionary = item
		var id := String(region.get("id", ""))
		out[id] = {
			"id": id,
			"name_zh": String(region.get("name_zh", id)),
			"owner": String(region.get("owner", "neutral")),
			"x": int(region.get("x", 0)),
			"y": int(region.get("y", 0)),
			"production": int(region.get("production", 1)),
			"strength": int(region.get("production", 1)) + 2,
			"neighbors": region.get("neighbors", []),
		}
	return out

static func _best_ai_attack(regions: Dictionary, country_id: String) -> Dictionary:
	var best := {}
	var best_score := -999999
	for region_id in regions.keys():
		var source: Dictionary = regions[region_id]
		if String(source.get("owner", "")) != country_id or int(source.get("strength", 0)) <= 1:
			continue
		for neighbor_id in source.get("neighbors", []):
			var target: Dictionary = regions.get(String(neighbor_id), {})
			if target.is_empty() or String(target.get("owner", "")) == country_id:
				continue
			var score := int(source.get("strength", 0)) + int(target.get("production", 0)) - int(target.get("strength", 0))
			if score > best_score:
				best_score = score
				best = {"from": String(region_id), "to": String(neighbor_id)}
	return best

static func _region_name(region: Dictionary) -> String:
	return String(region.get("name_zh", region.get("id", "")))
