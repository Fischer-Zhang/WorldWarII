# Scenario Probe

Static tactical probe for pressure tuning. Coverage is approximate and ignores LOS/fog; use it to spot scenarios that need manual playtesting.

| scenario | suppression sources | artillery coverage | spotter coverage | breach path | breach tempo | artillery reposition | objective pressure | secondary pressure | reinforcement delta |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 00_sandbox | allies mg_team:1; axis artillery:1 | allies 24/384 (6%); axis 54/384 (14%) | axis 43/384 (11%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | none | none |
| 01_sedan_1940 | allies mg_team:2; axis artillery:1 | axis 33/384 (9%) | axis 64/384 (17%), spots 1 | axis: eng none, art 0/3, targets 3 | axis: eng turns none | axis: art move 1/3 | axis target 20,14 own min 2 enemy min 0 | 橋頭補給 15,5 capture min 7 XP 1; 中路渡口 13,5 recon min 9 XP 1 | none |
| 02_kiev_1941 | axis artillery:2; soviet mg_team:1 | axis 57/384 (15%) | soviet 68/384 (18%), spots 0 | axis: eng none, art 0/1, targets 1 | axis: eng turns none | axis: art move 0/1 | n/a | 壓制馬克沁火點 4,4 destroy min 19 XP 1, enemy supp +1 R2; 南翼掃蕩 3,13 recon min 18 XP 1 | none |
| 03_stalingrad_1942 | axis artillery:1, mg_team:1; soviet mg_team:2 | axis 61/384 (16%); soviet 21/384 (5%) | axis 65/384 (17%), spots 0 | axis: eng min 7, art 0/6, targets 6 | axis: eng turns 3 | axis: art move 1/6 | n/a | 突擊工兵 13,10 destroy min 7 XP 1, enemy supp +1 R2 | none |
| 04_kursk_1943 | axis artillery:1; soviet artillery:1 | axis 34/384 (9%); soviet 42/384 (11%) | axis 43/384 (11%), spots 2 | axis: eng none, art 0/2, targets 2 | axis: eng turns none | axis: art move 0/2 | axis target 5,2 own min 17 enemy min 0 | 壓制 SU-152 4,0 destroy min 18 XP 1; 北側高地偵察 18,2 recon min 4 XP 1 | none |
| 05_bastogne_1944 | allies artillery:1, mg_team:1; axis artillery:1 | allies 61/384 (16%); axis 42/384 (11%) | none | axis: eng none, art 0/5, targets 5 | axis: eng turns none | axis: art move 0/5 | axis target 6,4 own min 3 enemy min 0 | 鎮心補給 6,4 hold 2t min 0 XP 1 | allies +129.5; T7 3 units |
| 06_market_garden_1944 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:1 | allies 55/384 (14%); axis 50/384 (13%) | none | allies: eng min 2, art 5/6, targets 6 | allies: eng turns 2 | allies: art move 5/6 | allies target 5,11 own min 7 enemy min 9 | 南岸橋頭 5,12 hold 2t min 8 XP 1; 德軍遠程砲 18,2 destroy min 12 XP 1 | allies +129.5; T7 3 units |
| 07_bagration_1944 | axis artillery:1, mg_team:1; soviet artillery:1, mg_team:1 | axis 34/384 (9%); soviet 61/384 (16%) | none | soviet: eng none, art 0/4, targets 4 | soviet: eng turns none | soviet: art move 0/4 | soviet target 2,4 own min 20 enemy min 1 | 奪取路口 3,4 capture min 19 XP 1, reinforce -2t; 壓制德軍砲位 1,2 destroy min 21 XP 1 | soviet +77.6; T6 2 units |
| blitz_00_poland_1939 | allies artillery:1, mg_team:1; axis artillery:1 | allies 27/384 (7%); axis 37/384 (10%) | axis 51/384 (13%), spots 0 | axis: eng none, art 0/2, targets 2 | axis: eng turns none | axis: art move 0/2 | axis target 1,1 own min 23 enemy min 0 | 摧毀 37mm 反戰車砲 3,3 destroy min 20 XP 1; 偵察砲兵陣地 0,2 recon min 24 XP 1 | none |
| blitz_02_dunkirk_1940 | allies artillery:1, mg_team:1; axis artillery:1 | allies 38/384 (10%); axis 23/384 (6%) | axis 43/384 (11%), spots 0 | axis: eng none, art 0/4, targets 4 | axis: eng turns none | axis: art move 0/4 | axis target 5,0 own min 18 enemy min 0 | 堅守撤退出口 5,0 hold 2t min 0 XP 1, supp -2; 偵察裝甲縱隊 22,2 recon min 18 XP 1 | none |
| blitz_03_moscow_1941 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 43/384 (11%); soviet 40/384 (10%) | none | soviet: eng none, art 0/1, targets 1 | soviet: eng turns none | soviet: art move 0/1 | soviet target 6,2 own min 16 enemy min 0 | 壓制 MG 34 17,2 destroy min 5 XP 1; 前進觀測點 18,2 recon min 4 XP 1 | none |
| conq_atlantic_convoy | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 港口補給線 16,9 capture min 16 XP 1, conquest enemy -1 | none |
| conq_cbi_jungle | allies mg_team:1; axis artillery:1, mg_team:1 | axis 34/384 (9%) | none | allies: eng min 20, art 0/5, targets 5 | allies: eng turns 12 | allies: art move none | n/a | 叢林補給村 9,5 capture min 9 XP 1, conquest enemy -2 | none |
| conq_china_plains | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | n/a | n/a | n/a | 河橋補給線 14,6 capture min 13 XP 1, conquest enemy -1 | none |
| conq_desert_north_africa | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 綠洲補給站 13,11 capture min 12 XP 1, conquest enemy -1 | none |
| conq_home_islands | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 山脊彈藥庫 15,6 capture min 14 XP 1, conquest enemy -2 | none |
| conq_mediterranean_coast | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 44/384 (11%) | none | n/a | n/a | n/a | n/a | 海岸補給港 12,11 capture min 8 XP 1, conquest enemy -1 | none |
| conq_middle_east_oilfields | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 油田泵站 12,4 capture min 10 XP 1, conquest enemy -2 | none |
| conq_north_sea_raid | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 港灣油料庫 11,4 capture min 9 XP 1, conquest enemy -1 | none |
| conq_pacific_carrier | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | n/a | n/a | n/a | 環礁通信站 11,3 capture min 9 XP 1, conquest enemy -1 | none |
| conq_pacific_island | allies mg_team:1; axis artillery:1, mg_team:1 | axis 50/384 (13%) | allies 57/384 (15%), spots 0 | n/a | n/a | n/a | n/a | 中央港鎮倉庫 11,6 capture min 9 XP 1, conquest enemy -1 | none |
| east_05_kharkov_1943 | axis artillery:1; soviet artillery:1, mg_team:1 | axis 33/384 (9%); soviet 46/384 (12%) | axis 56/384 (15%), spots 0 | axis: eng none, art 0/7, targets 7 | axis: eng turns none | axis: art move 0/7 | axis target 4,3 own min 19 enemy min 1 | 突破機槍據點 5,3 destroy min 18 XP 1; 南側警戒線 5,4 recon min 19 XP 1 | none |
| east_09_seelow_1945 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 35/384 (9%); soviet 24/384 (6%) | none | soviet: eng none, art 0/4, targets 4 | soviet: eng turns none | soviet: art move 0/4 | soviet target 18,3 own min 21 enemy min 0 | 清除 MG 42 19,2 destroy min 22 XP 1; 偵察砲兵觀測點 21,1 recon min 25 XP 1 | none |
| east_10_berlin_1945 | axis artillery:1, mg_team:2; soviet artillery:1 | axis 37/384 (10%); soviet 56/384 (15%) | none | soviet: eng min 7, art 0/3, targets 3 | soviet: eng turns 3 | soviet: art move 1/3 | soviet target 19,4 own min 9 enemy min 0 | 清除西側 MG 42 18,3 destroy min 9 XP 1, repair 2, enemy supp +1 R2; 標定重砲陣地 22,2 recon min 13 XP 1, enemy dig -1 R2, campaign +1p | none |
| tut_00_basic_turn | none | none | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move none | allies target 6,2 own min 5 enemy min 0 | none | none |
| tut_01_terrain_zoc_overwatch | allies mg_team:1 | none | axis 38/54 (70%), spots 3 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move none | allies target 6,0 own min 4 enemy min 2 | 道路檢查點 4,0 capture min 2 XP 1 | none |
| tut_02_los_spotting_artillery | allies artillery:1 | allies 50/70 (71%) | allies 62/70 (89%), spots 2 | allies: eng none, art 1/1, targets 1 | allies: eng turns none | allies: art move 1/1 | n/a | none | none |
| tut_03_suppression_digin_engineer | allies artillery:1; axis mg_team:1 | allies 43/70 (61%) | none | allies: eng min 1, art 2/2, targets 2 | allies: eng turns 0 | allies: art move 2/2 | allies target 7,3 own min 3 enemy min 0 | none | none |
| tut_04_armor_at_veteran_general | none | none | none | n/a | n/a | n/a | n/a | none | none |
| tut_05_airdrop_reinforcement_rocket | axis mg_team:1 | allies 37/70 (53%) | none | allies: eng none, art 2/2, targets 2 | allies: eng turns none | allies: art move 2/2 | n/a | none | allies +77.6; T3 2 units |
| west_08_falaise_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 21,4 own min 19 enemy min 0 | 封鎖撤退道路 22,11 recon min 19 XP 1, enemy supp +1 R1 | none |
| west_08_normandy_cobra_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 2,2 own min 2 enemy min 0 | 清除 MG 42 1,2 destroy min 2 XP 1; 反砲兵偵察 22,2 recon min 21 XP 1 | none |
| west_09_aachen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | n/a | n/a | n/a | allies target 5,11 own min 2 enemy min 0 | 清除西側 PaK 40 6,4 destroy min 4 XP 1, enemy dig -1 R1 | none |
| west_09_hurtgen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | n/a | n/a | n/a | allies target 5,4 own min 3 enemy min 0 | 控制森林林道 4,4 hold 2t min 2 XP 1, supp -2 | none |
| west_10_remagen_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 17,4 own min 15 enemy min 0 | 奪取橋西岸 12,0 capture min 10 XP 1, repair 2 | none |
| west_11_colmar_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 19,11 own min 16 enemy min 0 | 壓制口袋機槍 18,11 destroy min 15 XP 1, enemy supp +1 R2 | none |

## Urban Breach Focus

Focused gate for city assaults that already have breach tools but still need manual survivability checks.

| scenario | faction | high-cover targets | eng min | eng turns | art now | art after move | check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 03_stalingrad_1942 | axis | 6/6 | 7 | 3 | 0/6 | 1/6 | supported |
| east_10_berlin_1945 | soviet | 3/3 | 7 | 3 | 0/3 | 1/3 | supported |

## Secondary Objective Reward Audit

Focused audit of optional objective pressure, reward type, and static reward effectiveness.

| scenario | objective | target | faction | distance | rewards | audit |
| --- | --- | --- | --- | --- | --- | --- |
| 01_sedan_1940 | 橋頭補給 | capture 15,5 | axis | own 7 / enemy 9 | XP 1 | ok |
| 01_sedan_1940 | 中路渡口 | recon 13,5 | axis | own 9 / enemy 11 | XP 1 | ok |
| 02_kiev_1941 | 壓制馬克沁火點 | destroy 4,4 | axis | own 19 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 02_kiev_1941 | 南翼掃蕩 | recon 3,13 | axis | own 18 / enemy 0 | XP 1 | enemy closer |
| 03_stalingrad_1942 | 突擊工兵 | destroy 13,10 | soviet | own 7 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 04_kursk_1943 | 壓制 SU-152 | destroy 4,0 | axis | own 18 / enemy 0 | XP 1 | enemy closer |
| 04_kursk_1943 | 北側高地偵察 | recon 18,2 | axis | own 4 / enemy 0 | XP 1 | enemy closer |
| 05_bastogne_1944 | 鎮心補給 | hold 2t 6,4 | allies | own 0 / enemy 3 | XP 1 | starts held |
| 06_market_garden_1944 | 南岸橋頭 | hold 2t 5,12 | allies | own 8 / enemy 10 | XP 1 | ok |
| 06_market_garden_1944 | 德軍遠程砲 | destroy 18,2 | allies | own 12 / enemy 0 | XP 1 | enemy closer |
| 07_bagration_1944 | 奪取路口 | capture 3,4 | soviet | own 19 / enemy 0 | XP 1, reinforce -2t | enemy closer; reinforce best T6->T4 |
| 07_bagration_1944 | 壓制德軍砲位 | destroy 1,2 | soviet | own 21 / enemy 0 | XP 1 | enemy closer |
| blitz_00_poland_1939 | 摧毀 37mm 反戰車砲 | destroy 3,3 | axis | own 20 / enemy 0 | XP 1 | enemy closer |
| blitz_00_poland_1939 | 偵察砲兵陣地 | recon 0,2 | axis | own 24 / enemy 0 | XP 1 | enemy closer |
| blitz_02_dunkirk_1940 | 堅守撤退出口 | hold 2t 5,0 | allies | own 0 / enemy 18 | XP 1, supp -2 | starts held; sustain reward |
| blitz_02_dunkirk_1940 | 偵察裝甲縱隊 | recon 22,2 | allies | own 18 / enemy 0 | XP 1 | enemy closer |
| blitz_03_moscow_1941 | 壓制 MG 34 | destroy 17,2 | soviet | own 5 / enemy 0 | XP 1 | enemy closer |
| blitz_03_moscow_1941 | 前進觀測點 | recon 18,2 | soviet | own 4 / enemy 1 | XP 1 | enemy closer |
| conq_atlantic_convoy | 港口補給線 | capture 16,9 | allies | own 16 / enemy 7 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_cbi_jungle | 叢林補給村 | capture 9,5 | allies | own 9 / enemy 14 | XP 1, conquest enemy -2 | conquest pressure -2 |
| conq_china_plains | 河橋補給線 | capture 14,6 | allies | own 13 / enemy 9 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_desert_north_africa | 綠洲補給站 | capture 13,11 | allies | own 12 / enemy 9 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_home_islands | 山脊彈藥庫 | capture 15,6 | allies | own 14 / enemy 8 | XP 1, conquest enemy -2 | enemy closer; conquest pressure -2 |
| conq_mediterranean_coast | 海岸補給港 | capture 12,11 | allies | own 8 / enemy 10 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_middle_east_oilfields | 油田泵站 | capture 12,4 | allies | own 10 / enemy 10 | XP 1, conquest enemy -2 | conquest pressure -2 |
| conq_north_sea_raid | 港灣油料庫 | capture 11,4 | allies | own 9 / enemy 11 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_pacific_carrier | 環礁通信站 | capture 11,3 | allies | own 9 / enemy 10 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_pacific_island | 中央港鎮倉庫 | capture 11,6 | allies | own 9 / enemy 11 | XP 1, conquest enemy -1 | conquest pressure -1 |
| east_05_kharkov_1943 | 突破機槍據點 | destroy 5,3 | axis | own 18 / enemy 0 | XP 1 | enemy closer |
| east_05_kharkov_1943 | 南側警戒線 | recon 5,4 | axis | own 19 / enemy 0 | XP 1 | enemy closer |
| east_09_seelow_1945 | 清除 MG 42 | destroy 19,2 | soviet | own 22 / enemy 0 | XP 1 | enemy closer |
| east_09_seelow_1945 | 偵察砲兵觀測點 | recon 21,1 | soviet | own 25 / enemy 0 | XP 1 | enemy closer |
| east_10_berlin_1945 | 清除西側 MG 42 | destroy 18,3 | soviet | own 9 / enemy 0 | XP 1, repair 2, enemy supp +1 R2 | enemy closer; damage recovery; tactical suppression reward R2 |
| east_10_berlin_1945 | 標定重砲陣地 | recon 22,2 | soviet | own 13 / enemy 0 | XP 1, enemy dig -1 R2, campaign +1p | enemy closer; breach reward R2; campaign bonus +1 |
| tut_01_terrain_zoc_overwatch | 道路檢查點 | capture 4,0 | allies | own 2 / enemy 2 | XP 1 | ok |
| west_08_falaise_1944 | 封鎖撤退道路 | recon 22,11 | allies | own 19 / enemy 0 | XP 1, enemy supp +1 R1 | enemy closer; tactical suppression reward R1 |
| west_08_normandy_cobra_1944 | 清除 MG 42 | destroy 1,2 | allies | own 2 / enemy 0 | XP 1 | enemy closer |
| west_08_normandy_cobra_1944 | 反砲兵偵察 | recon 22,2 | allies | own 21 / enemy 0 | XP 1 | enemy closer |
| west_09_aachen_1944 | 清除西側 PaK 40 | destroy 6,4 | allies | own 4 / enemy 0 | XP 1, enemy dig -1 R1 | enemy closer; breach reward R1 |
| west_09_hurtgen_1944 | 控制森林林道 | hold 2t 4,4 | allies | own 2 / enemy 0 | XP 1, supp -2 | enemy closer; sustain reward |
| west_10_remagen_1945 | 奪取橋西岸 | capture 12,0 | allies | own 10 / enemy 6 | XP 1, repair 2 | enemy closer; damage recovery |
| west_11_colmar_1945 | 壓制口袋機槍 | destroy 18,11 | allies | own 15 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |

## Conquest Secondary Coverage

Focused gate for conquest templates: each conq_* battle should give optional objectives a strategic enemy-strength effect instead of XP-only pressure.

| scenario | secondary objectives | strategic objectives | enemy strength pressure | check |
| --- | --- | --- | --- | --- |
| conq_atlantic_convoy | 1 | 1 | -1 | covered |
| conq_cbi_jungle | 1 | 1 | -2 | covered |
| conq_china_plains | 1 | 1 | -1 | covered |
| conq_desert_north_africa | 1 | 1 | -1 | covered |
| conq_home_islands | 1 | 1 | -2 | covered |
| conq_mediterranean_coast | 1 | 1 | -1 | covered |
| conq_middle_east_oilfields | 1 | 1 | -2 | covered |
| conq_north_sea_raid | 1 | 1 | -1 | covered |
| conq_pacific_carrier | 1 | 1 | -1 | covered |
| conq_pacific_island | 1 | 1 | -1 | covered |

## Gameplay Depth Coverage

Focused gate for non-tutorial, non-conquest battles: each main battle should have optional pressure, and reports should show XP-only objectives separately from richer tactical or strategic rewards.

| scenario | secondary objectives | xp-only objectives | enriched objectives | check |
| --- | --- | --- | --- | --- |
| 01_sedan_1940 | 2 | 2 | 0 | xp-only |
| 02_kiev_1941 | 2 | 1 | 1 | covered |
| 03_stalingrad_1942 | 1 | 0 | 1 | covered |
| 04_kursk_1943 | 2 | 2 | 0 | xp-only |
| 05_bastogne_1944 | 1 | 1 | 0 | xp-only |
| 06_market_garden_1944 | 2 | 2 | 0 | xp-only |
| 07_bagration_1944 | 2 | 1 | 1 | covered |
| blitz_00_poland_1939 | 2 | 2 | 0 | xp-only |
| blitz_02_dunkirk_1940 | 2 | 1 | 1 | covered |
| blitz_03_moscow_1941 | 2 | 2 | 0 | xp-only |
| east_05_kharkov_1943 | 2 | 2 | 0 | xp-only |
| east_09_seelow_1945 | 2 | 2 | 0 | xp-only |
| east_10_berlin_1945 | 2 | 0 | 2 | covered |
| west_08_falaise_1944 | 1 | 0 | 1 | covered |
| west_08_normandy_cobra_1944 | 2 | 2 | 0 | xp-only |
| west_09_aachen_1944 | 1 | 0 | 1 | covered |
| west_09_hurtgen_1944 | 1 | 0 | 1 | covered |
| west_10_remagen_1945 | 1 | 0 | 1 | covered |
| west_11_colmar_1945 | 1 | 0 | 1 | covered |

## Scenario Expansion Coverage

Dynamic coverage gate for formal campaign expansion: reports campaign size, victory variety, special terrain usage, and role hooks that should diversify new battles.

| campaign | scenarios | victory mix | special terrain | role hooks | check |
| --- | --- | --- | --- | --- | --- |
| blitzkrieg_early_war | 5 | capture:3, eliminate:1, survive:1 | river:3 | scout:2 | tracked |
| eastern_front | 6 | capture:5, survive:1 | river:1, town:3 | reinforcement:1, scout:2, engineer:1 | tracked |
| western_front | 8 | capture:7, survive:1 | river:1 | reinforcement:2, engineer:2, airdrop:2 | tracked |
