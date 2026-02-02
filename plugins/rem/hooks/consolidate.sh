#!/bin/bash
# Consolidate: Crystallize recurring patterns into skills (~5% chance)

# Random gate + check patterns exist
[ $((RANDOM % 20)) -eq 0 ] || exit 0
[ -d .claude/rem/patterns ] || exit 0
find .claude/rem/patterns -name '*.md' -size +0 -print -quit | grep -q . || exit 0

claude --print --dangerously-skip-permissions \
  "Consolidate patterns:
   - Scan .claude/rem/patterns/ for recurring learnings (3+ occurrences)
   - Crystallize into .claude/skills/{domain}/ or CLAUDE.md
   - Prune stale entries (>30 days)

   Constraints:
   - Only project-scoped .claude/skills/
   - Keep concise"
