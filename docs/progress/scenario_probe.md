# Scenario Probe

Static tactical probe for pressure tuning. Coverage is approximate and ignores LOS/fog; use it to spot scenarios that need manual playtesting.

| scenario | suppression sources | artillery coverage | spotter coverage | objective pressure | reinforcement delta |
| --- | --- | --- | --- | --- | --- |
| 00_sandbox | allies mg_team:1; axis artillery:1 | allies 24/384 (6%); axis 54/384 (14%) | axis 43/384 (11%), spots 0 | n/a | none |
| 01_sedan_1940 | allies mg_team:2; axis artillery:1 | axis 33/384 (9%) | axis 64/384 (17%), spots 1 | axis target 20,14 own min 2 enemy min 0 | none |
| 02_kiev_1941 | axis artillery:2; soviet mg_team:1 | axis 57/384 (15%) | soviet 68/384 (18%), spots 0 | n/a | none |
| 03_stalingrad_1942 | axis artillery:1, mg_team:1; soviet mg_team:2 | axis 33/384 (9%); soviet 21/384 (5%) | axis 65/384 (17%), spots 0 | n/a | none |
| 04_kursk_1943 | axis artillery:1; soviet artillery:1 | axis 34/384 (9%); soviet 42/384 (11%) | axis 43/384 (11%), spots 2 | axis target 5,2 own min 17 enemy min 0 | none |
| 05_bastogne_1944 | allies artillery:1, mg_team:1; axis artillery:1 | allies 61/384 (16%); axis 42/384 (11%) | none | axis target 6,4 own min 3 enemy min 0 | allies +129.5; T7 3 units |
| 06_market_garden_1944 | allies artillery:1, mg_team:1; axis artillery:1, mg_team:1 | allies 55/384 (14%); axis 50/384 (13%) | none | allies target 5,11 own min 7 enemy min 9 | allies +129.5; T7 3 units |
| 07_bagration_1944 | axis artillery:1, mg_team:1; soviet artillery:1, mg_team:1 | axis 34/384 (9%); soviet 61/384 (16%) | none | soviet target 2,4 own min 20 enemy min 1 | soviet +77.6; T6 2 units |
| blitz_00_poland_1939 | allies artillery:1, mg_team:1; axis artillery:1 | allies 27/384 (7%); axis 37/384 (10%) | axis 51/384 (13%), spots 0 | axis target 1,1 own min 23 enemy min 0 | none |
| blitz_02_dunkirk_1940 | allies artillery:1, mg_team:1; axis artillery:1 | allies 38/384 (10%); axis 23/384 (6%) | axis 43/384 (11%), spots 0 | axis target 5,0 own min 18 enemy min 0 | none |
| blitz_03_moscow_1941 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 43/384 (11%); soviet 40/384 (10%) | none | soviet target 6,2 own min 16 enemy min 0 | none |
| conq_atlantic_convoy | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_cbi_jungle | allies mg_team:1; axis artillery:1, mg_team:1 | axis 34/384 (9%) | none | n/a | none |
| conq_china_plains | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_desert_north_africa | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_home_islands | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_mediterranean_coast | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 44/384 (11%) | none | n/a | none |
| conq_middle_east_oilfields | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_north_sea_raid | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_pacific_carrier | allies artillery:1; axis artillery:1, mg_team:1 | allies 37/384 (10%); axis 34/384 (9%) | allies 60/384 (16%), spots 0 | n/a | none |
| conq_pacific_island | allies mg_team:1; axis artillery:1, mg_team:1 | axis 50/384 (13%) | allies 57/384 (15%), spots 0 | n/a | none |
| east_05_kharkov_1943 | axis artillery:1; soviet artillery:1, mg_team:1 | axis 33/384 (9%); soviet 46/384 (12%) | axis 56/384 (15%), spots 0 | axis target 4,3 own min 19 enemy min 1 | none |
| east_09_seelow_1945 | axis artillery:1, mg_team:1; soviet artillery:1 | axis 35/384 (9%); soviet 24/384 (6%) | none | soviet target 18,3 own min 21 enemy min 0 | none |
| east_10_berlin_1945 | axis artillery:1, mg_team:2; soviet artillery:1 | axis 37/384 (10%); soviet 23/384 (6%) | none | soviet target 19,4 own min 20 enemy min 0 | none |
| tut_00_basic_turn | none | none | none | allies target 6,2 own min 5 enemy min 0 | none |
| tut_01_terrain_zoc_overwatch | allies mg_team:1 | none | axis 38/54 (70%), spots 3 | allies target 6,0 own min 4 enemy min 2 | none |
| tut_02_los_spotting_artillery | allies artillery:1 | allies 27/70 (39%) | allies 45/70 (64%), spots 1 | n/a | none |
| tut_03_suppression_digin_engineer | allies artillery:1; axis mg_team:1 | allies 34/70 (49%) | none | allies target 7,3 own min 5 enemy min 0 | none |
| tut_04_armor_at_veteran_general | none | none | none | n/a | none |
| tut_05_airdrop_reinforcement_rocket | axis mg_team:1 | allies 31/70 (44%) | none | n/a | allies +77.6; T3 2 units |
| west_08_falaise_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 21,4 own min 19 enemy min 0 | none |
| west_08_normandy_cobra_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 2,2 own min 2 enemy min 0 | none |
| west_09_aachen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 5,11 own min 2 enemy min 0 | none |
| west_09_hurtgen_1944 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 5,4 own min 3 enemy min 0 | none |
| west_10_remagen_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 17,4 own min 15 enemy min 0 | none |
| west_11_colmar_1945 | allies artillery:1; axis artillery:1, mg_team:1 | allies 23/384 (6%); axis 37/384 (10%) | none | allies target 19,11 own min 16 enemy min 0 | none |
