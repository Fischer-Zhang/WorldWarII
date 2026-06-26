extends SceneTree

# Standalone tests for suppression and dig-in side effects.
# Run with: godot --headless --script res://tests/test_combat_effects.gd

const CombatEffects := preload("res://scripts/combat/combat_effects.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	var infantry := {"id": "infantry"}
	var engineer := {"id": "engineer"}
	var mg := {"id": "mg_team"}
	var artillery := {"id": "artillery", "indirect": true}
	var plain := {"defense": 0}
	var town := {"defense": 3}

	# 1) Infantry applies light suppression on a damaging non-lethal hit.
	var s1 := CombatEffects.suppression_for_attack(infantry, 2, false)
	if s1 == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: infantry suppression expected 1 got %d" % s1)

	# 2) MG teams pin with one damaging attack.
	var s2 := CombatEffects.suppression_for_attack(mg, 2, false)
	if s2 == 3 and CombatEffects.is_pinned(s2):
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: MG suppression expected 3 pinned got %d" % s2)

	# 3) Artillery strips one dig-in level when it damages an entrenched target.
	var dig_loss := CombatEffects.dig_in_loss_for_attack(artillery, 3, 2)
	if dig_loss == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: artillery dig-in loss expected 1 got %d" % dig_loss)

	# 4) Suppression caps and recovers deterministically.
	var engineer_dig_loss := CombatEffects.dig_in_loss_for_attack(engineer, 1, 3)
	if engineer_dig_loss == 2:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: engineer dig-in loss expected 2 got %d" % engineer_dig_loss)

	# 5) Engineer breach is capped by remaining dig-in and requires damage.
	var engineer_capped := CombatEffects.dig_in_loss_for_attack(engineer, 1, 1)
	var engineer_no_damage := CombatEffects.dig_in_loss_for_attack(engineer, 0, 3)
	var infantry_no_breach := CombatEffects.dig_in_loss_for_attack(infantry, 1, 3)
	if engineer_capped == 1 and engineer_no_damage == 0 and infantry_no_breach == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr(
			"FAIL: engineer breach guardrails expected 1/0/0 got %d/%d/%d"
			% [engineer_capped, engineer_no_damage, infantry_no_breach]
		)

	# 6) Suppression caps and recovers deterministically.
	var capped := CombatEffects.apply_suppression(4, 3)
	var recovered := CombatEffects.recover_suppression(capped)
	if capped == CombatEffects.MAX_SUPPRESSION and recovered == 4:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: cap/recover expected 5->4 got %d->%d" % [capped, recovered])

	# 7) Heavy suppression affects movement and attack, light suppression does not.
	if CombatEffects.move_penalty(3) == 1 and CombatEffects.attack_penalty(4) == 1 \
			and CombatEffects.move_penalty(2) == 0 and CombatEffects.attack_penalty(3) == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: suppression penalties did not match thresholds")

	# 8) Lethal or zero-damage hits do not leave suppression behind.
	var lethal := CombatEffects.suppression_for_attack(mg, 4, true)
	var no_damage := CombatEffects.suppression_for_attack(artillery, 0, false)
	if lethal == 0 and no_damage == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: lethal/no-damage suppression expected 0/0 got %d/%d" % [lethal, no_damage])

	# 9) Rally recovers more suppression in cover.
	var rally_plain := CombatEffects.rally_suppression(5, plain)
	var rally_town := CombatEffects.rally_suppression(5, town)
	if rally_plain == 3 and rally_town == 2:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: rally expected plain/town 3/2 got %d/%d" % [rally_plain, rally_town])

	# 10) Indirect fire gets a small extra suppression bonus from a light-tank spotter.
	var spotted := CombatEffects.spotter_suppression_bonus(artillery, true, 2, false)
	var unspotted := CombatEffects.spotter_suppression_bonus(artillery, false, 2, false)
	if spotted == CombatEffects.SPOTTER_SUPPRESSION_BONUS and unspotted == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: spotter bonus expected 1/0 got %d/%d" % [spotted, unspotted])

	# 11) Spotter support does not help direct, lethal, or zero-damage attacks.
	var direct := CombatEffects.spotter_suppression_bonus(infantry, true, 2, false)
	var lethal_spotted := CombatEffects.spotter_suppression_bonus(artillery, true, 2, true)
	var no_damage_spotted := CombatEffects.spotter_suppression_bonus(artillery, true, 0, false)
	if direct == 0 and lethal_spotted == 0 and no_damage_spotted == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr(
			"FAIL: spotter guardrails expected 0/0/0 got %d/%d/%d"
			% [direct, lethal_spotted, no_damage_spotted]
		)

	# 12) Splash damage is a floored percentage of a direct hit; no base = no splash.
	if CombatEffects.splash_damage(8, 50) == 4 \
			and CombatEffects.splash_damage(1, 50) == 1 \
			and CombatEffects.splash_damage(5, 100) == 5 \
			and CombatEffects.splash_damage(0, 50) == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: splash_damage did not match expected falloff")

	print("CombatEffects tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
