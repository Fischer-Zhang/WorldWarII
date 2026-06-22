class_name AIController
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const CombatRules := preload("res://scripts/combat/combat_rules.gd")

# Heuristic AI: scores every reachable hex for each unit, picks the best,
# moves there, attacks if a target is available.
#
# Difficulty profiles tune the heuristic weights and enable an optional
# 1-ply lookahead that discounts a candidate hex by the worst counter-
# attack the player could deliver next turn.

const W_OBJECTIVE := 1.0
const W_TERRAIN := 0.3
const W_LOOKAHEAD := 1.0
const W_SCOUT := 0.45
const W_ARTILLERY_STANDOFF := 2.5
const AT_ARMOR_TARGET_BONUS := 2.0
const AT_SOFT_TARGET_PENALTY := 1.0

const DIFFICULTY_PROFILE := {
	"easy":   {"attack_w": 1.5, "kill_bonus": 2.5, "exposure_w": 0.3, "lookahead": false},
	"normal": {"attack_w": 2.5, "kill_bonus": 5.0, "exposure_w": 0.5, "lookahead": false},
	"hard":   {"attack_w": 3.0, "kill_bonus": 7.0, "exposure_w": 0.4, "lookahead": true},
}

var personality: String = "aggressive"
var difficulty: String = "normal"
var battle: Object  # the battle node — duck-typed (provides hex_map, units, factions)

# Difficulty-resolved scalars (set in _init from DIFFICULTY_PROFILE)
var _attack_w: float = 2.5
var _kill_bonus: float = 5.0
var _exposure_w: float = 0.5
var _use_lookahead: bool = false
var _data_loader = null

# Per-turn cache: player_unit -> Dictionary[Vector2i, int] (reachable hexes)
var _player_reach_cache: Dictionary = {}

func _init(battle_node: Object, ai_personality: String = "aggressive", ai_difficulty: String = "normal") -> void:
	battle = battle_node
	personality = ai_personality
	difficulty = ai_difficulty
	var p: Dictionary = DIFFICULTY_PROFILE.get(ai_difficulty, DIFFICULTY_PROFILE["normal"])
	_attack_w = float(p["attack_w"])
	_kill_bonus = float(p["kill_bonus"])
	_exposure_w = float(p["exposure_w"])
	_use_lookahead = bool(p["lookahead"])

func plan_for_unit(unit) -> Dictionary:
	# Returns: { "move_to": Vector2i, "attack": Unit | null, "score": float, "reachable": Dictionary }
	var hex_map = battle.hex_map
	var atk_def: Dictionary = _get_unit_def(unit.type_id)
	var move_pts := int(atk_def.get("move", 0))
	var rng := int(atk_def.get("range", 1))

	var reachable: Dictionary = Pathfinding.movement_range(
		unit.coord, move_pts, hex_map, hex_map.occupants, unit.faction_id
	)
	# Include staying in place as a candidate
	var candidates: Array = [unit.coord]
	for c in reachable.keys():
		candidates.append(c)

	# Symmetric fog: AI only knows enemies it can currently see + remembers.
	var known: Array = battle.get_known_enemies(unit.faction_id)
	if known.is_empty():
		return {"move_to": unit.coord, "attack": null, "score": 0.0, "reachable": reachable}

	# Only currently-visible enemies are valid attack targets.
	var visible_enemies: Array = []
	for k in known:
		if k.get("visible", false):
			visible_enemies.append(k["unit"])

	var best: Vector2i = unit.coord
	var best_score: float = -INF
	var best_target = null
	var best_action := "wait"  # "attack", "overwatch", or "wait"
	var visible_hexes: Dictionary = battle.visibility_by_faction.get(unit.faction_id, {})

	for cand in candidates:
		var coord: Vector2i = cand
		var base_score: float = _score_position(unit, coord, known, visible_enemies, hex_map, atk_def, visible_hexes)
		var target = _best_attack_from(coord, unit.faction_id, unit.type_id, visible_enemies, atk_def, visible_hexes)
		# Attack score is implicit in base_score (already includes attack_term).
		# Overwatch is an alternative: subtract the attack contribution (not
		# attacking this turn) and add the overwatch score.
		var overwatch_value: float = _overwatch_score(unit, coord, visible_enemies, hex_map, atk_def, rng)
		var attack_value: float = _best_attack_value(unit, coord, visible_enemies, hex_map, atk_def, visible_hexes)
		# attack_value and overwatch_value are both pre-weighted contributions.
		# base_score already has attack_value baked in (via _score_position).
		# To get the "overwatch" total, swap them:
		var overwatch_score: float = base_score - attack_value + overwatch_value

		if base_score > best_score:
			best_score = base_score
			best = coord
			best_target = target
			best_action = "attack" if target != null else "wait"
		if overwatch_score > best_score and not atk_def.get("indirect", false):
			best_score = overwatch_score
			best = coord
			best_target = null
			best_action = "overwatch"

	return {
		"move_to": best,
		"attack": best_target,
		"action": best_action,
		"score": best_score,
		"reachable": reachable,
	}

