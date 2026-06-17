# statusline

A Starship-style status line for Claude Code. One line showing:

- **Directory** — current working dir (cyan).
- **Git** — `on  <branch>` with a Nerd Font branch glyph, plus a red `*` when the working tree is dirty.
- **Model / effort** — a condensed tag like `s-m` (sonnet, medium), shown *only* when you've dropped below the coding baseline of Opus + xhigh, so it reads as an "off your usual config" flag and stays hidden otherwise.
- **Context bar** — a heavy/light rule bar colored green → yellow → red. Thresholds adapt to the window size (a 1M window redlines on absolute degradation; a 200K window redlines on proximity).
- **Rate limits** — `5h` and `7d` usage percentages. `5h` shows above 50%; `7d` uses a time-aware threshold that surfaces only when you're ahead of a sustainable linear pace through the week.

Requires a Nerd Font for the git glyph, and `jq` on PATH.

## Install

```
/plugin install statusline@lineofflight
/setup-statusline
```

A Claude Code plugin **can't register the main status line itself** — `settings.json`'s `statusLine` key isn't one a plugin may set (only `agent` and `subagentStatusLine` are). So `/setup-statusline` does the one-time wiring: it copies the script to `~/.claude/statusline.sh` and adds the `statusLine` entry to your `settings.json` (preserving everything else; backing up first if you already had one).

## How updates and removal work

`settings.json` points at a stable, user-owned path — `~/.claude/statusline.sh` — never at the plugin's install directory (which changes on every plugin update and is cleaned up days later).

- **Updates are seamless.** A `SessionStart` hook re-syncs `~/.claude/statusline.sh` from the plugin's bundled copy each session, so an upgraded script applies on your next session with no manual step.
- **Removal is safe.** Uninstall the plugin and the hook simply stops; the last-synced copy stays in place and the status line keeps working — leaving you with the same standalone script you'd have written by hand.

To pick up a script change without starting a new session, re-run `/setup-statusline`.

## Editing

The source of truth is `scripts/statusline.sh` in this plugin — edit it there (and bump the version in `plugin.json`). The hook overwrites `~/.claude/statusline.sh` from it, so local edits to the copy are replaced on the next session.
