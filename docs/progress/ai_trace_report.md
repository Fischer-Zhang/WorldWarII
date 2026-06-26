# AI Trace Report

Deterministic diagnostic traces generated from `AIController.plan_trace_for_unit()` using focused synthetic situations. Scores are rounded for review; source decisions use the full GDScript values.

## Light tank scout memory
No visible enemies; the scout should move toward the last-known contact band instead of idling.

Plan: `wait` to `3,0`, target `none`, score `-1.10`.

| rank | coord | target | base | overwatch | rally | distance | attack | exposure | terrain | role | objective | lookahead |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `4,-1` | `none` | -1.10 | -1.10 | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 |
| 2 | `3,0` | `none` | -1.10 | -1.10 | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 |
| 3 | `3,1` | `none` | -1.10 | -1.10 | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 |
| 4 | `5,-2` | `none` | -1.10 | -1.10 | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 |
| 5 | `3,2` | `none` | -1.10 | -1.10 | -inf | -2.00 | 0.00 | -0.00 | 0.00 | 0.90 | 0.00 | 0.00 |

## Engineer urban breach setup
Visible high-cover dig-in target should create breach movement pressure before contact.

Plan: `overwatch` to `2,0`, target `none`, score `3.70`.

| rank | coord | target | base | overwatch | rally | distance | attack | exposure | terrain | role | objective | lookahead |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `3,-1` | `none` | 2.20 | 3.70 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 |
| 2 | `2,1` | `none` | 2.20 | 3.70 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 |
| 3 | `2,0` | `none` | 2.20 | 3.70 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 5.20 | 0.00 | 0.00 |
| 4 | `1,0` | `none` | -0.20 | 1.30 | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 |
| 5 | `3,-2` | `none` | -0.20 | 1.30 | -inf | -3.00 | 0.00 | -1.00 | 0.00 | 3.80 | 0.00 | 0.00 |

## Hard lookahead exposure
Hard AI should expose the one-ply retaliation penalty in candidate components.

Plan: `attack` to `0,1`, target `medium_tank@0,2`, score `-0.60`.

| rank | coord | target | base | overwatch | rally | distance | attack | exposure | terrain | role | objective | lookahead |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `-1,2` | `medium_tank@0,2` | -0.60 | -4.80 | -inf | -1.00 | 6.00 | -1.40 | 0.00 | 0.00 | 0.00 | -6.00 |
| 2 | `0,1` | `medium_tank@0,2` | -0.60 | -4.80 | -inf | -1.00 | 6.00 | -1.40 | 0.00 | 0.00 | 0.00 | -6.00 |
| 3 | `1,1` | `medium_tank@0,2` | -0.60 | -4.80 | -inf | -1.00 | 6.00 | -1.40 | 0.00 | 0.00 | 0.00 | -6.00 |
| 4 | `0,-1` | `none` | -4.40 | -2.60 | -inf | -3.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | -0.00 |
| 5 | `0,-2` | `none` | -5.40 | -3.60 | -inf | -4.00 | 0.00 | -1.40 | 0.00 | 0.00 | 0.00 | -0.00 |

## Suppressed rally choice
Pinned unit in cover should show rally value competing with the attack plan.

Plan: `rally` to `0,0`, target `none`, score `19.50`.

| rank | coord | target | base | overwatch | rally | distance | attack | exposure | terrain | role | objective | lookahead |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `infantry@1,0` | 4.10 | 0.10 | 19.50 | -1.00 | 4.00 | -1.00 | 0.90 | 0.00 | 0.00 | 0.00 |
| 2 | `0,-1` | `none` | -3.00 | -3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `-1,0` | `none` | -3.00 | -3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `-1,1` | `none` | -3.00 | -3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `1,-2` | `none` | -3.00 | -3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## MG overwatch lane
MG reaction-fire profile should appear in overwatch candidate scores.

Plan: `overwatch` to `0,0`, target `none`, score `3.00`.

| rank | coord | target | base | overwatch | rally | distance | attack | exposure | terrain | role | objective | lookahead |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `0,0` | `none` | -3.00 | 3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2 | `1,-1` | `none` | -3.00 | 3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | `0,1` | `none` | -3.00 | 3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 4 | `2,-2` | `none` | -3.00 | 3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 5 | `0,2` | `none` | -3.00 | 3.00 | -inf | -2.00 | 0.00 | -1.00 | 0.00 | 0.00 | 0.00 | 0.00 |
