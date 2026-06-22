#!/usr/bin/env bash
# Fast validation without Godot. Used by the full validation script.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -m json.tool data/units.json >/tmp/worldwar2_units_check.json
python3 -m json.tool docs/progress/baselines/units_pre_balance_patch.json >/tmp/worldwar2_units_baseline_check.json
python3 -m py_compile tools/balance_report.py tools/scenario_balance_report.py tools/scenario_probe.py
python3 tools/balance_report.py --baseline docs/progress/baselines/units_pre_balance_patch.json
python3 tools/scenario_balance_report.py
python3 tools/scenario_probe.py
git diff --check

rm -rf tools/__pycache__
