extends SceneTree

const ConquestCatalog := preload("res://scripts/scenario/conquest_catalog.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var data_loader := root.get_node_or_null("DataLoader")
	if data_loader == null:
		printerr("FAIL: missing DataLoader autoload")
		quit(1)
		return
	var pass_count := 0
	var fail_count := 0

	if _test_region_scenario_mapping(data_loader):
		pass_count += 1
	else:
		fail_count += 1

	if _test_country_side_mapping(data_loader):
		pass_count += 1
	else:
		fail_count += 1

	print("Conquest UI data tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _test_region_scenario_mapping(data_loader: Node) -> bool:
	var ok := true
	var scenario_ids := {}
	for scenario in data_loader.get("scenarios"):
		scenario_ids[String(scenario.get("id", ""))] = true

	var conquest_map: Dictionary = data_loader.get("conquest_map")
	for region in conquest_map.get("regions", []):
		var region_id := String(region.get("id", ""))
		if not ConquestCatalog.REGION_SCENARIOS.has(region_id):
			printerr("FAIL: conquest region missing tactical scenario mapping: %s" % region_id)
			ok = false
			continue
		var scenario_id := String(ConquestCatalog.REGION_SCENARIOS.get(region_id, ""))
		if not scenario_ids.has(scenario_id):
			printerr("FAIL: conquest region %s maps to unknown scenario %s" % [region_id, scenario_id])
			ok = false
	if not scenario_ids.has(ConquestCatalog.FALLBACK_SCENARIO):
		printerr("FAIL: conquest fallback scenario is unknown: %s" % ConquestCatalog.FALLBACK_SCENARIO)
		ok = false
	return ok

func _test_country_side_mapping(data_loader: Node) -> bool:
	var ok := true
	var conquest_map: Dictionary = data_loader.get("conquest_map")
	var countries: Dictionary = conquest_map.get("countries", {})
	for country_id in countries.keys():
		var cid := String(country_id)
		if cid == "neutral":
			continue
		if not ConquestCatalog.COUNTRY_SIDE.has(cid):
			printerr("FAIL: conquest country missing side mapping: %s" % cid)
			ok = false
			continue
		var side := String(ConquestCatalog.COUNTRY_SIDE.get(cid, ""))
		if side not in ["axis", "allies", "soviet"]:
			printerr("FAIL: conquest country %s has invalid side %s" % [cid, side])
			ok = false
	return ok
