class_name ConquestManager
extends RefCounted

const CampaignManager := preload("res://scripts/scenario/campaign_manager.gd")
const ConquestRecruit := preload("res://scripts/scenario/conquest_recruit.gd")

static func conquest_state(state: Dictionary, map_data: Dictionary) -> Dictionary:
	var conquest: Dictionary = state.get("conquest", {})
	if not conquest.has("turn"):
		conquest["turn"] = 1
	if not conquest.has("player_country"):
		conquest["player_country"] = String(map_data.get("start_country", "germany"))
	if not conquest.has("regions"):
		conquest["regions"] = _initial_regions(map_data)
	if not conquest.has("next_unit_id"):
		conquest["next_unit_id"] = 1
	# Lazy-migrate saves that predate per-region garrisons.
	for rid in conquest.get("regions", {}).keys():
		var region: Dictionary = conquest["regions"][rid]
		if not region.has("garrison"):
			region["garrison"] = []
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
	if (source.get("garrison", []) as Array).is_empty():
		return false
	var neighbors: Array = source.get("neighbors", [])
	return neighbors.has(to_id)

static func can_transfer(state: Dictionary, map_data: Dictionary, from_id: String, to_id: String) -> bool:
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions.get(from_id, {})
	var target: Dictionary = regions.get(to_id, {})
	if source.is_empty() or target.is_empty() or from_id == to_id:
		return false
	var player_country := String(conquest.get("player_country", ""))
	if String(source.get("owner", "")) != player_country:
		return false
	if String(target.get("owner", "")) != player_country:
		return false
	if (source.get("garrison", []) as Array).is_empty():
		return false
	var neighbors: Array = source.get("neighbors", [])
	return neighbors.has(to_id)

static func transfer_units(state: Dictionary, map_data: Dictionary, from_id: String, to_id: String, ids: Array = []) -> Dictionary:
	# Relocate recruited army units between adjacent owned regions. `ids` selects
	# which garrison units move; an empty `ids` moves the whole garrison. Strength
	# is NOT moved — it stays as each region's local recruitment pool.
	if not can_transfer(state, map_data, from_id, to_id):
		return {"ok": false, "message": "無法調動:需選擇相鄰的兩塊己方地區,且出發地要有駐軍。"}
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions[from_id]
	var target: Dictionary = regions[to_id]
	var src_g: Array = source.get("garrison", [])
	var tgt_g: Array = target.get("garrison", [])
	var move_all := ids.is_empty()
	var want := {}
	for uid in ids:
		want[int(uid)] = true
	var kept: Array = []
	var moved := 0
	for rec in src_g:
		var r: Dictionary = rec
		if (move_all or want.has(int(r.get("id", -1)))) and tgt_g.size() < ConquestRecruit.GARRISON_CAP:
			tgt_g.append(r)
			moved += 1
		else:
			kept.append(r)
	if moved == 0:
		return {"ok": false, "message": "%s 的守備已滿,無法再進駐。" % _region_name(target)}
	source["garrison"] = kept
	target["garrison"] = tgt_g
	regions[from_id] = source
	regions[to_id] = target
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	return {"ok": true, "message": "已將 %d 支部隊從 %s 調往 %s。" % [moved, _region_name(source), _region_name(target)]}

static func resolve_battle_result(
	state: Dictionary,
	map_data: Dictionary,
	from_id: String,
	to_id: String,
	player_won: bool,
	survivors: Array = [],
) -> Dictionary:
	# Applies a fought conquest battle to the strategic map. The attacking
	# region's garrison is reduced to the survivors (keeping their gained xp);
	# on a win the survivors advance into and hold the captured region, on a
	# loss they retreat to the source.
	if not can_attack(state, map_data, from_id, to_id):
		return {"ok": false, "message": "戰役結果無法套用:征服地圖狀態已變更。"}
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions[from_id]
	var target: Dictionary = regions[to_id]
	var player_country := String(conquest.get("player_country", ""))
	var survived := _apply_survivors(source.get("garrison", []), survivors)
	var message := ""
	if player_won:
		target["owner"] = player_country
		target["garrison"] = survived
		target["strength"] = maxi(1, int(target.get("production", 1)))
		source["garrison"] = []
		message = "%s 攻佔 %s,%d 支部隊進駐。" % [_region_name(source), _region_name(target), survived.size()]
	else:
		source["garrison"] = survived
		target["strength"] = maxi(1, int(target.get("strength", 0)) - 1)
		message = "%s 進攻受挫,殘部撤回(剩 %d 支)。" % [_region_name(source), survived.size()]
	regions[from_id] = source
	regions[to_id] = target
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	return {"ok": true, "message": message}

static func _apply_survivors(garrison: Array, survivors: Array) -> Array:
	# Keep only the garrison records whose unit survived, updating xp/rank from
	# the battle outcome. Casualties are dropped.
	var by_id := {}
	for s in survivors:
		by_id[int((s as Dictionary).get("roster_id", -1))] = s
	var kept: Array = []
	for rec in garrison:
		var record: Dictionary = rec
		if by_id.has(int(record.get("id", -1))):
			var surv: Dictionary = by_id[int(record.get("id", -1))]
			record["xp"] = int(surv.get("xp", record.get("xp", 0)))
			record["rank"] = int(surv.get("rank", record.get("rank", 0)))
			kept.append(record)
	return kept

