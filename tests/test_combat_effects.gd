extends SceneTree

# Standalone tests for suppression and dig-in side effects.
# Run with: godot --headless --script res://tests/test_combat_effects.gd

const CombatEffects := preload("res://scripts/combat/combat_effects.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	var infantry := {"id": "infantry"}
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
	var capped := CombatEffects.apply_suppression(4, 3)
	var recovered := CombatEffects.recover_suppression(capped)
	if capped == CombatEffects.MAX_SUPPRESSION and recovered == 4:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: cap/recover expected 5->4 got %d->%d" % [capped, recovered])

	# 5) Heavy suppression affects movement and attack, light suppression does not.
	if CombatEffects.move_penalty(3) == 1 and CombatEffects.attack_penalty(4) == 1 \
			and CombatEffects.move_penalty(2) == 0 and CombatEffects.attack_penalty(3) == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: suppression penalties did not match thresholds")

	# 6) Lethal or zero-damage hits do not leave suppression behind.
	var lethal := CombatEffects.suppression_for_attack(mg, 4, true)
	var no_damage := CombatEffects.suppression_for_attack(artillery, 0, false)
	if lethal == 0 and no_damage == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: lethal/no-damage suppression expected 0/0 got %d/%d" % [lethal, no_damage])

	# 7) Rally recovers more suppression in cover.
	var rally_plain := CombatEffects.rally_suppression(5, plain)
	var rally_town := CombatEffects.rally_suppression(5, town)
	if rally_plain == 3 and rally_town == 2:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: rally expected plain/town 3/2 got %d/%d" % [rally_plain, rally_town])

	print("CombatEffects tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
