# AI Trace Report

Deterministic diagnostic traces generated from `AIController.plan_trace_for_unit()` using focused synthetic situations. Scores are rounded for review; source decisions use the full GDScript values.

## Light tank scout memory
No visible enemies; the scout should move toward the last-known contact band instead of idling.

Plan: `wait` to `3,0`, target `none`, score `-1.10`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `4,-1` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2 | `3,0` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `3,1` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `5,-2` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `3,2` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## Engineer urban breach setup
Visible high-cover dig-in target should create breach movement pressure before contact.

Plan: `overwatch` to `2,0`, target `none`, score `2.04`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,1` | `none` | `none` | `none` | `none` | 0.54 | 2.04 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 2 | `2,0` | `none` | `none` | `none` | `none` | 0.54 | 2.04 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 3 | `3,-1` | `none` | `none` | `none` | `none` | 0.54 | 2.04 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 4 | `1,0` | `none` | `none` | `none` | `none` | -1.77 | -0.27 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.42 | 0.00 | 0.00 |
| 5 | `1,2` | `none` | `none` | `none` | `none` | -1.85 | -0.35 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |

## Engineer breach support mark
An engineer near an entrenched target should mark it when artillery can immediately exploit the breach.

Plan: `breach_support` to `0,0`, target `infantry@2,0`, score `8.70`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | `none` | `infantry@2,0` | `none` | 3.20 | 4.70 | -inf | 8.70 | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2 | `1,-1` | `none` | `none` | `infantry@2,0` | `none` | 3.20 | 4.70 | -inf | 8.70 | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `1,2` | `none` | `none` | `infantry@2,0` | `none` | 3.20 | 4.70 | -inf | 8.70 | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `0,1` | `none` | `none` | `infantry@2,0` | `none` | 3.20 | 4.70 | -inf | 8.70 | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `2,-2` | `none` | `none` | `infantry@2,0` | `none` | 3.20 | 4.70 | -inf | 8.70 | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## Light tank fire-support mark
A light tank with no clean assault lane should spend its action marking a visible target when friendly artillery can follow up.

Plan: `fire_support_mark` to `0,0`, target `infantry@3,0`, score `-1.18`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | `infantry@3,0` | `none` | `none` | -4.50 | -1.50 | -1.18 | -inf | -inf | -inf | -3.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | -1.50 |

## Hard lookahead exposure
The net-exchange retaliation discount runs at all difficulties; Hard weights it most heavily.

Plan: `overwatch` to `0,-1`, target `none`, score `-0.33`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,-1` | `none` | `none` | `none` | `none` | -2.12 | -0.33 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 1.50 | -0.62 | 0.00 | 0.00 |
| 2 | `0,-2` | `none` | `none` | `none` | `none` | -2.25 | -0.45 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 2.00 | -0.25 | 0.00 | 0.00 |
| 3 | `0,-3` | `none` | `none` | `none` | `none` | -2.50 | -0.70 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 2.50 | 0.00 | 0.00 | 0.00 |
| 4 | `1,-3` | `none` | `none` | `none` | `none` | -2.75 | -0.95 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 2.50 | -0.25 | 0.00 | 0.00 |
| 5 | `-1,-2` | `none` | `none` | `none` | `none` | -2.75 | -0.95 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 2.50 | -0.25 | 0.00 | 0.00 |

## Normal lookahead exchange
A slow AT gun caught inside a tank's reach shows the retaliation discount on every candidate at Normal weight.

