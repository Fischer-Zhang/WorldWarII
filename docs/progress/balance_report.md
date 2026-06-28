# Balance Report


Generated from `data/units.json`, `data/terrains.json`, and `data/scenarios/*.json`. Damage mirrors `scripts/combat/combat_resolver.gd`: attack plus armor bonus, minus defender defense, terrain, and dig-in; minimum 1; scaled by attacker HP.

## Unit Catalog

| id | name | hp | atk | def | rng | move | vision | vs armor | standoff | armor | ow% | indirect |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| infantry | 步兵 | 10 | 4 | 2 | 1 | 3 | 3 | 1 |  | 0 | 50 |  |
| mg_team | 機槍組 | 8 | 6 | 1 | 1 | 2 | 3 | 0 |  | 0 | 100 |  |
| at_gun | 反戰車砲 | 6 | 5 | 1 | 2 | 2 | 2 | 6 |  | 0 | 50 |  |
| light_tank | 輕戰車 | 12 | 5 | 4 | 1 | 5 | 5 | 2 |  | 2 | 50 |  |
| medium_tank | 中戰車 | 16 | 7 | 5 | 1 | 4 | 4 | 4 |  | 4 | 50 |  |
| artillery | 砲兵 | 8 | 7 | 1 | 4 | 2 | 2 | 1 |  | 0 | 50 | yes |
| paratrooper | 傘兵 | 8 | 5 | 2 | 1 | 3 | 4 | 2 |  | 0 | 50 |  |
| engineer | 工兵 | 8 | 3 | 2 | 1 | 3 | 3 | 1 |  | 0 | 50 |  |
| tank_destroyer | 驅逐戰車 | 12 | 5 | 4 | 2 | 3 | 3 | 7 | 2@2 | 3 | 50 |  |
| heavy_tank | 重戰車 | 22 | 9 | 5 | 1 | 3 | 4 | 7 |  | 6 | 50 |  |
| rocket_artillery | 火箭砲 | 8 | 6 | 1 | 3 | 2 | 2 | 0 |  | 0 | 50 | yes |

## Plain Damage / Counter

Cell format is `damage/counter`.

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 2/1 | 3/1 | 3/1 | 1/1 | 1/2 | 3/0 | 2/1 | 2/1 | 1/1 | 1/3 | 3/0 |
| 機槍組 | 4/1 | 5/1 | 5/1 | 2/1 | 1/3 | 5/0 | 4/1 | 4/1 | 2/1 | 1/4 | 5/0 |
| 反戰車砲 | 3/0 | 4/0 | 4/1 | 7/0 | 6/0 | 4/0 | 3/0 | 3/0 | 7/1 | 6/0 | 4/0 |
| 輕戰車 | 3/1 | 4/1 | 4/1 | 3/1 | 2/3 | 4/0 | 3/1 | 3/1 | 3/3 | 2/5 | 4/0 |
| 中戰車 | 5/1 | 6/1 | 6/0 | 7/1 | 6/2 | 6/0 | 5/1 | 5/1 | 7/1 | 6/4 | 6/0 |
| 砲兵 | 5/0 | 6/0 | 6/0 | 4/0 | 3/0 | 6/0 | 5/0 | 5/0 | 4/0 | 3/0 | 6/0 |
| 傘兵 | 3/1 | 4/1 | 4/1 | 3/1 | 2/2 | 4/0 | 3/1 | 3/1 | 3/1 | 2/3 | 4/0 |
| 工兵 | 1/1 | 2/1 | 2/1 | 1/1 | 1/2 | 2/0 | 1/1 | 1/1 | 1/1 | 1/3 | 2/0 |
| 驅逐戰車 | 3/0 | 4/0 | 4/1 | 10/0 | 9/0 | 4/0 | 3/0 | 3/0 | 10/1 | 9/0 | 4/0 |
| 重戰車 | 7/1 | 8/0 | 8/0 | 12/0 | 11/1 | 8/0 | 7/1 | 7/1 | 12/0 | 11/3 | 8/0 |
| 火箭砲 | 4/0 | 5/0 | 5/0 | 2/0 | 1/0 | 5/0 | 4/0 | 4/0 | 2/0 | 1/0 | 5/0 |

