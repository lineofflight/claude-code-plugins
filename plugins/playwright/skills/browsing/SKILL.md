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

## Headed Browser

When the user needs to see or interact with the browser (OAuth, CAPTCHAs, login), open a headed browser sharing the same profile. Close the headless browser first with `browser_close`, then launch via Bash with `run_in_background: true`:

```js
const pw = require('<playwright-path>');
(async () => {
  const ctx = await pw.chromium.launchPersistentContext('<profile-path>', {
    headless: false, channel: 'chrome',
    args: ['--disable-session-crashed-bubble', '--hide-crash-restore-bubble']
  });
  const page = ctx.pages()[0] || await ctx.newPage();
  await page.goto('<url>');
  await page.waitForEvent('close').catch(() => {});
  await ctx.close();
})();
```

To find the values:
- **playwright-path**: `find ~/.npm/_npx -path '*/@playwright/mcp' -type d` → sibling `playwright` package
- **profile-path**: `~/Library/Caches/ms-playwright/mcp-chrome-<hash>` where hash = first 7 chars of SHA-256 of project root path

The script waits in the background until the user closes the window, then cleans up so headless can resume.

## Tips

- `browser_fill_form` for multiple fields, not `browser_type` per field
- Screenshots to check visuals (saves tokens), snapshots when you need refs
- Cache refs from first snapshot, reuse for subsequent interactions
- On token limit errors, output is auto-saved to a file — use Bash to extract what you need

## Workflows

**Check UI:** Navigate → screenshot → analyze

**Submit form:** Snapshot (get refs) → `browser_fill_form` → click submit → screenshot (verify)

**Debug visuals:** Full-page screenshot → element screenshot → console messages
