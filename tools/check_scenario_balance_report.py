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
    require(
        "中路渡口 [recon 13,5]" in report,
        "Sedan should show the recon secondary objective with its target",
    )
    require(
        "突擊工兵 [destroy 突擊工兵@13,10 after stalingrad_spot_engineers branch stalingrad_counterattack]" in report
        and "德軍遠程砲 [destroy 150 mm sFH@18,2 after nijmegen_south_bridgehead]" in report
        and "壓制馬克沁火點 [destroy Maxim@4,4 after southern_sweep]" in report,
        "Destroy secondary objectives should show their marked unit targets",
    )
    require(
        "橋面工兵補給 [capture 10,12 after nijmegen_south_bridgehead] (XP 1, supp -2, repair 1)" in report,
        "Market Garden should expose the bridge engineer sustain cache",
    )
    require(
        "標定岸防砲廓 [recon 20,4 after carrier_lagoon_anchor] (enemy dig -1 R2, conquest fort -1)" in report,
        "Pacific carrier should expose the chained conquest fortification pressure objective",
    )
    require("east_10_berlin_1945" in report, "scenario report missing Berlin row")
    require(
        "soviet: eng 1, art 1, rocket 0, mg 0" in report,
        "Berlin should show the Soviet assault group has an engineer and artillery",
    )
    require(
        "最後突擊集結點 [hold 2t 18,4 after locate_heavy_battery] (XP 1, supp -2, enemy supp +1 R1)" in report,
        "Berlin should expose the final assault staging objective",
    )
    require(
        "前線救護站 [capture 5,5 after clear_western_at] (XP 1, supp -2, repair 1)" in report,
        "Aachen should expose the urban sustain objective",
    )
    print("Scenario balance report checks passed")


if __name__ == "__main__":
    main()
