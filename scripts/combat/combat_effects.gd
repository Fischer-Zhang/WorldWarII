class_name CombatEffects
extends RefCounted

const SUPPRESSION_PIN_THRESHOLD := 2
const SUPPRESSION_MOVE_THRESHOLD := 3
const SUPPRESSION_ATTACK_THRESHOLD := 4
const MAX_SUPPRESSION := 5
const RALLY_RECOVERY := 2
const RALLY_COVER_BONUS := 1
const SPOTTER_SUPPRESSION_BONUS := 1
const FIRE_SUPPORT_SUPPRESSION_BONUS := 1
const SUPPRESSIVE_FIRE_AMOUNT := 2
const BREACH_SUPPORT_DIG_IN_BONUS := 1
const SPLASH_DAMAGE_PCT := 50  # default falloff for splash targets when a unit omits splash_damage_pct
const OVERWATCH_DAMAGE_PCT := 50  # default reaction-fire damage when a unit omits overwatch_damage_pct

const SUPPRESSION_BY_TYPE := {
	"infantry": 1,
	"mg_team": 3,
	"at_gun": 1,
	"light_tank": 1,
	"medium_tank": 1,
	"artillery": 3,
}

static func suppression_for_attack(atk_def: Dictionary, damage: int, defender_dies: bool) -> int:
	if defender_dies or damage <= 0:
		return 0
	var type_id := String(atk_def.get("id", ""))
	var base: int = SUPPRESSION_BY_TYPE.get(type_id, 1)
	if atk_def.get("indirect", false):
		base = max(base, 3)
	return base

static func spotter_suppression_bonus(
	atk_def: Dictionary, has_light_tank_spotter: bool, damage: int, defender_dies: bool
) -> int:
	if defender_dies or damage <= 0:
		return 0
	if not atk_def.get("indirect", false):
		return 0
	return SPOTTER_SUPPRESSION_BONUS if has_light_tank_spotter else 0

static func fire_support_suppression_bonus(marked: bool, damage: int, defender_dies: bool) -> int:
	if defender_dies or damage <= 0 or not marked:
		return 0
	return FIRE_SUPPORT_SUPPRESSION_BONUS

static func breach_support_dig_in_bonus(marked: bool, damage: int, defender_dig_in: int) -> int:
	if damage <= 0 or defender_dig_in <= 0 or not marked:
		return 0
	return min(BREACH_SUPPORT_DIG_IN_BONUS, defender_dig_in)

static func dig_in_loss_for_attack(atk_def: Dictionary, damage: int, defender_dig_in: int) -> int:
	if damage <= 0 or defender_dig_in <= 0:
		return 0
	if String(atk_def.get("id", "")) == "engineer":
		return min(2, defender_dig_in)
	return 1 if atk_def.get("indirect", false) else 0

static func apply_suppression(current: int, added: int) -> int:
	return clampi(current + added, 0, MAX_SUPPRESSION)

static func recover_suppression(current: int) -> int:
	return max(0, current - 1)

static func rally_recovery_for_terrain(terrain_def: Dictionary) -> int:
	var recovery := RALLY_RECOVERY
	if int(terrain_def.get("defense", 0)) >= 2:
		recovery += RALLY_COVER_BONUS
	return recovery

static func rally_suppression(current: int, terrain_def: Dictionary) -> int:
	return max(0, current - rally_recovery_for_terrain(terrain_def))

static func splash_damage(full_damage: int, pct: int) -> int:
	# Damage to a unit caught in a splash/AoE attack: a percentage of what a
	# direct hit would have done, floored at 1 when a direct hit would land.
	if full_damage <= 0:
		return 0
	return max(1, int(round(full_damage * pct / 100.0)))

static func overwatch_damage(full_damage: int, atk_def: Dictionary) -> int:
	if full_damage <= 0:
		return 0
	var pct := int(atk_def.get("overwatch_damage_pct", OVERWATCH_DAMAGE_PCT))
	return max(1, int(ceil(full_damage * pct / 100.0)))

static func is_pinned(suppression: int) -> bool:
	return suppression >= SUPPRESSION_PIN_THRESHOLD

static func move_penalty(suppression: int) -> int:
	return 1 if suppression >= SUPPRESSION_MOVE_THRESHOLD else 0

static func attack_penalty(suppression: int) -> int:
	return 1 if suppression >= SUPPRESSION_ATTACK_THRESHOLD else 0
