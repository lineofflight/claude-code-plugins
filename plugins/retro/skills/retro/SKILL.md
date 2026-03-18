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
