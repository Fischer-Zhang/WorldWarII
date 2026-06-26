class_name AIController
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")
const Pathfinding := preload("res://scripts/grid/pathfinding.gd")
const Visibility := preload("res://scripts/grid/visibility.gd")
const CombatResolver := preload("res://scripts/combat/combat_resolver.gd")
const CombatRules := preload("res://scripts/combat/combat_rules.gd")
const CombatModifiers := preload("res://scripts/combat/combat_modifiers.gd")
const CombatEffects := preload("res://scripts/combat/combat_effects.gd")
const SecondaryObjectiveRules := preload("res://scripts/scenario/secondary_objective_rules.gd")

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
const W_SUPPRESSION := 1.2
const W_DIG_IN_BREAK := 2.0
const W_CAPTURE_OBJECTIVE := 1.8
const W_SECONDARY_OBJECTIVE := 1.1
const W_SECONDARY_RECON_OBJECTIVE := 1.35
const W_SECONDARY_DESTROY_OBJECTIVE := 1.45
const SECONDARY_DESTROY_TARGET_BONUS := 4.0
const W_RALLY := 4.0
const W_FOCUS_DAMAGE := 0.18
const W_FOCUS_SUPPRESSION := 0.7
const AT_ARMOR_TARGET_BONUS := 2.0
const AT_SOFT_TARGET_PENALTY := 1.0
const ENGINEER_BREACH_TARGET_BONUS := 2.5
const ENGINEER_HIGH_COVER_BONUS := 0.8
const ENGINEER_BREACH_SETUP_BONUS := 1.4
const BREACH_SETUP_BAND := 3

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
	# Invalidate the player-reach cache: a previous AI unit on this turn
	# may have killed or displaced players, so cached reach is stale.
	# (Within a single plan_for_unit, the cache still amortises across the
	# candidate enumeration — it's rebuilt lazily on first lookup.)
	_player_reach_cache.clear()
	var hex_map = battle.hex_map
	var atk_def: Dictionary = _get_unit_def(unit.type_id)
	var atk_general: Dictionary = _get_general_def(unit.general_id)
	var atk_mods: Dictionary = CombatModifiers.for_unit(unit, atk_general)
	var move_pts: int = int(atk_def.get("move", 0)) + int(atk_mods.get("move", 0)) \
		- CombatEffects.move_penalty(unit.suppression)
	move_pts = max(0, move_pts)
	var rng := int(atk_def.get("range", 1))

	var reachable: Dictionary = Pathfinding.movement_range(
		unit.coord, move_pts, hex_map, hex_map.occupants, unit.faction_id, unit.type_id
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
	var best_action := "wait"  # "attack", "overwatch", "rally", or "wait"
	var visible_hexes: Dictionary = battle.visibility_by_faction.get(unit.faction_id, {})

	for cand in candidates:
		var coord: Vector2i = cand
		var base_score: float = _score_position(unit, coord, known, visible_enemies, hex_map, atk_def, visible_hexes)
		var target = _best_attack_from(coord, unit.faction_id, unit.type_id, visible_enemies, atk_def, visible_hexes, unit)
		# Attack score is implicit in base_score (already includes attack_term).
		# Overwatch is an alternative: subtract the attack contribution (not
		# attacking this turn) and add the overwatch score.
		var overwatch_value: float = _overwatch_score(unit, coord, visible_enemies, hex_map, atk_def, rng)
		var attack_value: float = _best_attack_value(unit, coord, visible_enemies, hex_map, atk_def, visible_hexes)
		# attack_value and overwatch_value are both pre-weighted contributions.
		# base_score already has attack_value baked in (via _score_position).
		# To get the "overwatch" total, swap them:
		var overwatch_score: float = base_score - attack_value + overwatch_value
		var rally_score: float = _rally_score(unit, coord, hex_map, atk_def)

		if base_score > best_score:
			best_score = base_score
			best = coord
			best_target = target
			best_action = "attack" if target != null else "wait"
		if overwatch_score > best_score and not atk_def.get("indirect", false) \
				and not CombatEffects.is_pinned(unit.suppression):
			best_score = overwatch_score
			best = coord
			best_target = null
			best_action = "overwatch"
		if rally_score > best_score:
			best_score = rally_score
			best = coord
			best_target = null
			best_action = "rally"

	return {
		"move_to": best,
		"attack": best_target,
		"action": best_action,
		"score": best_score,
		"reachable": reachable,
	}

func plan_trace_for_unit(unit) -> Dictionary:
	# Diagnostic mirror of plan_for_unit. It returns the selected plan plus
	# deterministic per-candidate score components without changing AI state.
	var plan: Dictionary = plan_for_unit(unit)
	var atk_def: Dictionary = _get_unit_def(unit.type_id)
	var known: Array = battle.get_known_enemies(unit.faction_id)
	var visible_enemies: Array = []
	for k in known:
		if k.get("visible", false):
			visible_enemies.append(k["unit"])
	var visible_hexes: Dictionary = battle.visibility_by_faction.get(unit.faction_id, {})
	var candidates: Array = [unit.coord]
	var reachable: Dictionary = plan.get("reachable", {})
	for c in reachable.keys():
		candidates.append(c)
	var traces: Array[Dictionary] = []
	for cand in candidates:
		var coord: Vector2i = cand
		var breakdown := _score_position_breakdown(
			unit, coord, known, visible_enemies, battle.hex_map, atk_def, visible_hexes
		)
		var target = _best_attack_from(
			coord, unit.faction_id, unit.type_id, visible_enemies, atk_def, visible_hexes, unit
		)
		var attack_value: float = _best_attack_value(unit, coord, visible_enemies, battle.hex_map, atk_def, visible_hexes)
		var overwatch_value: float = _overwatch_score(unit, coord, visible_enemies, battle.hex_map, atk_def, int(atk_def.get("range", 1)))
		var rally_value: float = _rally_score(unit, coord, battle.hex_map, atk_def)
		traces.append({
			"coord": coord,
			"target": target,
			"base_score": float(breakdown.total),
			"overwatch_score": float(breakdown.total) - attack_value + overwatch_value,
			"rally_score": rally_value,
			"components": breakdown,
		})
	traces.sort_custom(func(a, b):
		return _trace_sort_score(a) > _trace_sort_score(b)
	)
	_player_reach_cache.clear()
	return {
		"unit": unit,
		"plan": plan,
		"candidates": traces,
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
	return float(_score_position_breakdown(
		unit, pos, known, visible_enemies, hex_map, atk_def, visible_hexes
	).total)

func _score_position_breakdown(
	unit,
	pos: Vector2i,
	known: Array,
	visible_enemies: Array,
	hex_map,
	atk_def: Dictionary,
	visible_hexes: Dictionary,
) -> Dictionary:
	# Distance term: use the best known position (memory or current).
	var nearest := 9999
	for k in known:
		var d: int = HexCoord.distance(pos, k["coord"])
		if d < nearest:
			nearest = d
	var dist_term: float = -float(nearest) * W_OBJECTIVE

	# Attack term: only currently-visible enemies (can't shoot fog).
	var attack_term := 0.0
	var atk_general_for_score: Dictionary = _get_general_def(unit.general_id)
	var atk_mods_for_score: Dictionary = CombatModifiers.for_unit(unit, atk_general_for_score)
	for e in visible_enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, unit.faction_id, enemy, atk_def, hex_map, visible_hexes):
			continue
		var dmg_score: float = _attack_candidate_score(
			unit, pos, unit.faction_id, unit.type_id, enemy, atk_def, atk_mods_for_score
		)
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
	var objective_term: float = _objective_position_score(unit.faction_id, pos) \
		+ _secondary_objective_position_score(unit.faction_id, pos)

	# 1-ply lookahead: discount by worst counter the player could deliver
	# *after* we land on this hex. Only enabled on Hard difficulty.
	var lookahead_term := 0.0
	if _use_lookahead and not visible_enemies.is_empty():
		var counter_dmg: int = _lookahead_counter_damage(unit, pos, visible_enemies, hex_map, atk_def)
		lookahead_term = -float(counter_dmg) * W_LOOKAHEAD

	var raw_total: float = dist_term + attack_term + exposure_term + terrain_term + role_term + objective_term + lookahead_term
	var total := _apply_personality(raw_total, attack_term, exposure_term)
	return {
		"distance": dist_term,
		"attack": attack_term,
		"exposure": exposure_term,
		"terrain": terrain_term,
		"role": role_term,
		"objective": objective_term,
		"lookahead": lookahead_term,
		"raw_total": raw_total,
		"total": total,
	}

func _trace_sort_score(trace: Dictionary) -> float:
	return max(
		float(trace.get("base_score", -INF)),
		max(float(trace.get("overwatch_score", -INF)), float(trace.get("rally_score", -INF)))
	)

func _rally_score(unit, pos: Vector2i, hex_map, atk_def: Dictionary) -> float:
	if unit.suppression <= 0 or pos != unit.coord:
		return -INF
	var terrain_def: Dictionary = _get_terrain_def(hex_map.terrain_at(unit.coord))
	var recovery: int = CombatEffects.rally_recovery_for_terrain(terrain_def)
	var after: int = max(0, unit.suppression - recovery)
	var score: float = float(unit.suppression - after) * W_RALLY
	if CombatEffects.is_pinned(unit.suppression):
		score += 3.0
	score += float(CombatEffects.move_penalty(unit.suppression) - CombatEffects.move_penalty(after)) * 2.0
	score += float(CombatEffects.attack_penalty(unit.suppression) - CombatEffects.attack_penalty(after)) * 2.0
	if not atk_def.get("indirect", false):
		score += 0.5
	return score

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
	var atk_general_local: Dictionary = _get_general_def(unit.general_id)
	var atk_mods_local: Dictionary = CombatModifiers.for_unit(unit, atk_general_local)
	for e in visible_enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, unit.faction_id, enemy, atk_def, hex_map, visible_hexes):
			continue
		var dmg: float = _attack_candidate_score(
			unit, pos, unit.faction_id, unit.type_id, enemy, atk_def, atk_mods_local
		)
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
	if CombatEffects.is_pinned(unit.suppression):
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
		var atk_general_ow: Dictionary = _get_general_def(unit.general_id)
		var atk_mods_ow: Dictionary = CombatModifiers.for_unit(unit, atk_general_ow)
		var def_general_ow: Dictionary = _get_general_def(enemy.general_id)
		var def_mods_ow: Dictionary = CombatModifiers.for_unit(enemy, def_general_ow)
		atk_mods_ow.attack -= CombatEffects.attack_penalty(unit.suppression)
		var r: CombatResolver.Result = CombatResolver.resolve(
			atk_def, edef, unit.hp, enemy.hp, atk_terr, def_terr, rng,
			0, atk_mods_ow, def_mods_ow
		)
		var snap: float = float(CombatEffects.overwatch_damage(r.damage_to_defender, atk_def))
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
	attacker = null,
) -> Variant:
	var best = null
	var best_dmg := 0.0
	var attacker_unit = attacker if attacker != null else _unit_at(pos, attacker_faction, attacker_type)
	var attacker_mods: Dictionary = {}
	if attacker_unit != null:
		var atk_general: Dictionary = _get_general_def(attacker_unit.general_id)
		attacker_mods = CombatModifiers.for_unit(attacker_unit, atk_general)
	for e in enemies:
		var enemy = e
		if not CombatRules.can_attack_from_coord(pos, attacker_faction, enemy, atk_def, battle.hex_map, visible_hexes):
			continue
		var dmg: float = _attack_candidate_score(
			attacker_unit, pos, attacker_faction, attacker_type, enemy, atk_def, attacker_mods
		)
		if dmg > best_dmg:
			best_dmg = dmg
			best = enemy
	return best

