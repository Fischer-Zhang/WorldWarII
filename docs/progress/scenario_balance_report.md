# Scenario Balance Report

Static diagnostics from scenario JSON. This report does not simulate turns; it highlights force composition, terrain pressure, objective distance, and obvious role-coverage risks.

## Overview

| scenario | title | terrain pressure | urban breach tools | objective distance | risk notes |
| --- | --- | --- | --- | --- | --- |
| 00_sandbox | 沙盒測試地圖 | plain 71%, forest 11%, road 7%; def>=2 19%; move>=3 8% | axis: eng 0, art 1, rocket 1, mg 0; allies: eng 0, art 0, rocket 1, mg 1 | n/a | axis artillery-heavy: watch standoff dominance |
| 01_sedan_1940 | 色當突破 1940 | plain 63%, forest 21%, road 6%; def>=2 26%; move>=3 7% | axis: eng 0, art 1, rocket 0, mg 0; allies: eng 0, art 0, rocket 0, mg 2 | axis->20,14 min 2 avg 7.3 | high forest density: LOS and breakthrough tempo risk; force power ratio above 1.35: check victory-clock compensation |
| 02_kiev_1941 | 基輔包圍戰 1941 | plain 78%, forest 7%, road 7%; def>=2 8%; move>=3 7% | axis: eng 0, art 2, rocket 0, mg 0; soviet: eng 0, art 0, rocket 0, mg 1 | n/a | axis artillery-heavy: watch standoff dominance |
| 03_stalingrad_1942 | 史達林格勒巷戰 1942 | plain 47%, town 42%, river 6%; def>=2 42%; move>=3 6% | soviet: eng 0, art 0, rocket 1, mg 2; axis: eng 0, art 1, rocket 0, mg 1 | n/a | high town density: dig-in pacing risk; axis has no engineers for dense urban breach |
| 04_kursk_1943 | 庫斯克裝甲決戰 1943 | plain 83%, forest 7%, road 6%; def>=2 11%; move>=3 4% | axis: eng 0, art 1, rocket 0, mg 0; soviet: eng 0, art 1, rocket 0, mg 0 | axis->5,2 min 17 avg 20.9 | no major static risks |
| 05_bastogne_1944 | 突出部戰役:Bastogne 1944 | plain 63%, forest 18%, road 16%; def>=2 21%; move>=3 0% | allies: eng 1, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 0 | axis->6,4 min 3 avg 12.6 | no major static risks |
| 06_market_garden_1944 | 市場花園作戰:奈梅亨橋 1944 | plain 67%, river 11%, road 10%; def>=2 12%; move>=3 11% | allies: eng 1, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | allies->5,11 min 7 avg 7.6 | river crossings may dominate tempo |
| 07_bagration_1944 | 巴格拉基昂行動:明斯克突破 1944 | plain 79%, road 9%, forest 6%; def>=2 8%; move>=3 6% | soviet: eng 0, art 1, rocket 1, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | soviet->2,4 min 20 avg 22.8 | force power ratio above 1.35: check victory-clock compensation; soviet artillery-heavy: watch standoff dominance |
| blitz_00_poland_1939 | 波蘭戰役:布楚拉反擊 1939 | plain 71%, road 12%, forest 8%; def>=2 10%; move>=3 7% | axis: eng 0, art 1, rocket 0, mg 0; allies: eng 0, art 1, rocket 0, mg 1 | axis->1,1 min 23 avg 26.3 | no major static risks |
| blitz_02_dunkirk_1940 | 敦克爾克外圍防線 1940 | plain 71%, road 11%, river 7%; def>=2 11%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 0 | axis->5,0 min 18 avg 21.0 | river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| blitz_03_moscow_1941 | 莫斯科門前 1941 | plain 76%, forest 13%, road 10%; def>=2 13%; move>=3 2% | soviet: eng 0, art 1, rocket 1, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | soviet->6,2 min 16 avg 19.6 | soviet artillery-heavy: watch standoff dominance |
| conq_atlantic_convoy | 大西洋護航戰 | plain 75%, forest 11%, sea 9%; def>=2 14%; move>=3 9% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_cbi_jungle | 緬印叢林戰場 | jungle 88%, river 4%, plain 4%; def>=2 91%; move>=3 4% | allies: eng 1, art 0, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_china_plains | 中原會戰 | plain 74%, road 10%, forest 9%; def>=2 13%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_desert_north_africa | 北非沙漠戰場 | desert 82%, road 10%, mountain 7%; def>=2 9%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_home_islands | 本土防衛戰 | plain 69%, mountain 12%, forest 10%; def>=2 24%; move>=3 15% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_mediterranean_coast | 地中海海岸 | plain 74%, road 14%, sea 7%; def>=2 6%; move>=3 11% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_middle_east_oilfields | 中東油田爭奪 | desert 79%, road 10%, river 4%; def>=2 7%; move>=3 7% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_north_sea_raid | 北海沿岸突擊 | plain 77%, sea 12%, town 7%; def>=2 11%; move>=3 12% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_pacific_carrier | 太平洋海空決戰 | plain 73%, sea 17%, town 6%; def>=2 10%; move>=3 17% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| conq_pacific_island | 太平洋島嶼登陸 | plain 80%, sea 10%, jungle 8%; def>=2 10%; move>=3 10% | allies: eng 0, art 0, rocket 0, mg 1; axis: eng 0, art 1, rocket 0, mg 1 | n/a | no major static risks |
| east_05_kharkov_1943 | 第三次哈爾科夫 1943 | plain 72%, road 13%, forest 7%; def>=2 12%; move>=3 3% | axis: eng 0, art 1, rocket 0, mg 0; soviet: eng 0, art 1, rocket 0, mg 1 | axis->4,3 min 19 avg 21.7 | force power ratio above 1.35: check victory-clock compensation |
| east_09_seelow_1945 | 澤洛高地 1945 | plain 75%, road 10%, mountain 7%; def>=2 14%; move>=3 8% | soviet: eng 0, art 1, rocket 1, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | soviet->18,3 min 21 avg 22.1 | force power ratio above 1.35: check victory-clock compensation; soviet artillery-heavy: watch standoff dominance |
| east_10_berlin_1945 | 柏林終局 1945 | town 60%, plain 22%, road 18%; def>=2 60%; move>=3 0% | soviet: eng 1, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 2 | soviet->19,4 min 20 avg 21.8 | high town density: dig-in pacing risk |
| west_08_falaise_1944 | 法萊茲包圍圈 1944 | plain 72%, forest 12%, road 10%; def>=2 17%; move>=3 2% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->21,4 min 19 avg 22.4 | no major static risks |
| west_08_normandy_cobra_1944 | 諾曼第突破:眼鏡蛇行動 1944 | plain 73%, road 10%, forest 10%; def>=2 13%; move>=3 4% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->2,2 min 2 avg 8.6 | no major static risks |
| west_09_aachen_1944 | 亞琛巷戰 1944 | plain 74%, road 11%, forest 9%; def>=2 12%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->5,11 min 2 avg 5.7 | no major static risks |
| west_09_hurtgen_1944 | 赫特根森林 1944 | plain 70%, road 12%, forest 11%; def>=2 16%; move>=3 2% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->5,4 min 3 avg 7.7 | no major static risks |
| west_10_remagen_1945 | 雷馬根大橋 1945 | plain 72%, road 11%, forest 10%; def>=2 13%; move>=3 4% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->17,4 min 15 avg 18.4 | no major static risks |
| west_11_colmar_1945 | 科爾馬口袋 1945 | plain 71%, road 12%, forest 10%; def>=2 14%; move>=3 3% | allies: eng 0, art 1, rocket 0, mg 0; axis: eng 0, art 1, rocket 0, mg 1 | allies->19,11 min 16 avg 19.4 | no major static risks |