Plan: `attack` to `0,0`, target `medium_tank@0,2`, score `12.23`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `medium_tank@0,2` | `none` | `none` | `none` | 12.23 | -2.77 | -inf | -inf | -inf | -inf | -2.00 | 18.00 | -1.75 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -7.00 | 0.00 | -0.42 | 0.00 | 0.00 |
| 2 | `1,0` | `medium_tank@0,2` | `none` | `none` | `none` | 12.15 | -2.85 | -inf | -inf | -inf | -inf | -2.00 | 18.00 | -1.75 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -7.00 | 0.00 | -0.50 | 0.00 | 0.00 |
| 3 | `-1,1` | `medium_tank@0,2` | `none` | `none` | `none` | 12.15 | -2.85 | -inf | -inf | -inf | -inf | -2.00 | 18.00 | -1.75 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -7.00 | 0.00 | -0.50 | 0.00 | 0.00 |
| 4 | `2,0` | `medium_tank@0,2` | `none` | `none` | `none` | 12.15 | -2.85 | -inf | -inf | -inf | -inf | -2.00 | 18.00 | -1.75 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -7.00 | 0.00 | -0.50 | 0.00 | 0.00 |
| 5 | `-2,2` | `medium_tank@0,2` | `none` | `none` | `none` | 12.15 | -2.85 | -inf | -inf | -inf | -inf | -2.00 | 18.00 | -1.75 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -7.00 | 0.00 | -0.50 | 0.00 | 0.00 |

## Focus fire convergence
Two symmetric targets; an earlier unit already engaged the second one, so the tank should converge on it instead of the tie-break default.

Plan: `attack` to `-1,0`, target `infantry@-2,0`, score `16.69`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `-1,0` | `infantry@-2,0` | `none` | `none` | `none` | 16.69 | 5.99 | -inf | -inf | -inf | -inf | -1.00 | 14.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.21 | 0.00 | -0.50 | 1.20 | 0.00 |
| 2 | `-1,-1` | `infantry@-2,0` | `none` | `none` | `none` | 16.69 | 5.99 | -inf | -inf | -inf | -inf | -1.00 | 14.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.21 | 0.00 | -0.50 | 1.20 | 0.00 |
| 3 | `-2,1` | `infantry@-2,0` | `none` | `none` | `none` | 16.69 | 5.99 | -inf | -inf | -inf | -inf | -1.00 | 14.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.21 | 0.00 | -0.50 | 1.20 | 0.00 |
| 4 | `1,0` | `infantry@2,0` | `none` | `none` | `none` | 15.49 | 5.99 | -inf | -inf | -inf | -inf | -1.00 | 14.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.21 | 0.00 | -0.50 | 0.00 | 0.00 |
| 5 | `2,-1` | `infantry@2,0` | `none` | `none` | `none` | 15.49 | 5.99 | -inf | -inf | -inf | -inf | -1.00 | 14.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.21 | 0.00 | -0.50 | 0.00 | 0.00 |

## Fire support mark follow-up
A spotter already marked the second target this turn; the artillery should convert the mark instead of the tie-break default.

Plan: `attack` to `0,0`, target `infantry@-3,0`, score `27.15`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `infantry@-3,0` | `none` | `none` | `none` | 27.15 | 2.95 | -inf | -inf | -inf | -inf | -3.00 | 21.50 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | -0.50 | 2.70 | 0.00 |
| 2 | `1,-1` | `infantry@-3,0` | `none` | `none` | `none` | 24.13 | -0.07 | -inf | -inf | -inf | -inf | -3.00 | 21.50 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -2.10 | 0.00 | -0.42 | 2.70 | 0.00 |
| 3 | `0,-1` | `infantry@-3,0` | `none` | `none` | `none` | 24.13 | -0.07 | -inf | -inf | -inf | -inf | -3.00 | 21.50 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -2.10 | 0.00 | -0.42 | 2.70 | 0.00 |
| 4 | `-1,1` | `infantry@-3,0` | `none` | `none` | `none` | 24.13 | -0.07 | -inf | -inf | -inf | -inf | -3.00 | 21.50 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -2.10 | 0.00 | -0.42 | 2.70 | 0.00 |
| 5 | `0,1` | `infantry@-3,0` | `none` | `none` | `none` | 24.13 | -0.07 | -inf | -inf | -inf | -inf | -3.00 | 21.50 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -2.10 | 0.00 | -0.42 | 2.70 | 0.00 |

## Wounded veteran withdrawal
A low-HP veteran with no kill on offer should show a positive preservation pull toward safer hexes instead of trading itself away.

