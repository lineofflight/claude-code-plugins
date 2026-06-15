# demo-gif

Record a clean terminal or REPL demo as an animated GIF with [vhs](https://github.com/charmbracelet/vhs), suitable for a README, PR, or GitHub discussion. Each command appears typed with its output below, no startup banner or autocomplete noise.

## How it works

The `demo-gif` skill teaches the agent the vhs recipe: author a `.tape`, hide the REPL startup, suppress per-REPL noise, size sleeps to the work, dry-run, render, and publish to a CDN URL. Generalizes across irb, python, node, psql, and shells.

Invoke with `/demo-gif`, or the agent reaches for it on its own when a demo would land better than prose.

## Requirements

- `vhs` (`brew install vhs` pulls `ttyd` and `ffmpeg`)
