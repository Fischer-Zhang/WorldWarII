#!/usr/bin/env bash
# Project validation entrypoint used by Codex workflow and the local git hook.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -m json.tool data/units.json >/tmp/worldwar2_units_check.json
python3 -m json.tool docs/progress/baselines/units_pre_balance_patch.json >/tmp/worldwar2_units_baseline_check.json
python3 -m py_compile tools/balance_report.py tools/scenario_balance_report.py
python3 tools/balance_report.py --baseline docs/progress/baselines/units_pre_balance_patch.json
python3 tools/scenario_balance_report.py
git diff --check
bash tests/run_all.sh

rm -rf tools/__pycache__