Plan: `overwatch` to `-1,0`, target `none`, score `2.11`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `-1,0` | `none` | `none` | `none` | `none` | 0.31 | 2.11 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 5.31 | 0.00 | 0.00 | 0.00 |
| 2 | `0,-1` | `none` | `none` | `none` | `none` | -0.03 | 1.77 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 5.31 | -0.34 | 0.00 | 0.00 |
| 3 | `-1,1` | `none` | `none` | `none` | `none` | -0.03 | 1.77 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 5.31 | -0.34 | 0.00 | 0.00 |
| 4 | `0,0` | `none` | `none` | `none` | `none` | -0.27 | 1.53 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 4.25 | -0.52 | 0.00 | 0.00 |
| 5 | `0,-4` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 | 0.00 | 0.00 | 0.00 |

## Suppressed rally choice
Pinned unit in cover should show rally value competing with the attack plan.

Plan: `rally` to `0,0`, target `none`, score `19.50`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `infantry@1,0` | `none` | `none` | `none` | 3.14 | -0.86 | -inf | -inf | -inf | 19.50 | -1.00 | 4.00 | -1.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.45 | 0.00 | -0.50 | 0.00 | 0.00 |
| 2 | `0,-1` | `none` | `none` | `none` | `none` | -4.65 | -4.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 3 | `-1,0` | `none` | `none` | `none` | `none` | -4.65 | -4.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 4 | `-1,1` | `none` | `none` | `none` | `none` | -4.65 | -4.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 5 | `1,-2` | `none` | `none` | `none` | `none` | -4.65 | -4.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |

## MG overwatch lane
MG reaction-fire profile should appear in overwatch candidate scores.

Plan: `overwatch` to `-1,0`, target `none`, score `2.75`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `-1,0` | `none` | `none` | `none` | `none` | -3.25 | 2.75 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | -0.25 | 0.00 | 0.00 |
| 2 | `-2,0` | `none` | `none` | `none` | `none` | -4.00 | 2.00 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `-1,-1` | `none` | `none` | `none` | `none` | -4.17 | 1.83 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | -0.17 | 0.00 | 0.00 |
| 4 | `-2,1` | `none` | `none` | `none` | `none` | -4.17 | 1.83 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | -0.17 | 0.00 | 0.00 |
| 5 | `0,0` | `none` | `none` | `none` | `infantry@2,0` | -5.27 | 0.73 | -inf | -inf | -0.39 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.85 | 0.00 | -0.42 | 0.00 | 0.00 |

## MG suppressive-fire choice
A visible target outside direct attack range but inside the MG's suppressive-fire setup should produce an active control action.

Plan: `suppressive_fire` to `2,0`, target `infantry@4,0`, score `1.92`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `infantry@4,0` | -5.35 | 0.65 | -inf | -inf | 1.92 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.85 | 0.00 | -0.50 | 0.00 | 0.00 |
| 2 | `0,0` | `none` | `none` | `none` | `none` | -4.25 | 1.75 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.00 | -0.25 | 0.00 | 0.00 |
| 3 | `1,0` | `none` | `none` | `none` | `none` | -6.27 | -0.27 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.85 | 0.00 | -0.42 | 0.00 | 0.00 |
| 4 | `1,1` | `none` | `none` | `none` | `none` | -6.35 | -0.35 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.85 | 0.00 | -0.50 | 0.00 | 0.00 |
| 5 | `2,-1` | `none` | `none` | `none` | `none` | -6.35 | -0.35 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -1.85 | 0.00 | -0.50 | 0.00 | 0.00 |

## Tank destroyer standoff
Tank destroyers should prefer the authored anti-armor standoff band over adjacent armor contact.

Plan: `attack` to `1,0`, target `medium_tank@3,0`, score `27.04`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `3,-2` | `medium_tank@3,0` | `none` | `none` | `none` | 27.04 | 9.04 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -4.66 | 0.00 | -0.50 | 0.00 | 0.00 |
| 2 | `1,0` | `medium_tank@3,0` | `none` | `none` | `none` | 27.04 | 9.04 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -4.66 | 0.00 | -0.50 | 0.00 | 0.00 |
| 3 | `1,2` | `medium_tank@3,0` | `none` | `none` | `none` | 27.04 | 9.04 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -4.66 | 0.00 | -0.50 | 0.00 | 0.00 |
| 4 | `2,-1` | `medium_tank@3,0` | `none` | `none` | `none` | 27.04 | 9.04 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -4.66 | 0.00 | -0.50 | 0.00 | 0.00 |
| 5 | `1,1` | `medium_tank@3,0` | `none` | `none` | `none` | 27.04 | 9.04 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -4.66 | 0.00 | -0.50 | 0.00 | 0.00 |