## Damage Matrix: forest

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 2 | 3 | 3 | 1 | 1 | 3 | 2 | 2 | 1 | 1 | 3 |
| 反戰車砲 | 1 | 2 | 2 | 5 | 4 | 2 | 1 | 1 | 5 | 4 | 2 |
| 輕戰車 | 1 | 2 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 |
| 中戰車 | 3 | 4 | 4 | 5 | 4 | 4 | 3 | 3 | 5 | 4 | 4 |
| 砲兵 | 3 | 4 | 4 | 2 | 1 | 4 | 3 | 3 | 2 | 1 | 4 |
| 傘兵 | 1 | 2 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 |
| 工兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 驅逐戰車 | 1 | 2 | 2 | 8 | 7 | 2 | 1 | 1 | 8 | 7 | 2 |
| 重戰車 | 5 | 6 | 6 | 10 | 9 | 6 | 5 | 5 | 10 | 9 | 6 |
| 火箭砲 | 2 | 3 | 3 | 1 | 1 | 3 | 2 | 2 | 1 | 1 | 3 |

## Damage Matrix: town

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 2 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 |
| 反戰車砲 | 1 | 1 | 1 | 4 | 3 | 1 | 1 | 1 | 4 | 3 | 1 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 2 | 3 | 3 | 4 | 3 | 3 | 2 | 2 | 4 | 3 | 3 |
| 砲兵 | 2 | 3 | 3 | 1 | 1 | 3 | 2 | 2 | 1 | 1 | 3 |
| 傘兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 工兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 驅逐戰車 | 1 | 1 | 1 | 7 | 6 | 1 | 1 | 1 | 7 | 6 | 1 |
| 重戰車 | 4 | 5 | 5 | 9 | 8 | 5 | 4 | 4 | 9 | 8 | 5 |
| 火箭砲 | 1 | 2 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 |

## Damage Matrix: town_dig2

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 反戰車砲 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 1 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 1 |
| 砲兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 傘兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 工兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 驅逐戰車 | 1 | 1 | 1 | 5 | 4 | 1 | 1 | 1 | 5 | 4 | 1 |
| 重戰車 | 2 | 3 | 3 | 7 | 6 | 3 | 2 | 2 | 7 | 6 | 3 |
| 火箭砲 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

## Damage Matrix: town_dig3

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 機槍組 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 反戰車砲 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 輕戰車 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 中戰車 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 砲兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 傘兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 工兵 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| 驅逐戰車 | 1 | 1 | 1 | 4 | 3 | 1 | 1 | 1 | 4 | 3 | 1 |
| 重戰車 | 1 | 2 | 2 | 6 | 5 | 2 | 1 | 1 | 6 | 5 | 2 |
| 火箭砲 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

## Suppression / Dig-In Break Matrix

Cell format is `Sx/Dy`: suppression applied to a surviving defender and dig-in levels stripped on town+dig2. MG teams and indirect fire are the primary pinning tools; indirect fire strips one dig-in level, while engineers strip up to two levels when they damage an entrenched target.

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 步兵 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 機槍組 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 | S3/D0 |
| 反戰車砲 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 輕戰車 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 中戰車 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 砲兵 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 |
| 傘兵 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 工兵 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 | S1/D2 |
| 驅逐戰車 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 重戰車 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 | S1/D0 |
| 火箭砲 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 | S3/D1 |

## Urban Breach Baseline

Town breach cells simulate repeated attacks into town+dig3 without defender recovery. Cell format is first-hit `damage Sx/Dy`, then hits to clear all dig-in and hits to kill the defender within the simulation cap.