func _attack_candidate_score(
	attacker,
	pos: Vector2i,
	attacker_faction: String,
	attacker_type: String,
	enemy,
	atk_def: Dictionary,
	attacker_mods: Dictionary = {},
) -> float:
	var hex_map = battle.hex_map
	var d: int = HexCoord.distance(pos, enemy.coord)
	var def_def: Dictionary = _get_unit_def(enemy.type_id)
	var def_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(enemy.coord))
	var atk_terr: Dictionary = _get_terrain_def(hex_map.terrain_at(pos))
	var def_general: Dictionary = _get_general_def(enemy.general_id)
	var def_mods: Dictionary = CombatModifiers.for_unit(enemy, def_general)
	var atk_mods_effective: Dictionary = attacker_mods.duplicate()
	var attacker_hp := int(atk_def.get("hp", 1))
	var attacker_suppression := 0
	if attacker != null:
		attacker_hp = int(attacker.hp)
		attacker_suppression = int(attacker.suppression)
	atk_mods_effective.attack = int(atk_mods_effective.get("attack", 0)) \
		- CombatEffects.attack_penalty(attacker_suppression)
	var r: CombatResolver.Result = CombatResolver.resolve(
		atk_def, def_def, attacker_hp, enemy.hp, atk_terr, def_terr, d,
		enemy.dig_in_level, atk_mods_effective, def_mods
	)
	var suppression := r.suppression_to_defender + _spotter_suppression_bonus(
		attacker_faction, enemy.coord, atk_def, r.damage_to_defender, r.defender_dies
	)
	var score: float = float(r.damage_to_defender)
	if r.defender_dies:
		score += _kill_bonus
	score += _target_role_score(attacker_type, def_def)
	score += _target_focus_score(enemy, def_def)
	score += float(suppression) * W_SUPPRESSION
	score += float(r.defender_dig_in_loss) * W_DIG_IN_BREAK
	score += _engineer_breach_role_score(attacker_type, enemy, def_terr, r)
	score += _secondary_destroy_target_score(attacker_faction, enemy)
	score -= 0.6 * float(r.counter_damage)
	return score

