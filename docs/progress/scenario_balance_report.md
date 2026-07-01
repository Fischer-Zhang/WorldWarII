# Scenario Balance Report

Static diagnostics from scenario JSON. This report does not simulate turns; it highlights force composition, terrain pressure, objective distance, and obvious role-coverage risks.

## Overview

| scenario | title | terrain pressure | urban breach tools | objective distance | secondary objectives | risk notes |
| --- | --- | --- | --- | --- | --- | --- |
| 00_sandbox | 沙盒測試地圖 | plain 71%, forest 11%, road 7%; def>=2 19%; move>=3 8% | axis: eng 0, art 1, rocket 1, mg 0; allies: eng 0, art 0, rocket 1, mg 1 | n/a | none | axis artillery-heavy: watch standoff dominance |
| 01_sedan_1940 | 色當突破 1940 | plain 63%, forest 21%, road 6%; def>=2 26%; move>=3 7% | axis: eng 0, art 1, rocket 0, mg 0; allies: eng 0, art 0, rocket 0, mg 2 | axis->20,14 min 2 avg 7.3 | 橋頭補給 [capture 15,5] (XP 1, repair 2); 中路渡口 [recon 13,5] (XP 1, enemy supp +1 R2) | high forest density: LOS and breakthrough tempo risk; force power ratio above 1.35: check victory-clock compensation |
| 02_kiev_1941 | 基輔包圍戰 1941 | plain 78%, forest 7%, road 7%; def>=2 8%; move>=3 7% | axis: eng 0, art 2, rocket 0, mg 0; soviet: eng 0, art 0, rocket 0, mg 1 | n/a | 南翼掃蕩 [recon 3,13] (XP 1, enemy dig -1 R2); 壓制馬克沁火點 [destroy Maxim@4,4 after southern_sweep] (XP 1, enemy supp +1 R2) | axis artillery-heavy: watch standoff dominance |
| 03_stalingrad_1942 | 史達林格勒巷戰 1942 | plain 47%, town 42%, river 6%; def>=2 42%; move>=3 6% | soviet: eng 0, art 0, rocket 1, mg 2; axis: eng 1, art 1, rocket 0, mg 1 | n/a | 標定突擊路線 [recon 13,10] (XP 1, enemy dig -1 R2); 突擊工兵 [destroy 突擊工兵@13,10 after stalingrad_spot_engineers] (XP 1, enemy supp +1 R2) | high town density: dig-in pacing risk |
| 04_kursk_1943 | 庫斯克裝甲決戰 1943 | plain 83%, forest 7%, road 6%; def>=2 11%; move>=3 4% | axis: eng 0, art 1, rocket 0, mg 0; soviet: eng 0, art 1, rocket 0, mg 0 | axis control 2/3 min 6 avg 9.3 | 壓制 SU-152 [destroy SU-152@4,0] (XP 1, repair 2); 北側高地偵察 [recon 18,2] (XP 1, enemy dig -1 R2) | no major static risks |
| 05_bastogne_1944 | 突出部戰役:Bastogne 1944 | plain 63%, forest 18%, road 16%; def>=2 21%; move>=3 0% | allies: eng 1, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 0 | axis->6,4 min 3 avg 12.6; allies hold 6,4 12t min 0 avg 4.4 | 鎮心補給 [hold 2t 6,4] (XP 1, supp -2, reinforce -2t); 南側遠程砲 [destroy 150 mm@22,11 after bastogne_supply_hold] (XP 1, enemy supp +1 R2) | no major static risks |
| 06_market_garden_1944 | 市場花園作戰:奈梅亨橋 1944 | plain 67%, river 11%, road 10%; def>=2 12%; move>=3 11% | allies: eng 1, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | allies->5,11 min 7 avg 7.6 | 南岸橋頭 [hold 2t 5,12] (XP 1, reinforce -2t); 德軍遠程砲 [destroy 150 mm sFH@18,2 after nijmegen_south_bridgehead] (XP 1, enemy supp +1 R2) | river crossings may dominate tempo |
| 07_bagration_1944 | 巴格拉基昂行動:明斯克突破 1944 | plain 79%, road 9%, forest 6%; def>=2 8%; move>=3 6% | soviet: eng 0, art 1, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | soviet->2,4 min 20 avg 22.8 | 奪取路口 [capture 3,4] (XP 1, reinforce -2t); 壓制德軍砲位 [destroy 105 mm@1,2] (XP 1, enemy supp +1 R2) | force power ratio above 1.35: check victory-clock compensation; soviet artillery-heavy: watch standoff dominance |
| blitz_00_poland_1939 | 波蘭戰役:布楚拉反擊 1939 | plain 71%, road 12%, forest 8%; def>=2 10%; move>=3 7% | axis: eng 0, art 1, rocket 0, mg 0; allies: eng 0, art 1, rocket 0, mg 1 | axis->1,1 min 23 avg 26.3 | 摧毀 37mm 反戰車砲 [destroy 37 mm AT@3,3] (XP 1, repair 2); 偵察砲兵陣地 [recon 0,2] (XP 1, enemy supp +1 R2) | no major static risks |
| blitz_02_dunkirk_1940 | 敦克爾克外圍防線 1940 | plain 71%, road 11%, river 7%; def>=2 11%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 0 | axis->5,0 min 18 avg 21.0 | 堅守撤退出口 [hold 2t 5,0] (XP 1, supp -2); 偵察裝甲縱隊 [recon 22,2] (XP 1, enemy supp +1 R2) | river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| blitz_03_moscow_1941 | 莫斯科門前 1941 | plain 76%, forest 13%, road 10%; def>=2 13%; move>=3 2% | soviet: eng 0, art 1, rocket 1, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | soviet->6,2 min 16 avg 19.6 | 壓制 MG 34 [destroy MG 34@17,2] (XP 1, enemy supp +1 R2); 前進觀測點 [recon 18,2] (XP 1, enemy dig -1 R2) | soviet artillery-heavy: watch standoff dominance |
| conq_atlantic_convoy | 大西洋護航戰 | plain 75%, forest 11%, sea 9%; def>=2 14%; move>=3 9% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 港口補給線 [capture 16,9] (XP 1, conquest enemy -1); 偵察海岸信號站 [recon 17,2 after atlantic_port_sabotage] (enemy supp +1 R2, conquest enemy -1) | no major static risks |
| conq_cbi_jungle | 緬印叢林戰場 | jungle 88%, river 4%, plain 4%; def>=2 91%; move>=3 4% | allies: eng 1, art 0, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 叢林補給村 [capture 9,5] (XP 1, conquest enemy -2); 偵察叢林渡口 [recon 12,12 after cbi_jungle_supply] (enemy dig -1 R2, conquest enemy -1) | no major static risks |
| conq_china_plains | 中原會戰 | plain 74%, road 10%, forest 9%; def>=2 13%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 河橋補給線 [capture 14,6] (XP 1, conquest enemy -1); 固守前進鐵路站 [hold 2t 10,10 after china_bridge_cache] (supp -2, conquest enemy -1) | no major static risks |
| conq_desert_north_africa | 北非沙漠戰場 | desert 82%, road 10%, mountain 7%; def>=2 9%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 綠洲補給站 [capture 13,11] (XP 1, conquest enemy -1); 偵察沙漠高地 [recon 20,6 after desert_oasis_depot] (enemy supp +1 R2, conquest enemy -1) | no major static risks |
| conq_home_islands | 本土防衛戰 | plain 69%, mountain 12%, forest 10%; def>=2 24%; move>=3 15% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 山脊彈藥庫 [capture 15,6] (XP 1, conquest enemy -2); 標定山口火點 [recon 17,12 after home_islands_fort_depot] (enemy dig -1 R2, conquest enemy -1) | no major static risks |
| conq_mediterranean_coast | 地中海海岸 | plain 74%, road 14%, sea 7%; def>=2 6%; move>=3 11% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 海岸補給港 [capture 12,11] (XP 1, conquest enemy -1); 控制丘陵公路 [hold 2t 17,5 after med_coast_supply_port] (enemy supp +1 R2, conquest enemy -1) | no major static risks |
| conq_middle_east_oilfields | 中東油田爭奪 | desert 79%, road 10%, river 4%; def>=2 7%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 油田泵站 [capture 12,4] (XP 1, conquest enemy -2); 控制輸油管線 [capture 14,9 after oilfield_pump_station] (repair 2, conquest enemy -1) | no major static risks |
| conq_north_sea_raid | 北海沿岸突擊 | plain 77%, sea 12%, town 7%; def>=2 11%; move>=3 12% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 港灣油料庫 [capture 11,4] (XP 1, conquest enemy -1); 偵察海岸雷達站 [recon 17,11 after north_sea_harbor_cache] (enemy supp +1 R2, conquest enemy -1) | no major static risks |
| conq_pacific_carrier | 太平洋海空決戰 | plain 73%, sea 17%, town 6%; def>=2 10%; move>=3 17% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 環礁通信站 [capture 11,3] (XP 1, conquest enemy -1); 守住潟湖錨地 [hold 2t 14,4 after carrier_atoll_radio] (repair 2, conquest enemy -1) | no major static risks |
| conq_pacific_island | 太平洋島嶼登陸 | plain 80%, sea 10%, jungle 8%; def>=2 10%; move>=3 10% | allies: eng 0, art 0, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 中央港鎮倉庫 [capture 11,6] (XP 1, conquest enemy -1); 偵察島內洞口 [recon 14,8 after island_port_cache] (enemy dig -1 R2, conquest enemy -1) | no major static risks |
| east_05_kharkov_1943 | 第三次哈爾科夫 1943 | plain 72%, road 13%, forest 7%; def>=2 12%; move>=3 3% | axis: eng 0, art 1, rocket 0, mg 0; soviet: eng 0, art 1, rocket 0, mg 1 | axis->4,3 min 19 avg 21.7 | 突破機槍據點 [destroy Maxim@5,3] (XP 1, enemy supp +1 R2); 南側警戒線 [recon 5,4] (XP 1, enemy dig -1 R2) | force power ratio above 1.35: check victory-clock compensation |
| east_06_dnieper_1943 | 第聶伯河橋頭堡 1943 | plain 65%, road 13%, forest 11%; def>=2 13%; move>=3 9% | soviet: eng 1, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | soviet->9,5 min 6 avg 7.5 | 控制東岸渡口 [hold 2t 5,4] (XP 1, reinforce -2t); 偵察西岸觀測點 [recon 12,4] (XP 1, enemy dig -1 R2) | river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| east_09_seelow_1945 | 澤洛高地 1945 | plain 75%, road 10%, mountain 7%; def>=2 14%; move>=3 8% | soviet: eng 0, art 1, rocket 1, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | soviet->18,3 min 21 avg 22.1 | 清除 MG 42 [destroy MG 42@19,2] (XP 1, enemy supp +1 R2); 偵察砲兵觀測點 [recon 21,1] (XP 1, enemy dig -1 R2) | force power ratio above 1.35: check victory-clock compensation; soviet artillery-heavy: watch standoff dominance |
| east_10_berlin_1945 | 柏林終局 1945 | town 60%, plain 22%, road 18%; def>=2 60%; move>=3 0% | soviet: eng 1, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 2 | soviet->19,4 min 9 avg 17.7 | 清除西側 MG 42 [destroy MG 42 a@18,3] (XP 1, repair 2, enemy supp +1 R2); 標定重砲陣地 [recon 22,2] (XP 1, enemy dig -1 R2, campaign +1p) | high town density: dig-in pacing risk |
| north_00_gazala_1942 | 加查拉側翼戰 1942 | desert 74%, road 16%, mountain 8%; def>=2 11%; move>=3 8% | axis: eng 0, art 1, rocket 0, mg 0; allies: eng 0, art 1, rocket 0, mg 1 | axis->11,4 min 8 avg 10.3 | 偵察北側崖線 [recon 8,1] (XP 1, enemy supp +1 R2); 摧毀 6-pdr 反戰車砲 [destroy 6-pdr 反戰車砲@10,2] (XP 1, repair 2) | no major static risks |
| north_01_el_alamein_1942 | 阿拉曼防線 1942 | desert 76%, road 14%, mountain 7%; def>=2 9%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 0 | n/a | 奪取綠洲補給 [capture 8,5] (XP 1, repair 2); 偵察北側山脊 [recon 10,2] (XP 1, enemy supp +1 R2) | no major static risks |
| north_02_kasserine_1943 | 凱塞林山口 1943 | desert 67%, road 21%, mountain 10%; def>=2 12%; move>=3 10% | allies: eng 0, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 0 | axis->5,4 min 7 avg 9.0 | 守住山口補給 [hold 2t 5,4] (XP 1, reinforce -2t); 偵察南側山脊 [recon 10,6] (XP 1, enemy supp +1 R2) | no major static risks |
| north_03_tunis_1943 | 突尼斯山口 1943 | desert 71%, road 18%, mountain 8%; def>=2 11%; move>=3 8% | allies: eng 1, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 奪取山口補給站 [capture 8,5] (XP 1, repair 2); 摧毀山地遠程砲 [destroy 山地遠程砲@14,8] (XP 1, enemy supp +1 R2) | no major static risks |
| north_04_bizerte_1943 | 比塞大港口 1943 | desert 52%, road 25%, sea 11%; def>=2 12%; move>=3 18% | allies: eng 1, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | allies->13,4 min 11 avg 12.4 | 奪取前進燃料站 [capture 9,4] (XP 1, reinforce -2t); 摧毀港口遠程砲 [destroy 港口遠程砲@14,8] (XP 1, enemy supp +1 R2) | no major static risks |
| pacific_01_guadalcanal_1942 | 瓜達康納爾叢林戰 1942 | plain 67%, jungle 14%, sea 11%; def>=2 18%; move>=3 11% | allies: eng 1, art 0, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | n/a | 奪取補給村 [capture 8,4] (XP 1, supp -2); 摧毀叢林機槍 [destroy 叢林機槍火點@12,6] (XP 1, enemy supp +1 R2) | no major static risks |
| pacific_02_tarawa_1943 | 塔拉瓦灘頭 1943 | plain 64%, jungle 12%, sea 11%; def>=2 18%; move>=3 11% | allies: eng 1, art 0, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 2 | allies->11,4 min 9 avg 10.2 | 奪取棧橋補給 [capture 7,6] (XP 1, supp -2); 摧毀海堤機槍 [destroy 海堤機槍火點@10,4] (XP 1, enemy supp +1 R2) | no major static risks |
| pacific_03_peleliu_1944 | 貝里琉機場 1944 | plain 61%, jungle 13%, road 9%; def>=2 21%; move>=3 12% | allies: eng 1, art 0, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 2 | allies->11,4 min 9 avg 10.0 | 摧毀洞窟機槍 [destroy 洞窟機槍火點@10,4] (XP 1, enemy supp +1 R2); 偵察北側山脊 [recon 12,2] (XP 1, enemy dig -1 R2) | no major static risks |
| pacific_04_manila_1945 | 馬尼拉城區戰 1945 | plain 42%, town 28%, road 21%; def>=2 29%; move>=3 8% | allies: eng 1, art 1, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 2 | allies control 3/4 min 7 avg 8.6 | 奪取醫院補給 [capture 8,5] (XP 1, supp -2); 標定城北砲位 [recon 12,2] (XP 1, enemy dig -1 R2, campaign +1p) | high town density: dig-in pacing risk; river crossings may dominate tempo; allies artillery-heavy: watch standoff dominance |
| pacific_05_iwo_jima_1945 | 硫磺島折鉢山 1945 | plain 60%, road 13%, sea 11%; def>=2 16%; move>=3 14% | allies: eng 1, art 0, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 2 | allies->13,4 min 10 avg 11.7 | 控制機場補給點 [hold 2t 6,4] (XP 1, reinforce -2t); 偵察北側洞窟 [recon 12,2] (XP 1, enemy dig -1 R2) | force power ratio above 1.35: check victory-clock compensation |
| pacific_05_okinawa_1945 | 沖繩首里防線 1945 | plain 53%, road 18%, town 15%; def>=2 29%; move>=3 4% | allies: eng 1, art 1, rocket 2, mg 1; axis: eng 0, art 1, rocket 0, mg 2 | n/a | 控制前進觀測所 [hold 2t 8,4] (XP 1, reinforce -2t); 摧毀首里機槍 [destroy 首里機槍火點@10,4] (XP 1, enemy supp +1 R2) | force power ratio above 1.35: check victory-clock compensation; allies artillery-heavy: watch standoff dominance |
| tut_00_basic_turn | 教學 00: 移動、攻擊與佔領 | plain 88%, road 10%, town 2%; def>=2 2%; move>=3 0% | allies: eng 0, art 0, rocket 0, mg 0; axis: eng 0, art 0, rocket 0, mg 0 | allies->6,2 min 5 avg 5.0 | none | force power ratio above 1.35: check victory-clock compensation |
| tut_01_terrain_zoc_overwatch | 教學 01: 地形、管制區與警戒 | plain 81%, road 9%, forest 7%; def>=2 9%; move>=3 0% | allies: eng 0, art 0, rocket 0, mg 1; axis: eng 0, art 0, rocket 0, mg 0 | allies->6,0 min 4 avg 4.7 | 道路檢查點 [capture 4,0] (XP 1) | no major static risks |
| tut_02_los_spotting_artillery | 教學 02: 視線、觀測與間接火力 | plain 77%, forest 14%, road 9%; def>=2 14%; move>=3 0% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 0, rocket 0, mg 0 | n/a | none | force power ratio above 1.35: check victory-clock compensation |
| tut_03_suppression_digin_engineer | 教學 03: 壓制、整隊、構工與工兵破障 | plain 81%, river 14%, town 3%; def>=2 4%; move>=3 14% | allies: eng 1, art 1, rocket 0, mg 0; axis: eng 0, art 0, rocket 0, mg 1 | allies->7,3 min 3 avg 4.2 | none | river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| tut_04_armor_at_veteran_general | 教學 04: 裝甲、反戰車、老兵與將領技能 | plain 85%, road 11%, forest 4%; def>=2 4%; move>=3 0% | allies: eng 0, art 0, rocket 0, mg 0; axis: eng 0, art 0, rocket 0, mg 0 | n/a | none | no major static risks |
| tut_05_airdrop_reinforcement_rocket | 教學 05: 空降、援軍與火箭濺射 | plain 90%, road 4%, forest 3%; def>=2 6%; move>=3 0% | allies: eng 0, art 0, rocket 1, mg 0; axis: eng 0, art 0, rocket 0, mg 1 | n/a | none | force power ratio above 1.35: check victory-clock compensation |
| west_08_falaise_1944 | 法萊茲包圍圈 1944 | plain 72%, forest 12%, road 10%; def>=2 17%; move>=3 2% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->21,4 min 19 avg 22.4 | 封鎖撤退道路 [recon 22,11] (XP 1, enemy supp +1 R1); 摧毀 StuG 掩護 [destroy StuG III@22,0 after seal_escape_road] (XP 1, repair 2) | no major static risks |
| west_08_normandy_cobra_1944 | 諾曼第突破:眼鏡蛇行動 1944 | plain 73%, road 10%, forest 10%; def>=2 13%; move>=3 4% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->2,2 min 2 avg 8.6 | 清除 MG 42 [destroy MG 42@1,2] (XP 1, enemy supp +1 R2); 反砲兵偵察 [recon 22,2] (XP 1, enemy dig -1 R2) | no major static risks |
| west_08_pegasus_bridge_1944 | 飛馬橋突擊 1944 | plain 64%, road 14%, forest 9%; def>=2 12%; move>=3 9% | allies: eng 1, art 0, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | allies hold 7,4 3t min 4 avg 4.6 | 穩住南岸橋頭 [hold 2t 7,5] (XP 1, reinforce -2t); 摧毀橋北機槍 [destroy 橋北 MG 42@8,3] (XP 1, enemy supp +1 R2) | river crossings may dominate tempo |
| west_09_aachen_1944 | 亞琛巷戰 1944 | plain 74%, road 11%, forest 9%; def>=2 12%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->5,11 min 2 avg 5.7 | 清除西側 PaK 40 [destroy PaK 40@6,4] (XP 1, enemy dig -1 R1); 市政廳側翼 [recon 5,11 after clear_western_at] (XP 1, enemy dig -1 R2) | no major static risks |
| west_09_hurtgen_1944 | 赫特根森林 1944 | plain 70%, road 12%, forest 11%; def>=2 16%; move>=3 2% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies hold 5,4 2t min 3 avg 7.7 | 林道 MG 42 [destroy MG 42@4,4] (XP 1, enemy supp +1 R2); 控制前進林道 [hold 2t 4,5 after silence_forest_mg] (XP 1, supp -2) | no major static risks |
| west_10_remagen_1945 | 雷馬根大橋 1945 | plain 72%, road 11%, forest 10%; def>=2 13%; move>=3 4% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->17,4 min 15 avg 18.4 | 奪取橋西岸 [capture 12,0] (XP 1, repair 2); 偵察東岸橋頭 [recon 17,4 after secure_bridge_west_bank] (XP 1, enemy dig -1 R2) | no major static risks |
| west_11_colmar_1945 | 科爾馬口袋 1945 | plain 71%, road 12%, forest 10%; def>=2 14%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->19,11 min 16 avg 19.4 | 壓制口袋機槍 [destroy MG 42@18,11] (XP 1, enemy supp +1 R2); 側翼村道 [recon 19,11 after suppress_colmar_mg] (XP 1, enemy dig -1 R2) | no major static risks |