| attacker | 步兵 | 機槍組 | 反戰車砲 | 中戰車 |
| --- | --- | --- | --- | --- |
| 步兵 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 1 dmg S1/D0; clear --; kill >12 |
| 機槍組 | 1 dmg S3/D0; clear --; kill 10 | 1 dmg S3/D0; clear --; kill 8 | 1 dmg S3/D0; clear --; kill 6 | 1 dmg S3/D0; clear --; kill >12 |
| 反戰車砲 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 1 dmg S1/D0; clear --; kill >12 |
| 輕戰車 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 1 dmg S1/D0; clear --; kill >12 |
| 中戰車 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 1 dmg S1/D0; clear --; kill >12 |
| 砲兵 | 1 dmg S3/D1; clear 3; kill 7 | 1 dmg S3/D1; clear 3; kill 5 | 1 dmg S3/D1; clear 3; kill 4 | 1 dmg S3/D1; clear 3; kill >12 |
| 傘兵 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 1 dmg S1/D0; clear --; kill >12 |
| 工兵 | 1 dmg S1/D2; clear 2; kill 10 | 1 dmg S1/D2; clear 2; kill 8 | 1 dmg S1/D2; clear 2; kill 6 | 1 dmg S1/D2; clear 2; kill >12 |
| 驅逐戰車 | 1 dmg S1/D0; clear --; kill 10 | 1 dmg S1/D0; clear --; kill 8 | 1 dmg S1/D0; clear --; kill 6 | 3 dmg S1/D0; clear --; kill 6 |
| 重戰車 | 1 dmg S1/D0; clear --; kill 10 | 2 dmg S1/D0; clear --; kill 4 | 2 dmg S1/D0; clear --; kill 3 | 5 dmg S1/D0; clear --; kill 4 |
| 火箭砲 | 1 dmg S3/D1; clear 3; kill 10 | 1 dmg S3/D1; clear 3; kill 6 | 1 dmg S3/D1; clear 3; kill 5 | 1 dmg S3/D1; clear 3; kill >12 |

## Hits To Kill

