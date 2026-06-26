#!/usr/bin/env bash
# Full project validation entrypoint used by Codex workflow and the local git hook.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_TRACE_USER_DATA="$(mktemp -d "${TMPDIR:-/tmp}/worldwar2-ai-trace-userdata.XXXXXX")"

cleanup() {
  rm -rf "$AI_TRACE_USER_DATA"
  rm -rf "$ROOT/tools/__pycache__"
}
trap cleanup EXIT

"$ROOT/tools/validate_fast.sh"
cd "$ROOT"

if ! command -v godot >/dev/null 2>&1; then
  echo "godot not found on PATH — install Godot 4.2+ first" >&2
  exit 127
fi

XDG_DATA_HOME="$AI_TRACE_USER_DATA" godot --headless --path "$ROOT" --script "res://tools/ai_trace_report.gd"
git diff --check
bash tests/run_all.sh
