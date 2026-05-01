# tint-when-busy

Tints your terminal pane background when Claude is working, and clears the tint when Claude is waiting on you (a Notification fires or the turn ends). Useful when you split a terminal into multiple panes running parallel Claude sessions and need to spot which one is busy versus ready for input.

Implementation: hooks emit OSC 11 to `/dev/tty` to set/reset the pane background color. Per-pane signal — no app, no IPC, just terminal escape codes.

## How the tint color is chosen

Reads Ghostty's configured background via `ghostty +show-config` and shifts each RGB channel by 8. Direction comes from the bg's own brightness:

- If bg is light (mean channel > 127): subtract 8 → tint is slightly darker
- If bg is dark: add 8 → tint is slightly lighter

No OS-level theme detection — the bg color decides. Switch Ghostty themes and the tint follows automatically.

## Requirements

Ghostty terminal (`ghostty` on PATH).

## Caveats

- If a pane stays tinted after Claude exits, run `printf '\033]111\007'` in that pane to reset.
