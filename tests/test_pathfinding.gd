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

	# 1) 3 move pts on open ground: should reach 18 hexes (ring1=6 + ring2=12)
	var range1 := Pathfinding.movement_range(Vector2i(0, 0), 3, stub, {})
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

	print("Pathfinding tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
