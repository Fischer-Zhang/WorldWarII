#!/usr/bin/env python3
"""Focused checks for scenario tactical probe diagnostics."""

from __future__ import annotations

import glob
import json
from pathlib import Path

import scenario_probe


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    report = scenario_probe.generate_report()
    main_scenario_count = count_main_battle_scenarios()
    campaign_count = count_non_tutorial_campaigns()
    conquest_count = count_conquest_scenarios()
    conquest_region_count = count_conquest_regions()
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
        "## Conquest Secondary Coverage" in report
        and "| scenario | secondary objectives | strategic objectives | strategic effect mix | check |" in report,
        "scenario probe missing conquest secondary coverage section",
    )
    require(
        "## Conquest Primary Variety" in report
        and "| scenario | attack objective | objective pressure | check |" in report,
        "scenario probe missing conquest primary variety section",
    )
    require(
        "## Conquest Region Trait Coverage" in report
        and "| region | owner | logistics | traits | battle effects | check |" in report,
        "scenario probe missing conquest region trait coverage section",
    )
    require(
        "## Terrain Identity Coverage" in report
        and "| scenario | terrain theme | terrain signals | objective hooks | role hooks | check |" in report,
        "scenario probe missing terrain identity coverage section",
    )
    require(
        "## Morale Pressure Coverage" in report
        and "| scenario | pressure sources | rout window | sustain hooks | check |" in report,
        "scenario probe missing morale pressure coverage section",
    )
    require(
        "## Gameplay Depth Coverage" in report
        and "| scenario | secondary objectives | xp-only objectives | enriched objectives | check |" in report,
        "scenario probe missing gameplay depth coverage section",
    )
    require(
        "## Operation Chain Coverage" in report
        and "| scenario | chain links | longest chain | operation path | reward ladder | check |" in report,
        "scenario probe missing operation chain coverage section",
    )
    require(
        "## Objective Branch Coverage" in report
        and "| scenario | branch | options | choices | reward families | check |" in report,
        "scenario probe missing objective branch coverage section",
    )
    require(
        "## Campaign Strategic Reward Coverage" in report
        and "| campaign | scenarios | campaign reward objectives | reward scenarios | reward paths | check |" in report,
        "scenario probe missing campaign strategic reward coverage section",
    )
    require(
        "## Scenario Expansion Coverage" in report
        and "| campaign | scenarios | victory mix | special terrain | role hooks | check |" in report,
        "scenario probe missing scenario expansion coverage section",
    )
    require(
        "03_stalingrad_1942" in report
        and "axis: eng min 7, art 0/6, targets 6" in report,
        "Stalingrad breach probe should show forward Axis engineer approach",
    )
    require(
        "01_sedan_1940" in report
        and "中路渡口 13,5 recon min 9 XP 1, enemy supp +1 R2" in report,
        "Sedan probe should show recon secondary objective pressure",
    )
    require(
        "03_stalingrad_1942" in report
        and "突擊工兵 13,10 destroy after stalingrad_spot_engineers branch stalingrad_counterattack min 7 XP 1, enemy supp +1 R2" in report
        and "06_market_garden_1944" in report
        and "德軍遠程砲 18,2 destroy after nijmegen_south_bridgehead min 12 XP 1, enemy supp +1 R2" in report
        and "壓制馬克沁火點 4,4 destroy after southern_sweep min 19 XP 1, enemy supp +1 R2" in report,
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
    morale_section = section_text(report, "## Morale Pressure Coverage")
    morale_rows = [
        line for line in morale_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| scenario |")
    ]
    require(
        len(morale_rows) == main_scenario_count,
        "Morale pressure coverage should include every main battle",
    )
    require(
        "| 03_stalingrad_1942 | axis artillery:1, mg_team:1; soviet mg_team:2, rocket_artillery:1 |"
        in report,
        "Stalingrad morale coverage should include rocket and MG pressure sources",
    )
    require(
        "| 05_bastogne_1944 | allies artillery:1, mg_team:1; axis artillery:1 |"
        in report
        and "counter-suppress:1, recover:1, reinforce:1, repair:1"
        in report,
        "Bastogne morale coverage should expose both pressure and sustain hooks",
    )
    require(
        "| east_10_berlin_1945 | axis artillery:1, mg_team:2; soviet artillery:1 |"
        in report
        and "counter-suppress:2, recover:1, repair:1"
        in report,
        "Berlin morale coverage should expose dense defensive pressure and assault sustain hooks",
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
        "02_kiev_1941" in report
        and "南翼掃蕩 | recon 3,13 | axis | own 18 / enemy 0 | XP 1, enemy dig -1 R2 | enemy closer; breach reward R2"
        in report,
        "Reward audit should show Kiev recon breach reward pressure",
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
        and "突擊工兵 | destroy 13,10 after stalingrad_spot_engineers branch stalingrad_counterattack | soviet | own 7 / enemy 0 | XP 1, enemy supp +1 R2 | enemy closer; tactical suppression reward R2"
        in report,
        "Reward audit should show Stalingrad local suppression counter-assault reward",
    )
    require(
        "east_10_berlin_1945" in report
        and "標定重砲陣地 | recon 22,2 after clear_western_mg | soviet | own 13 / enemy 0 | XP 1, enemy dig -1 R2, campaign +1p | enemy closer; breach reward R2; campaign bonus +1"
        in report,
        "Reward audit should show Berlin recon breach reward and campaign bonus pressure",
    )
    require(
        "06_market_garden_1944" in report
        and "橋面工兵補給 | capture 10,12 after nijmegen_south_bridgehead | allies | own 8 / enemy 10 | XP 1, supp -2, repair 1 | sustain reward; damage recovery"
        in report,
        "Reward audit should show Market Garden bridge sustain cache",
    )
    require(
        "west_09_aachen_1944" in report
        and "前線救護站 | capture 5,5 after clear_western_at | allies | own 4 / enemy 1 | XP 1, supp -2, repair 1 | enemy closer; sustain reward; damage recovery"
        in report,
        "Reward audit should show Aachen urban sustain branch",
    )
    require(
        "east_10_berlin_1945" in report
        and "最後突擊集結點 | hold 2t 18,4 after locate_heavy_battery | soviet | own 8 / enemy 0 | XP 1, supp -2, enemy supp +1 R1 | enemy closer; sustain reward; tactical suppression reward R1"
        in report,
        "Reward audit should show Berlin final assault staging reward",
    )
    conquest_section = section_text(report, "## Conquest Secondary Coverage")
    conquest_rows = [
        line for line in conquest_section.splitlines()
        if line.startswith("| conq_") and line.endswith("| covered |")
    ]
    require(
        len(conquest_rows) == conquest_count,
        "Every conquest template should have covered strategic secondary pressure",
    )
    for line in conquest_rows:
        parts = [part.strip() for part in line.strip("|").split("|")]
        require(len(parts) >= 5, "Conquest secondary coverage rows should expose all columns")
        scenario_id = parts[0]
        secondary_count = int(parts[1])
        strategic_count = int(parts[2])
        effect_mix = parts[3]
        require(
            secondary_count >= 2 and strategic_count >= 2,
            f"{scenario_id} should have at least two conquest secondary objectives",
        )
        require(
            strategic_count == secondary_count and "strength -" in effect_mix,
            f"{scenario_id} should make every conquest secondary objective apply strategic pressure",
        )
        effect_axes = sum(1 for marker in ["strength -", "fort -", "production -"] if marker in effect_mix)
        require(
            effect_axes >= 2,
            f"{scenario_id} should mix at least two conquest strategic effect axes",
        )
    require(
        "| conq_cbi_jungle | 2 | 2 | strength -2, fort -1 | covered |" in report
        and "| conq_middle_east_oilfields | 2 | 2 | strength -2, production -1 | covered |" in report,
        "Conquest secondary coverage should expose varied strategic effect amounts",
    )
    require(
        "| conq_pacific_carrier | 3 | 3 | strength -1, fort -1, production -1 | covered |" in report
        and "標定岸防砲廓 | recon 20,4 after carrier_lagoon_anchor | allies | own 18 / enemy 2 | enemy dig -1 R2, conquest fort -1 | enemy closer; breach reward R2; conquest fort -1"
        in report,
        "Pacific carrier conquest coverage should expose chained three-axis strategic pressure",
    )
    conquest_primary_section = section_text(report, "## Conquest Primary Variety")
    conquest_primary_rows = [
        line for line in conquest_primary_section.splitlines()
        if line.startswith("| conq_")
    ]
    require(
        len(conquest_primary_rows) == conquest_count,
        "Conquest primary variety should include every conquest template",
    )
    require(
        all(line.endswith("| varied |") for line in conquest_primary_rows),
        "Every conquest template should use a varied attack objective instead of fallback eliminate",
    )
    primary_objective_mix = {
        line.strip("|").split("|")[1].strip().split(" ", 1)[0]
        for line in conquest_primary_rows
    }
    require(
        {"capture", "control", "hold"}.issubset(primary_objective_mix),
        "Conquest primary variety should include capture, control_count and hold objectives",
    )
    region_trait_section = section_text(report, "## Conquest Region Trait Coverage")
    region_trait_rows = [
        line for line in region_trait_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| region |")
    ]
    require(
        len(region_trait_rows) == conquest_region_count,
        "Conquest region trait coverage should include every conquest-map region",
    )
    require(
        all(line.endswith("| covered |") for line in region_trait_rows),
        "Every conquest region trait row should be covered",
    )
    trait_ids = set()
    region_ids = set()
    for line in region_trait_rows:
        parts = [part.strip() for part in line.strip("|").split("|")]
        require(len(parts) >= 6, "Conquest region trait rows should expose all columns")
        region_ids.add(parts[0])
        for trait_id in parts[3].split(","):
            trait_id = trait_id.strip()
            if trait_id and trait_id != "none":
                trait_ids.add(trait_id)
        require(parts[4] != "none", f"{parts[0]} should expose tactical trait effects")
    require(
        set(scenario_probe.REGION_TRAIT_EFFECTS.keys()).issubset(trait_ids),
        "Conquest region trait coverage should use every allowed trait family",
    )
    require(
        {"north_america", "atlantic", "britain", "germany", "poland", "ukraine", "moscow",
         "maghreb", "egypt", "middle_east", "north_pacific", "pacific", "central_pacific",
         "japan_home"}.issubset(region_ids),
        "Conquest region trait coverage should include all theater objective regions",
    )
    require(
        "| japan_home | japan | prod 5, supply, port, rail 1 | industrial_hub, rail_junction, fortress_line, naval_base, airfield_network | strength +2, support mg_team:1, XP +2 | covered |"
        in report
        and "| india | britain | prod 4, supply, port, rail 3 | industrial_hub, rail_junction, jungle_front | strength +1, support infantry:1, XP +1 | covered |"
        in report
        and "| middle_east | neutral | prod 4, port | oilfield, naval_base, airfield_network | strength +2, XP +1 | covered |"
        in report,
        "Conquest region trait coverage should expose capital, jungle and oilfield examples",
    )
    terrain_section = section_text(report, "## Terrain Identity Coverage")
    terrain_rows = [
        line for line in terrain_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| scenario |")
    ]
    require(
        len(terrain_rows) == main_scenario_count + conquest_count,
        "Terrain identity coverage should include every non-tutorial battle and conquest template",
    )
    require(
        not any("| needs terrain hook |" in line or "| partial |" in line for line in terrain_rows),
        "Terrain identity coverage should not contain missing or partial terrain hooks",
    )
    require(
        "| conq_desert_north_africa | desert, mountain | desert:82%, mountain:7% |" in report
        and "| conq_cbi_jungle | jungle | jungle:88% |" in report
        and "| east_10_berlin_1945 | town | town:60% |" in report
        and "| west_10_remagen_1945 | river | forest:10%, river:5% |" in report,
        "Terrain identity coverage should expose desert, jungle, city and bridge/river representatives",
    )
    require(
        "| pacific_02_tarawa_1943 | jungle, sea | jungle:12%, sea:11%, town:6% |" in report
        and "targets town:3 | armor:1, artillery:1, engineer:1, mg:1, scout:1, suppression:1 | covered |" in report,
        "Terrain identity coverage should expose Pacific island assault hooks",
    )
    depth_section = section_text(report, "## Gameplay Depth Coverage")
    depth_rows = [
        line for line in depth_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| scenario |")
    ]
    require(len(depth_rows) == main_scenario_count, "Gameplay depth coverage should include every main battle")
    require(
        not any("| missing secondary |" in line for line in depth_rows),
        "Every main battle should have secondary objective pressure",
    )
    xp_only_counts = []
    secondary_counts = []
    enriched_counts = []
    for line in depth_rows:
        parts = [part.strip() for part in line.strip("|").split("|")]
        if len(parts) >= 5:
            secondary_counts.append(int(parts[1]))
            xp_only_counts.append(int(parts[2]))
            enriched_counts.append(int(parts[3]))
    require(
        xp_only_counts
        and all(count == 0 for count in xp_only_counts)
        and any("| covered |" in line for line in depth_rows),
        "Every main battle secondary objective should be tactically enriched",
    )
    require(
        secondary_counts
        and all(count >= 2 for count in secondary_counts)
        and all(count >= 2 for count in enriched_counts),
        "Every main battle should have at least two enriched secondary objectives",
    )
    require(
        "| west_08_normandy_cobra_1944 | 2 | 0 | 2 | covered |" in report
        and "| 06_market_garden_1944 | 3 | 0 | 3 | covered |" in report
        and "| east_10_berlin_1945 | 3 | 0 | 3 | covered |" in report
        and "| west_09_aachen_1944 | 3 | 0 | 3 | covered |" in report,
        "Gameplay depth coverage should expose enriched objective counts",
    )
    operation_section = section_text(report, "## Operation Chain Coverage")
    operation_rows = [
        line for line in operation_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| scenario |")
    ]
    require(
        len(operation_rows) == main_scenario_count,
        "Operation chain coverage should include every main battle",
    )
    require(
        not any("| missing chain |" in line or "| broken chain |" in line for line in operation_rows),
        "Every main battle should have at least one secondary objective operation chain",
    )
    require(
        all("| covered |" in line for line in operation_rows),
        "Every operation chain row should be covered",
    )
    require(
        "| 03_stalingrad_1942 | 2 | 2 | 標定突擊路線 -> 突擊工兵 | breach -> suppression | covered |" in report
        and "| east_10_berlin_1945 | 2 | 3 | 清除西側 MG 42 -> 標定重砲陣地 -> 最後突擊集結點 | repair+suppression -> breach+campaign -> sustain+suppression | covered |" in report
        and "| west_10_remagen_1945 | 1 | 2 | 奪取橋西岸 -> 偵察東岸橋頭 | repair -> breach | covered |" in report,
        "Operation chain coverage should expose staged breach and bridgehead examples",
    )
    branch_section = section_text(report, "## Objective Branch Coverage")
    branch_rows = [
        line for line in branch_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| scenario |")
    ]
    require(
        branch_rows and all(line.endswith("| covered |") for line in branch_rows),
        "Every objective branch row should be covered",
    )
    require(
        len(branch_rows) >= 9,
        "Objective branch coverage should include at least nine explicit branch choices",
    )
    branch_scenarios = {
        line.strip("|").split("|")[0].strip()
        for line in branch_rows
    }
    require(
        len(branch_scenarios) >= 9,
        "Objective branch coverage should span at least nine main battles",
    )
    require(
        {
            "01_sedan_1940",
            "east_05_kharkov_1943",
            "north_04_bizerte_1943",
            "pacific_05_iwo_jima_1945",
            "pacific_05_okinawa_1945",
            "west_08_pegasus_bridge_1944",
        }.issubset(branch_scenarios),
        "Objective branch coverage should preserve newly branched campaign scenarios",
    )
    branch_reward_families = [
        part.strip()
        for line in branch_rows
        for part in line.strip("|").split("|")[4].split("/")
    ]
    require(
        any("campaign" in family for family in branch_reward_families)
        and any("repair" in family for family in branch_reward_families)
        and any("suppression" in family for family in branch_reward_families)
        and any("breach" in family for family in branch_reward_families),
        "Objective branch coverage should expose campaign, repair, suppression and breach tradeoffs",
    )
    require(
        "| 03_stalingrad_1942 | stalingrad_counterattack | 2 | 突擊工兵 / 迫砲觀測所 | suppression / sustain | covered |" in report
        and "| 05_bastogne_1944 | bastogne_relief_choice | 2 | 南側遠程砲 / 野戰醫護站 | suppression / repair | covered |" in report,
        "Objective branch coverage should expose mutually exclusive tactical choices",
    )
    require(
        "| 01_sedan_1940 | sedan_crossing_choice | 2 | 橋頭補給 / 清除南翼機槍 | repair / suppression+campaign | covered |" in report
        and "| pacific_05_iwo_jima_1945 | iwo_airfield_choice | 2 | 偵察北側洞窟 / 摧毀島內山砲 | breach+campaign / suppression | covered |" in report,
        "Objective branch coverage should expose strategic campaign reward tradeoffs",
    )
    campaign_reward_section = section_text(report, "## Campaign Strategic Reward Coverage")
    campaign_reward_rows = [
        line for line in campaign_reward_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| campaign |")
    ]
    require(
        len(campaign_reward_rows) == campaign_count,
        "Campaign strategic reward coverage should include every non-tutorial campaign",
    )
    require(
        all(line.endswith("| covered |") for line in campaign_reward_rows),
        "Every non-tutorial campaign should expose at least one campaign reward objective",
    )
    total_campaign_rewards = 0
    for line in campaign_reward_rows:
        parts = [part.strip() for part in line.strip("|").split("|")]
        require(len(parts) >= 6, "Campaign reward coverage rows should expose all columns")
        campaign_id = parts[0]
        scenario_count = int(parts[1])
        reward_count = int(parts[2])
        reward_paths = parts[4]
        require(scenario_count > 0, f"{campaign_id} should include scenario coverage")
        require(reward_count > 0 and "+1p" in reward_paths, f"{campaign_id} should include campaign bonus paths")
        total_campaign_rewards += reward_count
    require(
        total_campaign_rewards >= 8,
        "Formal campaigns should expose at least eight campaign bonus objectives",
    )
    require(
        "| blitzkrieg_early_war | 5 | 1 | 01_sedan_1940 | 01_sedan_1940:清除南翼機槍 +1p | covered |" in report
        and "| pacific_front | 6 | 3 | pacific_04_manila_1945, pacific_05_iwo_jima_1945, pacific_05_okinawa_1945 |" in report,
        "Campaign strategic reward coverage should expose early-war and Pacific bonus paths",
    )
    expansion_section = section_text(report, "## Scenario Expansion Coverage")
    expansion_rows = [
        line for line in expansion_section.splitlines()
        if line.startswith("| ")
        and not line.startswith("| ---")
        and not line.startswith("| campaign |")
    ]
    require(
        len(expansion_rows) == campaign_count,
        "Scenario expansion coverage should include every non-tutorial campaign",
    )
    require(
        any("| capture:" in line and "| " in line for line in expansion_rows)
        and any("river:" in line or "town:" in line or "desert:" in line or "jungle:" in line for line in expansion_rows)
        and any("reinforcement:" in line or "scout:" in line or "engineer:" in line or "airdrop:" in line for line in expansion_rows),
        "Scenario expansion coverage should expose victory mix, terrain and role hooks",
    )
    print("Scenario probe checks passed")


def count_main_battle_scenarios() -> int:
    total = 0
    root = Path(__file__).resolve().parents[1]
    for path in sorted(glob.glob(str(root / "data" / "scenarios" / "*.json"))):
        with Path(path).open("r", encoding="utf-8") as fh:
            scenario = json.load(fh)
        scenario_id = str(scenario.get("id", ""))
        if scenario_probe.is_main_battle_scenario(scenario_id):
            total += 1
    return total


def count_conquest_scenarios() -> int:
    total = 0
    root = Path(__file__).resolve().parents[1]
    for path in sorted(glob.glob(str(root / "data" / "scenarios" / "conq_*.json"))):
        with Path(path).open("r", encoding="utf-8") as fh:
            scenario = json.load(fh)
        scenario_id = str(scenario.get("id", ""))
        if scenario_id.startswith("conq_"):
            total += 1
    return total


def count_conquest_regions() -> int:
    root = Path(__file__).resolve().parents[1]
    with (root / "data" / "conquest_map.json").open("r", encoding="utf-8") as fh:
        conquest_map = json.load(fh)
    regions = conquest_map.get("regions", [])
    return sum(1 for region in regions if isinstance(region, dict))


def section_text(report: str, heading: str) -> str:
    section = report.split(heading, 1)[1]
    return section.split("\n## ", 1)[0]


def count_non_tutorial_campaigns() -> int:
    root = Path(__file__).resolve().parents[1]
    with (root / "data" / "campaigns.json").open("r", encoding="utf-8") as fh:
        campaigns = json.load(fh)
    return sum(1 for campaign_id in campaigns if str(campaign_id) != "00_tutorial")


if __name__ == "__main__":
    main()
