class_name AIController
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const Visibility := preload("res://scripts/grid/visibility.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const Unit := preload("res://scripts/units/unit.gd")

# Heuristic AI: scores every reachable hex for each unit, picks the best,
# moves there, attacks if a target is available.
#
# Difficulty profiles tune the heuristic weights and enable an optional
# 1-ply lookahead that discounts a candidate hex by the worst counter-
# attack the player could deliver next turn.

const W_OBJECTIVE := 1.0
const W_TERRAIN := 0.3
const W_LOOKAHEAD := 1.0

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

func plan_for_unit(unit: Unit) -> Dictionary:
	# Returns: { "move_to": Vector2i, "attack": Unit | null, "score": float, "reachable": Dictionary }
	var hex_map = battle.hex_map
	var atk_def: Dictionary = DataLoader.get_unit_def(unit.type_id)
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

	var best := unit.coord
	var best_score := -INF
	var best_target: Unit = null
	var best_action := "wait"  # "attack", "overwatch", or "wait"

	for cand in candidates:
		var coord: Vector2i = cand
		var base_score := _score_position(unit, coord, known, visible_enemies, hex_map, atk_def, rng)
		var target := _best_attack_from(coord, rng, visible_enemies, atk_def)
		# Attack score is implicit in base_score (already includes attack_term).
		# Overwatch is an alternative: subtract the attack contribution (not
		# attacking this turn) and add the overwatch score.
		var overwatch_value := _overwatch_score(unit, coord, visible_enemies, hex_map, atk_def, rng)
		var attack_value := _best_attack_value(unit, coord, visible_enemies, hex_map, atk_def, rng)
		# attack_value and overwatch_value are both pre-weighted contributions.
		# base_score already has attack_value baked in (via _score_position).
		# To get the "overwatch" total, swap them:
		var overwatch_score := base_score - attack_value + overwatch_value

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
	unit: Unit,
	pos: Vector2i,
	known: Array,
	visible_enemies: Array,
	hex_map,
	atk_def: Dictionary,
	rng: int,
) -> float:
	# Distance term: use the best known position (memory or current).
	var nearest := 9999
	for k in known:
		var d := HexCoord.distance(pos, k["coord"])
		if d < nearest:
			nearest = d
	var dist_term := -float(nearest) * W_OBJECTIVE

	# Attack term: only currently-visible enemies (can't shoot fog).
	var attack_term := 0.0
	for e in visible_enemies:
		var enemy: Unit = e
		if not _can_attack_from(pos, enemy, hex_map, atk_def, rng):
			continue
		var d := HexCoord.distance(pos, enemy.coord)
		var def_def := DataLoader.get_unit_def(enemy.type_id)
		var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		var r := CombatResolver.resolve(atk_def, def_def, unit.hp, enemy.hp, atk_terr, def_terr, d)
		var dmg_score := float(r.damage_to_defender)
		if r.defender_dies:
			dmg_score += _kill_bonus
		dmg_score -= 0.6 * float(r.counter_damage)
		attack_term = max(attack_term, dmg_score)
	attack_term *= _attack_w

	# Exposure: only visible enemies are a known threat.
	var exposure := 0.0
	for e in visible_enemies:
		var enemy: Unit = e
		var enemy_def := DataLoader.get_unit_def(enemy.type_id)
		var enemy_rng := int(enemy_def.get("range", 1))
		var enemy_move := int(enemy_def.get("move", 0))
		if HexCoord.distance(pos, enemy.coord) <= enemy_move + enemy_rng:
			exposure += float(enemy_def.get("attack", 0)) * 0.5
	var exposure_term := -exposure * _exposure_w

	# Terrain defense bonus
	var terr_def := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
	var terrain_term := float(terr_def.get("defense", 0)) * W_TERRAIN

	# 1-ply lookahead: discount by worst counter the player could deliver
	# *after* we land on this hex. Only enabled on Hard difficulty.
	var lookahead_term := 0.0
	if _use_lookahead and not visible_enemies.is_empty():
		var counter_dmg: int = _lookahead_counter_damage(unit, pos, visible_enemies, hex_map, atk_def)
		lookahead_term = -float(counter_dmg) * W_LOOKAHEAD

	var total := dist_term + attack_term + exposure_term + terrain_term + lookahead_term
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
	unit: Unit, pos: Vector2i, visible_enemies: Array, hex_map,
	atk_def: Dictionary, rng: int,
) -> float:
	# Returns the (pre-weighted) attack-term contribution this candidate
	# position would produce — mirrors the attack block in _score_position
	# so the AI can compare attack vs overwatch on equal footing.
	var best := 0.0
	for e in visible_enemies:
		var enemy: Unit = e
		if not _can_attack_from(pos, enemy, hex_map, atk_def, rng):
			continue
		var d := HexCoord.distance(pos, enemy.coord)
		var def_def := DataLoader.get_unit_def(enemy.type_id)
		var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		var r := CombatResolver.resolve(atk_def, def_def, unit.hp, enemy.hp, atk_terr, def_terr, d)
		var dmg := float(r.damage_to_defender)
		if r.defender_dies:
			dmg += _kill_bonus
		dmg -= 0.6 * float(r.counter_damage)
		best = max(best, dmg)
	return best * _attack_w

