# Balance Report


Generated from `data/units.json`, `data/terrains.json`, and `data/scenarios/*.json`. Damage mirrors `scripts/combat/combat_resolver.gd`: attack plus armor bonus, minus defender defense, terrain, and dig-in; minimum 1; scaled by attacker HP.

## Unit Catalog

| id | name | hp | atk | def | rng | move | vision | vs armor | armor | indirect |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| infantry | 步兵 | 10 | 4 | 2 | 1 | 3 | 3 | 1 | 0 |  |
| mg_team | 機槍組 | 8 | 6 | 1 | 1 | 2 | 3 | 0 | 0 |  |
| at_gun | 反戰車砲 | 6 | 7 | 1 | 1 | 1 | 2 | 5 | 0 |  |
| light_tank | 輕戰車 | 12 | 5 | 4 | 1 | 5 | 4 | 2 | 2 |  |
| medium_tank | 中戰車 | 16 | 7 | 5 | 1 | 4 | 4 | 4 | 4 |  |
| artillery | 砲兵 | 8 | 8 | 1 | 3 | 2 | 5 | 2 | 0 | yes |

## Plain Damage / Counter

Cell format is `damage/counter`.

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 2/1 | 3/1 | 3/1 | 1/1 | 1/2 | 3/0 |
| 機槍組 | 4/1 | 5/1 | 5/1 | 2/1 | 1/3 | 5/0 |
| 反戰車砲 | 5/1 | 6/1 | 6/0 | 8/1 | 7/1 | 6/0 |
| 輕戰車 | 3/1 | 4/1 | 4/1 | 3/1 | 2/3 | 4/0 |
| 中戰車 | 5/1 | 6/1 | 6/0 | 7/1 | 6/2 | 6/0 |
| 砲兵 | 6/0 | 7/0 | 7/0 | 6/0 | 5/0 | 7/0 |

## Damage Matrix: forest

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 2 | 3 | 3 | 1 | 1 | 3 |
| 反戰車砲 | 3 | 4 | 4 | 6 | 5 | 4 |
| 輕戰車 | 1 | 2 | 2 | 1 | 1 | 2 |
| 中戰車 | 3 | 4 | 4 | 5 | 4 | 4 |
| 砲兵 | 4 | 5 | 5 | 4 | 3 | 5 |

## Damage Matrix: town

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 2 | 2 | 1 | 1 | 2 |
| 反戰車砲 | 2 | 3 | 3 | 5 | 4 | 3 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 2 | 3 | 3 | 4 | 3 | 3 |
| 砲兵 | 3 | 4 | 4 | 3 | 2 | 4 |

## Damage Matrix: town_dig2

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 1 | 1 | 1 | 1 | 1 |
| 反戰車砲 | 1 | 1 | 1 | 3 | 2 | 1 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 1 | 1 | 1 | 2 | 1 | 1 |
| 砲兵 | 1 | 2 | 2 | 1 | 1 | 2 |

## Damage Matrix: town_dig3

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 1 | 1 | 1 | 1 | 1 |
| 反戰車砲 | 1 | 1 | 1 | 2 | 1 | 1 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 1 | 1 | 1 | 1 | 1 | 1 |
| 砲兵 | 1 | 1 | 1 | 1 | 1 | 1 |

## Hits To Kill