| attacker | defender | plain dmg | plain hits | town+dig3 dmg | town+dig3 hits |
| --- | --- | --- | --- | --- | --- |
| 步兵 | 步兵 | 2 | 5 | 1 | 10 |
| 步兵 | 機槍組 | 3 | 3 | 1 | 8 |
| 步兵 | 反戰車砲 | 3 | 2 | 1 | 6 |
| 步兵 | 輕戰車 | 1 | 12 | 1 | 12 |
| 步兵 | 中戰車 | 1 | 16 | 1 | 16 |
| 步兵 | 砲兵 | 3 | 3 | 1 | 8 |
| 步兵 | 傘兵 | 2 | 4 | 1 | 8 |
| 步兵 | 工兵 | 2 | 4 | 1 | 8 |
| 步兵 | 驅逐戰車 | 1 | 12 | 1 | 12 |
| 步兵 | 重戰車 | 1 | 22 | 1 | 22 |
| 步兵 | 火箭砲 | 3 | 3 | 1 | 8 |
| 機槍組 | 步兵 | 4 | 3 | 1 | 10 |
| 機槍組 | 機槍組 | 5 | 2 | 1 | 8 |
| 機槍組 | 反戰車砲 | 5 | 2 | 1 | 6 |
| 機槍組 | 輕戰車 | 2 | 6 | 1 | 12 |
| 機槍組 | 中戰車 | 1 | 16 | 1 | 16 |
| 機槍組 | 砲兵 | 5 | 2 | 1 | 8 |
| 機槍組 | 傘兵 | 4 | 2 | 1 | 8 |
| 機槍組 | 工兵 | 4 | 2 | 1 | 8 |
| 機槍組 | 驅逐戰車 | 2 | 6 | 1 | 12 |
| 機槍組 | 重戰車 | 1 | 22 | 1 | 22 |
| 機槍組 | 火箭砲 | 5 | 2 | 1 | 8 |
| 反戰車砲 | 步兵 | 3 | 4 | 1 | 10 |
| 反戰車砲 | 機槍組 | 4 | 2 | 1 | 8 |
| 反戰車砲 | 反戰車砲 | 4 | 2 | 1 | 6 |
| 反戰車砲 | 輕戰車 | 7 | 2 | 1 | 12 |
| 反戰車砲 | 中戰車 | 6 | 3 | 1 | 16 |
| 反戰車砲 | 砲兵 | 4 | 2 | 1 | 8 |
| 反戰車砲 | 傘兵 | 3 | 3 | 1 | 8 |
| 反戰車砲 | 工兵 | 3 | 3 | 1 | 8 |
| 反戰車砲 | 驅逐戰車 | 7 | 2 | 1 | 12 |
| 反戰車砲 | 重戰車 | 6 | 4 | 1 | 22 |
| 反戰車砲 | 火箭砲 | 4 | 2 | 1 | 8 |
| 輕戰車 | 步兵 | 3 | 4 | 1 | 10 |
| 輕戰車 | 機槍組 | 4 | 2 | 1 | 8 |
| 輕戰車 | 反戰車砲 | 4 | 2 | 1 | 6 |
| 輕戰車 | 輕戰車 | 3 | 4 | 1 | 12 |
| 輕戰車 | 中戰車 | 2 | 8 | 1 | 16 |
| 輕戰車 | 砲兵 | 4 | 2 | 1 | 8 |
| 輕戰車 | 傘兵 | 3 | 3 | 1 | 8 |
| 輕戰車 | 工兵 | 3 | 3 | 1 | 8 |
| 輕戰車 | 驅逐戰車 | 3 | 4 | 1 | 12 |
| 輕戰車 | 重戰車 | 2 | 11 | 1 | 22 |
| 輕戰車 | 火箭砲 | 4 | 2 | 1 | 8 |
| 中戰車 | 步兵 | 5 | 2 | 1 | 10 |
| 中戰車 | 機槍組 | 6 | 2 | 1 | 8 |
| 中戰車 | 反戰車砲 | 6 | 1 | 1 | 6 |
| 中戰車 | 輕戰車 | 7 | 2 | 1 | 12 |
| 中戰車 | 中戰車 | 6 | 3 | 1 | 16 |
| 中戰車 | 砲兵 | 6 | 2 | 1 | 8 |
| 中戰車 | 傘兵 | 5 | 2 | 1 | 8 |
| 中戰車 | 工兵 | 5 | 2 | 1 | 8 |
| 中戰車 | 驅逐戰車 | 7 | 2 | 1 | 12 |
| 中戰車 | 重戰車 | 6 | 4 | 1 | 22 |
| 中戰車 | 火箭砲 | 6 | 2 | 1 | 8 |
| 砲兵 | 步兵 | 5 | 2 | 1 | 10 |
| 砲兵 | 機槍組 | 6 | 2 | 1 | 8 |
| 砲兵 | 反戰車砲 | 6 | 1 | 1 | 6 |
| 砲兵 | 輕戰車 | 4 | 3 | 1 | 12 |
| 砲兵 | 中戰車 | 3 | 6 | 1 | 16 |
| 砲兵 | 砲兵 | 6 | 2 | 1 | 8 |
| 砲兵 | 傘兵 | 5 | 2 | 1 | 8 |
| 砲兵 | 工兵 | 5 | 2 | 1 | 8 |
| 砲兵 | 驅逐戰車 | 4 | 3 | 1 | 12 |
| 砲兵 | 重戰車 | 3 | 8 | 1 | 22 |
| 砲兵 | 火箭砲 | 6 | 2 | 1 | 8 |
| 傘兵 | 步兵 | 3 | 4 | 1 | 10 |
| 傘兵 | 機槍組 | 4 | 2 | 1 | 8 |
| 傘兵 | 反戰車砲 | 4 | 2 | 1 | 6 |
| 傘兵 | 輕戰車 | 3 | 4 | 1 | 12 |
| 傘兵 | 中戰車 | 2 | 8 | 1 | 16 |
| 傘兵 | 砲兵 | 4 | 2 | 1 | 8 |
| 傘兵 | 傘兵 | 3 | 3 | 1 | 8 |
| 傘兵 | 工兵 | 3 | 3 | 1 | 8 |
| 傘兵 | 驅逐戰車 | 3 | 4 | 1 | 12 |
| 傘兵 | 重戰車 | 2 | 11 | 1 | 22 |
| 傘兵 | 火箭砲 | 4 | 2 | 1 | 8 |
| 工兵 | 步兵 | 1 | 10 | 1 | 10 |
| 工兵 | 機槍組 | 2 | 4 | 1 | 8 |
| 工兵 | 反戰車砲 | 2 | 3 | 1 | 6 |
| 工兵 | 輕戰車 | 1 | 12 | 1 | 12 |
| 工兵 | 中戰車 | 1 | 16 | 1 | 16 |
| 工兵 | 砲兵 | 2 | 4 | 1 | 8 |
| 工兵 | 傘兵 | 1 | 8 | 1 | 8 |
| 工兵 | 工兵 | 1 | 8 | 1 | 8 |
| 工兵 | 驅逐戰車 | 1 | 12 | 1 | 12 |
| 工兵 | 重戰車 | 1 | 22 | 1 | 22 |
| 工兵 | 火箭砲 | 2 | 4 | 1 | 8 |
| 驅逐戰車 | 步兵 | 3 | 4 | 1 | 10 |
| 驅逐戰車 | 機槍組 | 4 | 2 | 1 | 8 |
| 驅逐戰車 | 反戰車砲 | 4 | 2 | 1 | 6 |
| 驅逐戰車 | 輕戰車 | 10 | 2 | 4 | 3 |
| 驅逐戰車 | 中戰車 | 9 | 2 | 3 | 6 |
| 驅逐戰車 | 砲兵 | 4 | 2 | 1 | 8 |
| 驅逐戰車 | 傘兵 | 3 | 3 | 1 | 8 |
| 驅逐戰車 | 工兵 | 3 | 3 | 1 | 8 |
| 驅逐戰車 | 驅逐戰車 | 10 | 2 | 4 | 3 |
| 驅逐戰車 | 重戰車 | 9 | 3 | 3 | 8 |
| 驅逐戰車 | 火箭砲 | 4 | 2 | 1 | 8 |
| 重戰車 | 步兵 | 7 | 2 | 1 | 10 |
| 重戰車 | 機槍組 | 8 | 1 | 2 | 4 |
| 重戰車 | 反戰車砲 | 8 | 1 | 2 | 3 |
| 重戰車 | 輕戰車 | 12 | 1 | 6 | 2 |
| 重戰車 | 中戰車 | 11 | 2 | 5 | 4 |
| 重戰車 | 砲兵 | 8 | 1 | 2 | 4 |
| 重戰車 | 傘兵 | 7 | 2 | 1 | 8 |
| 重戰車 | 工兵 | 7 | 2 | 1 | 8 |
| 重戰車 | 驅逐戰車 | 12 | 1 | 6 | 2 |
| 重戰車 | 重戰車 | 11 | 2 | 5 | 5 |
| 重戰車 | 火箭砲 | 8 | 1 | 2 | 4 |
| 火箭砲 | 步兵 | 4 | 3 | 1 | 10 |
| 火箭砲 | 機槍組 | 5 | 2 | 1 | 8 |
| 火箭砲 | 反戰車砲 | 5 | 2 | 1 | 6 |
| 火箭砲 | 輕戰車 | 2 | 6 | 1 | 12 |
| 火箭砲 | 中戰車 | 1 | 16 | 1 | 16 |
| 火箭砲 | 砲兵 | 5 | 2 | 1 | 8 |
| 火箭砲 | 傘兵 | 4 | 2 | 1 | 8 |
| 火箭砲 | 工兵 | 4 | 2 | 1 | 8 |
| 火箭砲 | 驅逐戰車 | 2 | 6 | 1 | 12 |
| 火箭砲 | 重戰車 | 1 | 22 | 1 | 22 |
| 火箭砲 | 火箭砲 | 5 | 2 | 1 | 8 |

