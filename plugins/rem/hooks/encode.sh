#!/bin/bash
# Encode: Extract patterns from conversation before context compaction

claude --print --dangerously-skip-permissions --model sonnet \
  "Review this session transcript for patterns worth remembering:
   - debugging with unclear root causes
   - framework/library workarounds
   - undocumented gotchas
   - codebase conventions
   - user preferences
   - brand voice/messaging
   - effective approaches
   - architectural decisions

   If any found, use Bash to append to .claude/rem/patterns/{domain}.md (mkdir -p first).

   Format:
   ### YYYY-MM-DD: Title
   - **Observation**: What
   - **Details**: Specifics
   - **Context**: When applies

   Skip if nothing notable.

   $ARGUMENTS"
