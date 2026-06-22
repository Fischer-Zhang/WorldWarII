class_name CombatResolver
extends RefCounted

const HexCoord := preload("res://scripts/grid/hex_coord.gd")

# Deterministic combat resolution.
# Damage scales with the attacker's current HP — wounded units hit softer.
# Defender counter-attacks if it survives, the attacker is in its range, and
# it has the means to retaliate. Counter damage is halved.
#
# Inputs are *defs* (Dictionary) + the unit instances. Pure logic, no scene
# side effects — caller applies the result.

class Result:
	var damage_to_defender: int = 0
	var counter_damage: int = 0
	var attacker_dies: bool = false
	var defender_dies: bool = false

static func resolve(
	atk_def: Dictionary,
	def_def: Dictionary,
	attacker_hp: int,
	defender_hp: int,
	attacker_terrain_def: Dictionary,
	defender_terrain_def: Dictionary,
	distance: int,
	defender_dig_in: int = 0,
	attacker_mods: Dictionary = {},
	defender_mods: Dictionary = {},
) -> Result:
	var out := Result.new()
	out.damage_to_defender = _compute_damage(
		atk_def, def_def, attacker_hp, defender_terrain_def, false,
		defender_dig_in, attacker_mods, defender_mods
	)
	var defender_hp_after := defender_hp - out.damage_to_defender
	out.defender_dies = defender_hp_after <= 0

	# Counter-attack: defender must survive, attacker must be in defender's
	# range, and defender must not be an indirect-fire unit (artillery cannot
	# counter melee in this ruleset). The defender now plays attacker, so its
	# modifiers swap into the attacker slot.
	var def_range := int(def_def.get("range", 1))
	if not out.defender_dies and distance <= def_range and not def_def.get("indirect", false):
		out.counter_damage = max(
			1,
			_compute_damage(
				def_def, atk_def, defender_hp_after, attacker_terrain_def, true,
				0, defender_mods, attacker_mods
			)
		)
		out.attacker_dies = (attacker_hp - out.counter_damage) <= 0
	return out

static func _compute_damage(
	atk_def: Dictionary,
	def_def: Dictionary,
	atk_hp_now: int,
	defender_terrain_def: Dictionary,
	is_counter: bool,
	defender_dig_in: int = 0,
	atk_mods: Dictionary = {},
	def_mods: Dictionary = {},
) -> int:
	var atk: int = int(atk_def.get("attack", 0)) + int(atk_mods.get("attack", 0))
	var bonus := 0
	if int(def_def.get("armor", 0)) > 0:
		bonus = int(atk_def.get("vs_armor", 0)) + int(atk_mods.get("vs_armor", 0))
	var def_val: int = int(def_def.get("defense", 0)) + int(def_mods.get("defense", 0)) + defender_dig_in
	var terrain_def := int(defender_terrain_def.get("defense", 0))
	var base: int = max(1, atk + bonus - def_val - terrain_def)
	var atk_max_hp := int(atk_def.get("hp", 1))
	var hp_ratio := float(atk_hp_now) / float(max(1, atk_max_hp))
	var scaled: int = max(1, int(round(base * hp_ratio)))
	if is_counter:
		scaled = max(1, scaled / 2)
	return scaled