| attacker | defender | plain dmg | plain hits | town+dig3 dmg | town+dig3 hits |
| --- | --- | --- | --- | --- | --- |
| 步兵 | 步兵 | 2 | 5 | 1 | 10 |
| 步兵 | 機槍組 | 3 | 3 | 1 | 8 |
| 步兵 | 反戰車砲 | 3 | 2 | 1 | 6 |
| 步兵 | 輕戰車 | 1 | 12 | 1 | 12 |
| 步兵 | 中戰車 | 1 | 16 | 1 | 16 |
| 步兵 | 砲兵 | 3 | 3 | 1 | 8 |
| 機槍組 | 步兵 | 4 | 3 | 1 | 10 |
| 機槍組 | 機槍組 | 5 | 2 | 1 | 8 |
| 機槍組 | 反戰車砲 | 5 | 2 | 1 | 6 |
| 機槍組 | 輕戰車 | 2 | 6 | 1 | 12 |
| 機槍組 | 中戰車 | 1 | 16 | 1 | 16 |
| 機槍組 | 砲兵 | 5 | 2 | 1 | 8 |
| 反戰車砲 | 步兵 | 5 | 2 | 1 | 10 |
| 反戰車砲 | 機槍組 | 6 | 2 | 1 | 8 |
| 反戰車砲 | 反戰車砲 | 6 | 1 | 1 | 6 |
| 反戰車砲 | 輕戰車 | 8 | 2 | 2 | 6 |
| 反戰車砲 | 中戰車 | 7 | 3 | 1 | 16 |
| 反戰車砲 | 砲兵 | 6 | 2 | 1 | 8 |
| 輕戰車 | 步兵 | 3 | 4 | 1 | 10 |
| 輕戰車 | 機槍組 | 4 | 2 | 1 | 8 |
| 輕戰車 | 反戰車砲 | 4 | 2 | 1 | 6 |
| 輕戰車 | 輕戰車 | 3 | 4 | 1 | 12 |
| 輕戰車 | 中戰車 | 2 | 8 | 1 | 16 |
| 輕戰車 | 砲兵 | 4 | 2 | 1 | 8 |
| 中戰車 | 步兵 | 5 | 2 | 1 | 10 |
| 中戰車 | 機槍組 | 6 | 2 | 1 | 8 |
| 中戰車 | 反戰車砲 | 6 | 1 | 1 | 6 |
| 中戰車 | 輕戰車 | 7 | 2 | 1 | 12 |
| 中戰車 | 中戰車 | 6 | 3 | 1 | 16 |
| 中戰車 | 砲兵 | 6 | 2 | 1 | 8 |
| 砲兵 | 步兵 | 6 | 2 | 1 | 10 |
| 砲兵 | 機槍組 | 7 | 2 | 1 | 8 |
| 砲兵 | 反戰車砲 | 7 | 1 | 1 | 6 |
| 砲兵 | 輕戰車 | 6 | 2 | 1 | 12 |
| 砲兵 | 中戰車 | 5 | 4 | 1 | 16 |
| 砲兵 | 砲兵 | 7 | 2 | 1 | 8 |

## Role Diagnostics

| unit | avg vs soft | avg vs armor | armor delta | diagnostic |
| --- | --- | --- | --- | --- |
| 步兵 | 2.75 | 1.00 | -1.75 |  |
| 機槍組 | 4.75 | 1.50 | -3.25 |  |
| 反戰車砲 | 5.75 | 7.50 | +1.75 | AT has high soft-target output |
| 輕戰車 | 3.75 | 2.50 | -1.25 | Mobility/vision must justify lower damage |
| 中戰車 | 5.75 | 6.50 | +0.75 | Baseline main battle unit; many named tanks share this stat |
| 砲兵 | 6.75 | 5.50 | -1.25 | Artillery remains strong into armor |

## Scenario Exposure

| scenario | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 00_sandbox | 2 | 1 | 1 | 1 | 2 | 1 |
| 01_sedan_1940 | 5 | 2 | 1 | 1 | 3 | 1 |
| 02_kiev_1941 | 5 | 1 | 2 | 1 | 4 | 2 |
| 03_stalingrad_1942 | 6 | 3 | 2 | 1 | 1 | 1 |
| 04_kursk_1943 | 3 | 0 | 4 | 1 | 7 | 2 |
| 05_bastogne_1944 | 6 | 1 | 1 | 0 | 5 | 2 |
| TOTAL | 27 | 8 | 11 | 5 | 22 | 9 |

| scenario | tiles | dominant terrain |
| --- | --- | --- |
| 00_sandbox | 80 | plain 69%, forest 11%, road 8% |
| 01_sedan_1940 | 140 | plain 59%, forest 25%, river 8% |
| 02_kiev_1941 | 140 | plain 76%, road 9%, river 7% |
| 03_stalingrad_1942 | 140 | plain 46%, town 44%, river 5% |
| 04_kursk_1943 | 140 | plain 87%, forest 6%, road 6% |
| 05_bastogne_1944 | 140 | plain 63%, forest 18%, road 16% |

## Rule Risks

| risk | why it matters | next action |
| --- | --- | --- |
| Attack visibility | Resolved: direct attacks require visibility + LOS; indirect attacks require visibility and ignore LOS blockers. | Keep future attack helpers routed through CombatRules. |
| indirect semantics | Resolved: indirect units cannot counter while defending, but close indirect attacks can still be countered. | Preserve this distinction in UI text and combat tests. |
| ZoC path reconstruction | Resolved: movement range and path reconstruction share the same terrain + ZoC step cost. | Keep new pathfinding callsites passing occupied + mover_faction. |
| Town + dig-in | Town defense 3 plus dig-in 3 pushes most attacks to the 1-damage floor. | Consider max dig-in 2, siege traits, or partial artillery/AT entrenchment bypass. |

## Recommended Next Pass

1. Run this report before and after every candidate stat patch, then compare role diagnostics plus hits-to-kill.
2. Start with narrow candidate changes: lower AT soft damage, lower artillery armor effectiveness, and give light tanks a stronger scouting identity.
3. Validate those changes in Stalingrad, Bastogne, Kursk, Kiev, then Sedan, because those scenarios stress the highest-risk mechanics in order.