## Secondary objective pull
Primary, secondary and locked follow-up objective pressure should be split so reviewers can see which target shaped the move.

Plan: `wait` to `3,0`, target `none`, score `-5.39`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `3,0` | `none` | `none` | `none` | `none` | -5.39 | -5.39 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | 1.11 | 0.00 | 0.00 | -4.29 | `primary:6,0 d3; secondary:forward_cache 3,0 d0 w1.35 rv0.15 rp0.21 fv0.90 fp0.90` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2 | `4,-1` | `none` | `none` | `none` | `none` | -7.02 | -7.02 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -0.52 | 0.00 | 0.00 | -5.92 | `primary:6,0 d3; secondary:forward_cache 3,0 d1 w1.35 rv0.15 rp0.16 fv0.90 fp0.67` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `3,1` | `none` | `none` | `none` | `none` | -7.02 | -7.02 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -0.52 | 0.00 | 0.00 | -5.92 | `primary:6,0 d3; secondary:forward_cache 3,0 d1 w1.35 rv0.15 rp0.16 fv0.90 fp0.67` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `3,2` | `none` | `none` | `none` | `none` | -8.65 | -8.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -2.15 | 0.00 | 0.00 | -7.55 | `primary:6,0 d3; secondary:forward_cache 3,0 d2 w1.35 rv0.15 rp0.10 fv0.90 fp0.45` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `5,-2` | `none` | `none` | `none` | `none` | -8.65 | -8.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -2.15 | 0.00 | 0.00 | -7.55 | `primary:6,0 d3; secondary:forward_cache 3,0 d2 w1.35 rv0.15 rp0.10 fv0.90 fp0.45` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## Objective denial guard
Defenders should value blocking opponent control objectives even when they only have a survival objective.

Plan: `wait` to `2,0`, target `none`, score `2.29`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `none` | 2.29 | 2.29 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.25 | 5.04 | 6.29 | `denial:control_count 2,0 d0 w1.25; guard:control_count 2,0 d0 w2.52` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2 | `1,2` | `none` | `none` | `none` | `none` | 1.29 | 1.29 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.25 | 5.04 | 6.29 | `denial:control_count 1,2 d0 w1.25; guard:control_count 1,2 d0 w2.52` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `3,0` | `none` | `none` | `none` | `none` | 0.56 | 0.56 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `2,1` | `none` | `none` | `none` | `none` | -0.44 | -0.44 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `3,-1` | `none` | `none` | `none` | `none` | -0.44 | -0.44 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## Victory point guard hold
A survival defender already on the attacker's victory hex should not abandon it for a distant visible lure.

Plan: `overwatch` to `2,0`, target `none`, score `4.00`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement | coordination | blocking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `none` | 2.50 | 4.00 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.15 | 5.60 | 6.75 | `denial:capture 2,0 d0 w1.15; guard:capture 2,0 d0 w2.80` | -0.00 | 0.00 | -0.25 | 0.00 | 0.00 |
| 2 | `3,0` | `none` | `none` | `none` | `none` | -1.73 | -0.23 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | -1.15 | 0.00 | -0.42 | 0.00 | 0.00 |
| 3 | `4,0` | `none` | `none` | `none` | `none` | -2.40 | -0.90 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.38 | 1.87 | 2.25 | `denial:capture 2,0 d2 w1.15; guard:capture 2,0 d2 w2.80` | -1.15 | 0.00 | -0.50 | 0.00 | 0.00 |
| 4 | `3,-1` | `none` | `none` | `none` | `none` | -2.56 | -1.06 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | -1.15 | 0.00 | -0.25 | 0.00 | 0.00 |
| 5 | `2,1` | `none` | `none` | `none` | `none` | -2.56 | -1.06 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | -1.15 | 0.00 | -0.25 | 0.00 | 0.00 |
