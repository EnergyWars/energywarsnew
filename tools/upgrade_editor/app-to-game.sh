#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
source "$here/claude.sh"
use_ai=1
[[ "${1:-}" == "--no-ai" ]] && use_ai=0
cd "$here"
python3 -m upgrade_editor changes > "$here/data/last_changes.jsonl" || true
python3 -m upgrade_editor validate
python3 -m upgrade_editor apply
git -C "$root" --no-pager diff --no-color -- src/core/game_config.gd > "$here/data/last_config.diff" || true
echo "App -> Spiel: bearbeitete Kopie in src/core/game_config.gd übernommen (Original archiviert)."
if [[ $use_ai -eq 1 ]]; then
  cd "$root"
  run_claude "$here/prompts/app-to-game.md"
fi