## 00_sandbox

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | Axis | player | 7 | 294.2 | anti_armor:1, armor:2, artillery:2, infantry:1, scout_armor:1 |
| allies | Allies | ai | 8 | 295.4 | anti_armor:2, armor:2, artillery:1, infantry:2, support:1 |

## 01_sedan_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲軍 | player | 7 | 283.1 | armor:3, artillery:1, infantry:2, scout_armor:1 |
| allies | 法軍第 55 師 | ai | 6 | 153.2 | anti_armor:1, infantry:3, support:2 |

## 02_kiev_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲群 | player | 8 | 322.9 | anti_armor:1, armor:3, artillery:2, infantry:2 |
| soviet | 蘇軍殘部 | ai | 8 | 246.5 | anti_armor:2, armor:1, infantry:3, scout_armor:1, support:1 |

## 03_stalingrad_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 62 軍團 | player | 8 | 212.2 | anti_armor:2, artillery:1, infantry:3, support:2 |
| axis | 德軍第六軍團 | ai | 8 | 271.6 | anti_armor:1, armor:1, artillery:1, infantry:3, scout_armor:1, support:1 |

## 04_kursk_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍第四裝甲軍 | player | 9 | 417.8 | anti_armor:1, armor:5, artillery:1, infantry:1, scout_armor:1 |
| soviet | 蘇軍中央方面軍 | ai | 11 | 393.6 | anti_armor:5, armor:3, artillery:1, infantry:2 |

## 05_bastogne_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 101 空降師 | player | 11 | 361.3 | anti_armor:2, armor:2, artillery:1, engineer:1, infantry:4, support:1 |
| axis | 德軍第 5 裝甲軍 | ai | 7 | 310.5 | armor:4, artillery:1, infantry:2 |

## 06_market_garden_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 82 空降師 | player | 10 | 320.6 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:4, support:1 |
| axis | 德軍第 9 SS 裝甲 | ai | 8 | 285.6 | anti_armor:2, armor:2, artillery:1, infantry:2, support:1 |

## 07_bagration_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 12 | 471.7 | anti_armor:1, armor:5, artillery:2, infantry:3, support:1 |
| axis | 德軍中央集團軍 | ai | 9 | 302.6 | anti_armor:4, armor:1, artillery:1, infantry:2, support:1 |

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
| axis | 德軍南方集團軍群 | player | 9 | 391.6 | anti_armor:1, armor:4, artillery:1, infantry:2, scout_armor:1 |
| soviet | 蘇軍沃羅涅日方面軍 | ai | 7 | 243.6 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## east_09_seelow_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 7 | 290.7 | armor:3, artillery:2, infantry:2 |
| axis | 德軍第 9 集團軍 | ai | 7 | 208.7 | anti_armor:3, artillery:1, infantry:2, support:1 |

## east_10_berlin_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍突擊群 | player | 6 | 228.4 | armor:2, artillery:1, engineer:1, infantry:2 |
| axis | 柏林守備隊 | ai | 9 | 284.0 | anti_armor:2, armor:1, artillery:1, infantry:3, support:2 |

## west_08_falaise_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 盟軍封鎖部隊 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍撤退縱隊 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_08_normandy_cobra_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 3 裝甲師 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍諾曼第防線 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_09_aachen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 1 步兵師 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 亞琛守備隊 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_09_hurtgen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍步兵師 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍森林防線 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_10_remagen_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 9 裝甲師 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍萊茵防線 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |

## west_11_colmar_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 法美聯軍 | player | 7 | 261.0 | anti_armor:2, armor:2, artillery:1, infantry:2 |
| axis | 德軍第 19 軍 | ai | 7 | 233.7 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1 |