## Baseline Delta

Baseline deltas compare current `data/units.json` against the provided `--baseline` unit catalog.

### Stat Changes

| id | name | changes |
| --- | --- | --- |
| mg_team | 機槍組 | overwatch_damage_pct 50->100 (+50) |
| at_gun | 反戰車砲 | attack 7->5 (-2)<br>range 1->2 (+1)<br>move 1->2 (+1)<br>vs_armor 5->6 (+1) |
| light_tank | 輕戰車 | vision 4->5 (+1) |
| artillery | 砲兵 | attack 8->7 (-1)<br>range 3->4 (+1)<br>vision 5->2 (-3)<br>vs_armor 2->1 (-1) |
| paratrooper | 傘兵 | new unit |
| engineer | 工兵 | new unit |
| tank_destroyer | 驅逐戰車 | new unit |
| heavy_tank | 重戰車 | new unit |
| rocket_artillery | 火箭砲 | new unit |

### Plain Damage Delta

| atk \ def | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 |
| --- | --- | --- | --- | --- | --- | --- |
| 步兵 | 0 | 0 | 0 | 0 | 0 | 0 |
| 機槍組 | 0 | 0 | 0 | 0 | 0 | 0 |
| 反戰車砲 | -2 | -2 | -2 | -1 | -1 | -2 |
| 輕戰車 | 0 | 0 | 0 | 0 | 0 | 0 |
| 中戰車 | 0 | 0 | 0 | 0 | 0 | 0 |
| 砲兵 | -1 | -1 | -1 | -2 | -2 | -1 |

### Hits-To-Kill Delta

| attacker | defender | baseline hits | current hits | delta |
| --- | --- | --- | --- | --- |
| 反戰車砲 | 步兵 | 2 | 4 | +2 |
| 反戰車砲 | 反戰車砲 | 1 | 2 | +1 |
| 砲兵 | 輕戰車 | 2 | 3 | +1 |
| 砲兵 | 中戰車 | 4 | 6 | +2 |