## 00_sandbox

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | Axis | player | 7 | 297.4 | anti_armor:1, armor:2, artillery:2, infantry:1, scout_armor:1 |
| allies | Allies | ai | 8 | 298.6 | anti_armor:2, armor:2, artillery:1, infantry:2, support:1 |

## 01_sedan_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲軍 | player | 7 | 283.1 | armor:3, artillery:1, infantry:2, scout_armor:1 |
| allies | 法軍第 55 師 | ai | 6 | 153.2 | anti_armor:1, infantry:3, support:2 |

## 02_kiev_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲群 | player | 8 | 326.1 | anti_armor:1, armor:3, artillery:2, infantry:2 |
| soviet | 蘇軍殘部 | ai | 8 | 246.5 | anti_armor:2, armor:1, infantry:3, scout_armor:1, support:1 |

## 03_stalingrad_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 62 軍團 | player | 8 | 212.2 | anti_armor:2, artillery:1, infantry:3, support:2 |
| axis | 德軍第六軍團 | ai | 8 | 270.8 | anti_armor:1, armor:1, artillery:1, engineer:1, infantry:2, scout_armor:1, support:1 |

## 04_kursk_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍第四裝甲軍 | player | 9 | 421.0 | anti_armor:1, armor:5, artillery:1, infantry:1, scout_armor:1 |
| soviet | 蘇軍中央方面軍 | ai | 11 | 396.8 | anti_armor:5, armor:3, artillery:1, infantry:2 |

