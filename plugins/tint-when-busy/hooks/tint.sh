#!/bin/bash
# Tint or clear the pane background based on session state.
# Usage: tint.sh <waiting|working>
#
# Resolves Ghostty's active theme (handling `theme = light:X,dark:Y` split
# syntax via macOS appearance) and shifts each RGB channel by 10. Direction
# is decided by the bg's own brightness — light bgs darken, dark bgs lighten.

state="$1"

[ -w /dev/tty ] || exit 0

if [ "$state" = "waiting" ]; then
    printf '\033]111\007' >/dev/tty 2>/dev/null
    exit 0
fi

command -v ghostty >/dev/null || exit 0

resolve_bg() {
    local theme_line theme_name path
    theme_line=$(ghostty +show-config 2>/dev/null | sed -n 's/^theme = //p' | head -1)
    if [[ "$theme_line" =~ ^light:(.+),dark:(.+)$ ]]; then
        if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
            theme_name="${BASH_REMATCH[2]}"
        else
            theme_name="${BASH_REMATCH[1]}"
        fi
    elif [ -n "$theme_line" ]; then
        theme_name="$theme_line"
    fi
    if [ -n "$theme_name" ]; then
        for path in "$HOME/.config/ghostty/themes/$theme_name" \
                    "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/$theme_name"; do
            if [ -r "$path" ]; then
                awk '$1=="background"{print $3; exit}' "$path"
                return
            fi
        done
    fi
    ghostty +show-config 2>/dev/null | awk '$1=="background"{print $3; exit}'
}

bg=$(resolve_bg)
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

r=$((r + direction * 10))
g=$((g + direction * 10))
b=$((b + direction * 10))
clamp() { local v=$1; [ $v -lt 0 ] && v=0; [ $v -gt 255 ] && v=255; printf '%02x' $v; }

printf '\033]11;#%s%s%s\007' "$(clamp $r)" "$(clamp $g)" "$(clamp $b)" >/dev/tty 2>/dev/null
