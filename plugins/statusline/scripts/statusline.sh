#!/bin/bash

# Default user-scoped statusline
# Projects can override via .claude/settings.json

input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

dir_name=$(basename "$current_dir")

# Starship-style colors (ANSI-C $'...' embeds real ESC bytes, works even on bash 3.2)
cyan=$'\033[1;36m'
purple=$'\033[1;35m'
red=$'\033[0;31m'
reset=$'\033[0m'
dim=$'\033[90m'               # bright-black, for the empty part of the bar
branch_glyph=$'\356\202\240'  # U+E0A0 Nerd Font git branch icon (UTF-8 bytes ee 82 a0)
bar_fill=$'\342\224\201'      # ━ U+2501 heavy horizontal (filled)
bar_empty=$'\342\224\200'     # ─ U+2500 light horizontal (empty)

# Git: Starship-style "on  <branch>" — the  glyph is U+E0A0 and needs a Nerd Font.
# Dirty working tree adds a red "*".
git_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"

    dirty=""
    if ! git --no-optional-locks -C "$current_dir" diff --quiet 2>/dev/null || \
       ! git --no-optional-locks -C "$current_dir" diff --cached --quiet 2>/dev/null; then
        dirty="${red}*${reset}"
    fi

    git_info=" on ${purple}${branch_glyph} ${branch}${reset}${dirty}"
fi

# Model and effort, spelled out, surfaced independently and only when below the
# Opus + xhigh coding baseline (xhigh is Claude Code's default effort). Decoupled:
# a cheaper model shows just the model, lower effort shows just the effort, both
# show both. Rendered after the context bar (see usage_display).
# Hide at/above baseline: model >= opus (opus/fable/mythos); effort >= xhigh (xhigh/max).
model_full=$(echo "$model_name" | sed 's/Claude //i' | awk '{print tolower($1)}')
effort=$(echo "$input" | jq -r '.effort.level // empty')  # low | medium | high | xhigh | max

case "$model_full" in opus|fable|mythos) model_seg="" ;; *) model_seg="  $model_full" ;; esac
case "$effort" in xhigh|max|"") effort_seg="" ;; *) effort_seg="  $effort" ;; esac

# Format a labeled percentage with color thresholds (defaults: green <50, yellow <75, red >=75).
# 5th arg hides the indicator entirely below that value (default 0 = always show).
fmt_pct() {
    local pct=$1 label=$2 yellow_at=${3:-50} red_at=${4:-75} min_at=${5:-0}
    [ -z "$pct" ] && return
    local int=${pct%.*}
    [ "$int" -lt "$min_at" ] && return
    local color
    if [ "$int" -lt "$yellow_at" ]; then color="\033[32m"
    elif [ "$int" -lt "$red_at" ]; then color="\033[33m"
    else color="\033[31m"
    fi
    echo -n "  $label: ${color}${int}%\033[0m"
}

# Line-style progress bar (heavy/light horizontal rules): filled = bar_fill in bold
# cyan (matches the directory), empty = bar_empty dimmed.
# No threshold coloring — the fill level alone shows how full the window is.
# 3rd arg hides the bar entirely below that percent (default 0 = always show).
draw_bar() {
    local pct=$1 label=$2 min_at=${3:-0} width=${4:-7}
    [ -z "$pct" ] && return
    local int=${pct%.*}
    [ "$int" -lt "$min_at" ] && return
    local filled
    filled=$(awk -v p="$int" -v w="$width" 'BEGIN{f=int(p/100.0*w+0.5); if(f>w)f=w; if(f<0)f=0; print f}')
    local bar="$cyan" i
    for ((i = 0; i < filled; i++)); do bar="$bar$bar_fill"; done
    bar="$bar$dim"
    for ((i = filled; i < width; i++)); do bar="$bar$bar_empty"; done
    local lbl=""; [ -n "$label" ] && lbl="$label "
    printf '  %s%s%s' "$lbl" "$bar" "$reset"
}

# 7d uses a time-aware hide threshold: hide unless usage is ahead of a linear pace line.
# At fraction f through the (fixed) 7-day window, sustainable usage is f*100%; surface only
# when used >= pace + 10pp (so it doesn't flicker at pace), capped at 75 so the red zone
# always shows late in the week. Falls back to a flat 50 if resets_at is absent.
seven_d_min=50
if [ -n "$seven_d_reset" ]; then
    seven_d_min=$(awk -v now="$(date +%s)" -v r="$seven_d_reset" 'BEGIN {
        win = 7 * 86400; f = (now - (r - win)) / win;
        if (f < 0) f = 0; if (f > 1) f = 1;
        t = f * 100 + 10; if (t > 75) t = 75;
        printf "%d", t
    }')
fi

usage_display="$(draw_bar "$used_pct" "" 10)${model_seg}${effort_seg}$(fmt_pct "$five_h_pct" "5h" 50 75 50)$(fmt_pct "$seven_d_pct" "7d" 50 75 "$seven_d_min")"

printf "%s%s%b\n" "${cyan}${dir_name}${reset}" "$git_info" "$usage_display"