func _score_position(
	unit,
	pos: Vector2i,
	known: Array,
	visible_enemies: Array,
	hex_map,
	atk_def: Dictionary,
	visible_hexes: Dictionary,
) -> float:
	# Distance term: use the best known position (memory or current).
	var nearest := 9999
	for k in known:
		var d: int = HexCoord.distance(pos, k["coord"])
		if d < nearest:
			nearest = d
	var dist_term: float = -float(nearest) * W_OBJECTIVE

	# Attack term: only currently-visible enemies (can't shoot fog).
	var attack_term := 0.0
	for e in visible_enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, unit.faction_id, enemy, atk_def, hex_map, visible_hexes):
			continue
		var d: int = HexCoord.distance(pos, enemy.coord)
		var def_def: Dictionary = _get_unit_def(enemy.type_id)
		var def_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
		var r: CombatResolver.Result = CombatResolver.resolve(atk_def, def_def, unit.hp, enemy.hp, atk_terr, def_terr, d)
		var dmg_score := float(r.damage_to_defender)
		if r.defender_dies:
			dmg_score += _kill_bonus
		dmg_score += _target_role_score(unit.type_id, def_def)
		dmg_score -= 0.6 * float(r.counter_damage)
		attack_term = max(attack_term, dmg_score)
	attack_term *= _attack_w

	# Exposure: only visible enemies are a known threat.
	var exposure := 0.0
	for e in visible_enemies:
		var enemy = e
		var enemy_def: Dictionary = _get_unit_def(enemy.type_id)
		var enemy_rng := int(enemy_def.get("range", 1))
		var enemy_move := int(enemy_def.get("move", 0))
		if HexCoord.distance(pos, enemy.coord) <= enemy_move + enemy_rng:
			exposure += float(enemy_def.get("attack", 0)) * 0.5
	var exposure_term: float = -exposure * _exposure_w

	# Terrain defense bonus
	var terr_def: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
	var terrain_term: float = float(terr_def.get("defense", 0)) * W_TERRAIN
	var role_term: float = _role_position_score(unit, pos, known, visible_enemies, atk_def)

	# 1-ply lookahead: discount by worst counter the player could deliver
	# *after* we land on this hex. Only enabled on Hard difficulty.
	var lookahead_term := 0.0
	if _use_lookahead and not visible_enemies.is_empty():
		var counter_dmg: int = _lookahead_counter_damage(unit, pos, visible_enemies, hex_map, atk_def)
		lookahead_term = -float(counter_dmg) * W_LOOKAHEAD

	var total: float = dist_term + attack_term + exposure_term + terrain_term + role_term + lookahead_term
	return _apply_personality(total, attack_term, exposure_term)