## 05_bastogne_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 101 空降師 | player | 11 | 364.5 | anti_armor:2, armor:2, artillery:1, engineer:1, infantry:4, support:1 |
| axis | 德軍第 5 裝甲軍 | ai | 7 | 310.5 | armor:4, artillery:1, infantry:2 |

## 06_market_garden_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 82 空降師 | player | 10 | 320.6 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:4, support:1 |
| axis | 德軍第 9 SS 裝甲 | ai | 8 | 288.8 | anti_armor:2, armor:2, artillery:1, infantry:2, support:1 |

## 07_bagration_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 12 | 471.7 | anti_armor:1, armor:5, artillery:2, infantry:3, support:1 |
| axis | 德軍中央集團軍 | ai | 9 | 309.0 | anti_armor:4, armor:1, artillery:1, infantry:2, support:1 |

## blitz_00_poland_1939

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲先遣隊 | player | 6 | 218.4 | armor:1, artillery:1, infantry:2, scout_armor:2 |
| allies | 波蘭波茲南軍團 | ai | 6 | 165.5 | anti_armor:1, artillery:1, infantry:3, support:1 |

## blitz_02_dunkirk_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 英法後衛部隊 | player | 6 | 165.5 | anti_armor:1, artillery:1, infantry:3, support:1 |
| axis | 德軍裝甲軍 | ai | 6 | 231.2 | armor:2, artillery:1, infantry:2, scout_armor:1 |

