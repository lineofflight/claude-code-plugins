#!/usr/bin/env bash
# One-time wiring for the status line.
#
# A plugin can't register the main `statusLine` setting itself (Claude Code only
# honors `agent` and `subagentStatusLine` from a plugin's settings.json), so this
# does the two things install can't: copy the script to a stable path and add the
# `statusLine` entry to the user's settings.json. Idempotent — safe to re-run.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${CLAUDE_PLUGIN_ROOT:-$(dirname "$here")}"

# 1. Initial copy of the script (the SessionStart hook keeps it current after this).
bash "$root/hooks/sync.sh"
echo "Synced status-line script -> ~/.claude/statusline.sh"

# 2. Wire settings.json, preserving every other setting.
python3 - "$HOME/.claude/settings.json" <<'PY'
import json, os, sys, shutil

path = sys.argv[1]
desired = {"type": "command", "command": "bash ~/.claude/statusline.sh"}

data = {}
if os.path.exists(path):
    with open(path) as f:
        raw = f.read()
    if raw.strip():
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as e:
            sys.exit(f"ERROR: {path} is not valid JSON ({e}). Left unchanged; add statusLine by hand.")
    if not isinstance(data, dict):
        sys.exit(f"ERROR: {path} top-level is not a JSON object. Left unchanged.")

existing = data.get("statusLine")
if existing == desired:
    print("settings.json already wired - no change.")
else:
    if existing is not None:
        shutil.copy(path, path + ".bak")
        print(f"Backed up previous statusLine -> {os.path.basename(path)}.bak")
    data["statusLine"] = desired
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print('Wired statusLine -> "bash ~/.claude/statusline.sh"')
PY

echo "Done. The status line appears on your next session; the plugin keeps the script in sync automatically."
