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

`SKILL.md` frontmatter: `name: demo-gif`, `user_invocable: true`, and a `description` written to trigger on agent judgment ("Use when creating a terminal/REPL demo GIF for a README, PR, or post, not just describing what a command does").

The body teaches the battle-tested VHS recipe (passed on by the agent that built the first demo). It generalizes beyond Ruby's irb to any REPL or CLI (python, node, psql, a shell). Lean: the recipe, one example tape, the dry-run/verify steps. No padding.

The workflow:

1. **Preflight.** Confirm `vhs` is on PATH. If missing, stop and point to `brew install vhs` (the formula pulls `ttyd` and `ffmpeg`, both required).
2. **Author the tape.** A `.tape` is directives: `Output "demo.gif"`, then `Set` (Shell, FontSize, Width, Height, Padding, Theme), then `Type '...'` / `Enter` / `Sleep <n>s`. House defaults keep output consistent. The agent fills the demo's beats.
3. **Dry-run.** Pipe the commands through the REPL non-interactively (e.g. `irb --prompt simple < cmds.rb`) to confirm output and time the sleeps before rendering.
4. **Render.** Run `vhs <name>.tape`, producing a local GIF.
5. **Verify.** Inspect the first frame and the file: no banner, no completion dropdown, sleeps long enough that output lands before the next line types. Report dimensions and filesize. No blind success claim.
6. **Publish.** Run `vhs publish <name>.gif`, capture the returned Charm CDN URL (or commit/drag-drop for GitHub-hosted).
7. **Embed.** Put the URL into the target: PR body via `gh pr edit`, or a README/markdown file via edit.

## The hard-won rules (the core of the skill)

These are the specifics that separate a clean demo from a garbled one. The SKILL.md states each with its reasoning:

1. **Start at the first real command.** Wrap REPL startup in `Hide … Show`: launch, wait for load, `Ctrl+L` to clear the banner, then `Show`. The GIF opens on a clean prompt.
2. **Kill REPL noise.** Per-REPL knobs to suppress the banner and the autocomplete dropdown (which flickers under every keystroke and bloats the file). irb: `--prompt simple --noautocomplete`, preload libs with `-r`. python: `-q`. The skill carries a small per-REPL table.
3. **Single-quote `Type`** so commands with double quotes need no escaping: `Type 'api.call("x")'`.
4. **Keep per-line output short.** Append `; nil` to assignments whose inspect is huge; chain each demo line to a small return value.
5. **Size sleeps to the work.** ~1.5s for instant local calls, 6 to 7s for network/LLM calls. Garbled GIFs are almost always too-short sleeps.
6. **Hold the final frame** with a long trailing `Sleep` (~7s) so it pauses before looping.
7. **Size the canvas:** Width so the longest line doesn't wrap, Height for the line count.

One example tape (irb) ships in the skill.

## Guardrails baked into the skill

- **Tape is the source of truth.** A GIF regenerates from the tape. Keeping it (optional, in `.vhs/` or `docs/demos/`) is the reproducibility win over ad hoc screen capture; the default is ephemeral after publish.
- **Never demo secrets.** A tape captures whatever renders, and `vhs publish` uploads to an external host (Charm's CDN). The skill warns against demoing any command that prints tokens, credentials, or private data, and says to scrub or fake such values first.

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
