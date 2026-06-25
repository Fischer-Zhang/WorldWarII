# Scenario Balance Report

Static diagnostics from scenario JSON. This report does not simulate turns; it highlights force composition, terrain pressure, objective distance, and obvious role-coverage risks.

## Overview

| scenario | title | terrain pressure | objective distance | risk notes |
| --- | --- | --- | --- | --- |
| 00_sandbox | 沙盒測試地圖 | plain 69%, forest 11%, road 8%; def>=2 19%; move>=3 10% | n/a | no major static risks |
| 01_sedan_1940 | 色當突破 1940 | plain 59%, forest 23%, river 8%; def>=2 26%; move>=3 10% | axis->10,8 min 2 avg 4.7 | high forest density: LOS and breakthrough tempo risk; river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| 02_kiev_1941 | 基輔包圍戰 1941 | plain 76%, road 9%, river 7%; def>=2 8%; move>=3 7% | n/a | river crossings may dominate tempo; axis artillery-heavy: watch standoff dominance |
| 03_stalingrad_1942 | 史達林格勒巷戰 1942 | plain 46%, town 44%, river 5%; def>=2 44%; move>=3 5% | n/a | high town density: dig-in pacing risk |
| 04_kursk_1943 | 庫斯克裝甲決戰 1943 | plain 84%, forest 6%, road 6%; def>=2 10%; move>=3 3% | axis->5,2 min 7 avg 9.2 | axis lacks AT against 3 enemy armor units |
| 05_bastogne_1944 | 突出部戰役:Bastogne 1944 | plain 63%, forest 18%, road 16%; def>=2 21%; move>=3 0% | axis->6,4 min 3 avg 5.0 | no major static risks |
| 06_market_garden_1944 | 市場花園作戰:奈梅亨橋 1944 | plain 67%, road 12%, river 9%; def>=2 11%; move>=3 9% | allies->5,5 min 1 avg 1.9 | river crossings may dominate tempo |
| 07_bagration_1944 | 巴格拉基昂行動:明斯克突破 1944 | plain 81%, forest 7%, road 6%; def>=2 9%; move>=3 5% | soviet->2,4 min 10 avg 11.3 | force power ratio above 1.35: check victory-clock compensation |
| blitz_00_poland_1939 | 波蘭戰役:布楚拉反擊 1939 | plain 73%, road 11%, forest 8%; def>=2 10%; move>=3 6% | axis->1,1 min 13 avg 13.8 | no major static risks |
| blitz_02_dunkirk_1940 | 敦克爾克外圍防線 1940 | plain 74%, road 11%, river 7%; def>=2 8%; move>=3 7% | axis->5,0 min 8 avg 9.5 | river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| blitz_03_moscow_1941 | 莫斯科門前 1941 | plain 69%, forest 15%, road 13%; def>=2 16%; move>=3 2% | soviet->6,2 min 6 avg 7.4 | no major static risks |
| conq_atlantic_convoy | 大西洋護航戰 | plain 58%, sea 31%, forest 7%; def>=2 9%; move>=3 31% | n/a | no major static risks |
| conq_cbi_jungle | 緬印叢林戰場 | jungle 89%, river 5%, plain 3%; def>=2 91%; move>=3 5% | n/a | no major static risks |
| conq_china_plains | 中原會戰 | plain 72%, forest 10%, road 9%; def>=2 14%; move>=3 5% | n/a | no major static risks |
| conq_desert_north_africa | 北非沙漠戰場 | desert 82%, road 11%, mountain 5%; def>=2 7%; move>=3 5% | n/a | no major static risks |
| conq_home_islands | 本土防衛戰 | plain 63%, mountain 13%, sea 10%; def>=2 25%; move>=3 23% | n/a | no major static risks |
| conq_mediterranean_coast | 地中海海岸 | plain 62%, sea 22%, road 11%; def>=2 5%; move>=3 26% | n/a | no major static risks |
| conq_middle_east_oilfields | 中東油田爭奪 | desert 79%, road 9%, river 5%; def>=2 7%; move>=3 9% | n/a | no major static risks |
| conq_north_sea_raid | 北海沿岸突擊 | plain 53%, sea 39%, town 4%; def>=2 8%; move>=3 39% | n/a | no major static risks |
| conq_pacific_carrier | 太平洋海空決戰 | sea 56%, plain 39%, town 3%; def>=2 4%; move>=3 56% | n/a | no major static risks |
| conq_pacific_island | 太平洋島嶼登陸 | plain 60%, sea 34%, jungle 5%; def>=2 6%; move>=3 34% | n/a | no major static risks |
| east_05_kharkov_1943 | 第三次哈爾科夫 1943 | plain 73%, road 11%, forest 7%; def>=2 13%; move>=3 3% | axis->4,3 min 8 avg 9.3 | force power ratio above 1.35: check victory-clock compensation |
| east_09_seelow_1945 | 澤洛高地 1945 | plain 73%, road 11%, mountain 7%; def>=2 14%; move>=3 9% | soviet->8,3 min 8 avg 9.1 | force power ratio above 1.35: check victory-clock compensation |
| east_10_berlin_1945 | 柏林終局 1945 | town 59%, plain 22%, road 19%; def>=2 59%; move>=3 0% | soviet->9,4 min 7 avg 8.8 | high town density: dig-in pacing risk |
| west_08_falaise_1944 | 法萊茲包圍圈 1944 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->11,4 min 8 avg 10.3 | no major static risks |
| west_08_normandy_cobra_1944 | 諾曼第突破:眼鏡蛇行動 1944 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->2,2 min 2 avg 4.3 | no major static risks |
| west_09_aachen_1944 | 亞琛巷戰 1944 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->5,5 min 2 avg 4.6 | no major static risks |
| west_09_hurtgen_1944 | 赫特根森林 1944 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->5,4 min 3 avg 4.4 | no major static risks |
| west_10_remagen_1945 | 雷馬根大橋 1945 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->7,4 min 4 avg 6.3 | no major static risks |
| west_11_colmar_1945 | 科爾馬口袋 1945 | plain 72%, road 11%, forest 10%; def>=2 14%; move>=3 3% | allies->9,5 min 6 avg 8.6 | no major static risks |