## blitz_03_moscow_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍西方面軍 | player | 7 | 251.1 | anti_armor:1, armor:2, artillery:2, infantry:2 |
| axis | 德軍中央集團軍群 | ai | 7 | 243.6 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## conq_atlantic_convoy

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_cbi_jungle

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 150.3 | anti_armor:1, engineer:1, infantry:3, support:1 |
| axis | 守備軍 | ai | 6 | 165.5 | anti_armor:1, artillery:1, infantry:3, support:1 |

## conq_china_plains

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_desert_north_africa

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_home_islands

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_mediterranean_coast

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 192.8 | anti_armor:1, armor:1, artillery:1, infantry:3 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_middle_east_oilfields

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_north_sea_raid

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_pacific_carrier

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.2 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_pacific_island

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 167.7 | anti_armor:1, infantry:3, scout_armor:1, support:1 |
| axis | 守備軍 | ai | 6 | 165.5 | anti_armor:1, artillery:1, infantry:3, support:1 |

## east_05_kharkov_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍南方集團軍群 | player | 9 | 394.8 | anti_armor:1, armor:4, artillery:1, infantry:2, scout_armor:1 |
| soviet | 蘇軍沃羅涅日方面軍 | ai | 7 | 243.6 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## east_06_dnieper_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 3 近衛軍 | player | 8 | 278.6 | armor:2, artillery:1, engineer:1, infantry:3, scout_armor:1 |
| axis | 德軍南方集團軍 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## east_09_seelow_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 7 | 290.7 | armor:3, artillery:2, infantry:2 |
| axis | 德軍第 9 集團軍 | ai | 7 | 211.9 | anti_armor:3, artillery:1, infantry:2, support:1 |