static func is_enemy_phase(state: Dictionary, map_data: Dictionary) -> bool:
	return bool(conquest_state(state, map_data).get("ai_phase", false))

static func end_turn(state: Dictionary, map_data: Dictionary) -> Dictionary:
	# Re-entrant enemy phase. Starts a fresh phase (strength regen + AI queue) if
	# none is in progress, then processes queued AI countries until the queue
	# drains ("done") or an AI attack targets a PLAYER-owned region ("defend"),
	# at which point it pauses so the player can fight the defensive battle. The
	# caller invokes end_turn again after the battle to resume the queue.
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var player_country := String(conquest.get("player_country", ""))
	var countries: Dictionary = map_data.get("countries", {})
	if not bool(conquest.get("ai_phase", false)):
		for region_id in regions.keys():
			var region: Dictionary = regions[region_id]
			region["strength"] = int(region.get("strength", 0)) + max(1, int(region.get("production", 0)) / 2)
			regions[region_id] = region
		conquest["ai_queue"] = _enemy_countries(regions, player_country)
		conquest["ai_messages"] = []
		conquest["ai_phase"] = true
	var queue: Array = conquest.get("ai_queue", [])
	var messages: Array = conquest.get("ai_messages", [])
	while not queue.is_empty():
		var cid := String(queue.pop_front())
		var attack := _best_ai_attack(regions, cid)
		if attack.is_empty():
			continue
		var from_id := String(attack["from"])
		var to_id := String(attack["to"])
		var source: Dictionary = regions[from_id]
		var target: Dictionary = regions[to_id]
		if String(target.get("owner", "")) == player_country:
			# Pause for a player-fought defensive battle; resume on re-entry.
			conquest["ai_queue"] = queue
			conquest["ai_messages"] = messages
			state["conquest"] = conquest
			CampaignManager.save_state(state)
			return {
				"status": "defend",
				"from": from_id,
				"to": to_id,
				"attacker_country": cid,
				"messages": messages.duplicate(),
			}
		# AI-vs-AI / neutral: abstract strength resolution (no player involved).
		var attack_power := int(source.get("strength", 0)) + int(source.get("production", 0))
		var defense_power := int(target.get("strength", 0)) + int(target.get("production", 0))
		source["strength"] = max(1, int(source.get("strength", 0)) - 1)
		if attack_power > defense_power:
			target["owner"] = cid
			target["strength"] = max(1, int(source.get("strength", 0)) - int(target.get("strength", 0)) + 1)
			target["garrison"] = []
			messages.append("%s 佔領 %s。" % [
				String(countries.get(cid, {}).get("name_zh", cid)),
				_region_name(target),
			])
		regions[from_id] = source
		regions[to_id] = target
	# Queue drained — finish the enemy phase.
	conquest["turn"] = int(conquest.get("turn", 1)) + 1
	conquest["ai_phase"] = false
	conquest["ai_queue"] = []
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	if messages.is_empty():
		messages.append("各國整補兵力,戰線暫無重大變化。")
	return {"status": "done", "messages": messages}

static func _enemy_countries(regions: Dictionary, player_country: String) -> Array:
	# Countries (excluding the player and neutral) owning at least one region.
	var seen := {}
	var out: Array = []
	for region in regions.values():
		var owner := String(region.get("owner", ""))
		if owner == player_country or owner == "neutral" or owner == "":
			continue
		if not seen.has(owner):
			seen[owner] = true
			out.append(owner)
	return out

static func resolve_defense_result(
	state: Dictionary,
	map_data: Dictionary,
	attacker_country: String,
	from_id: String,
	to_id: String,
	player_defended: bool,
	survivors: Array = [],
) -> Dictionary:
	# Applies a player-fought defensive battle: held -> surviving defenders stay
	# and the attacker is bloodied; fell -> the region is captured by the enemy.
	var conquest := conquest_state(state, map_data)
	var regions: Dictionary = conquest.get("regions", {})
	var source: Dictionary = regions.get(from_id, {})
	var target: Dictionary = regions.get(to_id, {})
	if source.is_empty() or target.is_empty():
		return {"ok": false, "message": "防守結果無法套用。"}
	var message := ""
	if player_defended:
		target["garrison"] = _apply_survivors(target.get("garrison", []), survivors)
		source["strength"] = maxi(1, int(source.get("strength", 0)) - 2)
		message = "守住了 %s。" % _region_name(target)
	else:
		target["owner"] = attacker_country
		target["garrison"] = []
		target["strength"] = maxi(1, int(target.get("production", 1)))
		message = "%s 失守,落入敵手。" % _region_name(target)
	regions[from_id] = source
	regions[to_id] = target
	conquest["regions"] = regions
	state["conquest"] = conquest
	CampaignManager.save_state(state)
	return {"ok": true, "message": message}

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
			"garrison": [],
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
