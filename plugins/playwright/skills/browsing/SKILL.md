---
name: browsing
description: Browser automation. MUST invoke before calling Playwright. Use when browsing websites, checking UI, filling forms, or automating web workflows.
---

# Browsing

**ALWAYS use a subagent for browser tasks.** Never call browser tools directly in main context — the snapshots consume thousands of tokens per page.

```
Task tool config:
  subagent_type: general-purpose
  model: haiku
```

The subagent does all navigation and interaction, then returns a concise summary.

Sessions persist per project. All tool calls in a conversation share one browser instance.

## Tips

- `browser_fill_form` for multiple fields, not `browser_type` per field
- Screenshots to check visuals (saves tokens), snapshots when you need refs
- Cache refs from first snapshot, reuse for subsequent interactions
- On token limit errors, output is auto-saved to a file — use Bash to extract what you need
