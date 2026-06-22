class_name UnitFactory
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const HexMap := preload("res://scripts/grid/hex_map.gd")

# Builds Unit instances from a scenario JSON.
# Returns: { "units": Array[Unit], "factions": Dictionary[String, Dictionary] }

const UNIT_SCRIPT := preload("res://scripts/units/unit.gd")

static func build(scenario: Dictionary, hex_map: HexMap) -> Dictionary:
	var factions := {}
	for f in scenario.get("factions", []):
		var fid := String(f.get("id", ""))
		factions[fid] = {
			"id": fid,
			"name": String(f.get("name", fid)),
			"controller": String(f.get("controller", "ai")),
			"color": Color(String(f.get("color", "#cccccc"))),
			"ai": String(f.get("ai", "")),
		}

	var units: Array = []
	for u in scenario.get("units", []):
		var type_id := String(u.get("type", ""))
		var faction_id := String(u.get("faction", ""))
		var at_arr: Array = u.get("at", [0, 0])
		# scenario coords come in odd-r offset (col, row); convert to axial
		var col := int(at_arr[0])
		var row := int(at_arr[1])
		var coord := Vector2i(col - (row >> 1), row)
		var unit_name := String(u.get("name", ""))

		var unit: Unit = UNIT_SCRIPT.new()
		var color: Color = factions.get(faction_id, {}).get("color", Color.WHITE)
		unit.configure(type_id, faction_id, color, coord, unit_name)
		unit.position = HexCoord.to_pixel(coord, HexMap.HEX_SIZE)
		units.append(unit)

	return {"units": units, "factions": factions}
