#!/usr/bin/env python3
"""Focused checks for scenario tactical probe diagnostics."""

from __future__ import annotations

import scenario_probe


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    report = scenario_probe.generate_report()
    require("breach path" in report, "scenario probe missing breach path column")
    require(
        "03_stalingrad_1942" in report
        and "axis: eng min 18, art 0/6, targets 6" in report,
        "Stalingrad breach probe should expose long Axis engineer approach",
    )
    require(
        "east_10_berlin_1945" in report
        and "soviet: eng min 17, art 0/3, targets 3" in report,
        "Berlin breach probe should expose long Soviet engineer approach",
    )
    require(
        "tut_03_suppression_digin_engineer" in report
        and "allies: eng min 1, art 2/2, targets 2" in report,
        "Tutorial breach probe should detect close engineer and artillery support",
    )
    print("Scenario probe checks passed")


if __name__ == "__main__":
    main()
