---
name: demo-gif
description: Use when creating a terminal or REPL demo GIF for a README, PR, or post — recording a sequence of commands so each appears typed with its output below, no startup noise. Reach for it whenever showing a command working would land better than describing it; you don't need to be asked. Covers any REPL/CLI (irb, python, node, psql, a shell) via vhs.
user_invocable: true
---

# demo-gif

Record a clean terminal/REPL demo as an animated GIF with [vhs](https://github.com/charmbracelet/vhs). From a sequence of commands you get a GIF where each command appears typed with its output below it, no banner, no autocomplete flicker. Good for a README, a PR, or a GitHub discussion.

Reach for this whenever showing a command working would land better than describing it. You don't need to be asked.

## Prerequisite

`vhs` must be on PATH. `brew install vhs` pulls its `ttyd` and `ffmpeg` dependencies. If it's missing, stop and say so.

## How vhs works

A `.tape` file is a script of directives that drives a real terminal and renders a GIF:

- `Output "demo.gif"` — the file to write.
- `Set Shell|FontSize|Width|Height|Padding|Theme` — the canvas.
- `Type '...'`, `Enter`, `Sleep <n>s` — the performance.
- `Hide` / `Show` — run commands without recording them.
- `Ctrl+L`, `Ctrl+C`, and other key chords.

Render it with `vhs demo.tape`.

## The recipe

1. **Open on a clean prompt.** Wrap REPL startup in `Hide … Show`: launch, wait for load, `Ctrl+L` to clear the banner, then `Show`. The recording starts on an empty prompt, not the launch noise.
2. **Kill REPL noise.** Suppress the banner and the autocomplete dropdown (it flickers under every keystroke and bloats the file). Preload libraries so there are no `require`/`import` lines on screen. Per-REPL knobs:

   | REPL | quiet launch |
   |------|--------------|
   | irb | `irb -r mylib --prompt simple --noautocomplete` |
   | python | `PYTHONSTARTUP=setup.py python -q` (startup file preloads imports) |
   | node | `node`, then preload inside the hidden block with `require(...)` / `.load setup.js` |
   | psql | `psql -q`, then `\set QUIET on` |
   | shell | set `PS1='$ '` for a clean prompt |

   Aim for the shortest clean prompt. A single `>` reads better than `>>`; in irb the `simple` prompt is `>>`, so override it in the hidden setup block: `conf.prompt_i = conf.prompt_n = conf.prompt_s = conf.prompt_c = "> "`.
3. **Single-quote `Type`** so double quotes inside a command need no escaping: `Type 'api.call("x")'`.
4. **Keep each line's output short.** Append `; nil` to assignments whose inspect is huge (a configured client); chain each demo line to a small return value.
5. **Size sleeps to the work.** ~1.5s for instant local calls, 6 to 7s for a network or LLM call so output lands before the next line types. A garbled GIF is almost always a too-short sleep.
6. **Hold the final frame** with a long trailing `Sleep` (~7s) so the GIF pauses before it loops.
7. **Size the canvas.** Width so the longest line doesn't wrap; Height for the line count.

## Dry-run before you render

Pipe the commands through the REPL non-interactively to confirm output and time the sleeps:

```
irb --prompt simple < cmds.rb
```

Then render and inspect the first frame: no banner, no dropdown, sleeps long enough that output lands before the next line types. Report the GIF's dimensions and filesize. Don't claim it's done without looking.

## Publish

`vhs publish demo.gif` uploads to Charm's CDN and prints a public URL — drop it into the PR (`gh pr edit`) or the README. Or commit the GIF / drag-drop into a GitHub discussion for GitHub-hosted.

Keep the `.tape` if you want the GIF to be regenerable (it's small, text); the GIF binary doesn't need to live in git.

## Don't record secrets

A tape captures whatever renders, and `vhs publish` uploads to an external host. Never demo a command that prints tokens, credentials, or private data. Scrub or fake those values first.

## Example tape (irb)

```
Output "demo.gif"
Set Shell bash
Set FontSize 13
Set Width 1300
Set Height 640
Set Padding 18
Set Theme "Dracula"

Hide
Type 'bundle exec irb -r mylib --prompt simple --noautocomplete'
Enter
Sleep 6s
Type 'conf.prompt_i = conf.prompt_n = conf.prompt_s = conf.prompt_c = "> "; nil'
Enter
Ctrl+L
Sleep 700ms
Show

Type 'client = MyLib.new("http://localhost:9001"); nil'
Enter
Sleep 1.5s
Type 'client.status'
Enter
Sleep 2.5s
Sleep 7s
```