## 00_sandbox

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | Axis | player | 7 | 296.7 | armor:1, artillery:1, heavy_tank:1, infantry:1, rocket_artillery:1, scout_armor:1, tank_destroyer:1 |
| allies | Allies | ai | 8 | 295.6 | anti_armor:1, armor:1, heavy_tank:1, infantry:2, rocket_artillery:1, support:1, tank_destroyer:1 |

## 01_sedan_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲軍 | player | 7 | 284.6 | armor:3, artillery:1, infantry:2, scout_armor:1 |
| allies | 法軍第 55 師 | ai | 6 | 152.4 | anti_armor:1, infantry:3, support:2 |

## 02_kiev_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲群 | player | 8 | 325.9 | armor:3, artillery:2, infantry:2, tank_destroyer:1 |
| soviet | 蘇軍殘部 | ai | 8 | 244.9 | anti_armor:2, armor:1, infantry:3, scout_armor:1, support:1 |

## 03_stalingrad_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 62 軍團 | player | 8 | 211.6 | anti_armor:2, infantry:3, rocket_artillery:1, support:2 |
| axis | 德軍第六軍團 | ai | 8 | 273.1 | armor:1, artillery:1, infantry:3, scout_armor:1, support:1, tank_destroyer:1 |

## 04_kursk_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍第四裝甲軍 | player | 9 | 419.3 | armor:4, artillery:1, heavy_tank:1, infantry:1, scout_armor:1, tank_destroyer:1 |
| soviet | 蘇軍中央方面軍 | ai | 11 | 391.9 | anti_armor:4, armor:3, artillery:1, infantry:2, tank_destroyer:1 |

## 05_bastogne_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 101 空降師 | player | 11 | 361.2 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:2, paratrooper:2, support:1, tank_destroyer:1 |
| axis | 德軍第 5 裝甲軍 | ai | 7 | 312.0 | armor:3, artillery:1, heavy_tank:1, infantry:2 |