func _apply_personality(total: float, attack_term: float, exposure_term: float) -> float:
	match personality:
		"aggressive":
			return total + attack_term * 0.3
		"defensive":
			return total + exposure_term * 0.8
		"hold":
			return total - 0.5
		_:
			return total

func _best_attack_value(
	unit, pos: Vector2i, visible_enemies: Array, hex_map,
	atk_def: Dictionary, visible_hexes: Dictionary,
) -> float:
	# Returns the (pre-weighted) attack-term contribution this candidate
	# position would produce — mirrors the attack block in _score_position
	# so the AI can compare attack vs overwatch on equal footing.
	var best := 0.0
	for e in visible_enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, unit.faction_id, enemy, atk_def, hex_map, visible_hexes):
			continue
		var d: int = HexCoord.distance(pos, enemy.coord)
		var def_def: Dictionary = _get_unit_def(enemy.type_id)
		var def_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
		var r: CombatResolver.Result = CombatResolver.resolve(atk_def, def_def, unit.hp, enemy.hp, atk_terr, def_terr, d)
		var dmg := float(r.damage_to_defender)
		if r.defender_dies:
			dmg += _kill_bonus
		dmg += _target_role_score(unit.type_id, def_def)
		dmg -= 0.6 * float(r.counter_damage)
		best = max(best, dmg)
	return best * _attack_w

func _overwatch_score(
	unit, pos: Vector2i, visible_enemies: Array, hex_map,
	atk_def: Dictionary, rng: int,
) -> float:
	# Estimates the value of *finishing turn on overwatch from pos*:
	# best snap-shot damage to any enemy that could enter our range next
	# turn. Discounted vs attack because triggering is uncertain.
	if visible_enemies.is_empty():
		return 0.0
	if atk_def.get("indirect", false):
		return 0.0
	var best_snap := 0.0
	for e in visible_enemies:
		var enemy = e
		var edef: Dictionary = _get_unit_def(enemy.type_id)
		var emove := int(edef.get("move", 0))
		var d: int = HexCoord.distance(pos, enemy.coord)
		# Enemy must be able to enter our attack range next turn.
		if d > rng + emove:
			continue
		var def_terr: Dictionary = _get_terrain_def("plain")  # worst-case (no cover bonus)
		var atk_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
		var r: CombatResolver.Result = CombatResolver.resolve(
			atk_def, edef, unit.hp, enemy.hp, atk_terr, def_terr, rng, 0
		)
		var snap: float = max(1.0, ceil(float(r.damage_to_defender) / 2.0))
		if snap >= enemy.hp:
			snap += _kill_bonus * 0.5  # half kill bonus — less reliable
		if snap > best_snap:
			best_snap = snap
	# 0.6 discount: enemy might not actually walk into range.
	return best_snap * _attack_w * 0.6

func _best_attack_from(
	pos: Vector2i,
	attacker_faction: String,
	attacker_type: String,
	enemies: Array,
	atk_def: Dictionary,
	visible_hexes: Dictionary,
) -> Variant:
	var hex_map = battle.hex_map
	var best = null
	var best_dmg := 0.0
	for e in enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, attacker_faction, enemy, atk_def, hex_map, visible_hexes):
			continue
		var d: int = HexCoord.distance(pos, enemy.coord)
		var def_def: Dictionary = _get_unit_def(enemy.type_id)
		var def_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
		var atk_hp := int(atk_def.get("hp", 1))
		var r: CombatResolver.Result = CombatResolver.resolve(atk_def, def_def, atk_hp, enemy.hp, atk_terr, def_terr, d)
		var dmg: float = r.damage_to_defender + (10 if r.defender_dies else 0) \
			+ _target_role_score(attacker_type, def_def)
		if dmg > best_dmg:
			best_dmg = dmg
			best = enemy
	return best

func _target_role_score(attacker_type: String, defender_def: Dictionary) -> float:
	if attacker_type == "at_gun":
		if int(defender_def.get("armor", 0)) > 0:
			return AT_ARMOR_TARGET_BONUS
		return -AT_SOFT_TARGET_PENALTY
	return 0.0