## east_10_berlin_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍突擊群 | player | 6 | 228.4 | armor:2, artillery:1, engineer:1, infantry:2 |
| axis | 柏林守備隊 | ai | 9 | 287.2 | anti_armor:2, armor:1, artillery:1, infantry:3, support:2 |

## north_00_gazala_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德意非洲軍機動群 | player | 7 | 277.6 | anti_armor:2, armor:2, artillery:1, infantry:1, scout_armor:1 |
| allies | 英軍沙漠縱隊 | ai | 7 | 243.6 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## north_01_el_alamein_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 英軍第八軍團 | player | 7 | 277.6 | anti_armor:2, armor:2, artillery:1, infantry:1, scout_armor:1 |
| axis | 德意非洲軍 | ai | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |

## north_02_kasserine_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍山口守備隊 | player | 10 | 353.6 | anti_armor:2, armor:2, artillery:1, infantry:3, scout_armor:1, support:1 |
| axis | 德意裝甲突擊群 | ai | 8 | 303.3 | anti_armor:2, armor:2, artillery:1, infantry:2, scout_armor:1 |

## north_03_tunis_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 盟軍突尼斯遠征隊 | player | 8 | 273.1 | anti_armor:2, armor:1, artillery:1, engineer:1, infantry:2, scout_armor:1 |
| axis | 軸心山口守軍 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## north_04_bizerte_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 盟軍海岸追擊群 | player | 10 | 348.4 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:3, scout_armor:1, support:1 |
| axis | 軸心港口後衛 | ai | 8 | 262.6 | anti_armor:2, armor:1, artillery:1, infantry:3, support:1 |

