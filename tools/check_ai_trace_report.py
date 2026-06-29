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
    print("AI trace report checks passed")


if __name__ == "__main__":
    main()
