class_name Visibility
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")

# Hex line-of-sight + per-faction visibility.
# Symmetric model: every faction (player or AI) calls compute_visible_hexes
# for its own units. The Battle node renders only the *player's* fog overlay,
# but each AI faction independently consults its own visibility set (plus the
# last-known-position memory it maintains) when planning. See
# docs/ARCHITECTURE.md → "Symmetric design + AI memory".

# `hex_map` is duck-typed (needs terrain_at + tiles dict).

static func has_los(observer: Vector2i, target: Vector2i, hex_map) -> bool:
	# Returns true if `observer` can see `target`. A non-endpoint hex on
	# the line whose terrain blocks LOS interrupts vision. `hex_map`
	# must provide `terrain_at(coord) -> String` and `blocks_los_at(coord) -> bool`.
	if observer == target:
		return true
	var path: Array = HexCoord.line(observer, target)
	# Skip endpoints (index 0 and last)
	for i in range(1, path.size() - 1):
		var hex: Vector2i = path[i]
		if hex_map.terrain_at(hex) == "":
			continue  # off-map — don't treat as blocker
		if hex_map.blocks_los_at(hex):
			return false
	return true

static func compute_visible_hexes(
	units: Array, faction_id: String, hex_map, unit_defs: Dictionary = {}
) -> Dictionary:
	# Returns the set of hexes (as a Dictionary[Vector2i, true]) visible
	# to any living unit of `faction_id`.
	var visible: Dictionary = {}
	for u in units:
		var unit = u
		if not unit.is_alive() or unit.faction_id != faction_id:
			continue
		var unit_def: Dictionary = unit_defs.get(unit.type_id, {})
		var vision: int = int(unit_def.get("vision", 3))
		visible[unit.coord] = true  # unit's own hex always visible
		for c in HexCoord.range_within(unit.coord, vision):
			var coord: Vector2i = c
			if hex_map.terrain_at(coord) == "":
				continue  # off-map
			if has_los(unit.coord, coord, hex_map):
				visible[coord] = true
	return visible
