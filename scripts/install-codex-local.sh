#!/usr/bin/env bash
set -euo pipefail

kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tgoskits_repo="${1:-${TGOSKITS_REPO:-}}"

if [[ -z "$tgoskits_repo" ]]; then
  echo "usage: scripts/install-codex-local.sh /path/to/tgoskits" >&2
  exit 2
fi

if [[ ! -d "$tgoskits_repo/os/StarryOS" || ! -f "$tgoskits_repo/Cargo.toml" ]]; then
  echo "not a TGOSKits checkout: $tgoskits_repo" >&2
  exit 2
fi

python_bin="${PYTHON:-}"
if [[ -z "$python_bin" ]]; then
  python_bin="$(command -v python3.13 || command -v python3)"
fi

mkdir -p "$HOME/.codex/skills"
ln -sfn "$kit_root/skills/starry-syscall-harness" "$HOME/.codex/skills/starry-syscall-harness"

if command -v codex >/dev/null 2>&1; then
  codex mcp remove starry-syscall-harness >/dev/null 2>&1 || true
  codex mcp add starry-syscall-harness -- \
    "$python_bin" \
    "$kit_root/tools/starry-syscall-harness/mcp_server.py" \
    --repo "$tgoskits_repo"
else
  echo "codex CLI not found; skill symlink installed, MCP registration skipped" >&2
fi

echo "installed starry-syscall-harness skill"
echo "TGOSKits repo: $tgoskits_repo"
echo "Python: $python_bin"
