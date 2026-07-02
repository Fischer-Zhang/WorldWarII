#!/usr/bin/env python3
"""Smoke checks for generated AI trace report diagnostics."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "docs" / "progress" / "ai_trace_report.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"AI trace report check failed: {message}")


def section_text(report: str, heading: str) -> str:
    start = report.find(heading)
    require(start >= 0, f"missing section {heading}")
    next_heading = report.find("\n## ", start + len(heading))
    if next_heading == -1:
        return report[start:]
    return report[start:next_heading]


def table_row(section: str, rank: int) -> list[str]:
    prefix = f"| {rank} |"
    for line in section.splitlines():
        if line.startswith(prefix):
            return [part.strip() for part in line.strip("|").split("|")]
    require(False, f"missing rank {rank} trace row")
    return []


def main() -> None:
    report = REPORT_PATH.read_text(encoding="utf-8")
    section = section_text(report, "## Secondary objective pull")
    match = re.search(
        r"secondary:forward_cache[^`]*rv([0-9.]+) rp([0-9.]+) fv([0-9.]+) fp([0-9.]+)",
        section,
    )
    require(match is not None, "secondary objective detail lacks forward_cache reward/future fields")

    reward_value, reward_pull, future_value, future_pull = (float(value) for value in match.groups())
    require(reward_value > 0.0, "forward_cache reward value must remain visible")
    require(reward_pull > 0.0, "forward_cache reward pull must remain visible")
    require(future_value > 0.0, "forward_cache future value must remain visible")
    require(future_pull > 0.0, "forward_cache future pull must remain visible")

    denial_section = section_text(report, "## Objective denial guard")
    require(
        "| rank | coord | target | fire support | breach support | suppressive fire | base | overwatch | mark | breach | suppress | rally | distance | attack | exposure | terrain | role | primary | secondary | denial | guard | objective | objective detail | lookahead | preservation | encirclement |"
        in denial_section,
        "AI trace table must expose denial, guard and encirclement scores",
    )
    denial_match = re.search(
        r"\|\s*1\s*\|[^\n]*\|\s*([0-9.]+)\s*\|\s*[0-9.]+\s*\|\s*[0-9.-]+\s*\|\s*`[^`]*denial:control_count",
        denial_section,
    )
    require(denial_match is not None, "objective denial guard lacks top-ranked control_count detail")
    require(float(denial_match.group(1)) > 0.0, "objective denial guard must show positive denial score")

    exchange_section = section_text(report, "## Normal lookahead exchange")
    exchange_row = table_row(exchange_section, 1)
    require(
        float(exchange_row[23]) < 0.0,
        "normal difficulty must expose a net-exchange lookahead penalty",
    )

    guard_section = section_text(report, "## Victory point guard hold")
    require(
        re.search(r"Plan: `(wait|overwatch)` to `2,0`, target `none`", guard_section) is not None,
        "victory point guard should hold the defended capture hex",
    )
    guard_row = table_row(guard_section, 1)
    require(guard_row[1] == "`2,0`", "victory point guard top row must remain on the capture hex")
    require(guard_row[2] == "`none`", "victory point guard should not chase a target")
    require(float(guard_row[20]) > 0.0, "victory point guard must show positive guard score")
    require(
        "guard:capture 2,0 d0" in guard_row[22],
        "victory point guard lacks top-ranked guard capture detail",
    )
    print("AI trace report checks passed")


if __name__ == "__main__":
    main()
