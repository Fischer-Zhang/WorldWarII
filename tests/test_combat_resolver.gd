extends SceneTree

# Standalone tests for CombatResolver — no DataLoader needed (defs passed in directly).
# Run with: godot --headless --script res://tests/test_combat_resolver.gd

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	var infantry := {
		"hp": 10, "attack": 4, "defense": 2, "range": 1, "vs_armor": 1, "armor": 0
	}
	var medium_tank := {
		"hp": 16, "attack": 7, "defense": 5, "range": 1, "vs_armor": 4, "armor": 4
	}
	var at_gun := {
		"hp": 6, "attack": 7, "defense": 1, "range": 1, "vs_armor": 5, "armor": 0
	}
	var artillery := {
		"hp": 8, "attack": 8, "defense": 1, "range": 3, "vs_armor": 2, "armor": 0,
		"indirect": true
	}
	var plain := {"defense": 0}
	var forest := {"defense": 2}

	# 1) Infantry vs infantry on plain: base = max(1, 4 + 0 - 2 - 0) = 2; full HP -> 2
	var r := CombatResolver.resolve(infantry, infantry, 10, 10, plain, plain, 1)
	if r.damage_to_defender == 2 and r.counter_damage == 1 and not r.defender_dies:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: inf-vs-inf plain — dmg=%d counter=%d died=%s" % [
			r.damage_to_defender, r.counter_damage, r.defender_dies])

	# 2) Defender in forest reduces damage: 4 + 0 - 2 - 2 = 0 -> floor 1
	var r2 := CombatResolver.resolve(infantry, infantry, 10, 10, plain, forest, 1)
	if r2.damage_to_defender == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: forest defense — dmg=%d" % r2.damage_to_defender)

	# 3) AT gun vs medium tank: 7 + 5(vs_armor) - 5(def) - 0 = 7 dmg
	var r3 := CombatResolver.resolve(at_gun, medium_tank, 6, 16, plain, plain, 1)
	if r3.damage_to_defender == 7:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: AT vs tank — dmg=%d" % r3.damage_to_defender)

	# 4) Wounded attacker hits softer (HP ratio scaling): half HP -> half damage (rounded)
	var r4 := CombatResolver.resolve(infantry, infantry, 5, 10, plain, plain, 1)
	if r4.damage_to_defender == 1:  # round(2 * 0.5) = 1
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: wounded scaling — dmg=%d" % r4.damage_to_defender)

	# 5) Lethal attack: 1 HP target dies, no counter
	var r5 := CombatResolver.resolve(infantry, infantry, 10, 1, plain, plain, 1)
	if r5.defender_dies and r5.counter_damage == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: lethal — died=%s counter=%d" % [r5.defender_dies, r5.counter_damage])

	# 6) Artillery (indirect) does NOT trigger counter even if defender alive and in own range
	var r6 := CombatResolver.resolve(infantry, artillery, 10, 8, plain, plain, 1)
	if r6.counter_damage == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: indirect counter — counter=%d (should be 0)" % r6.counter_damage)

	# 7) Out-of-range: no counter (artillery shoots from distance, infantry can't reach back)
	var r7 := CombatResolver.resolve(artillery, infantry, 8, 10, plain, plain, 3)
	if r7.counter_damage == 0:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: out-of-range counter — counter=%d" % r7.counter_damage)

	# 8) Dig-in: defender_dig_in=2 raises effective defense → base 2 → 2-2 = 0 → floor 1
	var r8 := CombatResolver.resolve(infantry, infantry, 10, 10, plain, plain, 1, 2)
	if r8.damage_to_defender == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: dig-in 2 — dmg=%d" % r8.damage_to_defender)

	# 9) Dig-in does NOT help the attacker's counter (attacker just moved/attacked)
	# Counter half of base(2) = 1; dig-in on attacker is 0 by design.
	var r9 := CombatResolver.resolve(infantry, infantry, 10, 10, plain, plain, 1, 0)
	if r9.counter_damage == 1:
		pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: counter without dig-in — counter=%d" % r9.counter_damage)

	print("CombatResolver tests: %d pass, %d fail" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)
