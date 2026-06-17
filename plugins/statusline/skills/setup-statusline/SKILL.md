---
name: setup-statusline
description: Install the bundled status line — copy the script to ~/.claude/statusline.sh and wire it into settings.json. Use right after installing the statusline plugin. Re-running is safe and idempotent.
user_invocable: true
---

# setup-statusline

Wire this plugin's status line into the user's Claude Code config. A plugin can't
register the main `statusLine` setting on its own, so this one-time step does it.

Run the bundled setup script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh"
```

It:

1. Copies `statusline.sh` to `~/.claude/statusline.sh` — a stable path that survives
   uninstalling the plugin (a `SessionStart` hook keeps it in sync after this).
2. Adds a `statusLine` entry to `~/.claude/settings.json`, preserving every other
   setting. If a different `statusLine` was already set, it backs up `settings.json`
   to `settings.json.bak` first.

Then report to the user exactly what the script printed (synced path, whether
settings.json changed or was already wired, any backup), and tell them the status
line shows up on their next session — or right away if they restart Claude Code.

If the script aborts because `settings.json` isn't valid JSON, surface that error and
do NOT try to hand-edit the file blindly — show the user the broken file first.