## pacific_01_guadalcanal_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美國陸戰隊 | player | 6 | 168.9 | artillery:1, engineer:1, infantry:2, scout_armor:1, support:1 |
| axis | 日軍守備隊 | ai | 6 | 165.5 | anti_armor:1, artillery:1, infantry:3, support:1 |

## pacific_02_tarawa_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美國陸戰隊 | player | 6 | 168.9 | artillery:1, engineer:1, infantry:2, scout_armor:1, support:1 |
| axis | 日軍環礁守備隊 | ai | 7 | 190.1 | anti_armor:1, artillery:1, infantry:3, support:2 |

## pacific_03_peleliu_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美國陸戰隊 | player | 6 | 168.9 | artillery:1, engineer:1, infantry:2, scout_armor:1, support:1 |
| axis | 日軍貝里琉守備隊 | ai | 7 | 190.1 | anti_armor:1, artillery:1, infantry:3, support:2 |

## pacific_04_manila_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第六軍 | player | 9 | 302.9 | anti_armor:1, armor:1, artillery:2, engineer:1, infantry:2, scout_armor:1, support:1 |
| axis | 日軍馬尼拉守備隊 | ai | 8 | 242.0 | anti_armor:1, armor:1, artillery:1, infantry:3, support:2 |

## pacific_05_iwo_jima_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美國陸戰隊 | player | 9 | 298.4 | armor:2, artillery:1, engineer:1, infantry:3, scout_armor:1, support:1 |
| axis | 日軍硫磺島守備隊 | ai | 7 | 190.1 | anti_armor:1, artillery:1, infantry:3, support:2 |

