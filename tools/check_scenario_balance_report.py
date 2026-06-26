#!/usr/bin/env python3
"""Focused checks for scenario balance report diagnostics."""

from __future__ import annotations

import scenario_balance_report


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    report = scenario_balance_report.generate_report()
    require("urban breach tools" in report, "scenario report missing urban breach tools column")
    require("03_stalingrad_1942" in report, "scenario report missing Stalingrad row")
    require(
        "axis: eng 1, art 1, rocket 0, mg 1" in report,
        "Stalingrad should show Axis has an engineer and artillery after siege tuning",
    )
    require(
        "03_stalingrad_1942 | 史達林格勒巷戰 1942" in report
        and "high town density: dig-in pacing risk" in report,
        "Stalingrad should still flag dense urban dig-in pacing risk",
    )
    require("east_10_berlin_1945" in report, "scenario report missing Berlin row")
    require(
        "soviet: eng 1, art 1, rocket 0, mg 0" in report,
        "Berlin should show the Soviet assault group has an engineer and artillery",
    )
    print("Scenario balance report checks passed")


if __name__ == "__main__":
    main()