## 06_market_garden_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 82 空降師 | player | 10 | 320.5 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:1, paratrooper:3, support:1 |
| axis | 德軍第 9 SS 裝甲 | ai | 8 | 286.3 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## 07_bagration_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 12 | 473.4 | anti_armor:1, armor:4, artillery:1, heavy_tank:1, infantry:3, rocket_artillery:1, support:1 |
| axis | 德軍中央集團軍 | ai | 9 | 302.5 | anti_armor:2, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:2 |

## blitz_00_poland_1939

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲先遣隊 | player | 6 | 219.9 | armor:1, artillery:1, infantry:2, scout_armor:2 |
| allies | 波蘭波茲南軍團 | ai | 6 | 166.2 | anti_armor:1, artillery:1, infantry:3, support:1 |

## blitz_02_dunkirk_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 英法後衛部隊 | player | 6 | 166.2 | anti_armor:1, artillery:1, infantry:3, support:1 |
| axis | 德軍裝甲軍 | ai | 6 | 232.7 | armor:2, artillery:1, infantry:2, scout_armor:1 |

## blitz_03_moscow_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍西方面軍 | player | 7 | 252.8 | anti_armor:1, armor:2, artillery:1, infantry:2, rocket_artillery:1 |
| axis | 德軍中央集團軍群 | ai | 7 | 244.3 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## conq_atlantic_convoy

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_cbi_jungle

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 148.7 | anti_armor:1, engineer:1, infantry:3, support:1 |
| axis | 守備軍 | ai | 6 | 166.2 | anti_armor:1, artillery:1, infantry:3, support:1 |

## conq_china_plains

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_desert_north_africa

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_home_islands

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_mediterranean_coast

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 193.5 | anti_armor:1, armor:1, artillery:1, infantry:3 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_middle_east_oilfields

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_north_sea_raid

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_pacific_carrier

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 206.9 | anti_armor:1, armor:1, artillery:1, infantry:2, scout_armor:1 |
| axis | 守備軍 | ai | 6 | 192.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1 |

## conq_pacific_island

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 進攻軍 | player | 6 | 166.9 | anti_armor:1, infantry:3, scout_armor:1, support:1 |
| axis | 守備軍 | ai | 6 | 166.2 | anti_armor:1, artillery:1, infantry:3, support:1 |

## east_05_kharkov_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍南方集團軍群 | player | 9 | 393.1 | armor:3, artillery:1, heavy_tank:1, infantry:2, scout_armor:1, tank_destroyer:1 |
| soviet | 蘇軍沃羅涅日方面軍 | ai | 7 | 244.3 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## east_09_seelow_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 7 | 293.2 | armor:2, artillery:1, heavy_tank:1, infantry:2, rocket_artillery:1 |
| axis | 德軍第 9 集團軍 | ai | 7 | 208.6 | anti_armor:2, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## east_10_berlin_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍突擊群 | player | 6 | 229.1 | armor:1, artillery:1, engineer:1, heavy_tank:1, infantry:2 |
| axis | 柏林守備隊 | ai | 9 | 284.7 | anti_armor:1, armor:1, artillery:1, infantry:3, support:2, tank_destroyer:1 |

## west_08_falaise_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 盟軍封鎖部隊 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 德軍撤退縱隊 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## west_08_normandy_cobra_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 3 裝甲師 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 德軍諾曼第防線 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## west_09_aachen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 1 步兵師 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 亞琛守備隊 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## west_09_hurtgen_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍步兵師 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 德軍森林防線 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## west_10_remagen_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美軍第 9 裝甲師 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 德軍萊茵防線 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |

## west_11_colmar_1945

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 法美聯軍 | player | 7 | 261.7 | anti_armor:1, armor:2, artillery:1, infantry:2, tank_destroyer:1 |
| axis | 德軍第 19 軍 | ai | 7 | 234.4 | anti_armor:1, armor:1, artillery:1, infantry:2, support:1, tank_destroyer:1 |
