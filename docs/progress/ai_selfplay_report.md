# AI Self-Play Report

Deterministic full-battle self-play: every faction is driven by the live `AIController` through the real battle scene (`tools/selfplay_runner.gd`), so combat, morale, overwatch, reinforcements and victory all execute through game code. The engine has no RNG, so rerunning the generator yields byte-identical output until AI scoring, unit stats or scenario data change — regenerate it then with:

`godot --headless --path . --script res://tools/ai_selfplay_report.gd`

## Run matrix

HP lost = hit points destroyed from that side's pool (reinforcements counted at full strength). A exchange = B hp lost - A hp lost, from side A's seat.

| # | scenario | matchup | winner | end turn | A alive/start | A hp | B alive/start | B hp | A hp lost | B hp lost | A exchange |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | tut_00_basic_turn | allies:normal vs axis:normal | allies | 4 | 2/2 | 21 | 0/2 | 0 | 5 | 11 | 6 |
| 2 | north_00_gazala_1942 | axis:easy vs allies:easy | axis | 6 | 3/7 | 21 | 3/7 | 19 | 59 | 55 | -4 |
| 3 | north_00_gazala_1942 | axis:normal vs allies:normal | axis | 7 | 5/7 | 37 | 1/7 | 1 | 43 | 73 | 30 |
| 4 | north_00_gazala_1942 | axis:hard vs allies:hard | axis | 8 | 5/7 | 31 | 1/7 | 4 | 49 | 70 | 21 |
| 5 | pacific_01_guadalcanal_1942 | allies:easy vs axis:easy | axis | 9 | 0/6 | 0 | 3/6 | 12 | 56 | 40 | -16 |
| 6 | pacific_01_guadalcanal_1942 | allies:normal vs axis:normal | axis | 10 | 0/6 | 0 | 4/6 | 19 | 56 | 33 | -23 |
| 7 | pacific_01_guadalcanal_1942 | allies:hard vs axis:hard | axis | 11 | 1/6 | 2 | 5/6 | 27 | 54 | 25 | -29 |
| 8 | east_06_dnieper_1943 | soviet:normal vs axis:normal | soviet | 9 | 5/6 | 61 | 0/6 | 0 | 29 | 58 | 29 |
| 9 | north_00_gazala_1942 | axis:hard vs allies:easy | axis | 7 | 4/7 | 33 | 0/7 | 0 | 47 | 74 | 27 |
| 10 | north_00_gazala_1942 | axis:easy vs allies:hard | axis | 3 | 6/7 | 62 | 6/7 | 62 | 18 | 12 | -6 |
| 11 | pacific_01_guadalcanal_1942 | allies:hard vs axis:easy | allies | 11 | 3/6 | 12 | 0/6 | 0 | 44 | 52 | 8 |
| 12 | pacific_01_guadalcanal_1942 | allies:easy vs axis:hard | axis | 11 | 1/6 | 5 | 3/6 | 15 | 51 | 37 | -14 |

## Difficulty ladder

For each scenario the attacking seat plays hard-vs-easy and easy-vs-hard. The seat's HP exchange must not get worse when it is the stronger side (exchange is zero-sum, so one comparison covers both seats).

| scenario | seat | exchange @ hard | exchange @ easy | delta | verdict |
| --- | --- | --- | --- | --- | --- |
| north_00_gazala_1942 | axis | 27 | -6 | 33 | PASS |
| pacific_01_guadalcanal_1942 | allies | 8 | -14 | 22 | PASS |

## Symmetric balance summary

Mirror matches (both sides at the same difficulty). Attacker = the scenario's first faction (capture/eliminate objective); defender wins by surviving.

| difficulty | runs | attacker wins | defender wins | mean attacker exchange |
| --- | --- | --- | --- | --- |
| easy | 2 | 1 | 1 | -10.0 |
| normal | 4 | 3 | 1 | 10.5 |
| hard | 2 | 1 | 1 | -4.0 |

## Notes

- No pathologies detected: every run resolved with a winner and two-sided contact.
