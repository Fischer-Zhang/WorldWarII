#!/usr/bin/env python3
"""Smoke checks for the generated AI self-play report.

Pins the run-matrix structure and robust invariants (clean resolution,
sane bookkeeping, difficulty-ladder verdicts recomputed from the table)
without pinning exact HP/casualty values — those legitimately move with
every AI or balance change, at which point the report is regenerated.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "docs" / "progress" / "ai_selfplay_report.md"

# (scenario, matchup) per run-matrix row, in order. Matchup strings encode the
# faction order (side A first) and per-side difficulty.
EXPECTED_RUNS = [
    ("tut_00_basic_turn", "allies:normal vs axis:normal"),
    ("north_00_gazala_1942", "axis:easy vs allies:easy"),
    ("north_00_gazala_1942", "axis:normal vs allies:normal"),
    ("north_00_gazala_1942", "axis:hard vs allies:hard"),
    ("pacific_01_guadalcanal_1942", "allies:easy vs axis:easy"),
    ("pacific_01_guadalcanal_1942", "allies:normal vs axis:normal"),
    ("pacific_01_guadalcanal_1942", "allies:hard vs axis:hard"),
    ("east_06_dnieper_1943", "soviet:normal vs axis:normal"),
    ("north_00_gazala_1942", "axis:hard vs allies:easy"),
    ("north_00_gazala_1942", "axis:easy vs allies:hard"),
    ("pacific_01_guadalcanal_1942", "allies:hard vs axis:easy"),
    ("pacific_01_guadalcanal_1942", "allies:easy vs axis:hard"),
]

# end-turn ceiling per scenario: victory by_turn + settle buffer.
MAX_END_TURN = {
    "tut_00_basic_turn": 9,
    "north_00_gazala_1942": 14,
    "pacific_01_guadalcanal_1942": 14,
    "east_06_dnieper_1943": 16,
}

# Ladder pairs: scenario -> (seat, hard-seat matchup, easy-seat matchup).
LADDER_PAIRS = {
    "north_00_gazala_1942": ("axis", "axis:hard vs allies:easy", "axis:easy vs allies:hard"),
    "pacific_01_guadalcanal_1942": ("allies", "allies:hard vs axis:easy", "allies:easy vs axis:hard"),
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"AI self-play report check failed: {message}")


def section_text(report: str, heading: str) -> str:
    start = report.find(heading)
    require(start >= 0, f"missing section {heading}")
    next_heading = report.find("\n## ", start + len(heading))
    if next_heading == -1:
        return report[start:]
    return report[start:next_heading]


def table_rows(section: str) -> list[list[str]]:
    rows = []
    for line in section.splitlines():
        if re.match(r"^\|\s*\d+\s*\|", line) or (
            line.startswith("|") and not line.startswith("| ---") and "---" not in line
        ):
            cells = [part.strip() for part in line.strip("|").split("|")]
            rows.append(cells)
    return rows


def main() -> None:
    report = REPORT_PATH.read_text(encoding="utf-8")
    require("# AI Self-Play Report" in report, "missing report title")
    require(
        "godot --headless --path . --script res://tools/ai_selfplay_report.gd" in report,
        "missing regeneration command",
    )
    require("byte-identical" in report, "missing determinism note")
    require("(stalled)" not in report, "a run stalled — investigate the driver/AI loop")
    require("(turn-cap)" not in report, "a run hit the hard turn cap without a winner")

    matrix = section_text(report, "## Run matrix")
    data_rows = [row for row in table_rows(matrix) if row and row[0].isdigit()]
    require(
        len(data_rows) == len(EXPECTED_RUNS),
        f"run matrix must have {len(EXPECTED_RUNS)} rows, found {len(data_rows)}",
    )

    exchange_by_matchup: dict[tuple[str, str], int] = {}
    for row, (scenario, matchup) in zip(data_rows, EXPECTED_RUNS):
        require(len(row) == 12, f"run matrix row malformed: {row}")
        _, row_scenario, row_matchup, winner, end_turn = row[0], row[1], row[2], row[3], row[4]
        require(row_scenario == scenario, f"expected scenario {scenario}, found {row_scenario}")
        require(row_matchup == matchup, f"expected matchup {matchup}, found {row_matchup}")
        side_a, side_b = (part.split(":")[0] for part in matchup.split(" vs "))
        require(winner in (side_a, side_b), f"{scenario}: winner {winner!r} not a faction")
        require(
            int(end_turn) <= MAX_END_TURN[scenario],
            f"{scenario}: end turn {end_turn} exceeds ceiling {MAX_END_TURN[scenario]}",
        )
        a_alive, a_start = (int(v) for v in row[5].split("/"))
        b_alive, b_start = (int(v) for v in row[7].split("/"))
        require(0 <= a_alive <= a_start and 0 <= b_alive <= b_start, f"{scenario}: survivor counts insane")
        winner_alive = a_alive if winner == side_a else b_alive
        require(winner_alive >= 1, f"{scenario}: winner {winner} has no survivors")
        require(int(row[6]) >= 0 and int(row[8]) >= 0, f"{scenario}: negative remaining HP")
        a_lost, b_lost, a_exchange = int(row[9]), int(row[10]), int(row[11])
        require(a_lost >= 0 and b_lost >= 0, f"{scenario}: negative HP lost")
        require(a_exchange == b_lost - a_lost, f"{scenario}: exchange column inconsistent")
        exchange_by_matchup[(scenario, matchup)] = a_exchange

    ladder = section_text(report, "## Difficulty ladder")
    for scenario, (seat, hard_matchup, easy_matchup) in LADDER_PAIRS.items():
        hard_x = exchange_by_matchup[(scenario, hard_matchup)]
        easy_x = exchange_by_matchup[(scenario, easy_matchup)]
        require(
            hard_x >= easy_x,
            f"{scenario}: difficulty ladder broken — {seat} exchange {hard_x} @hard < {easy_x} @easy",
        )
        row_match = re.search(
            rf"\|\s*{re.escape(scenario)}\s*\|\s*{re.escape(seat)}\s*\|\s*(-?\d+)\s*\|\s*(-?\d+)\s*\|\s*(-?\d+)\s*\|\s*(PASS|FAIL)\s*\|",
            ladder,
        )
        require(row_match is not None, f"{scenario}: missing ladder row for seat {seat}")
        require(
            int(row_match.group(1)) == hard_x and int(row_match.group(2)) == easy_x,
            f"{scenario}: ladder row disagrees with run matrix",
        )
        require(row_match.group(4) == "PASS", f"{scenario}: ladder verdict must be PASS")

    section_text(report, "## Symmetric balance summary")
    section_text(report, "## Notes")
    print("AI self-play report checks passed")


if __name__ == "__main__":
    main()
