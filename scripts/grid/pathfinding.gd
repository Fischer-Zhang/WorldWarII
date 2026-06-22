class_name Pathfinding
extends RefCounted

# Dijkstra-style BFS for hex movement.
# Returns `coord -> cumulative_cost` for every hex reachable within `move_points`,
# honoring per-terrain move_cost and blocking on occupied hexes (except the start).
#
# `occupied` is Dictionary[Vector2i, Object] — any non-null value blocks the hex.

static func movement_range(
	start: Vector2i,
	move_points: int,
	hex_map,  # duck-typed: needs terrain_at(coord) and move_cost_at(coord)
	occupied: Dictionary,
) -> Dictionary:
	var cost_to: Dictionary = {start: 0}
	var frontier: Array = [start]  # poor-man's priority via re-relaxation; map sizes are small

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var current_cost: int = cost_to[current]
		for n in HexCoord.neighbors(current):
			if hex_map.terrain_at(n) == "":
				continue  # off-map
			if occupied.has(n) and occupied[n] != null:
				continue  # blocked by another unit
			var step_cost: int = hex_map.move_cost_at(n)
			var new_cost := current_cost + step_cost
			if new_cost > move_points:
				continue
			if not cost_to.has(n) or new_cost < cost_to[n]:
				cost_to[n] = new_cost
				frontier.append(n)

	cost_to.erase(start)  # caller does not need to know it can "stay"
	return cost_to

static func reconstruct_path(
	start: Vector2i,
	goal: Vector2i,
	cost_to: Dictionary,
	hex_map,
) -> Array[Vector2i]:
	# Walk backwards from goal to start by picking the neighbor with the cheapest cost.
	if not cost_to.has(goal):
		return []
	var path: Array[Vector2i] = [goal]
	var cursor := goal
	var safety := 256
	while cursor != start and safety > 0:
		safety -= 1
		var best: Vector2i = cursor
		var best_cost: int = cost_to[cursor]
		for n in HexCoord.neighbors(cursor):
			if n == start:
				best = n
				best_cost = -1
				break
			if cost_to.has(n) and cost_to[n] < best_cost:
				var step: int = hex_map.move_cost_at(cursor)
				if cost_to[n] + step == cost_to[cursor]:
					best = n
					best_cost = cost_to[n]
		if best == cursor:
			break  # no progress; bail
		cursor = best
		path.append(cursor)
	path.reverse()
	return path

