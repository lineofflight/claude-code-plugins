# Retro Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a two-phase plugin that silently observes session gaps and lets users consolidate them into skills and CLAUDE.md rules via `/retro`.

**Architecture:** A `hooks/observe` bash script fires on PreCompact/SessionEnd, runs Claude Haiku to classify gaps, and writes per-session files to `~/.claude/projects/<project>/retro/`. A `skills/retro/SKILL.md` skill reads those files and proposes batch consolidation actions.

**Tech Stack:** Bash (hook), Claude CLI (`claude --print`), Claude Code plugin system (hooks.json, SKILL.md)

**Design doc:** `docs/plans/2026-03-18-retro-design.md`

---

### Task 1: Plugin scaffold

**Files:**
- Create: `plugins/retro/.claude-plugin/plugin.json`

**Step 1: Create plugin.json**

```json
{
  "name": "retro",
  "description": "Session gap extraction and skill consolidation",
  "version": "0.1.0",
  "author": { "name": "Line of Flight" },
  "repository": "https://github.com/lineofflight/claude-code-plugins"
}
```

**Step 2: Commit**

```bash
git add plugins/retro/.claude-plugin/plugin.json
git commit -m "scaffold retro plugin"
```

---

### Task 2: Observe hook

**Files:**
- Create: `plugins/retro/hooks/hooks.json`
- Create: `plugins/retro/hooks/observe`

**Step 1: Create hooks.json**

Subscribe to PreCompact and SessionEnd (on clear), both async:

```json
{
  "description": "Observe session gaps",
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/observe",
            "async": true
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "clear",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/observe",
            "async": true
          }
        ]
      }
    ]
  }
}
```

**Step 2: Create the observe hook script**

`plugins/retro/hooks/observe` — executable bash script.

Computes the project slug for `~/.claude/projects/<project>/retro/`, then calls `claude --print` with Haiku to classify gaps from the session transcript.

```bash
#!/bin/bash
# Observe: extract and classify session gaps
#
# Triggers: PreCompact, SessionEnd (on clear)
# Output: ~/.claude/projects/<project>/retro/<date>-<summary>.md

PROJECT_PATH=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROJECT_SLUG=$(echo "$PROJECT_PATH" | sed 's|^/||; s|/|-|g')
RETRO_DIR="$HOME/.claude/projects/-$PROJECT_SLUG/retro"
mkdir -p "$RETRO_DIR"

TODAY=$(date +%Y-%m-%d)

claude --print --dangerously-skip-permissions --model haiku \
  "You are a session observer. Review this session transcript for gaps worth noting.

   Classify each gap into exactly one category:
   - missing_skill: repeated manual workflow that should be a skill
   - missing_tool: needed a tool or MCP that wasn't available
   - repeated_failure: same error hit multiple times, workaround found
   - wrong_info: Claude gave incorrect information, had to be corrected
   - new_convention: pattern or preference established during the session

   If you find gaps, write ONE file using Bash to:
   $RETRO_DIR/$TODAY-<short-slug>.md

   Use this exact format:

   # Session: $TODAY - <2-5 word summary>

   - type: <category>
     summary: <one line>
     details: <one line of context>
     context: <comma-separated tags>

   Rules:
   - Use a short lowercase slug for the filename (e.g. $TODAY-flaky-tests.md)
   - Only include genuine gaps — skip routine work
   - If nothing notable happened, write nothing and exit
   - Do not create skills or modify CLAUDE.md — just record observations

   $ARGUMENTS"
```

**Step 3: Make it executable**

```bash
chmod +x plugins/retro/hooks/observe
```

**Step 4: Commit**

```bash
git add plugins/retro/hooks/hooks.json plugins/retro/hooks/observe
git commit -m "add observe hook for session gap extraction"
```

---

### Task 3: Retro skill

**Files:**
- Create: `plugins/retro/skills/retro/SKILL.md`

**Step 1: Create the skill**