### High-Risk TTK Changes

| attacker | defender | baseline hits | current hits | change |
| --- | --- | --- | --- | --- |
| 反戰車砲 | 步兵 | 2 | 4 | +100% |
| 反戰車砲 | 反戰車砲 | 1 | 2 | +100% |
| 砲兵 | 輕戰車 | 2 | 3 | +50% |
| 砲兵 | 中戰車 | 4 | 6 | +50% |

## Role Diagnostics

| unit | avg vs soft | avg vs armor | armor delta | diagnostic |
| --- | --- | --- | --- | --- |
| 步兵 | 2.57 | 1.00 | -1.57 |  |
| 機槍組 | 4.57 | 1.50 | -3.07 |  |
| 反戰車砲 | 3.57 | 6.50 | +2.93 |  |
| 輕戰車 | 3.57 | 2.50 | -1.07 | Mobility/vision must justify lower damage |
| 中戰車 | 5.57 | 6.50 | +0.93 | Baseline main battle unit; many named tanks share this stat |
| 砲兵 | 5.57 | 3.50 | -2.07 |  |
| 傘兵 | 3.57 | 2.50 | -1.07 |  |
| 工兵 | 1.57 | 1.00 | -0.57 |  |
| 驅逐戰車 | 3.57 | 9.50 | +5.93 |  |
| 重戰車 | 7.57 | 11.50 | +3.93 |  |
| 火箭砲 | 4.57 | 1.50 | -3.07 |  |

## Scenario Exposure

| scenario | 步兵 | 機槍組 | 反戰車砲 | 輕戰車 | 中戰車 | 砲兵 | 傘兵 | 工兵 | 驅逐戰車 | 重戰車 | 火箭砲 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 00_sandbox | 3 | 1 | 1 | 1 | 2 | 1 | 0 | 0 | 2 | 2 | 2 |
| 01_sedan_1940 | 5 | 2 | 1 | 1 | 3 | 1 | 0 | 0 | 0 | 0 | 0 |
| 02_kiev_1941 | 5 | 1 | 2 | 1 | 4 | 2 | 0 | 0 | 1 | 0 | 0 |
| 03_stalingrad_1942 | 5 | 3 | 2 | 1 | 1 | 1 | 0 | 1 | 1 | 0 | 1 |
| 04_kursk_1943 | 3 | 0 | 4 | 1 | 7 | 2 | 0 | 0 | 2 | 1 | 0 |
| 05_bastogne_1944 | 4 | 1 | 1 | 0 | 5 | 2 | 2 | 1 | 1 | 1 | 0 |
| 06_market_garden_1944 | 3 | 2 | 2 | 0 | 4 | 2 | 3 | 1 | 1 | 0 | 0 |
| 07_bagration_1944 | 5 | 2 | 3 | 0 | 5 | 2 | 0 | 0 | 2 | 1 | 1 |
| blitz_00_poland_1939 | 5 | 1 | 1 | 2 | 1 | 2 | 0 | 0 | 0 | 0 | 0 |
| blitz_02_dunkirk_1940 | 5 | 1 | 1 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| blitz_03_moscow_1941 | 4 | 1 | 2 | 0 | 4 | 2 | 0 | 0 | 0 | 0 | 1 |
| conq_atlantic_convoy | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_cbi_jungle | 6 | 2 | 2 | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| conq_china_plains | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_desert_north_africa | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_home_islands | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_mediterranean_coast | 5 | 1 | 2 | 0 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_middle_east_oilfields | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_north_sea_raid | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_pacific_carrier | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| conq_pacific_island | 6 | 2 | 2 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| east_05_kharkov_1943 | 4 | 1 | 1 | 1 | 5 | 2 | 0 | 0 | 1 | 1 | 0 |
| east_06_dnieper_1943 | 5 | 1 | 1 | 1 | 3 | 2 | 0 | 1 | 0 | 0 | 0 |
| east_09_seelow_1945 | 4 | 1 | 2 | 0 | 2 | 2 | 0 | 0 | 1 | 1 | 1 |
| east_10_berlin_1945 | 5 | 2 | 1 | 0 | 2 | 2 | 0 | 1 | 1 | 1 | 0 |
| north_00_gazala_1942 | 3 | 1 | 2 | 1 | 4 | 2 | 0 | 0 | 1 | 0 | 0 |
| north_01_el_alamein_1942 | 3 | 0 | 2 | 1 | 4 | 2 | 0 | 0 | 2 | 0 | 0 |
| north_02_kasserine_1943 | 5 | 1 | 2 | 2 | 4 | 2 | 0 | 0 | 2 | 0 | 0 |
| north_03_tunis_1943 | 4 | 1 | 2 | 1 | 2 | 2 | 0 | 1 | 2 | 0 | 0 |
| north_04_bizerte_1943 | 6 | 2 | 1 | 1 | 3 | 2 | 0 | 1 | 2 | 0 | 0 |
| pacific_01_guadalcanal_1942 | 5 | 2 | 1 | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1 |
| pacific_02_tarawa_1943 | 5 | 3 | 1 | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1 |
| pacific_03_peleliu_1944 | 5 | 3 | 1 | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1 |
| pacific_04_manila_1945 | 5 | 3 | 1 | 1 | 2 | 2 | 0 | 1 | 1 | 0 | 1 |
| pacific_05_iwo_jima_1945 | 6 | 3 | 1 | 1 | 2 | 1 | 0 | 1 | 0 | 0 | 1 |
| pacific_05_okinawa_1945 | 6 | 3 | 1 | 1 | 3 | 2 | 0 | 1 | 1 | 0 | 2 |
| tut_00_basic_turn | 3 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| tut_01_terrain_zoc_overwatch | 3 | 1 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| tut_02_los_spotting_artillery | 1 | 0 | 2 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| tut_03_suppression_digin_engineer | 2 | 1 | 0 | 0 | 1 | 1 | 0 | 1 | 0 | 0 | 0 |
| tut_04_armor_at_veteran_general | 1 | 0 | 1 | 0 | 2 | 0 | 0 | 0 | 1 | 1 | 0 |
| tut_05_airdrop_reinforcement_rocket | 4 | 1 | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| west_08_falaise_1944 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| west_08_normandy_cobra_1944 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| west_08_pegasus_bridge_1944 | 3 | 2 | 2 | 0 | 2 | 1 | 2 | 1 | 0 | 0 | 0 |
| west_09_aachen_1944 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| west_09_hurtgen_1944 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| west_10_remagen_1945 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| west_11_colmar_1945 | 4 | 1 | 2 | 0 | 3 | 2 | 0 | 0 | 2 | 0 | 0 |
| TOTAL | 204 | 65 | 78 | 32 | 116 | 78 | 8 | 16 | 37 | 9 | 14 |

