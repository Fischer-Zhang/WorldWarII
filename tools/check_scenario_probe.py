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
        and "axis: eng min 7, art 0/6, targets 6" in report,
        "Stalingrad breach probe should show forward Axis engineer approach",
    )
    require(
        "01_sedan_1940" in report
        and "中路渡口 13,5 recon min 9 XP 1" in report,
        "Sedan probe should show recon secondary objective pressure",
    )
    require(
        "03_stalingrad_1942" in report
        and "突擊工兵 13,10 destroy min 7 XP 1, enemy supp +1 R2" in report
        and "06_market_garden_1944" in report
        and "德軍遠程砲 18,2 destroy min 12 XP 1" in report,
        "Destroy secondary objectives should be included in pressure probes",
    )
    require(
        "03_stalingrad_1942" in report
        and "axis: eng turns 3" in report
        and "axis: art move 1/6" in report,
        "Stalingrad tempo probe should show supported breach timing",
    )
    require(
        "east_10_berlin_1945" in report
        and "soviet: eng min 7, art 0/3, targets 3" in report,
        "Berlin breach probe should show forward Soviet engineer approach",
    )
    require(
        "east_10_berlin_1945" in report
        and "soviet: eng turns 3" in report
        and "soviet: art move 1/3" in report,
        "Berlin tempo probe should show supported breach timing",
    )
    require(
        "| 03_stalingrad_1942 | axis | 6/6 | 7 | 3 | 0/6 | 1/6 | supported |"
        in report,
        "Stalingrad urban breach focus should show supported breach access",
    )
    require(
        "| east_10_berlin_1945 | soviet | 3/3 | 7 | 3 | 0/3 | 1/3 | supported |"
        in report,
        "Berlin urban breach focus should show supported breach access",
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
        and "清除西側 MG 42 | destroy 18,3 | soviet | own 9 / enemy 0 | XP 1, repair 2, enemy supp +1 R2 | enemy closer; damage recovery; tactical suppression reward R2"
        in report,
        "Reward audit should show Berlin repair and local suppression reward pressure",
    )
    require(
        "03_stalingrad_1942" in report
        and "突擊工兵 | destroy 13,10 | soviet | own 7 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2"
        in report,
        "Reward audit should show Stalingrad local suppression counter-assault reward",
    )
    require(
        "east_10_berlin_1945" in report
        and "標定重砲陣地 | recon 22,2 | soviet | own 13 / enemy 0 | XP 1, enemy dig -1 R2, campaign +1p | enemy closer; breach reward R2; campaign bonus +1"
        in report,
        "Reward audit should show Berlin recon breach reward and campaign bonus pressure",
    )
    print("Scenario probe checks passed")


if __name__ == "__main__":
    main()
