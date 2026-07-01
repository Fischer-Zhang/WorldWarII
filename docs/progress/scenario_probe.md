# Scenario Probe

Static tactical probe for pressure tuning. Coverage is approximate and ignores LOS/fog; use it to spot scenarios that need manual playtesting.

| scenario | suppression sources | artillery coverage | spotter coverage | breach path | breach tempo | artillery reposition | objective pressure | secondary pressure | reinforcement delta |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 00_sandbox | allies mg_team:1; axis artillery:1 | allies 24/384 (6%); axis 54/384 (14%) | axis 43/384 (11%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | none | none |
| 01_sedan_1940 | allies mg_team:2; axis artillery:1 | axis 33/384 (9%) | axis 64/384 (17%), spots 1 | axis: eng none, art 0/3, targets 3 | axis: eng turns none | axis: art move 1/3 | axis target 20,14 own min 2 enemy min 0 | 橋頭補給 15,5 capture min 7 XP 1, repair 2; 中路渡口 13,5 recon min 9 XP 1, enemy supp +1 R2 | none |
| 02_kiev_1941 | axis artillery:2; soviet mg_team:1 | axis 57/384 (15%) | soviet 68/384 (18%), spots 0 | axis: eng none, art 0/1, targets 1 | axis: eng turns none | axis: art move 0/1 | n/a | 南翼掃蕩 3,13 recon min 18 XP 1, enemy dig -1 R2; 壓制馬克沁火點 4,4 destroy after southern_sweep min 19 XP 1, enemy supp +1 R2 | none |
| 03_stalingrad_1942 | axis artillery:1, mg_team:1; soviet mg_team:2 | axis 61/384 (16%); soviet 21/384 (5%) | axis 65/384 (17%), spots 0 | axis: eng min 7, art 0/6, targets 6 | axis: eng turns 3 | axis: art move 1/6 | n/a | 標定突擊路線 13,10 recon min 7 XP 1, enemy dig -1 R2; 突擊工兵 13,10 destroy after stalingrad_spot_engineers min 7 XP 1, enemy supp +1 R2 | none |
| 04_kursk_1943 | axis artillery:1; soviet artillery:1 | axis 34/384 (9%); soviet 42/384 (11%) | axis 43/384 (11%), spots 2 | n/a | n/a | n/a | axis control 2/3 own min 6 enemy min 0 | 壓制 SU-152 4,0 destroy min 18 XP 1, repair 2; 北側高地偵察 18,2 recon min 4 XP 1, enemy dig -1 R2 | none |
| 05_bastogne_1944 | allies artillery:1, mg_team:1; axis artillery:1 | allies 61/384 (16%); axis 42/384 (11%) | none | axis: eng none, art 0/5, targets 5 | axis: eng turns none | axis: art move 0/5 | axis target 6,4 own min 3 enemy min 0; allies hold 6,4 12t own min 0 enemy min 3 | 鎮心補給 6,4 hold 2t min 0 XP 1, supp -2, reinforce -2t; 南側遠程砲 22,11 destroy after bastogne_supply_hold min 16 XP 1, enemy supp +1 R2 | allies +129.5; T7 3 units |
| 06_market_garden_1944 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:1 | allies 55/384 (14%); axis 50/384 (13%) | none | allies: eng min 2, art 5/6, targets 6 | allies: eng turns 2 | allies: art move 5/6 | allies target 5,11 own min 7 enemy min 9 | 南岸橋頭 5,12 hold 2t min 8 XP 1, reinforce -2t; 德軍遠程砲 18,2 destroy after nijmegen_south_bridgehead min 12 XP 1, enemy supp +1 R2 | allies +129.5; T7 3 units |
| 07_bagration_1944 | axis artillery:1, mg_team:1; soviet artillery:1, mg_team:1 | axis 34/384 (9%); soviet 61/384 (16%) | none | soviet: eng none, art 0/4, targets 4 | soviet: eng turns none | soviet: art move 0/4 | soviet target 2,4 own min 20 enemy min 1 | 奪取路口 3,4 capture min 19 XP 1, reinforce -2t; 壓制德軍砲位 1,2 destroy min 21 XP 1, enemy supp +1 R2 | soviet +77.6; T6 2 units |
| blitz_00_poland_1939 | allies artillery:1, mg_team:1; axis artillery:1 | allies 27/384 (7%); axis 37/384 (10%) | axis 51/384 (13%), spots 0 | axis: eng none, art 0/2, targets 2 | axis: eng turns none | axis: art move 0/2 | axis target 1,1 own min 23 enemy min 0 | 摧毀 37mm 反戰車砲 3,3 destroy min 20 XP 1, repair 2; 偵察砲兵陣地 0,2 recon min 24 XP 1, enemy supp +1 R2 | none |
| blitz_02_dunkirk_1940 | allies artillery:1, mg_team:1; axis artillery:1 | allies 38/384 (10%); axis 23/384 (6%) | axis 43/384 (11%), spots 0 | axis: eng none, art 0/4, targets 4 | axis: eng turns none | axis: art move 0/4 | axis target 5,0 own min 18 enemy min 0 | 堅守撤退出口 5,0 hold 2t min 0 XP 1, supp -2; 偵察裝甲縱隊 22,2 recon min 18 XP 1, enemy supp +1 R2 | none |
| blitz_03_moscow_1941 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 43/384 (11%); soviet 40/384 (10%) | none | soviet: eng none, art 0/1, targets 1 | soviet: eng turns none | soviet: art move 0/1 | soviet target 6,2 own min 16 enemy min 0 | 壓制 MG 34 17,2 destroy min 5 XP 1, enemy supp +1 R2; 前進觀測點 18,2 recon min 4 XP 1, enemy dig -1 R2 | none |
| conq_atlantic_convoy | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 港口補給線 16,9 capture min 16 XP 1, conquest enemy -1; 偵察海岸信號站 17,2 recon after atlantic_port_sabotage min 15 enemy supp +1 R2, conquest enemy -1 | none |
| conq_cbi_jungle | allies mg_team:1; axis artillery:1, mg_team:1 | axis 34/384 (9%) | none | allies: eng min 20, art 0/5, targets 5 | allies: eng turns 12 | allies: art move none | n/a | 叢林補給村 9,5 capture min 9 XP 1, conquest enemy -2; 偵察叢林渡口 12,12 recon after cbi_jungle_supply min 10 enemy dig -1 R2, conquest enemy -1 | none |
| conq_china_plains | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | n/a | n/a | n/a | 河橋補給線 14,6 capture min 13 XP 1, conquest enemy -1; 固守前進鐵路站 10,10 hold 2t after china_bridge_cache min 9 supp -2, conquest enemy -1 | none |
| conq_desert_north_africa | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 綠洲補給站 13,11 capture min 12 XP 1, conquest enemy -1; 偵察沙漠高地 20,6 recon after desert_oasis_depot min 19 enemy supp +1 R2, conquest enemy -1 | none |
| conq_home_islands | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 山脊彈藥庫 15,6 capture min 14 XP 1, conquest enemy -2; 標定山口火點 17,12 recon after home_islands_fort_depot min 15 enemy dig -1 R2, conquest enemy -1 | none |
| conq_mediterranean_coast | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 44/384 (11%) | none | n/a | n/a | n/a | n/a | 海岸補給港 12,11 capture min 8 XP 1, conquest enemy -1; 控制丘陵公路 17,5 hold 2t after med_coast_supply_port min 16 enemy supp +1 R2, conquest enemy -1 | none |
| conq_middle_east_oilfields | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 油田泵站 12,4 capture min 10 XP 1, conquest enemy -2; 控制輸油管線 14,9 capture after oilfield_pump_station min 14 repair 2, conquest enemy -1 | none |
| conq_north_sea_raid | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 港灣油料庫 11,4 capture min 9 XP 1, conquest enemy -1; 偵察海岸雷達站 17,11 recon after north_sea_harbor_cache min 16 enemy supp +1 R2, conquest enemy -1 | none |
| conq_pacific_carrier | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | n/a | n/a | n/a | 環礁通信站 11,3 capture min 9 XP 1, conquest enemy -1; 守住潟湖錨地 14,4 hold 2t after carrier_atoll_radio min 12 repair 2, conquest enemy -1 | none |
| conq_pacific_island | allies mg_team:1; axis artillery:1, mg_team:1 | axis 50/384 (13%) | allies 57/384 (15%), spots 0 | n/a | n/a | n/a | n/a | 中央港鎮倉庫 11,6 capture min 9 XP 1, conquest enemy -1; 偵察島內洞口 14,8 recon after island_port_cache min 13 enemy dig -1 R2, conquest enemy -1 | none |
| east_05_kharkov_1943 | axis artillery:1; soviet artillery:1, mg_team:1 | axis 33/384 (9%); soviet 46/384 (12%) | axis 56/384 (15%), spots 0 | axis: eng none, art 0/7, targets 7 | axis: eng turns none | axis: art move 0/7 | axis target 4,3 own min 19 enemy min 1 | 突破機槍據點 5,3 destroy min 18 XP 1, enemy supp +1 R2; 南側警戒線 5,4 recon min 19 XP 1, enemy dig -1 R2 | none |
| east_06_dnieper_1943 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 29/160 (18%); soviet 37/160 (23%) | soviet 61/160 (38%), spots 0 | soviet: eng min 5, art 0/3, targets 3 | soviet: eng turns 2 | soviet: art move 0/3 | soviet target 9,5 own min 6 enemy min 1 | 控制東岸渡口 5,4 hold 2t min 1 XP 1, reinforce -2t; 偵察西岸觀測點 12,4 recon min 8 XP 1, enemy dig -1 R2 | soviet +77.6; T6 2 units |
| east_09_seelow_1945 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 35/384 (9%); soviet 24/384 (6%) | none | soviet: eng none, art 0/4, targets 4 | soviet: eng turns none | soviet: art move 0/4 | soviet target 18,3 own min 21 enemy min 0 | 清除 MG 42 19,2 destroy min 22 XP 1, enemy supp +1 R2; 偵察砲兵觀測點 21,1 recon min 25 XP 1, enemy dig -1 R2 | none |
| east_10_berlin_1945 | axis artillery:1, mg_team:2; soviet artillery:1 | axis 37/384 (10%); soviet 56/384 (15%) | none | soviet: eng min 7, art 0/3, targets 3 | soviet: eng turns 3 | soviet: art move 1/3 | soviet target 19,4 own min 9 enemy min 0 | 清除西側 MG 42 18,3 destroy min 9 XP 1, repair 2, enemy supp +1 R2; 標定重砲陣地 22,2 recon min 13 XP 1, enemy dig -1 R2, campaign +1p | none |
| north_00_gazala_1942 | allies artillery:1, mg_team:1; axis artillery:1 | allies 32/160 (20%); axis 23/160 (14%) | axis 49/160 (31%), spots 0 | axis: eng none, art 0/4, targets 4 | axis: eng turns none | axis: art move 0/4 | axis target 11,4 own min 8 enemy min 0 | 偵察北側崖線 8,1 recon min 7 XP 1, enemy supp +1 R2; 摧毀 6-pdr 反戰車砲 10,2 destroy min 8 XP 1, repair 2 | none |
| north_01_el_alamein_1942 | allies artillery:1; axis artillery:1 | allies 23/160 (14%); axis 26/160 (16%) | allies 49/160 (31%), spots 0 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | n/a | 奪取綠洲補給 8,5 capture min 6 XP 1, repair 2; 偵察北側山脊 10,2 recon min 9 XP 1, enemy supp +1 R2 | none |
| north_02_kasserine_1943 | allies artillery:1, mg_team:1; axis artillery:1 | allies 29/160 (18%); axis 26/160 (16%) | allies 68/160 (42%), spots 0; axis 57/160 (36%), spots 0 | axis: eng none, art 0/3, targets 3 | axis: eng turns none | axis: art move 0/3 | axis target 5,4 own min 7 enemy min 0 | 守住山口補給 5,4 hold 2t min 0 XP 1, reinforce -2t; 偵察南側山脊 10,6 recon min 5 XP 1, enemy supp +1 R2 | allies +122.8; T6 3 units |
| north_03_tunis_1943 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/160 (14%); axis 32/160 (20%) | allies 55/160 (34%), spots 0 | allies: eng min 8, art 0/4, targets 4 | allies: eng turns 3 | allies: art move 0/4 | n/a | 奪取山口補給站 8,5 capture min 6 XP 1, repair 2; 摧毀山地遠程砲 14,8 destroy min 11 XP 1, enemy supp +1 R2 | none |
| north_04_bizerte_1943 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:1 | allies 23/160 (14%); axis 32/160 (20%) | allies 60/160 (38%), spots 0 | allies: eng min 9, art 0/5, targets 5 | allies: eng turns 3 | allies: art move 0/5 | allies target 13,4 own min 11 enemy min 0 | 奪取前進燃料站 9,4 capture min 7 XP 1, reinforce -2t; 摧毀港口遠程砲 14,8 destroy min 11 XP 1, enemy supp +1 R2 | allies +77.6; T7 2 units |
| pacific_01_guadalcanal_1942 | allies mg_team:1; axis artillery:1, mg_team:1 | allies 27/160 (17%); axis 34/160 (21%) | allies 70/160 (44%), spots 0 | allies: eng min 9, art 0/4, targets 4 | allies: eng turns 4 | allies: art move 0/4 | n/a | 奪取補給村 8,4 capture min 6 XP 1, supp -2; 摧毀叢林機槍 12,6 destroy min 9 XP 1, enemy supp +1 R2 | none |
| pacific_02_tarawa_1943 | allies mg_team:1; axis artillery:1, mg_team:2 | allies 25/160 (16%); axis 34/160 (21%) | allies 68/160 (42%), spots 0 | allies: eng min 8, art 0/5, targets 5 | allies: eng turns 3 | allies: art move 0/5 | allies target 11,4 own min 9 enemy min 0 | 奪取棧橋補給 7,6 capture min 4 XP 1, supp -2; 摧毀海堤機槍 10,4 destroy min 8 XP 1, enemy supp +1 R2 | none |
| pacific_03_peleliu_1944 | allies mg_team:1; axis artillery:1, mg_team:2 | allies 27/160 (17%); axis 34/160 (21%) | allies 70/160 (44%), spots 0 | allies: eng min 8, art 0/5, targets 5 | allies: eng turns 3 | allies: art move 0/5 | allies target 11,4 own min 9 enemy min 0 | 摧毀洞窟機槍 10,4 destroy min 8 XP 1, enemy supp +1 R2; 偵察北側山脊 12,2 recon min 11 XP 1, enemy dig -1 R2 | none |
| pacific_04_manila_1945 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:2 | allies 24/160 (15%); axis 37/160 (23%) | allies 60/160 (38%), spots 0 | n/a | n/a | n/a | allies control 3/4 own min 7 enemy min 0 | 奪取醫院補給 8,5 capture min 6 XP 1, supp -2; 標定城北砲位 12,2 recon min 11 XP 1, enemy dig -1 R2, campaign +1p | none |
| pacific_05_iwo_jima_1945 | allies mg_team:1; axis artillery:1, mg_team:2 | allies 27/160 (17%); axis 34/160 (21%) | allies 70/160 (44%), spots 0 | allies: eng min 10, art 0/6, targets 6 | allies: eng turns 4 | allies: art move 0/6 | allies target 13,4 own min 10 enemy min 0 | 控制機場補給點 6,4 hold 2t min 3 XP 1, reinforce -2t; 偵察北側洞窟 12,2 recon min 10 XP 1, enemy dig -1 R2 | allies +77.6; T7 2 units |
| pacific_05_okinawa_1945 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:2 | allies 24/160 (15%); axis 37/160 (23%) | allies 60/160 (38%), spots 0 | allies: eng min 9, art 0/5, targets 5 | allies: eng turns 4 | allies: art move 0/5 | n/a | 控制前進觀測所 8,4 hold 2t min 6 XP 1, reinforce -2t; 摧毀首里機槍 10,4 destroy min 8 XP 1, enemy supp +1 R2 | allies +109.7; T6 3 units |
| tut_00_basic_turn | none | none | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move none | allies target 6,2 own min 5 enemy min 0 | none | none |
| tut_01_terrain_zoc_overwatch | allies mg_team:1 | none | axis 38/54 (70%), spots 3 | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move none | allies target 6,0 own min 4 enemy min 2 | 道路檢查點 4,0 capture min 2 XP 1 | none |
| tut_02_los_spotting_artillery | allies artillery:1 | allies 50/70 (71%) | allies 62/70 (89%), spots 2 | allies: eng none, art 1/1, targets 1 | allies: eng turns none | allies: art move 1/1 | n/a | none | none |
| tut_03_suppression_digin_engineer | allies artillery:1; axis mg_team:1 | allies 43/70 (61%) | none | allies: eng min 1, art 2/2, targets 2 | allies: eng turns 0 | allies: art move 2/2 | allies target 7,3 own min 3 enemy min 0 | none | none |
| tut_04_armor_at_veteran_general | none | none | none | n/a | n/a | n/a | n/a | none | none |
| tut_05_airdrop_reinforcement_rocket | axis mg_team:1 | allies 37/70 (53%) | none | allies: eng none, art 2/2, targets 2 | allies: eng turns none | allies: art move 2/2 | n/a | none | allies +77.6; T3 2 units |
| west_08_falaise_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 21,4 own min 19 enemy min 0 | 封鎖撤退道路 22,11 recon min 19 XP 1, enemy supp +1 R1; 摧毀 StuG 掩護 22,0 destroy after seal_escape_road min 20 XP 1, repair 2 | none |
| west_08_normandy_cobra_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 2,2 own min 2 enemy min 0 | 清除 MG 42 1,2 destroy min 2 XP 1, enemy supp +1 R2; 反砲兵偵察 22,2 recon min 21 XP 1, enemy dig -1 R2 | none |
| west_08_pegasus_bridge_1944 | allies mg_team:1; axis artillery:1, mg_team:1 | axis 32/160 (20%) | none | n/a | n/a | n/a | allies hold 7,4 3t own min 4 enemy min 1 | 穩住南岸橋頭 7,5 hold 2t min 4 XP 1, reinforce -2t; 摧毀橋北機槍 8,3 destroy min 5 XP 1, enemy supp +1 R2 | allies +77.6; T6 2 units |
| west_09_aachen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | n/a | n/a | n/a | allies target 5,11 own min 2 enemy min 0 | 清除西側 PaK 40 6,4 destroy min 4 XP 1, enemy dig -1 R1; 市政廳側翼 5,11 recon after clear_western_at min 2 XP 1, enemy dig -1 R2 | none |
| west_09_hurtgen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | n/a | n/a | n/a | allies hold 5,4 2t own min 3 enemy min 0 | 林道 MG 42 4,4 destroy min 2 XP 1, enemy supp +1 R2; 控制前進林道 4,5 hold 2t after silence_forest_mg min 3 XP 1, supp -2 | none |
| west_10_remagen_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 17,4 own min 15 enemy min 0 | 奪取橋西岸 12,0 capture min 10 XP 1, repair 2; 偵察東岸橋頭 17,4 recon after secure_bridge_west_bank min 15 XP 1, enemy dig -1 R2 | none |
| west_11_colmar_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies: eng none, art 0/1, targets 1 | allies: eng turns none | allies: art move 0/1 | allies target 19,11 own min 16 enemy min 0 | 壓制口袋機槍 18,11 destroy min 15 XP 1, enemy supp +1 R2; 側翼村道 19,11 recon after suppress_colmar_mg min 16 XP 1, enemy dig -1 R2 | none |

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
| 01_sedan_1940 | 橋頭補給 | capture 15,5 | axis | own 7 / enemy 9 | XP 1, repair 2 | damage recovery |
| 01_sedan_1940 | 中路渡口 | recon 13,5 | axis | own 9 / enemy 11 | XP 1, enemy supp +1 R2 | tactical suppression reward R2 |
| 02_kiev_1941 | 南翼掃蕩 | recon 3,13 | axis | own 18 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| 02_kiev_1941 | 壓制馬克沁火點 | destroy 4,4 after southern_sweep | axis | own 19 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 03_stalingrad_1942 | 標定突擊路線 | recon 13,10 | soviet | own 7 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| 03_stalingrad_1942 | 突擊工兵 | destroy 13,10 after stalingrad_spot_engineers | soviet | own 7 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 04_kursk_1943 | 壓制 SU-152 | destroy 4,0 | axis | own 18 / enemy 0 | XP 1, repair 2 | enemy closer; damage recovery |
| 04_kursk_1943 | 北側高地偵察 | recon 18,2 | axis | own 4 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| 05_bastogne_1944 | 鎮心補給 | hold 2t 6,4 | allies | own 0 / enemy 3 | XP 1, supp -2, reinforce -2t | starts held; sustain reward; reinforce best T7->T5 |
| 05_bastogne_1944 | 南側遠程砲 | destroy 22,11 after bastogne_supply_hold | allies | own 16 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 06_market_garden_1944 | 南岸橋頭 | hold 2t 5,12 | allies | own 8 / enemy 10 | XP 1, reinforce -2t | reinforce best T7->T5 |
| 06_market_garden_1944 | 德軍遠程砲 | destroy 18,2 after nijmegen_south_bridgehead | allies | own 12 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| 07_bagration_1944 | 奪取路口 | capture 3,4 | soviet | own 19 / enemy 0 | XP 1, reinforce -2t | enemy closer; reinforce best T6->T4 |
| 07_bagration_1944 | 壓制德軍砲位 | destroy 1,2 | soviet | own 21 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| blitz_00_poland_1939 | 摧毀 37mm 反戰車砲 | destroy 3,3 | axis | own 20 / enemy 0 | XP 1, repair 2 | enemy closer; damage recovery |
| blitz_00_poland_1939 | 偵察砲兵陣地 | recon 0,2 | axis | own 24 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| blitz_02_dunkirk_1940 | 堅守撤退出口 | hold 2t 5,0 | allies | own 0 / enemy 18 | XP 1, supp -2 | starts held; sustain reward |
| blitz_02_dunkirk_1940 | 偵察裝甲縱隊 | recon 22,2 | allies | own 18 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| blitz_03_moscow_1941 | 壓制 MG 34 | destroy 17,2 | soviet | own 5 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| blitz_03_moscow_1941 | 前進觀測點 | recon 18,2 | soviet | own 4 / enemy 1 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| conq_atlantic_convoy | 港口補給線 | capture 16,9 | allies | own 16 / enemy 7 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_atlantic_convoy | 偵察海岸信號站 | recon 17,2 after atlantic_port_sabotage | allies | own 15 / enemy 5 | enemy supp +1 R2, conquest enemy -1 | enemy closer; tactical suppression reward R2; conquest pressure -1 |
| conq_cbi_jungle | 叢林補給村 | capture 9,5 | allies | own 9 / enemy 14 | XP 1, conquest enemy -2 | conquest pressure -2 |
| conq_cbi_jungle | 偵察叢林渡口 | recon 12,12 after cbi_jungle_supply | allies | own 10 / enemy 9 | enemy dig -1 R2, conquest enemy -1 | enemy closer; breach reward R2; conquest pressure -1 |
| conq_china_plains | 河橋補給線 | capture 14,6 | allies | own 13 / enemy 9 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_china_plains | 固守前進鐵路站 | hold 2t 10,10 after china_bridge_cache | allies | own 9 / enemy 13 | supp -2, conquest enemy -1 | sustain reward; conquest pressure -1 |
| conq_desert_north_africa | 綠洲補給站 | capture 13,11 | allies | own 12 / enemy 9 | XP 1, conquest enemy -1 | enemy closer; conquest pressure -1 |
| conq_desert_north_africa | 偵察沙漠高地 | recon 20,6 after desert_oasis_depot | allies | own 19 / enemy 3 | enemy supp +1 R2, conquest enemy -1 | enemy closer; tactical suppression reward R2; conquest pressure -1 |
| conq_home_islands | 山脊彈藥庫 | capture 15,6 | allies | own 14 / enemy 8 | XP 1, conquest enemy -2 | enemy closer; conquest pressure -2 |
| conq_home_islands | 標定山口火點 | recon 17,12 after home_islands_fort_depot | allies | own 15 / enemy 5 | enemy dig -1 R2, conquest enemy -1 | enemy closer; breach reward R2; conquest pressure -1 |
| conq_mediterranean_coast | 海岸補給港 | capture 12,11 | allies | own 8 / enemy 10 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_mediterranean_coast | 控制丘陵公路 | hold 2t 17,5 after med_coast_supply_port | allies | own 16 / enemy 2 | enemy supp +1 R2, conquest enemy -1 | enemy closer; tactical suppression reward R2; conquest pressure -1 |
| conq_middle_east_oilfields | 油田泵站 | capture 12,4 | allies | own 10 / enemy 10 | XP 1, conquest enemy -2 | conquest pressure -2 |
| conq_middle_east_oilfields | 控制輸油管線 | capture 14,9 after oilfield_pump_station | allies | own 14 / enemy 9 | repair 2, conquest enemy -1 | enemy closer; damage recovery; conquest pressure -1 |
| conq_north_sea_raid | 港灣油料庫 | capture 11,4 | allies | own 9 / enemy 11 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_north_sea_raid | 偵察海岸雷達站 | recon 17,11 after north_sea_harbor_cache | allies | own 16 / enemy 5 | enemy supp +1 R2, conquest enemy -1 | enemy closer; tactical suppression reward R2; conquest pressure -1 |
| conq_pacific_carrier | 環礁通信站 | capture 11,3 | allies | own 9 / enemy 10 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_pacific_carrier | 守住潟湖錨地 | hold 2t 14,4 after carrier_atoll_radio | allies | own 12 / enemy 8 | repair 2, conquest enemy -1 | enemy closer; damage recovery; conquest pressure -1 |
| conq_pacific_island | 中央港鎮倉庫 | capture 11,6 | allies | own 9 / enemy 11 | XP 1, conquest enemy -1 | conquest pressure -1 |
| conq_pacific_island | 偵察島內洞口 | recon 14,8 after island_port_cache | allies | own 13 / enemy 9 | enemy dig -1 R2, conquest enemy -1 | enemy closer; breach reward R2; conquest pressure -1 |
| east_05_kharkov_1943 | 突破機槍據點 | destroy 5,3 | axis | own 18 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| east_05_kharkov_1943 | 南側警戒線 | recon 5,4 | axis | own 19 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| east_06_dnieper_1943 | 控制東岸渡口 | hold 2t 5,4 | soviet | own 1 / enemy 4 | XP 1, reinforce -2t | reinforce best T6->T4 |
| east_06_dnieper_1943 | 偵察西岸觀測點 | recon 12,4 | soviet | own 8 / enemy 1 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| east_09_seelow_1945 | 清除 MG 42 | destroy 19,2 | soviet | own 22 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| east_09_seelow_1945 | 偵察砲兵觀測點 | recon 21,1 | soviet | own 25 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| east_10_berlin_1945 | 清除西側 MG 42 | destroy 18,3 | soviet | own 9 / enemy 0 | XP 1, repair 2, enemy supp +1 R2 | enemy closer; damage recovery; tactical suppression reward R2 |
| east_10_berlin_1945 | 標定重砲陣地 | recon 22,2 | soviet | own 13 / enemy 0 | XP 1, enemy dig -1 R2, campaign +1p | enemy closer; breach reward R2; campaign bonus +1 |
| north_00_gazala_1942 | 偵察北側崖線 | recon 8,1 | axis | own 7 / enemy 2 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| north_00_gazala_1942 | 摧毀 6-pdr 反戰車砲 | destroy 10,2 | axis | own 8 / enemy 0 | XP 1, repair 2 | enemy closer; damage recovery |
| north_01_el_alamein_1942 | 奪取綠洲補給 | capture 8,5 | allies | own 6 / enemy 3 | XP 1, repair 2 | enemy closer; damage recovery |
| north_01_el_alamein_1942 | 偵察北側山脊 | recon 10,2 | allies | own 9 / enemy 2 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| north_02_kasserine_1943 | 守住山口補給 | hold 2t 5,4 | allies | own 0 / enemy 7 | XP 1, reinforce -2t | starts held; reinforce best T6->T4 |
| north_02_kasserine_1943 | 偵察南側山脊 | recon 10,6 | allies | own 5 / enemy 1 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| north_03_tunis_1943 | 奪取山口補給站 | capture 8,5 | allies | own 6 / enemy 2 | XP 1, repair 2 | enemy closer; damage recovery |
| north_03_tunis_1943 | 摧毀山地遠程砲 | destroy 14,8 | allies | own 11 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| north_04_bizerte_1943 | 奪取前進燃料站 | capture 9,4 | allies | own 7 / enemy 3 | XP 1, reinforce -2t | enemy closer; reinforce best T7->T5 |
| north_04_bizerte_1943 | 摧毀港口遠程砲 | destroy 14,8 | allies | own 11 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| pacific_01_guadalcanal_1942 | 奪取補給村 | capture 8,4 | allies | own 6 / enemy 4 | XP 1, supp -2 | enemy closer; sustain reward |
| pacific_01_guadalcanal_1942 | 摧毀叢林機槍 | destroy 12,6 | allies | own 9 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| pacific_02_tarawa_1943 | 奪取棧橋補給 | capture 7,6 | allies | own 4 / enemy 3 | XP 1, supp -2 | enemy closer; sustain reward |
| pacific_02_tarawa_1943 | 摧毀海堤機槍 | destroy 10,4 | allies | own 8 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| pacific_03_peleliu_1944 | 摧毀洞窟機槍 | destroy 10,4 | allies | own 8 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| pacific_03_peleliu_1944 | 偵察北側山脊 | recon 12,2 | allies | own 11 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| pacific_04_manila_1945 | 奪取醫院補給 | capture 8,5 | allies | own 6 / enemy 2 | XP 1, supp -2 | enemy closer; sustain reward |
| pacific_04_manila_1945 | 標定城北砲位 | recon 12,2 | allies | own 11 / enemy 2 | XP 1, enemy dig -1 R2, campaign +1p | enemy closer; breach reward R2; campaign bonus +1 |
| pacific_05_iwo_jima_1945 | 控制機場補給點 | hold 2t 6,4 | allies | own 3 / enemy 6 | XP 1, reinforce -2t | reinforce best T7->T5 |
| pacific_05_iwo_jima_1945 | 偵察北側洞窟 | recon 12,2 | allies | own 10 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| pacific_05_okinawa_1945 | 控制前進觀測所 | hold 2t 8,4 | allies | own 6 / enemy 2 | XP 1, reinforce -2t | enemy closer; reinforce best T6->T4 |
| pacific_05_okinawa_1945 | 摧毀首里機槍 | destroy 10,4 | allies | own 8 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| tut_01_terrain_zoc_overwatch | 道路檢查點 | capture 4,0 | allies | own 2 / enemy 2 | XP 1 | ok |
| west_08_falaise_1944 | 封鎖撤退道路 | recon 22,11 | allies | own 19 / enemy 0 | XP 1, enemy supp +1 R1 | enemy closer; tactical suppression reward R1 |
| west_08_falaise_1944 | 摧毀 StuG 掩護 | destroy 22,0 after seal_escape_road | allies | own 20 / enemy 0 | XP 1, repair 2 | enemy closer; damage recovery |
| west_08_normandy_cobra_1944 | 清除 MG 42 | destroy 1,2 | allies | own 2 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| west_08_normandy_cobra_1944 | 反砲兵偵察 | recon 22,2 | allies | own 21 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| west_08_pegasus_bridge_1944 | 穩住南岸橋頭 | hold 2t 7,5 | allies | own 4 / enemy 1 | XP 1, reinforce -2t | enemy closer; reinforce best T6->T4 |
| west_08_pegasus_bridge_1944 | 摧毀橋北機槍 | destroy 8,3 | allies | own 5 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| west_09_aachen_1944 | 清除西側 PaK 40 | destroy 6,4 | allies | own 4 / enemy 0 | XP 1, enemy dig -1 R1 | enemy closer; breach reward R1 |
| west_09_aachen_1944 | 市政廳側翼 | recon 5,11 after clear_western_at | allies | own 2 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| west_09_hurtgen_1944 | 林道 MG 42 | destroy 4,4 | allies | own 2 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| west_09_hurtgen_1944 | 控制前進林道 | hold 2t 4,5 after silence_forest_mg | allies | own 3 / enemy 1 | XP 1, supp -2 | enemy closer; sustain reward |
| west_10_remagen_1945 | 奪取橋西岸 | capture 12,0 | allies | own 10 / enemy 6 | XP 1, repair 2 | enemy closer; damage recovery |
| west_10_remagen_1945 | 偵察東岸橋頭 | recon 17,4 after secure_bridge_west_bank | allies | own 15 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |
| west_11_colmar_1945 | 壓制口袋機槍 | destroy 18,11 | allies | own 15 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2 |
| west_11_colmar_1945 | 側翼村道 | recon 19,11 after suppress_colmar_mg | allies | own 16 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2 |

## Conquest Secondary Coverage

Focused gate for conquest templates: each conq_* battle should give optional objectives a strategic enemy-strength effect instead of XP-only pressure.

| scenario | secondary objectives | strategic objectives | enemy strength pressure | check |
| --- | --- | --- | --- | --- |
| conq_atlantic_convoy | 2 | 2 | -2 | covered |
| conq_cbi_jungle | 2 | 2 | -3 | covered |
| conq_china_plains | 2 | 2 | -2 | covered |
| conq_desert_north_africa | 2 | 2 | -2 | covered |
| conq_home_islands | 2 | 2 | -3 | covered |
| conq_mediterranean_coast | 2 | 2 | -2 | covered |
| conq_middle_east_oilfields | 2 | 2 | -3 | covered |
| conq_north_sea_raid | 2 | 2 | -2 | covered |
| conq_pacific_carrier | 2 | 2 | -2 | covered |
| conq_pacific_island | 2 | 2 | -2 | covered |

## Conquest Primary Variety

Focused gate for conquest templates: attack battles should vary their formal objective instead of defaulting every region to a roster wipe.

| scenario | attack objective | objective pressure | check |
| --- | --- | --- | --- |
| conq_atlantic_convoy | control 2/3 by T13 | own min 15 enemy min 3 | varied |
| conq_cbi_jungle | hold 14,6 2t by T13 | own min 14 enemy min 10 | varied |
| conq_china_plains | control 2/3 by T13 | own min 9 enemy min 5 | varied |
| conq_desert_north_africa | control 2/3 by T13 | own min 12 enemy min 0 | varied |
| conq_home_islands | capture 15,6 by T13 | own min 14 enemy min 8 | varied |
| conq_mediterranean_coast | hold 12,11 2t by T12 | own min 8 enemy min 10 | varied |
| conq_middle_east_oilfields | control 2/3 by T13 | own min 10 enemy min 7 | varied |
| conq_north_sea_raid | capture 11,4 by T12 | own min 9 enemy min 11 | varied |
| conq_pacific_carrier | hold 14,4 2t by T12 | own min 12 enemy min 8 | varied |
| conq_pacific_island | control 2/3 by T13 | own min 9 enemy min 9 | varied |

## Terrain Identity Coverage

Focused gate for terrain/theater identity: each non-tutorial battle should expose its dominant terrain signals, objective hooks, and player-side role hooks.

| scenario | terrain theme | terrain signals | objective hooks | role hooks | check |
| --- | --- | --- | --- | --- | --- |
| 01_sedan_1940 | forest | forest:21% | capture:2, recon_hex:1; targets town:1 | armor:4, artillery:1, recon:1, scout:1, suppression:1 | covered |
| 02_kiev_1941 | river | forest:7%, river:7% | destroy_unit:1, eliminate:1, recon_hex:1 | armor:4, artillery:2, breach:1, recon:1, suppression:1 | covered |
| 03_stalingrad_1942 | town, river | town:42%, river:6% | destroy_unit:1, recon_hex:1, survive:1; targets town:2 | artillery:1, breach:1, mg:2, recon:1, suppression:1 | covered |
| 04_kursk_1943 | open | forest:7% | control_count:1, destroy_unit:1, recon_hex:1; targets town:3 | armor:6, artillery:1, breach:1, recon:1, scout:1 | tracked |
| 05_bastogne_1944 | forest | forest:18% | destroy_unit:1, hold_hex_turns:1, hold_turns:1; targets town:2 | airdrop:2, armor:1, artillery:1, engineer:1, mg:1, suppression:1 | covered |
| 06_market_garden_1944 | river | river:11%, forest:7% | capture:1, destroy_unit:1, hold_turns:1; targets town:1 | airdrop:3, artillery:1, engineer:1, mg:1, suppression:1 | covered |
| 07_bagration_1944 | open | forest:6% | capture:2, destroy_unit:1; targets town:1 | armor:3, artillery:2, mg:1, suppression:1 | tracked |
| blitz_00_poland_1939 | river | forest:8%, river:7% | capture:1, destroy_unit:1, recon_hex:1; targets town:1 | armor:3, artillery:1, recon:1, scout:2, suppression:1 | covered |
| blitz_02_dunkirk_1940 | river | river:7%, forest:7% | hold_turns:1, recon_hex:1, survive:1; targets town:1 | artillery:1, mg:1, recon:1, suppression:1 | covered |
| blitz_03_moscow_1941 | forest | forest:13% | capture:1, destroy_unit:1, recon_hex:1; targets town:1 | armor:2, artillery:2, breach:1, recon:1, suppression:1 | covered |
| conq_atlantic_convoy | sea, forest | forest:11%, sea:9% | capture:1, control_count:1, recon_hex:1; targets town:5 | armor:2, artillery:1, recon:1, scout:1, suppression:1 | covered |
| conq_cbi_jungle | jungle | jungle:88% | capture:1, hold_hex_turns:1, recon_hex:1; targets town:3 | breach:1, engineer:1, mg:1, recon:1 | covered |
| conq_china_plains | open | forest:9% | capture:1, control_count:1, hold_turns:1; targets town:3 | armor:2, artillery:1, scout:1 | tracked |
| conq_desert_north_africa | desert, mountain | desert:82%, mountain:7% | capture:1, control_count:1, recon_hex:1; targets town:5 | armor:2, artillery:1, recon:1, scout:1, suppression:1 | covered |
| conq_home_islands | mountain | mountain:12%, forest:10% | capture:2, recon_hex:1; targets town:3 | armor:2, artillery:1, breach:1, recon:1, scout:1 | covered |
| conq_mediterranean_coast | open | sea:7% | capture:1, hold_hex_turns:1, hold_turns:1; targets town:2 | armor:1, artillery:1, suppression:1 | tracked |
| conq_middle_east_oilfields | desert | desert:79% | capture:2, control_count:1; targets town:5 | armor:2, artillery:1, scout:1 | covered |
| conq_north_sea_raid | sea | sea:12%, town:7% | capture:2, recon_hex:1; targets town:3 | armor:2, artillery:1, recon:1, scout:1, suppression:1 | covered |
| conq_pacific_carrier | sea | sea:17%, town:6% | capture:1, hold_hex_turns:1, hold_turns:1; targets town:3 | armor:2, artillery:1, scout:1 | covered |
| conq_pacific_island | jungle, sea | sea:10%, jungle:8% | capture:1, control_count:1, recon_hex:1; targets town:5 | armor:1, breach:1, mg:1, recon:1, scout:1 | covered |
| east_05_kharkov_1943 | open | forest:7%, town:5% | capture:1, destroy_unit:1, recon_hex:1; targets town:3 | armor:5, artillery:1, breach:1, recon:1, scout:1, suppression:1 | tracked |
| east_06_dnieper_1943 | river, forest | forest:11%, river:9% | capture:1, hold_turns:1, recon_hex:1; targets town:1 | armor:2, artillery:1, breach:1, engineer:1, recon:1, scout:1 | covered |
| east_09_seelow_1945 | mountain | mountain:7%, forest:6% | capture:1, destroy_unit:1, recon_hex:1; targets forest:1, town:1 | armor:2, artillery:2, breach:1, recon:1, suppression:1 | covered |
| east_10_berlin_1945 | town | town:60% | capture:1, destroy_unit:1, recon_hex:1; targets town:1 | armor:1, artillery:1, breach:1, engineer:1, recon:1, suppression:1 | covered |
| north_00_gazala_1942 | desert, mountain | desert:74%, mountain:8% | capture:1, destroy_unit:1, recon_hex:1; targets desert:1, town:1 | armor:4, artillery:1, recon:1, scout:1, suppression:1 | covered |
| north_01_el_alamein_1942 | desert, mountain | desert:76%, mountain:7% | capture:1, eliminate:1, recon_hex:1; targets desert:1, town:1 | armor:4, artillery:1, recon:1, scout:1, suppression:1 | covered |
| north_02_kasserine_1943 | desert, mountain | desert:67%, mountain:10% | hold_turns:1, recon_hex:1, survive:1; targets desert:1, town:1 | armor:2, artillery:1, mg:1, recon:1, scout:1, suppression:1 | covered |
| north_03_tunis_1943 | desert, mountain | desert:71%, mountain:8% | capture:1, destroy_unit:1, eliminate:1; targets desert:1, town:1 | armor:3, artillery:1, engineer:1, scout:1, suppression:1 | covered |
| north_04_bizerte_1943 | desert, sea, mountain | desert:52%, sea:11%, mountain:7%, town:6% | capture:2, destroy_unit:1; targets desert:1, town:2 | armor:3, artillery:1, engineer:1, mg:1, scout:1, suppression:1 | covered |
| pacific_01_guadalcanal_1942 | jungle, sea | jungle:14%, sea:11% | capture:1, destroy_unit:1, eliminate:1; targets town:2 | armor:1, artillery:1, engineer:1, mg:1, scout:1, suppression:1 | covered |
| pacific_02_tarawa_1943 | jungle, sea | jungle:12%, sea:11%, town:6% | capture:2, destroy_unit:1; targets town:3 | armor:1, artillery:1, engineer:1, mg:1, scout:1, suppression:1 | covered |
| pacific_03_peleliu_1944 | jungle, sea | jungle:13%, sea:9% | capture:1, destroy_unit:1, recon_hex:1; targets town:1 | armor:1, artillery:1, breach:1, engineer:1, mg:1, recon:1, scout:1, suppression:1 | covered |
| pacific_04_manila_1945 | town, river | town:28%, river:8% | capture:1, control_count:1, recon_hex:1; targets town:6 | armor:3, artillery:2, breach:1, engineer:1, mg:1, recon:1, scout:1 | covered |
| pacific_05_iwo_jima_1945 | jungle, sea | sea:11%, jungle:9% | capture:1, hold_turns:1, recon_hex:1; targets mountain:2, town:1 | armor:2, artillery:1, breach:1, engineer:1, mg:1, recon:1, scout:1 | covered |
| pacific_05_okinawa_1945 | jungle, town | town:15%, jungle:10% | destroy_unit:1, eliminate:1, hold_turns:1; targets town:2 | armor:3, artillery:2, engineer:1, mg:1, scout:1, suppression:1 | covered |
| west_08_falaise_1944 | forest | forest:12% | capture:1, destroy_unit:1, recon_hex:1 | armor:3, artillery:1, recon:1, suppression:1 | covered |
| west_08_normandy_cobra_1944 | open | forest:10% | capture:1, destroy_unit:1, recon_hex:1 | armor:3, artillery:1, breach:1, recon:1, suppression:1 | tracked |
| west_08_pegasus_bridge_1944 | river | forest:9%, river:9% | destroy_unit:1, hold_hex_turns:1, hold_turns:1; targets town:2 | airdrop:2, engineer:1, mg:1, suppression:1 | covered |
| west_09_aachen_1944 | open | forest:9% | capture:1, destroy_unit:1, recon_hex:1 | armor:3, artillery:1, breach:2, recon:1 | tracked |
| west_09_hurtgen_1944 | forest | forest:11% | destroy_unit:1, hold_hex_turns:1, hold_turns:1 | armor:3, artillery:1, suppression:1 | covered |
| west_10_remagen_1945 | river | forest:10%, river:5% | capture:2, recon_hex:1; targets town:1 | armor:3, artillery:1, breach:1, recon:1 | covered |
| west_11_colmar_1945 | forest | forest:10% | capture:1, destroy_unit:1, recon_hex:1; targets town:2 | armor:3, artillery:1, breach:1, recon:1, suppression:1 | covered |

## Gameplay Depth Coverage

Focused gate for non-tutorial, non-conquest battles: each main battle should have optional pressure, and reports should show XP-only objectives separately from richer tactical or strategic rewards.

| scenario | secondary objectives | xp-only objectives | enriched objectives | check |
| --- | --- | --- | --- | --- |
| 01_sedan_1940 | 2 | 0 | 2 | covered |
| 02_kiev_1941 | 2 | 0 | 2 | covered |
| 03_stalingrad_1942 | 2 | 0 | 2 | covered |
| 04_kursk_1943 | 2 | 0 | 2 | covered |
| 05_bastogne_1944 | 2 | 0 | 2 | covered |
| 06_market_garden_1944 | 2 | 0 | 2 | covered |
| 07_bagration_1944 | 2 | 0 | 2 | covered |
| blitz_00_poland_1939 | 2 | 0 | 2 | covered |
| blitz_02_dunkirk_1940 | 2 | 0 | 2 | covered |
| blitz_03_moscow_1941 | 2 | 0 | 2 | covered |
| east_05_kharkov_1943 | 2 | 0 | 2 | covered |
| east_06_dnieper_1943 | 2 | 0 | 2 | covered |
| east_09_seelow_1945 | 2 | 0 | 2 | covered |
| east_10_berlin_1945 | 2 | 0 | 2 | covered |
| north_00_gazala_1942 | 2 | 0 | 2 | covered |
| north_01_el_alamein_1942 | 2 | 0 | 2 | covered |
| north_02_kasserine_1943 | 2 | 0 | 2 | covered |
| north_03_tunis_1943 | 2 | 0 | 2 | covered |
| north_04_bizerte_1943 | 2 | 0 | 2 | covered |
| pacific_01_guadalcanal_1942 | 2 | 0 | 2 | covered |
| pacific_02_tarawa_1943 | 2 | 0 | 2 | covered |
| pacific_03_peleliu_1944 | 2 | 0 | 2 | covered |
| pacific_04_manila_1945 | 2 | 0 | 2 | covered |
| pacific_05_iwo_jima_1945 | 2 | 0 | 2 | covered |
| pacific_05_okinawa_1945 | 2 | 0 | 2 | covered |
| west_08_falaise_1944 | 2 | 0 | 2 | covered |
| west_08_normandy_cobra_1944 | 2 | 0 | 2 | covered |
| west_08_pegasus_bridge_1944 | 2 | 0 | 2 | covered |
| west_09_aachen_1944 | 2 | 0 | 2 | covered |
| west_09_hurtgen_1944 | 2 | 0 | 2 | covered |
| west_10_remagen_1945 | 2 | 0 | 2 | covered |
| west_11_colmar_1945 | 2 | 0 | 2 | covered |

## Scenario Expansion Coverage

Dynamic coverage gate for formal campaign expansion: reports campaign size, victory variety, special terrain usage, and role hooks that should diversify new battles.

| campaign | scenarios | victory mix | special terrain | role hooks | check |
| --- | --- | --- | --- | --- | --- |
| blitzkrieg_early_war | 5 | capture:3, eliminate:1, survive:1 | river:3 | scout:2 | tracked |
| eastern_front | 7 | capture:5, control_count:1, survive:1 | river:2, town:3 | reinforcement:2, scout:3, engineer:2 | tracked |
| north_africa | 5 | capture:2, eliminate:2, survive:1 | desert:5, sea:1, town:1 | reinforcement:2, scout:5, engineer:2 | tracked |
| pacific_front | 6 | capture:3, control_count:1, eliminate:2 | jungle:5, sea:4, river:1, town:3 | reinforcement:2, scout:6, engineer:6 | tracked |
| western_front | 9 | capture:6, hold_hex_turns:3 | river:3 | reinforcement:3, engineer:3, airdrop:3 | tracked |