| scenario | tiles | dominant terrain |
| --- | --- | --- |
| 00_sandbox | 384 | plain 71%, forest 11%, road 7% |
| 01_sedan_1940 | 384 | plain 63%, forest 21%, road 6% |
| 02_kiev_1941 | 384 | plain 78%, forest 7%, road 7% |
| 03_stalingrad_1942 | 384 | plain 47%, town 42%, river 6% |
| 04_kursk_1943 | 384 | plain 83%, forest 7%, road 6% |
| 05_bastogne_1944 | 384 | plain 63%, forest 18%, road 16% |
| 06_market_garden_1944 | 384 | plain 67%, river 11%, road 10% |
| 07_bagration_1944 | 384 | plain 79%, road 9%, forest 6% |
| blitz_00_poland_1939 | 384 | plain 71%, road 12%, forest 8% |
| blitz_02_dunkirk_1940 | 384 | plain 71%, road 11%, river 7% |
| blitz_03_moscow_1941 | 384 | plain 76%, forest 13%, road 10% |
| conq_atlantic_convoy | 384 | plain 75%, forest 11%, sea 9% |
| conq_cbi_jungle | 384 | jungle 88%, river 4%, plain 4% |
| conq_china_plains | 384 | plain 74%, road 10%, forest 9% |
| conq_desert_north_africa | 384 | desert 82%, road 10%, mountain 7% |
| conq_home_islands | 384 | plain 69%, mountain 12%, forest 10% |
| conq_mediterranean_coast | 384 | plain 74%, road 14%, sea 7% |
| conq_middle_east_oilfields | 384 | desert 79%, road 10%, river 4% |
| conq_north_sea_raid | 384 | plain 77%, sea 12%, town 7% |
| conq_pacific_carrier | 384 | plain 73%, sea 17%, town 6% |
| conq_pacific_island | 384 | plain 80%, sea 10%, jungle 8% |
| east_05_kharkov_1943 | 384 | plain 72%, road 13%, forest 7% |
| east_06_dnieper_1943 | 160 | plain 65%, road 13%, forest 11% |
| east_09_seelow_1945 | 384 | plain 75%, road 10%, mountain 7% |
| east_10_berlin_1945 | 384 | town 60%, plain 22%, road 18% |
| north_00_gazala_1942 | 160 | desert 74%, road 16%, mountain 8% |
| north_01_el_alamein_1942 | 160 | desert 76%, road 14%, mountain 7% |
| north_02_kasserine_1943 | 160 | desert 67%, road 21%, mountain 10% |
| north_03_tunis_1943 | 160 | desert 71%, road 18%, mountain 8% |
| north_04_bizerte_1943 | 160 | desert 52%, road 25%, sea 11% |
| pacific_01_guadalcanal_1942 | 160 | plain 67%, jungle 14%, sea 11% |
| pacific_02_tarawa_1943 | 160 | plain 64%, jungle 12%, sea 11% |
| pacific_03_peleliu_1944 | 160 | plain 61%, jungle 13%, road 9% |
| pacific_04_manila_1945 | 160 | plain 42%, town 28%, road 21% |
| pacific_05_iwo_jima_1945 | 160 | plain 60%, road 13%, sea 11% |
| pacific_05_okinawa_1945 | 160 | plain 53%, road 18%, town 15% |
| tut_00_basic_turn | 48 | plain 88%, road 10%, town 2% |
| tut_01_terrain_zoc_overwatch | 54 | plain 81%, road 9%, forest 7% |
| tut_02_los_spotting_artillery | 70 | plain 77%, forest 14%, road 9% |
| tut_03_suppression_digin_engineer | 70 | plain 81%, river 14%, town 3% |
| tut_04_armor_at_veteran_general | 54 | plain 85%, road 11%, forest 4% |
| tut_05_airdrop_reinforcement_rocket | 70 | plain 90%, road 4%, forest 3% |
| west_08_falaise_1944 | 384 | plain 72%, forest 12%, road 10% |
| west_08_normandy_cobra_1944 | 384 | plain 73%, road 10%, forest 10% |
| west_08_pegasus_bridge_1944 | 160 | plain 64%, road 14%, forest 9% |
| west_09_aachen_1944 | 384 | plain 74%, road 11%, forest 9% |
| west_09_hurtgen_1944 | 384 | plain 70%, road 12%, forest 11% |
| west_10_remagen_1945 | 384 | plain 72%, road 11%, forest 10% |
| west_11_colmar_1945 | 384 | plain 71%, road 12%, forest 10% |