func _role_position_score(
	unit,
	pos: Vector2i,
	known: Array,
	visible_enemies: Array,
	atk_def: Dictionary,
) -> float:
	var score := 0.0
	if unit.type_id == "light_tank":
		score += _scout_position_score(pos, known, visible_enemies, atk_def)
	if atk_def.get("indirect", false):
		score += _artillery_standoff_score(pos, known)
	return score

func _scout_position_score(
	pos: Vector2i,
	known: Array,
	visible_enemies: Array,
	atk_def: Dictionary,
) -> float:
	if int(atk_def.get("vision", 0)) < 5 or int(atk_def.get("move", 0)) < 5:
		return 0.0
	if not visible_enemies.is_empty():
		return 0.0
	var nearest_known := 9999
	for k in known:
		nearest_known = min(nearest_known, HexCoord.distance(pos, k["coord"]))
	if nearest_known == 9999:
		return 0.0
	var ideal_distance := 3
	var distance_error: int = abs(nearest_known - ideal_distance)
	return max(0.0, 3.0 - float(distance_error)) * W_SCOUT

func _artillery_standoff_score(pos: Vector2i, known: Array) -> float:
	var penalty := 0.0
	for k in known:
		var d: int = HexCoord.distance(pos, k["coord"])
		if d <= 1:
			penalty -= W_ARTILLERY_STANDOFF * 2.0
		elif d == 2:
			penalty -= W_ARTILLERY_STANDOFF
	return penalty

# ---------- 1-ply lookahead ----------

func _ensure_player_reach_cached(players: Array, hex_map) -> void:
	for p in players:
		var player = p
		if _player_reach_cache.has(player):
			continue
		var pdef: Dictionary = _get_unit_def(player.type_id)
		var pmove := int(pdef.get("move", 0))
		var reach: Dictionary = Pathfinding.movement_range(
			player.coord, pmove, hex_map, hex_map.occupants, player.faction_id
		)
		# Player can also fire from their current hex without moving
		reach[player.coord] = 0
		_player_reach_cache[player] = reach

func _lookahead_counter_damage(
	ai_unit,
	candidate: Vector2i,
	visible_players: Array,
	hex_map,
	ai_def: Dictionary,
) -> int:
	# Worst damage any visible player unit could deliver to `ai_unit` if it
	# were standing on `candidate`. Approximates the player's next-turn
	# best response with a single-unit attack.
	_ensure_player_reach_cached(visible_players, hex_map)
	var ai_terrain_def: Dictionary = _get_terrain_def(hex_map.terrain_at(candidate))
	var worst := 0
	for p in visible_players:
		var player = p
		var pdef: Dictionary = _get_unit_def(player.type_id)
		var prange := int(pdef.get("range", 1))
		var reach: Dictionary = _player_reach_cache[player]
		# Can the player move to anywhere within prange of `candidate`?
		var in_threat := false
		for pos in reach.keys():
			if HexCoord.distance(pos, candidate) <= prange:
				in_threat = true
				break
		if not in_threat:
			continue
		# Damage formula doesn't depend on the attacker's terrain (only counter does).
		var plain := {"defense": 0}
		var result: CombatResolver.Result = CombatResolver.resolve(
			pdef, ai_def, player.hp, ai_unit.hp,
			plain, ai_terrain_def, 1,
		)
		if result.damage_to_defender > worst:
			worst = result.damage_to_defender
	return worst

func _get_unit_def(type_id: String) -> Dictionary:
	if _data_loader != null:
		return _data_loader.get_unit_def(type_id)
	push_error("AIController requires a data loader before planning")
	return {}

func _get_terrain_def(terrain_id: String) -> Dictionary:
	if _data_loader != null:
		return _data_loader.get_terrain_def(terrain_id)
	push_error("AIController requires a data loader before planning")
	return {}
