# AI Trace Report

Deterministic diagnostic traces generated from `AIController.plan_trace_for_unit()` using focused synthetic situations. Scores are rounded for review; source decisions use the full GDScript values.

## Light tank scout memory
No visible enemies; the scout should move toward the last-known contact band instead of idling.

Plan: `wait` to `3,0`, target `none`, score `-1.10`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `4,-1` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `3,0` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `3,1` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `5,-2` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `3,2` | `none` | `none` | `none` | `none` | -1.10 | -1.10 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Engineer urban breach setup
Visible high-cover dig-in target should create breach movement pressure before contact.

Plan: `overwatch` to `2,0`, target `none`, score `3.70`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `3,-1` | `none` | `none` | `none` | `none` | 2.20 | 3.70 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `2,1` | `none` | `none` | `none` | `none` | 2.20 | 3.70 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `2,0` | `none` | `none` | `none` | `none` | 2.20 | 3.70 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `1,0` | `none` | `none` | `none` | `none` | -0.20 | 1.30 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `3,-2` | `none` | `none` | `none` | `none` | -0.20 | 1.30 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Engineer breach support mark
An engineer near an entrenched target should mark it when artillery can immediately exploit the breach.

Plan: `breach_support` to `0,0`, target `infantry@2,0`, score `7.70`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | `none` | `infantry@2,0` | `none` | 2.20 | 3.70 | -inf | 7.70 | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `1,-1` | `none` | `none` | `infantry@2,0` | `none` | 2.20 | 3.70 | -inf | 7.70 | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `1,2` | `none` | `none` | `infantry@2,0` | `none` | 2.20 | 3.70 | -inf | 7.70 | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `0,1` | `none` | `none` | `infantry@2,0` | `none` | 2.20 | 3.70 | -inf | 7.70 | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `2,-2` | `none` | `none` | `infantry@2,0` | `none` | 2.20 | 3.70 | -inf | 7.70 | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Light tank fire-support mark
A light tank with no clean assault lane should spend its action marking a visible target when friendly artillery can follow up.

Plan: `fire_support_mark` to `0,0`, target `infantry@3,0`, score `-0.68`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | `infantry@3,0` | `none` | `none` | -4.00 | -1.00 | -0.68 | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Hard lookahead exposure
Hard AI should expose the one-ply retaliation penalty in candidate components.

Plan: `overwatch` to `0,-1`, target `none`, score `-1.98`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,-1` | `none` | `none` | `none` | `none` | -3.78 | -1.98 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 0.62 |
| 2 | `0,-2` | `none` | `none` | `none` | `none` | -4.28 | -2.48 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 1.12 |
| 3 | `1,-3` | `none` | `none` | `none` | `none` | -4.78 | -2.98 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 1.62 |
| 4 | `0,-3` | `none` | `none` | `none` | `none` | -4.78 | -2.98 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 1.62 |
| 5 | `-1,-2` | `none` | `none` | `none` | `none` | -4.78 | -2.98 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 1.62 |

## Wounded veteran withdrawal
A low-HP veteran with no kill on offer should show a positive preservation pull toward safer hexes instead of trading itself away.

Plan: `wait` to `0,-4`, target `none`, score `0.50`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,-4` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 |
| 2 | `-4,4` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 |
| 3 | `-1,-3` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 |
| 4 | `-4,3` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 |
| 5 | `-4,2` | `none` | `none` | `none` | `none` | 0.50 | 0.50 | -inf | -inf | -inf | -inf | -8.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | -0.00 | 8.50 |

## Suppressed rally choice
Pinned unit in cover should show rally value competing with the attack plan.

Plan: `rally` to `0,0`, target `none`, score `19.50`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `infantry@1,0` | `none` | `none` | `none` | 4.10 | 0.10 | -inf | -inf | -inf | 19.50 | -1.00 | 4.00 | -1.00 | 0.90 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `0,-1` | `none` | `none` | `none` | `none` | -3.00 | -3.00 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `-1,0` | `none` | `none` | `none` | `none` | -3.00 | -3.00 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `-1,1` | `none` | `none` | `none` | `none` | -3.00 | -3.00 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `1,-2` | `none` | `none` | `none` | `none` | -3.00 | -3.00 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## MG overwatch lane
MG reaction-fire profile should appear in overwatch candidate scores.

Plan: `overwatch` to `0,0`, target `none`, score `3.00`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | `none` | `none` | `infantry@2,0` | -3.00 | 3.00 | -inf | -inf | 1.88 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `1,-1` | `none` | `none` | `none` | `infantry@2,0` | -3.00 | 3.00 | -inf | -inf | 1.88 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `0,1` | `none` | `none` | `none` | `infantry@2,0` | -3.00 | 3.00 | -inf | -inf | 1.88 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `2,-2` | `none` | `none` | `none` | `infantry@2,0` | -3.00 | 3.00 | -inf | -inf | 1.88 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `0,2` | `none` | `none` | `none` | `infantry@2,0` | -3.00 | 3.00 | -inf | -inf | 1.88 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## MG suppressive-fire choice
A visible target outside direct attack range but inside the MG's suppressive-fire setup should produce an active control action.

Plan: `suppressive_fire` to `2,0`, target `infantry@4,0`, score `4.27`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `infantry@4,0` | -3.00 | 3.00 | -inf | -inf | 4.27 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `1,0` | `none` | `none` | `none` | `none` | -4.00 | 2.00 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `1,1` | `none` | `none` | `none` | `none` | -4.00 | 2.00 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `2,-1` | `none` | `none` | `none` | `none` | -4.00 | 2.00 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `0,2` | `none` | `none` | `none` | `none` | -5.00 | 1.00 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Tank destroyer standoff
Tank destroyers should prefer the authored anti-armor standoff band over adjacent armor contact.