## Rule Risks

| risk | why it matters | next action |
| --- | --- | --- |
| Attack visibility | Resolved: direct attacks require visibility + LOS; indirect attacks require visibility and ignore LOS blockers. | Keep future attack helpers routed through CombatRules. |
| indirect semantics | Resolved: indirect units cannot counter while defending, but close indirect attacks can still be countered. | Preserve this distinction in UI text and combat tests. |
| ZoC path reconstruction | Resolved: movement range and path reconstruction share the same terrain + active-ZoC step cost; pinned units do not project ZoC. | Keep new pathfinding callsites passing occupied + mover_faction. |
| Town + dig-in | Town defense 3 plus dig-in 3 still pushes many attacks to the 1-damage floor, but artillery strips one dig-in level and engineers strip up to two on damaging hits. | Monitor scenario_probe.md breach paths plus playtests to confirm Stalingrad/Berlin create breach decisions instead of static 1-damage stalls. |
| MG control | MG teams use overwatch_damage_pct 100 while default reaction fire remains 50, and suppressive fire lets them spend an action to pin a visible short-range target without damage. | Keep AI overwatch/suppressive-fire scoring and help text aligned with unit-data action profiles. |

## Recommended Next Pass

1. Run this report before and after every candidate stat patch, then compare role diagnostics plus hits-to-kill.
2. Use the Urban Breach Baseline, scenario breach tools, and scenario_probe.md breach paths before changing Stalingrad or Berlin rosters or turn clocks.
3. Validate whether engineers survive the approach and open town+dig3 positions; Stalingrad/Berlin now have closer engineer starts and limited artillery reposition coverage, so playtest before further defender nerfs.
4. Validate Rally and suppression tempo in Stalingrad, Bastogne, Kursk, Kiev, then Sedan, because those scenarios stress the highest-risk mechanics in order.