func _unit_at(pos: Vector2i, faction_id: String, type_id: String):
	var occupant = battle.hex_map.occupants.get(pos)
	if occupant != null and occupant.faction_id == faction_id and occupant.type_id == type_id:
		return occupant
	for u in battle.units:
		var unit = u
		if unit.coord == pos and unit.faction_id == faction_id and unit.type_id == type_id and unit.is_alive():
			return unit
	return null

func _spotter_suppression_bonus(
	attacker_faction: String,
	target_coord: Vector2i,
	atk_def: Dictionary,
	damage: int,
	defender_dies: bool,
) -> int:
	return CombatEffects.spotter_suppression_bonus(
		atk_def,
		_has_light_tank_spotter(attacker_faction, target_coord),
		damage,
		defender_dies,
	)

func _has_light_tank_spotter(faction_id: String, target_coord: Vector2i) -> bool:
	var visible: Dictionary = battle.visibility_by_faction.get(faction_id, {})
	if not visible.has(target_coord):
		return false
	for u in battle.units:
		var spotter = u
		if not spotter.is_alive() or spotter.faction_id != faction_id:
			continue
		if spotter.type_id != "light_tank":
			continue
		var spotter_def: Dictionary = _get_unit_def(spotter.type_id)
		var spotter_general: Dictionary = _get_general_def(spotter.general_id)
		var spotter_mods: Dictionary = CombatModifiers.for_unit(spotter, spotter_general)
		var vision := int(spotter_def.get("vision", 3)) + int(spotter_mods.get("vision", 0))
		if HexCoord.distance(spotter.coord, target_coord) <= vision \
				and Visibility.has_los(spotter.coord, target_coord, battle.hex_map):
			return true
	return false

