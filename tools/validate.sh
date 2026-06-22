#!/usr/bin/env bash
# Full project validation entrypoint used by Codex workflow and the local git hook.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/tools/validate_fast.sh"
cd "$ROOT"
bash tests/run_all.sh

rm -rf tools/__pycache__
