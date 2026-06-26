#!/usr/bin/env bash
# Fast validation without Godot. Used by the full validation script.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Engine-version gate: the project is pinned to Godot 4.2. A newer editor silently
# rewrites this tag (and can introduce e.g. the native Wayland backend), which is a
# known cross-device footgun — fail loudly so it never reaches another machine.
EXPECTED_FEATURE='config/features=PackedStringArray("4.2", "GL Compatibility")'
if ! grep -qF "$EXPECTED_FEATURE" project.godot; then
  echo "project.godot config/features drifted from the pinned Godot 4.2 tag." >&2
  echo "Expected: $EXPECTED_FEATURE" >&2
  echo "Found:    $(grep -F 'config/features=' project.godot || echo '(missing)')" >&2
  echo "Open the project in Godot 4.2.2 (not a newer editor) and revert the rewrite." >&2
  exit 1
fi

python3 -m json.tool data/units.json >/tmp/worldwar2_units_check.json
python3 -m json.tool docs/progress/baselines/units_pre_balance_patch.json >/tmp/worldwar2_units_baseline_check.json
python3 -m py_compile \
  tools/balance_report.py \
  tools/check_scenario_balance_report.py \
  tools/scenario_balance_report.py \
  tools/scenario_probe.py \
  tools/tutorial_probe.py \
  tools/validate_data.py
python3 tools/validate_data.py
python3 tools/balance_report.py --baseline docs/progress/baselines/units_pre_balance_patch.json
python3 tools/scenario_balance_report.py
python3 tools/check_scenario_balance_report.py
python3 tools/scenario_probe.py
python3 tools/tutorial_probe.py
git diff --check

rm -rf tools/__pycache__