func _target_role_score(attacker_type: String, defender_def: Dictionary) -> float:
	if attacker_type == "at_gun":
		if int(defender_def.get("armor", 0)) > 0:
			return AT_ARMOR_TARGET_BONUS
		return -AT_SOFT_TARGET_PENALTY
	return 0.0

func _target_focus_score(enemy, defender_def: Dictionary) -> float:
	var max_hp := int(defender_def.get("hp", max(1, enemy.hp)))
	var missing_hp: int = max(0, max_hp - enemy.hp)
	var suppression := int(enemy.suppression)
	return float(missing_hp) * W_FOCUS_DAMAGE + float(suppression) * W_FOCUS_SUPPRESSION

func _engineer_breach_role_score(
	attacker_type: String,
	enemy,
	defender_terrain_def: Dictionary,
	result: CombatResolver.Result,
) -> float:
	if attacker_type != "engineer" or result.defender_dig_in_loss <= 0:
		return 0.0
	var score := ENGINEER_BREACH_TARGET_BONUS
	score += float(max(0, int(enemy.dig_in_level) - 1)) * 0.5
	if int(defender_terrain_def.get("defense", 0)) >= 2:
		score += ENGINEER_HIGH_COVER_BONUS
	return score

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
	if unit.type_id == "engineer":
		score += _engineer_breach_position_score(pos, visible_enemies, atk_def)
	if atk_def.get("indirect", false):
		score += _artillery_standoff_score(pos, known)
	return score

func _engineer_breach_position_score(
	pos: Vector2i,
	visible_enemies: Array,
	atk_def: Dictionary,
) -> float:
	var best := 0.0
	var rng := int(atk_def.get("range", 1))
	for e in visible_enemies:
		var enemy = e
		var dig_in := int(enemy.dig_in_level)
		if dig_in <= 0:
			continue
		var terrain_def: Dictionary = _get_terrain_def(battle.hex_map.terrain_at(enemy.coord))
		var cover := int(terrain_def.get("defense", 0))
		if cover < 2 and dig_in < 2:
			continue
		var gap: int = max(0, HexCoord.distance(pos, enemy.coord) - rng)
		if gap == 0:
			best = max(best, ENGINEER_BREACH_TARGET_BONUS + ENGINEER_HIGH_COVER_BONUS)
		elif gap <= BREACH_SETUP_BAND:
			var setup: float = float(BREACH_SETUP_BAND + 1 - gap) * ENGINEER_BREACH_SETUP_BONUS
			setup += float(dig_in) * 0.2
			if cover >= 2:
				setup += ENGINEER_HIGH_COVER_BONUS * 0.5
			best = max(best, setup)
	return best

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

