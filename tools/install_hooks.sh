#!/usr/bin/env bash
# Install local git hooks for this repository.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.git/hooks/pre-commit"

mkdir -p "$(dirname "$HOOK")"
cat >"$HOOK" <<'HOOK_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
exec "$(git rev-parse --show-toplevel)/tools/validate.sh"
HOOK_SCRIPT
chmod +x "$HOOK"

echo "Installed $HOOK"