func _overwatch_score(
	unit: Unit, pos: Vector2i, visible_enemies: Array, hex_map,
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
		var enemy: Unit = e
		var edef := DataLoader.get_unit_def(enemy.type_id)
		var emove := int(edef.get("move", 0))
		var d := HexCoord.distance(pos, enemy.coord)
		# Enemy must be able to enter our attack range next turn.
		if d > rng + emove:
			continue
		var def_terr := DataLoader.get_terrain_def("plain")  # worst-case (no cover bonus)
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		var r := CombatResolver.resolve(
			atk_def, edef, unit.hp, enemy.hp, atk_terr, def_terr, rng, 0
		)
		var snap: float = max(1.0, ceil(float(r.damage_to_defender) / 2.0))
		if snap >= enemy.hp:
			snap += _kill_bonus * 0.5  # half kill bonus — less reliable
		if snap > best_snap:
			best_snap = snap
	# 0.6 discount: enemy might not actually walk into range.
	return best_snap * _attack_w * 0.6

func _best_attack_from(pos: Vector2i, rng: int, enemies: Array, atk_def: Dictionary) -> Unit:
	var hex_map = battle.hex_map
	var best: Unit = null
	var best_dmg := 0
	for e in enemies:
		var enemy: Unit = e
		if not _can_attack_from(pos, enemy, hex_map, atk_def, rng):
			continue
		var d := HexCoord.distance(pos, enemy.coord)
		var def_def := DataLoader.get_unit_def(enemy.type_id)
		var def_terr := DataLoader.get_terrain_def(hex_map.terrain_at(enemy.coord))
		var atk_terr := DataLoader.get_terrain_def(hex_map.terrain_at(pos))
		var atk_hp := int(atk_def.get("hp", 1))
		var r := CombatResolver.resolve(atk_def, def_def, atk_hp, enemy.hp, atk_terr, def_terr, d)
		var dmg := r.damage_to_defender + (10 if r.defender_dies else 0)
		if dmg > best_dmg:
			best_dmg = dmg
			best = enemy
	return best

func _can_attack_from(
	attacker_pos: Vector2i,
	target: Unit,
	hex_map,
	atk_def: Dictionary,
	rng: int,
) -> bool:
	if HexCoord.distance(attacker_pos, target.coord) > rng:
		return false
	if atk_def.get("indirect", false):
		return true
	return Visibility.has_los(attacker_pos, target.coord, hex_map)

# ---------- 1-ply lookahead ----------

func _ensure_player_reach_cached(players: Array, hex_map) -> void:
	for p in players:
		var player: Unit = p
		if _player_reach_cache.has(player):
			continue
		var pdef := DataLoader.get_unit_def(player.type_id)
		var pmove := int(pdef.get("move", 0))
		var reach: Dictionary = Pathfinding.movement_range(
			player.coord, pmove, hex_map, hex_map.occupants, player.faction_id
		)
		# Player can also fire from their current hex without moving
		reach[player.coord] = 0
		_player_reach_cache[player] = reach

func _lookahead_counter_damage(
	ai_unit: Unit,
	candidate: Vector2i,
	visible_players: Array,
	hex_map,
	ai_def: Dictionary,
) -> int:
	# Worst damage any visible player unit could deliver to `ai_unit` if it
	# were standing on `candidate`. Approximates the player's next-turn
	# best response with a single-unit attack.
	_ensure_player_reach_cached(visible_players, hex_map)
	var ai_terrain_def := DataLoader.get_terrain_def(hex_map.terrain_at(candidate))
	var worst := 0
	for p in visible_players:
		var player: Unit = p
		var pdef := DataLoader.get_unit_def(player.type_id)
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
		var result := CombatResolver.resolve(
			pdef, ai_def, player.hp, ai_unit.hp,
			plain, ai_terrain_def, 1,
		)
		if result.damage_to_defender > worst:
			worst = result.damage_to_defender
	return worst