func _objective_position_score(faction_id: String, pos: Vector2i) -> float:
	var victory_cfg: Dictionary = battle.scenario.get("victory", {})
	var objective: Dictionary = victory_cfg.get(faction_id, {})
	if String(objective.get("type", "")) != "capture":
		return 0.0
	var target: Variant = objective.get("target", [])
	if typeof(target) != TYPE_ARRAY or target.size() < 2:
		return 0.0
	var col := int(target[0])
	var row := int(target[1])
	var target_coord := Vector2i(col - (row >> 1), row)
	return -float(HexCoord.distance(pos, target_coord)) * W_CAPTURE_OBJECTIVE

func _secondary_objective_position_score(faction_id: String, pos: Vector2i) -> float:
	var objectives: Array = battle.scenario.get("secondary_objectives", [])
	if objectives.is_empty():
		return 0.0
	var captured: Dictionary = {}
	var captured_value: Variant = battle.get("captured_secondary_objectives")
	if typeof(captured_value) == TYPE_DICTIONARY:
		captured = captured_value
	var best := -INF
	for i in range(objectives.size()):
		if typeof(objectives[i]) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objectives[i]
		var key := SecondaryObjectiveRules.key(objective, i)
		if captured.has(key):
			continue
		if not SecondaryObjectiveRules.applies_to_faction(objective, faction_id, faction_id):
			continue
		var target_coord_value: Variant = SecondaryObjectiveRules.target_coord(objective, battle.units)
		if target_coord_value == null:
			continue
		var target_coord: Vector2i = target_coord_value
		var score := -float(HexCoord.distance(pos, target_coord)) \
			* _secondary_objective_position_weight(objective)
		best = max(best, score)
	if best == -INF:
		return 0.0
	return best

func _secondary_objective_position_weight(objective: Dictionary) -> float:
	match SecondaryObjectiveRules.objective_type(objective):
		"recon_hex":
			return W_SECONDARY_RECON_OBJECTIVE
		"destroy_unit":
			return W_SECONDARY_DESTROY_OBJECTIVE
		_:
			return W_SECONDARY_OBJECTIVE

func _secondary_destroy_target_score(faction_id: String, enemy) -> float:
	if enemy == null:
		return 0.0
	var objectives: Array = battle.scenario.get("secondary_objectives", [])
	if objectives.is_empty():
		return 0.0
	var captured: Dictionary = {}
	var captured_value: Variant = battle.get("captured_secondary_objectives")
	if typeof(captured_value) == TYPE_DICTIONARY:
		captured = captured_value
	for i in range(objectives.size()):
		if typeof(objectives[i]) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objectives[i]
		var key := SecondaryObjectiveRules.key(objective, i)
		if captured.has(key):
			continue
		if SecondaryObjectiveRules.objective_type(objective) != "destroy_unit":
			continue
		if not SecondaryObjectiveRules.applies_to_faction(objective, faction_id, faction_id):
			continue
		if SecondaryObjectiveRules.target_matches_unit(objective, enemy):
			return SECONDARY_DESTROY_TARGET_BONUS
	return 0.0

# ---------- 1-ply lookahead ----------

func _ensure_player_reach_cached(players: Array, hex_map) -> void:
	for p in players:
		var player = p
		if _player_reach_cache.has(player):
			continue
		var pdef: Dictionary = _get_unit_def(player.type_id)
		var pmove := int(pdef.get("move", 0)) - CombatEffects.move_penalty(player.suppression)
		pmove = max(0, pmove)
		var reach: Dictionary = Pathfinding.movement_range(
			player.coord, pmove, hex_map, hex_map.occupants, player.faction_id, player.type_id
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
		var p_general: Dictionary = _get_general_def(player.general_id)
		var p_mods: Dictionary = CombatModifiers.for_unit(player, p_general)
		var ai_general: Dictionary = _get_general_def(ai_unit.general_id)
		var ai_mods: Dictionary = CombatModifiers.for_unit(ai_unit, ai_general)
		p_mods.attack -= CombatEffects.attack_penalty(player.suppression)
		var result: CombatResolver.Result = CombatResolver.resolve(
			pdef, ai_def, player.hp, ai_unit.hp,
			plain, ai_terrain_def, 1,
			ai_unit.dig_in_level, p_mods, ai_mods,
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

func _get_general_def(general_id: String) -> Dictionary:
	if general_id == "":
		return {}
	if _data_loader != null:
		return _data_loader.get_general_def(general_id)
	return {}
