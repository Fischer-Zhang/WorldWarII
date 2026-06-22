class_name AIController
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const Unit := preload("res://scripts/units/unit.gd")

# Heuristic AI: scores every reachable hex for each unit, picks the best,
# moves there, attacks if a target is available.
#
# Caller provides callbacks to execute moves/attacks because the controller
# itself doesn't touch the scene. This keeps the controller pure and testable.

const W_OBJECTIVE := 1.0
const W_ATTACK := 2.5
const W_EXPOSURE := 0.5
const W_TERRAIN := 0.3

var personality: String = "aggressive"
var battle: Object  # the battle node — duck-typed (provides hex_map, units, factions)

func _init(battle_node: Object, ai_personality: String = "aggressive") -> void:
	battle = battle_node
	personality = ai_personality

func plan_for_unit(unit: Unit) -> Dictionary:
	# Returns: { "move_to": Vector2i, "attack": Unit | null, "score": float }
	var hex_map = battle.hex_map
	var atk_def: Dictionary = DataLoader.get_unit_def(unit.type_id)
	var move_pts := int(atk_def.get("move", 0))
	var rng := int(atk_def.get("range", 1))

	var reachable: Dictionary = Pathfinding.movement_range(
		unit.coord, move_pts, hex_map, hex_map.occupants
	)
	# Include staying in place as a candidate
	var candidates: Array = [unit.coord]
	for c in reachable.keys():
		candidates.append(c)

	var enemies := _enemy_units(unit.faction_id)
	if enemies.is_empty():
		return {"move_to": unit.coord, "attack": null, "score": 0.0}

	var best := unit.coord
	var best_score := -INF
	var best_target: Unit = null

	for cand in candidates:
		var coord: Vector2i = cand
		var score := _score_position(unit, coord, enemies, hex_map, atk_def, rng)
		var target := _best_attack_from(coord, rng, enemies, atk_def)
		if score > best_score:
			best_score = score
			best = coord
			best_target = target

	return {"move_to": best, "attack": best_target, "score": best_score}

func _score_position(
	unit: Unit,
	pos: Vector2i,
	enemies: Array,
	hex_map,
	atk_def: Dictionary,
	rng: int,
) -> float:
	# Closer to nearest enemy is better (negative distance contributes)
	var nearest := 9999
	for e in enemies:
		var d := HexCoord.distance(pos, (e as Unit).coord)
		if d < nearest:
			nearest = d
	var dist_term := -float(nearest) * W_OBJECTIVE

	# Best damage we could deal from this hex
	var attack_term := 0.0
	for e in enemies:
		var enemy: Unit = e
		var d := HexCoord.distance(pos, enemy.coord)
		if d > rng:
			continue
		var def_def := DataLoader.get_unit_def(enemy.type_id)
		var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		var r := CombatResolver.resolve(atk_def, def_def, unit.hp, enemy.hp, atk_terr, def_terr, d)
		var dmg_score := float(r.damage_to_defender)
		# kill bonus: bigger reward if this would kill the target
		if r.defender_dies:
			dmg_score += 5.0
		# risk: subtract counter damage we'd eat
		dmg_score -= 0.6 * float(r.counter_damage)
		attack_term = max(attack_term, dmg_score)
	attack_term *= W_ATTACK

	# Exposure: enemies that could shoot us next turn
	var exposure := 0.0
	for e in enemies:
		var enemy: Unit = e
		var enemy_def := DataLoader.get_unit_def(enemy.type_id)
		var enemy_rng := int(enemy_def.get("range", 1))
		var enemy_move := int(enemy_def.get("move", 0))
		# rough approximation: anyone within (enemy_move + enemy_rng) hexes is a threat
		if HexCoord.distance(pos, enemy.coord) <= enemy_move + enemy_rng:
			exposure += float(enemy_def.get("attack", 0)) * 0.5
	var exposure_term := -exposure * W_EXPOSURE

	# Terrain defense bonus
	var terr_def := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
	var terrain_term := float(terr_def.get("defense", 0)) * W_TERRAIN

	var total := dist_term + attack_term + exposure_term + terrain_term
	return _apply_personality(total, attack_term, exposure_term)

func _apply_personality(total: float, attack_term: float, exposure_term: float) -> float:
	match personality:
		"aggressive":
			return total + attack_term * 0.3  # weight attacks even more
		"defensive":
			return total + exposure_term * 0.8  # avoid risk more
		"hold":
			return total - 0.5  # discourage moving at all (slight bias)
		_:
			return total

func _best_attack_from(pos: Vector2i, rng: int, enemies: Array, atk_def: Dictionary) -> Unit:
	var hex_map = battle.hex_map
	var best: Unit = null
	var best_dmg := 0
	for e in enemies:
		var enemy: Unit = e
		var d := HexCoord.distance(pos, enemy.coord)
		if d > rng:
			continue
		var def_def := DataLoader.get_unit_def(enemy.type_id)
		var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		# attacker_hp uses the unit's current — passed via a hack: we look up via battle.units
		# Actually for a candidate evaluation we use the unit's current HP, which we don't have here.
		# Use max HP as approximation (this only affects target tie-breaking).
		var atk_hp := int(atk_def.get("hp", 1))
		var r := CombatResolver.resolve(atk_def, def_def, atk_hp, enemy.hp, atk_terr, def_terr, d)
		var dmg := r.damage_to_defender + (10 if r.defender_dies else 0)
		if dmg > best_dmg:
			best_dmg = dmg
			best = enemy
	return best

func _enemy_units(own_faction: String) -> Array:
	var out: Array = []
	for u in battle.units:
		var unit: Unit = u
		if unit.is_alive() and unit.faction_id != own_faction:
			out.append(unit)
	return out
