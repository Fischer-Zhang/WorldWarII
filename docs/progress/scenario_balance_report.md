# Scenario Balance Report

Static diagnostics from scenario JSON. This report does not simulate turns; it highlights force composition, terrain pressure, objective distance, and obvious role-coverage risks.

## Overview

| scenario | title | terrain pressure | objective distance | risk notes |
| --- | --- | --- | --- | --- |
| 00_sandbox | 沙盒測試地圖 | plain 69%, forest 11%, road 8%; def>=2 19%; move>=3 10% | n/a | no major static risks |
| 01_sedan_1940 | 色當突破 1940 | plain 59%, forest 23%, river 8%; def>=2 26%; move>=3 10% | axis->10,8 min 2 avg 4.7 | high forest density: LOS and breakthrough tempo risk; river crossings may dominate tempo; force power ratio above 1.35: check victory-clock compensation |
| 02_kiev_1941 | 基輔包圍戰 1941 | plain 76%, road 9%, river 7%; def>=2 8%; move>=3 7% | n/a | river crossings may dominate tempo; axis artillery-heavy: watch standoff dominance |
| 03_stalingrad_1942 | 史達林格勒巷戰 1942 | plain 46%, town 44%, river 5%; def>=2 44%; move>=3 5% | n/a | high town density: dig-in pacing risk |
| 04_kursk_1943 | 庫斯克裝甲決戰 1943 | plain 84%, forest 6%, road 6%; def>=2 10%; move>=3 3% | axis->5,2 min 7 avg 9.4 | axis lacks AT against 3 enemy armor units |
| 05_bastogne_1944 | 突出部戰役:Bastogne 1944 | plain 63%, forest 18%, road 16%; def>=2 21%; move>=3 0% | axis->6,4 min 3 avg 5.2 | no major static risks |
| 06_market_garden_1944 | 市場花園作戰:奈梅亨橋 1944 | plain 67%, road 12%, river 9%; def>=2 11%; move>=3 9% | allies->5,5 min 1 avg 1.9 | river crossings may dominate tempo |
| 07_bagration_1944 | 巴格拉基昂行動:明斯克突破 1944 | plain 81%, forest 7%, road 6%; def>=2 9%; move>=3 5% | soviet->2,4 min 10 avg 11.2 | force power ratio above 1.35: check victory-clock compensation; soviet artillery-heavy: watch standoff dominance |

## 00_sandbox

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | Axis | player | 4 | 153.1 | armor:1, artillery:1, infantry:1, scout_armor:1 |
| allies | Allies | ai | 4 | 126.3 | anti_armor:1, armor:1, infantry:1, support:1 |

## 01_sedan_1940

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲軍 | player | 7 | 282.6 | armor:3, artillery:1, infantry:2, scout_armor:1 |
| allies | 法軍第 55 師 | ai | 6 | 150.4 | anti_armor:1, infantry:3, support:2 |

## 02_kiev_1941

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍裝甲群 | player | 7 | 279.9 | armor:3, artillery:2, infantry:2 |
| soviet | 蘇軍殘部 | ai | 8 | 240.9 | anti_armor:2, armor:1, infantry:3, scout_armor:1, support:1 |

## 03_stalingrad_1942

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 62 軍團 | player | 7 | 174.5 | anti_armor:2, infantry:3, support:2 |
| axis | 德軍第六軍團 | ai | 7 | 229.1 | armor:1, artillery:1, infantry:3, scout_armor:1, support:1 |

## 04_kursk_1943

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| axis | 德軍第四裝甲軍 | player | 8 | 360.7 | armor:5, artillery:1, infantry:1, scout_armor:1 |
| soviet | 蘇軍中央方面軍 | ai | 10 | 339.9 | anti_armor:4, armor:3, artillery:1, infantry:2 |

## 05_bastogne_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 101 空降師 | player | 10 | 315.2 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:2, paratrooper:2, support:1 |
| axis | 德軍第 5 裝甲軍 | ai | 6 | 243.5 | armor:3, artillery:1, infantry:2 |

## 06_market_garden_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| allies | 美 82 空降師 | player | 10 | 316.5 | anti_armor:1, armor:2, artillery:1, engineer:1, infantry:1, paratrooper:3, support:1 |
| axis | 德軍第 9 SS 裝甲 | ai | 7 | 240.3 | anti_armor:1, armor:2, artillery:1, infantry:2, support:1 |

## 07_bagration_1944

| faction | name | controller | units | power | roles |
| --- | --- | --- | --- | --- | --- |
| soviet | 蘇軍第 1 白俄方面軍 | player | 11 | 406.2 | anti_armor:1, armor:4, artillery:2, infantry:3, support:1 |
| axis | 德軍中央集團軍 | ai | 8 | 264.4 | anti_armor:2, armor:2, artillery:1, infantry:2, support:1 |