## pacific_05_okinawa_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍沖繩突擊群 | player | 12 | 412.6 | anti_armor:1, armor:2, artillery:3, engineer:1, infantry:3, scout_armor:1, support:1 |
| axis | 日軍首里守備隊 | ai | 8 | 242.0 | anti_armor:1, armor:1, artillery:1, infantry:3, support:2 |

## tut_00_basic_turn

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 教學部隊 | player | 2 | 77.6 | armor:1, infantry:1 |
| axis | 目標守軍 | ai | 2 | 51.4 | infantry:2 |

## tut_01_terrain_zoc_overwatch

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 教學防線 | player | 3 | 102.2 | armor:1, infantry:1, support:1 |
| axis | 突入部隊 | ai | 3 | 90.5 | infantry:2, scout_armor:1 |

## tut_02_los_spotting_artillery

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 觀測分隊 | player | 3 | 102.9 | anti_armor:1, artillery:1, scout_armor:1 |
| axis | 隱蔽火點 | ai | 2 | 52.6 | anti_armor:1, infantry:1 |

## tut_03_suppression_digin_engineer

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 攻堅教學隊 | player | 4 | 136.2 | armor:1, artillery:1, engineer:1, infantry:1 |
| axis | 構工守軍 | ai | 2 | 50.3 | infantry:1, support:1 |

## tut_04_armor_at_veteran_general

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 裝甲教學隊 | player | 3 | 124.0 | anti_armor:2, armor:1 |
| axis | 裝甲目標 | ai | 3 | 144.1 | armor:2, infantry:1 |

## tut_05_airdrop_reinforcement_rocket

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 空降教學隊 | player | 5 | 162.4 | armor:1, artillery:1, infantry:3 |
| axis | 密集守軍 | ai | 4 | 102.9 | anti_armor:1, infantry:2, support:1 |

## west_08_falaise_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 盟軍封鎖部隊 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍撤退縱隊 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_08_normandy_cobra_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 3 裝甲師 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍諾曼第防線 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_08_pegasus_bridge_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 英軍第 6 空降師 | player | 7 | 204.8 | anti_armor:1, armor:1, engineer:1, infantry:3, support:1 |
| axis | 德軍橋頭守備隊 | ai | 6 | 191.7 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## west_09_aachen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 1 步兵師 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 亞琛守備隊 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_09_hurtgen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍步兵師 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍森林防線 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_10_remagen_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 9 裝甲師 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍萊茵防線 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_11_colmar_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 法美聯軍 | player | 7 | 264.2 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍第 19 軍 | ai | 7 | 236.9 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |
