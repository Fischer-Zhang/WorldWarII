extends SceneTree

# Standalone test for Pathfinding. Uses a stub hex_map with a fixed terrain layout.
# Run with: godot --headless --script res://tests/test_pathfinding.gd

class StubHexMap:
	var tiles: Dictionary = {}
	var costs: Dictionary = {"plain": 1, "forest": 2, "river": 4}
	func terrain_at(coord: Vector2i) -> String:
		return tiles.get(coord, "")
	func move_cost_at(coord: Vector2i) -> int:
		var t: String = tiles.get(coord, "")
		return costs.get(t, 999) if t != "" else 999

func _init() -> void:
	# Build a 5x5 axial patch, all plain (move_cost = 1)
	var stub := StubHexMap.new()
	for q in range(-2, 3):
		for r in range(-2, 3):
			stub.tiles[Vector2i(q, r)] = "plain"

	var pass_count := 0
	var fail_count := 0

	# 1) 2 move pts on open ground: should reach 18 hexes (ring1=6 + ring2=12)
	var range1: Dictionary = Pathfinding.movement_range(Vector2i(0, 0), 2, stub, {})
	if range1.size() == 18:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: open-ground range expected 18 got ", range1.size())

	# 2) Cost stored correctly (a distance-2 neighbor should cost 2)
	if range1.has(Vector2i(2, 0)) and range1[Vector2i(2, 0)] == 2:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: cost to (2,0) wrong: ", range1.get(Vector2i(2, 0), "missing"))

	# 3) Forest doubles cost
	stub.tiles[Vector2i(1, 0)] = "forest"
	var range2 := Pathfinding.movement_range(Vector2i(0, 0), 2, stub, {})
	if range2.has(Vector2i(1, 0)) and range2[Vector2i(1, 0)] == 2:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: forest cost expected 2 got ", range2.get(Vector2i(1, 0), "missing"))

	# 4) Occupied hex blocks
	stub.tiles[Vector2i(1, 0)] = "plain"
	var range3 := Pathfinding.movement_range(
		Vector2i(0, 0), 2, stub, {Vector2i(1, 0): 1}
	)
	if not range3.has(Vector2i(1, 0)):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: blocked hex should not be in range")

	# 5) Range does not include the start
	if not range3.has(Vector2i(0, 0)):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: range should not include start")

	# 6) Off-map filtered out (small 2-tile strip)
	var small := StubHexMap.new()
	small.tiles[Vector2i(0, 0)] = "plain"
	small.tiles[Vector2i(1, 0)] = "plain"
	var range4 := Pathfinding.movement_range(Vector2i(0, 0), 5, small, {})
	if range4.size() == 1 and range4.has(Vector2i(1, 0)):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: off-map filtering broken; got ", range4)

	# ZoC tests use a small object that mimics a Unit for occupancy.
	# `faction_id` is the only field movement_range looks at.
	var enemy_unit := RefCounted.new()
	enemy_unit.set_script(GDScript.new())
	# Simpler: use a Dictionary-like duck — Pathfinding just reads `.faction_id`.
	# Make a tiny class.
	var enemy := EnemyStub.new("axis")
	var friendly := EnemyStub.new("allies")

	# 7) ZoC: hex adjacent to enemy costs ZOC_PENALTY extra
	stub.tiles[Vector2i(1, 0)] = "plain"  # reset
	# place enemy at (1, 1); (1, 0) is its neighbor and so is (0, 1).
	var occ_zoc := {Vector2i(1, 1): enemy}
	var range_zoc := Pathfinding.movement_range(
		Vector2i(0, 0), 1, stub, occ_zoc, "allies"
	)
	# (1, 0) is adjacent to (1, 1) enemy → costs 1 + 2 = 3, exceeds budget 1 → not in range
	if not range_zoc.has(Vector2i(1, 0)):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: ZoC should block (1,0) with 1 move pt; got cost ",
			range_zoc[Vector2i(1, 0)])

	# 8) Without ZoC (no faction passed), same hex IS reachable
	var range_no_zoc := Pathfinding.movement_range(
		Vector2i(0, 0), 1, stub, occ_zoc
	)
	if range_no_zoc.has(Vector2i(1, 0)) and range_no_zoc[Vector2i(1, 0)] == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: without faction param, ZoC must not apply; got ",
			range_no_zoc.get(Vector2i(1, 0), "missing"))

	# 9) Same-faction adjacent does NOT impose ZoC
	var occ_friend := {Vector2i(1, 1): friendly}
	var range_friend := Pathfinding.movement_range(
		Vector2i(0, 0), 1, stub, occ_friend, "allies"
	)
	if range_friend.has(Vector2i(1, 0)) and range_friend[Vector2i(1, 0)] == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: friendly adjacency must not apply ZoC; got ",
			range_friend.get(Vector2i(1, 0), "missing"))

	# 10) Reconstructed path must honor ZoC-adjusted cumulative costs.
	# The goal itself is in enemy ZoC, so the reconstructed path is only valid
	# if its accumulated terrain + ZoC cost matches the Dijkstra cost map.
	var range_zoc_path := Pathfinding.movement_range(
		Vector2i(0, 0), 6, stub, occ_zoc, "allies"
	)
	var path_zoc := Pathfinding.reconstruct_path(
		Vector2i(0, 0), Vector2i(2, 0), range_zoc_path, stub, occ_zoc, "allies"
	)
	var path_cost := 0
	for i in range(1, path_zoc.size()):
		path_cost += stub.move_cost_at(path_zoc[i])
		if Pathfinding._enters_enemy_zoc(path_zoc[i], occ_zoc, "allies"):
			path_cost += Pathfinding.ZOC_PENALTY
	if path_zoc.size() > 1 and path_zoc[0] == Vector2i(0, 0) \
			and path_zoc[-1] == Vector2i(2, 0) \
			and path_cost == range_zoc_path[Vector2i(2, 0)]:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: reconstructed ZoC path wrong: path=%s cost=%d expected=%s" % [
			path_zoc, path_cost, range_zoc_path.get(Vector2i(2, 0), "missing"),
		])

	print("Pathfinding tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)

class EnemyStub:
	var faction_id: String
	func _init(fid: String) -> void:
		faction_id = fid
