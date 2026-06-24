extends SceneTree

# Tests for ConquestRecruit — recruitment/disband economy + force generation.
# Run: godot --headless --script res://tests/test_conquest_recruit.gd

const ConquestRecruit := preload("res://scripts/scenario/conquest_recruit.gd")

const CATALOG := {
	"infantry": {"name_zh": "步兵", "cost": 1},
	"at_gun": {"name_zh": "反戰車砲", "cost": 2},
	"medium_tank": {"name_zh": "中戰車", "cost": 3},
}

func _init() -> void:
	var pass_count := 0
	var fail_count := 0
	if _test_cost_lookup(): pass_count += 1
	else: fail_count += 1
	if _test_recruit_deducts_and_appends(): pass_count += 1
	else: fail_count += 1
	if _test_recruit_rejects_when_poor(): pass_count += 1
	else: fail_count += 1
	if _test_recruit_rejects_at_cap(): pass_count += 1
	else: fail_count += 1
	if _test_disband_refunds_and_removes(): pass_count += 1
	else: fail_count += 1
	if _test_generate_force_tiers(): pass_count += 1
	else: fail_count += 1
	print("ConquestRecruit tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

func _test_cost_lookup() -> bool:
	if ConquestRecruit.unit_cost(CATALOG, "medium_tank") != 3:
		printerr("FAIL: medium_tank cost should be 3")
		return false
	if ConquestRecruit.unit_cost(CATALOG, "unknown") < 1:
		printerr("FAIL: unknown type should fall back to a positive default cost")
		return false
	return true

func _test_recruit_deducts_and_appends() -> bool:
	var region := {"strength": 5, "garrison": []}
	var result := ConquestRecruit.recruit(region, CATALOG, "medium_tank", 7)
	if not bool(result.get("ok", false)):
		printerr("FAIL: recruit should succeed with enough strength")
		return false
	if int(region.get("strength", -1)) != 2:
		printerr("FAIL: recruit should deduct cost (5-3=2), got %d" % int(region.get("strength", -1)))
		return false
	var garrison: Array = region.get("garrison", [])
	if garrison.size() != 1:
		printerr("FAIL: garrison should hold 1 unit")
		return false
	var rec: Dictionary = garrison[0]
	if int(rec.get("id", -1)) != 7 or String(rec.get("type", "")) != "medium_tank" \
			or int(rec.get("xp", -1)) != 0 or int(rec.get("rank", -1)) != 0:
		printerr("FAIL: recruited record fields wrong: %s" % str(rec))
		return false
	return true

func _test_recruit_rejects_when_poor() -> bool:
	var region := {"strength": 0, "garrison": []}
	if ConquestRecruit.can_recruit(region, CATALOG, "infantry"):
		printerr("FAIL: can_recruit should be false with 0 strength")
		return false
	var result := ConquestRecruit.recruit(region, CATALOG, "infantry", 1)
	if bool(result.get("ok", false)) or not region.get("garrison", []).is_empty():
		printerr("FAIL: recruit should reject and not mutate when too poor")
		return false
	return true

func _test_recruit_rejects_at_cap() -> bool:
	var garrison: Array = []
	for i in range(ConquestRecruit.GARRISON_CAP):
		garrison.append({"id": i, "type": "infantry", "xp": 0, "rank": 0, "name": "x"})
	var region := {"strength": 99, "garrison": garrison}
	if ConquestRecruit.can_recruit(region, CATALOG, "infantry"):
		printerr("FAIL: can_recruit should be false at garrison cap")
		return false
	return true

func _test_disband_refunds_and_removes() -> bool:
	var region := {"strength": 2, "garrison": [
		{"id": 7, "type": "medium_tank", "xp": 0, "rank": 0, "name": "中戰車 #7"},
	]}
	var result := ConquestRecruit.disband(region, CATALOG, 7)
	if not bool(result.get("ok", false)):
		printerr("FAIL: disband should succeed for an existing unit")
		return false
	if int(region.get("strength", -1)) != 5:
		printerr("FAIL: disband should refund cost (2+3=5), got %d" % int(region.get("strength", -1)))
		return false
	if not region.get("garrison", []).is_empty():
		printerr("FAIL: disband should remove the unit from garrison")
		return false
	return true

func _test_generate_force_tiers() -> bool:
	var weak := ConquestRecruit.generate_force(2)
	if weak.size() < 1:
		printerr("FAIL: weak region should still field at least 1 unit")
		return false
	var strong := ConquestRecruit.generate_force(10)
	if strong.size() > 6:
		printerr("FAIL: generated force should be capped at 6, got %d" % strong.size())
		return false
	if not strong.has("medium_tank"):
		printerr("FAIL: a strong region's force should include armor")
		return false
	if strong.size() <= weak.size():
		printerr("FAIL: stronger region should field a larger force than a weak one")
		return false
	return true
