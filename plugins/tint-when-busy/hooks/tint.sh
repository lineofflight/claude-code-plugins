#!/bin/bash
# Tint or clear the pane background based on session state.
# Usage: tint.sh <waiting|working>
#
# Reads Ghostty's configured background and shifts each RGB channel by 8.
# Direction is decided by the bg's own brightness — light bgs darken, dark
# bgs lighten — so it works on any Ghostty theme without OS-level detection.

state="$1"

[ -w /dev/tty ] || exit 0

if [ "$state" = "waiting" ]; then
    printf '\033]111\007' >/dev/tty 2>/dev/null
    exit 0
fi

bg=$(command -v ghostty >/dev/null && ghostty +show-config 2>/dev/null | awk '$1=="background"{print $3; exit}')
bg="${bg#\#}"
[ ${#bg} -eq 6 ] || exit 0

r=$((16#${bg:0:2}))
g=$((16#${bg:2:2}))
b=$((16#${bg:4:2}))

if (( (r + g + b) / 3 > 127 )); then
    direction=-1
else
    direction=1
fi

r=$((r + direction * 8))
g=$((g + direction * 8))
b=$((b + direction * 8))
clamp() { local v=$1; [ $v -lt 0 ] && v=0; [ $v -gt 255 ] && v=255; printf '%02x' $v; }

printf '\033]11;#%s%s%s\007' "$(clamp $r)" "$(clamp $g)" "$(clamp $b)" >/dev/tty 2>/dev/null
