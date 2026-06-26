# Tutorial Probe

Static checks that tutorial scenario mechanics are actionable from authored starting data.

| scenario | passes | passed checks | failed checks |
| --- | --- | --- | --- |
| tut_00_basic_turn | 5 | movement (2 units can move), attack (教學步兵->接敵步兵, 教學中戰車->接敵步兵), counterattack (adjacent enemy pair), capture (targets=[[6, 2]]), deployment_locked | none |
| tut_01_terrain_zoc_overwatch | 8 | movement (3 units can move), attack (管制區步兵->道路尖兵, 警戒機槍->道路尖兵), capture (targets=[[6, 0]]), secondary_objective (count=1), terrain_defense (defensive terrain present), zoc (enemy near player), overwatch (player MG available), deployment_locked | none |
| tut_02_los_spotting_artillery | 6 | movement (3 units can move), attack (觀測輕戰車->遮蔽步兵, 後方砲兵->森林後 AT), direct_fire_los (直射受阻 AT->遮蔽步兵), indirect_fire (後方砲兵->森林後 AT, 後方砲兵->遮蔽步兵), spotting (light tank sees target for indirect fire), deployment_locked | none |
| tut_03_suppression_digin_engineer | 10 | movement (4 units can move), attack (架橋工兵->壓制火點, 攻堅砲兵->構工守軍), capture (targets=[[7, 3]]), suppression (source or initial suppression), rally (suppressed player unit), dig_in (initial dug-in unit), indirect_fire (攻堅砲兵->構工守軍, 攻堅砲兵->壓制火點), engineer_bridge (engineer adjacent to water), engineer_breach (架橋工兵->壓制火點), deployment_locked | none |
| tut_04_armor_at_veteran_general | 8 | movement (3 units can move), attack (教學 AT->Pz.IV 目標), counterattack (adjacent enemy pair), armor (armored units present), anti_armor (player AT weapon present), general_skill (player general), veteran (player veteran), deployment_locked | none |
| tut_05_airdrop_reinforcement_rocket | 8 | movement (3 units can move), attack (教學火箭砲->密集守軍 A, 教學火箭砲->密集守軍 C), suppression (source or initial suppression), indirect_fire (教學火箭砲->密集守軍 A, 教學火箭砲->密集守軍 C), airdrop (player paratrooper), reinforcements (scheduled reinforcements), splash_damage (adjacent clustered units), deployment_locked | none |