```markdown
---
name: retro
description: Review session gaps and consolidate into skills or CLAUDE.md
user_invocable: true
---

# Retro

Review accumulated session observations and consolidate them into durable project knowledge.

## What to do

1. Compute the retro directory. The project slug is the absolute project path with the leading `/` stripped and remaining `/` replaced by `-`, prefixed with `-`:

   ```bash
   PROJECT_PATH=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   PROJECT_SLUG=$(echo "$PROJECT_PATH" | sed 's|^/||; s|/|-|g')
   RETRO_DIR="$HOME/.claude/projects/-$PROJECT_SLUG/retro"
   ```

2. Read all `.md` files in `$RETRO_DIR`. If the directory is empty or missing, tell the user there are no observations to review.

3. Analyze the gaps across all sessions. Group by classification and look for patterns — recurring themes, repeated categories, related contexts.

4. Propose a **batch action plan**. For each action, explain which gaps support it:

   - **Create skill** `<name>` — when 2+ gaps point to a repeated workflow
   - **Update CLAUDE.md** — when a convention applies universally to every task
   - **Discard** — one-off issues that aren't patterns

   Placement guidance:
   - CLAUDE.md: universal rules needed on every task. Burns context tokens every turn — only universal rules justify the cost.
   - Skills (`.claude/skills/{domain}/SKILL.md`): domain knowledge for specific areas. Loaded on demand.

5. Wait for user approval. They may approve, edit, or reject items.

6. Execute approved actions: create skills, update CLAUDE.md, etc.

7. Remove processed gap files from `$RETRO_DIR`. Keep any files with gaps that were deferred (not approved or discarded).
```

**Step 2: Commit**

```bash
git add plugins/retro/skills/retro/SKILL.md
git commit -m "add /retro skill for gap review and consolidation"
```

---

### Task 4: Marketplace and README

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Step 1: Add retro to marketplace.json**

Add to the `plugins` array:

```json
{
  "name": "retro",
  "source": "./plugins/retro",
  "description": "Session gap extraction and skill consolidation"
}
```

**Step 2: Add retro to README.md**

Add a row to the plugins table:

```markdown
| [retro](plugins/retro) | Session gap extraction and skill consolidation |
```

**Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "add retro plugin to marketplace"
```

---

### Task 5: Plugin README

**Files:**
- Create: `plugins/retro/README.md`

**Step 1: Write the README**

```markdown
# Retro

Session gap extraction and skill consolidation for Claude Code.

## How it works

**Observe** — A hook fires on PreCompact and SessionEnd, scanning the transcript for gaps: missing skills, missing tools, repeated failures, wrong information, and new conventions. Observations are stored per-session in `~/.claude/projects/<project>/retro/`.

**Review** — Run `/retro` to review accumulated observations. The skill analyzes gaps across sessions, proposes batch actions (create skills, update CLAUDE.md, or discard), and executes approved changes.

## Gap classifications

| Type | Description |
|------|-------------|
| `missing_skill` | Repeated manual workflow that should be encoded |
| `missing_tool` | Needed a tool or MCP that wasn't available |
| `repeated_failure` | Same error hit multiple times, workaround found |
| `wrong_info` | Claude gave incorrect information, corrected by user |
| `new_convention` | Pattern or preference established during the session |
```

**Step 2: Commit**

```bash
git add plugins/retro/README.md
git commit -m "add retro README"
```

---

### Task 6: Verify

**Step 1: Check plugin structure**

```bash
find plugins/retro -type f | sort
```

Expected:
```
plugins/retro/.claude-plugin/plugin.json
plugins/retro/README.md
plugins/retro/hooks/hooks.json
plugins/retro/hooks/observe
plugins/retro/skills/retro/SKILL.md
```

**Step 2: Verify observe is executable**

```bash
test -x plugins/retro/hooks/observe && echo "OK" || echo "FAIL"
```

Expected: `OK`

**Step 3: Verify JSON is valid**

```bash
python3 -c "import json; json.load(open('plugins/retro/.claude-plugin/plugin.json')); print('plugin.json OK')"
python3 -c "import json; json.load(open('plugins/retro/hooks/hooks.json')); print('hooks.json OK')"
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); print('marketplace.json OK')"
```

Expected: all OK

**Step 4: Verify marketplace includes retro**

```bash
python3 -c "import json; plugins = [p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']]; assert 'retro' in plugins; print('retro in marketplace OK')"
```

Expected: `retro in marketplace OK`