Plan: `attack` to `1,0`, target `medium_tank@3,0`, score `32.20`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1,0` | `medium_tank@3,0` | `none` | `none` | `none` | 32.20 | 14.20 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 2 | `1,2` | `medium_tank@3,0` | `none` | `none` | `none` | 32.20 | 14.20 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 3 | `3,-2` | `medium_tank@3,0` | `none` | `none` | `none` | 32.20 | 14.20 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 4 | `2,-1` | `medium_tank@3,0` | `none` | `none` | `none` | 32.20 | 14.20 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |
| 5 | `1,1` | `medium_tank@3,0` | `none` | `none` | `none` | 32.20 | 14.20 | -inf | -inf | -inf | -inf | -2.00 | 25.50 | -1.75 | 0.00 | 2.80 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | `none` | 0.00 | 0.00 |

## Secondary objective pull
Primary, secondary and locked follow-up objective pressure should be split so reviewers can see which target shaped the move.

Plan: `wait` to `3,0`, target `none`, score `-5.39`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `3,0` | `none` | `none` | `none` | `none` | -5.39 | -5.39 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | 1.11 | 0.00 | 0.00 | -4.29 | `primary:6,0 d3; secondary:forward_cache 3,0 d0 w1.35 rv0.15 rp0.21 fv0.90 fp0.90` | 0.00 | 0.00 |
| 2 | `4,-1` | `none` | `none` | `none` | `none` | -7.02 | -7.02 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -0.52 | 0.00 | 0.00 | -5.92 | `primary:6,0 d3; secondary:forward_cache 3,0 d1 w1.35 rv0.15 rp0.16 fv0.90 fp0.67` | 0.00 | 0.00 |
| 3 | `3,1` | `none` | `none` | `none` | `none` | -7.02 | -7.02 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -0.52 | 0.00 | 0.00 | -5.92 | `primary:6,0 d3; secondary:forward_cache 3,0 d1 w1.35 rv0.15 rp0.16 fv0.90 fp0.67` | 0.00 | 0.00 |
| 4 | `3,2` | `none` | `none` | `none` | `none` | -8.65 | -8.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -2.15 | 0.00 | 0.00 | -7.55 | `primary:6,0 d3; secondary:forward_cache 3,0 d2 w1.35 rv0.15 rp0.10 fv0.90 fp0.45` | 0.00 | 0.00 |
| 5 | `5,-2` | `none` | `none` | `none` | `none` | -8.65 | -8.65 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | -5.40 | -2.15 | 0.00 | 0.00 | -7.55 | `primary:6,0 d3; secondary:forward_cache 3,0 d2 w1.35 rv0.15 rp0.10 fv0.90 fp0.45` | 0.00 | 0.00 |

## Objective denial guard
Defenders should value blocking opponent control objectives even when they only have a survival objective.

Plan: `wait` to `2,0`, target `none`, score `2.29`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `none` | 2.29 | 2.29 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.25 | 5.04 | 6.29 | `denial:control_count 2,0 d0 w1.25; guard:control_count 2,0 d0 w2.52` | 0.00 | 0.00 |
| 2 | `1,2` | `none` | `none` | `none` | `none` | 1.29 | 1.29 | -inf | -inf | -inf | -inf | -5.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.25 | 5.04 | 6.29 | `denial:control_count 1,2 d0 w1.25; guard:control_count 1,2 d0 w2.52` | 0.00 | 0.00 |
| 3 | `3,0` | `none` | `none` | `none` | `none` | 0.56 | 0.56 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 |
| 4 | `2,1` | `none` | `none` | `none` | `none` | -0.44 | -0.44 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 |
| 5 | `3,-1` | `none` | `none` | `none` | `none` | -0.44 | -0.44 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 2.94 | 3.56 | `denial:control_count 2,0 d1 w1.25; guard:control_count 2,0 d1 w2.52` | 0.00 | 0.00 |

## Victory point guard hold
A survival defender already on the attacker's victory hex should not abandon it for a distant visible lure.

Plan: `overwatch` to `2,0`, target `none`, score `3.25`.

| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `2,0` | `none` | `none` | `none` | `none` | 1.75 | 3.25 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 1.15 | 5.60 | 6.75 | `denial:capture 2,0 d0 w1.15; guard:capture 2,0 d0 w2.80` | 0.00 | 0.00 |
| 2 | `3,0` | `none` | `none` | `none` | `none` | -0.16 | 1.34 | -inf | -inf | -inf | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | 0.00 | 0.00 |
| 3 | `4,0` | `none` | `none` | `none` | `none` | -0.75 | 0.75 | -inf | -inf | -inf | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.38 | 1.87 | 2.25 | `denial:capture 2,0 d2 w1.15; guard:capture 2,0 d2 w2.80` | 0.00 | 0.00 |
| 4 | `3,-1` | `none` | `none` | `none` | `none` | -1.16 | 0.34 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | 0.00 | 0.00 |
| 5 | `2,1` | `none` | `none` | `none` | `none` | -1.16 | 0.34 | -inf | -inf | -inf | -inf | -4.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.57 | 3.27 | 3.84 | `denial:capture 2,0 d1 w1.15; guard:capture 2,0 d1 w2.80` | 0.00 | 0.00 |
