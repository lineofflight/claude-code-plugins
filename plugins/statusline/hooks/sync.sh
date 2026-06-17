#!/usr/bin/env bash
# Sync the bundled status-line script to a stable, user-owned path.
#
# The main `statusLine` setting lives in the user's settings.json, which is NOT
# a plugin context — so it can't reference ${CLAUDE_PLUGIN_ROOT}, and the plugin
# install path changes on every update anyway. So settings.json points at a fixed
# path (~/.claude/statusline.sh) and this hook keeps that copy current.
#
# Runs on SessionStart: status-line updates from plugin upgrades apply on the next
# session with no manual step. If the plugin is later removed, this stops running
# and the last-synced copy persists, so the status line keeps working.
set -euo pipefail

# CLAUDE_PLUGIN_ROOT is set when invoked as a hook; fall back to our own location
# so the script also works when run directly (e.g. from setup.sh).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${CLAUDE_PLUGIN_ROOT:-$(dirname "$here")}"
src="$root/scripts/statusline.sh"
dest="$HOME/.claude/statusline.sh"

[ -f "$src" ] || exit 0
mkdir -p "$HOME/.claude"

# Copy only when content differs, to avoid needless writes every session.
if ! cmp -s "$src" "$dest" 2>/dev/null; then
  cp "$src" "$dest"
  chmod +x "$dest"
fi
