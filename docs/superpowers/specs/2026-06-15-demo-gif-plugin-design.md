# demo-gif plugin design

A Claude Code plugin that turns a terminal demo into a hosted GIF for a PR or README, using VHS end to end.

## Purpose

When a session decides a change would land better shown than described (a CLI change working, a PR illustration, a README demo), it reaches for this skill. The skill writes a VHS tape, renders it to a GIF, publishes the GIF to Charm's CDN, and drops the URL into the PR or README.

The trigger is the agent's own judgment, not an explicit request from the user. The same way peddler reached for `vhs publish` unprompted when it wanted a GIF in a PR. A `/demo-gif` invocation is a convenience, not the gate.

## Scope

- **In:** terminal demos via VHS (Charm). Tape authoring, render, publish to CDN, embed URL.
- **Out:** browser or app screen capture (that would be a separate tool, e.g. the Chrome `gif_creator` MCP). Not in this plugin.

## Plugin layout

Matches the existing plugins in this repo (flat `plugin.json`, one skill per directory):

```
plugins/demo-gif/
  .claude-plugin/plugin.json
  skills/demo-gif/SKILL.md
  README.md
```

`plugin.json` follows the repo convention: name, description, version (start `0.1.0`), author `Line of Flight`, repository URL.

The plugin is registered in `.claude-plugin/marketplace.json` under the `lineofflight` marketplace, category `productivity`.

## Skill behavior

`SKILL.md` frontmatter: `name: demo-gif`, `user_invocable: true`, and a `description` written to trigger on agent judgment ("Use when you want to show a terminal change working as a GIF for a PR or README, not just describe it").

The skill walks these steps:

1. **Preflight.** Confirm `vhs` is on PATH. If missing, stop and point to `brew install charmbracelet/tap/vhs`. (`ffmpeg` is a VHS dependency; the brew formula pulls it.)
2. **Author the tape.** Write a `.tape` for the command(s) to demo. The skill carries house defaults so output looks consistent across demos: readable font size, a dark theme, sensible width/height, a typing speed that reads naturally, and padded start/end frames (a `Sleep` before and after) so the loop is not jarring. The agent fills in the `Type`/`Enter`/`Sleep` beats for the specific demo.
3. **Render.** Run `vhs <name>.tape`, producing a local GIF.
4. **Verify.** Confirm the GIF exists and report its dimensions and filesize. No blind success claim. If the render produced nothing or an empty file, surface that.
5. **Publish.** Run `vhs publish <name>.gif`, capture the returned Charm CDN URL.
6. **Embed.** Put the URL into the target: PR body via `gh pr edit`, or a README/markdown file via edit. The agent picks based on context.
7. **Keep tape, drop binary.** Commit the `.tape` (small, text, reproducible) into the target repo under `.vhs/` or `docs/demos/`. The GIF itself lives on the CDN, not in git.

## Guardrails baked into the skill

- **Tape is the source of truth.** A GIF can always be regenerated from the committed tape. This is the reproducibility win over ad hoc screen capture.
- **Never demo secrets.** A tape captures whatever renders in the terminal, and `vhs publish` uploads to an external host (Charm's CDN). The skill warns against demoing any command that prints tokens, credentials, or private data, and says to scrub or fake such values first.

## Open defaults (decided)

- **Name:** `demo-gif`.
- **Marketplace:** `claude-code-plugins` (the `lineofflight` CC marketplace).
- **Capture:** terminal only, via VHS.
- **Publish:** `vhs publish` to Charm CDN; embed the URL. GIF binary not committed.

## Success criteria

- A session can go from "this should be a GIF" to a CDN URL embedded in a PR with no manual steps from Hakan.
- Output looks consistent across demos (shared theme/font/padding defaults).
- The committed tape regenerates the same GIF.
- The skill refuses, or warns, before capturing anything that would leak secrets.
