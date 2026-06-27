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
    require("breach tempo" in report, "scenario probe missing breach tempo column")
    require("artillery reposition" in report, "scenario probe missing artillery reposition column")
    require("## Urban Breach Focus" in report, "scenario probe missing urban breach focus section")
    require(
        "## Secondary Objective Reward Audit" in report
        and "| scenario | objective | target | faction | distance | rewards | audit |" in report,
        "scenario probe missing secondary objective reward audit section",
    )
    require(
        "03_stalingrad_1942" in report
        and "axis: eng min 12, art 0/6, targets 6" in report,
        "Stalingrad breach probe should show tuned Axis engineer approach and artillery gap",
    )
    require(
        "01_sedan_1940" in report
        and "中路渡口 13,5 recon min 9 XP 1" in report,
        "Sedan probe should show recon secondary objective pressure",
    )
    require(
        "03_stalingrad_1942" in report
        and "突擊工兵 8,9 destroy min 12 XP 1" in report
        and "06_market_garden_1944" in report
        and "德軍遠程砲 18,2 destroy min 12 XP 1" in report,
        "Destroy secondary objectives should be included in pressure probes",
    )
    require(
        "03_stalingrad_1942" in report
        and "axis: eng turns 4" in report
        and "axis: art move 0/6" in report,
        "Stalingrad tempo probe should show improved engineer timing and poor artillery access",
    )
    require(
        "east_10_berlin_1945" in report
        and "soviet: eng min 12, art 0/3, targets 3" in report,
        "Berlin breach probe should show tuned Soviet engineer approach and artillery gap",
    )
    require(
        "east_10_berlin_1945" in report
        and "soviet: eng turns 4" in report
        and "soviet: art move 0/3" in report,
        "Berlin tempo probe should show improved engineer timing and poor artillery access",
    )
    require(
        "| 03_stalingrad_1942 | axis | 6/6 | 12 | 4 | 0/6 | 0/6 | playtest engineer survivability; no artillery breach coverage |"
        in report,
        "Stalingrad urban breach focus should keep the engineer survivability gate visible",
    )
    require(
        "| east_10_berlin_1945 | soviet | 3/3 | 12 | 4 | 0/3 | 0/3 | playtest engineer survivability; no artillery breach coverage |"
        in report,
        "Berlin urban breach focus should keep the engineer survivability gate visible",
    )
    require(
        "tut_03_suppression_digin_engineer" in report
        and "allies: eng min 1, art 2/2, targets 2" in report,
        "Tutorial breach probe should detect close engineer and artillery support",
    )
    require(
        "tut_03_suppression_digin_engineer" in report
        and "allies: eng turns 0" in report
        and "allies: art move 2/2" in report,
        "Tutorial tempo probe should show immediate engineer and artillery access",
    )
    require(
        "07_bagration_1944" in report
        and "奪取路口 | capture 3,4 | soviet | own 19 / enemy 0 | XP 1, reinforce -2t | enemy closer; reinforce best T6->T4"
        in report,
        "Reward audit should show Bagration reinforcement timing reward and pressure",
    )
    require(
        "blitz_02_dunkirk_1940" in report
        and "堅守撤退出口 | hold 2t 5,0 | allies | own 0 / enemy 18 | XP 1, supp -2 | starts held; sustain reward"
        in report,
        "Reward audit should show Dunkirk suppression recovery hold reward",
    )
    require(
        "east_10_berlin_1945" in report
        and "清除西側 MG 42 | destroy 18,3 | soviet | own 15 / enemy 0 | XP 1, repair 2 | enemy closer; damage recovery"
        in report,
        "Reward audit should show Berlin repair reward and pressure",
    )
    print("Scenario probe checks passed")


if __name__ == "__main__":
    main()
