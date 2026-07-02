#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
home="$HOME"
code_prefix="$home/code/"

# --- Directory ---
if echo "$cwd" | grep -q "^$code_prefix"; then
  rel="${cwd#"$code_prefix"}"
  dir_part=$(printf '\033[34m%s\033[0m' "$rel")
else
  short=$(echo "$cwd" | sed "s|^$home|~|")
  dir_part=$(printf '%s' "$short")
fi

# --- Git branch ---
branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
branch_part=""
if [ -n "$branch" ]; then
  # Truncate display label to 15 characters
  branch_len=$(printf '%s' "$branch" | wc -c | tr -d ' ')
  if [ "$branch_len" -gt 15 ]; then
    branch_display=$(printf '%s' "$branch" | cut -c1-15)
    branch_display="${branch_display}…"
  else
    branch_display="$branch"
  fi
  branch_part=$(printf '\033[33m%s\033[0m' "$branch_display")
fi

# --- Git dirty state (dirty = red branch, clean = green) + Linear link ---
if [ -n "$branch" ]; then
  dirty=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null | head -1)
  if [ -n "$dirty" ]; then
    branch_color="31"  # red
  else
    branch_color="32"  # green
  fi
  branch_text=$(printf '\033[%sm%s\033[0m' "$branch_color" "$branch_display")

  # Link the branch to its Linear issue when it's a PBRD-NNN branch.
  ticket=$(printf '%s' "$branch" | grep -oiE '^pbrd-[0-9]+' | head -1)
  if [ -n "$ticket" ]; then
    ticket_uc=$(printf '%s' "$ticket" | tr '[:lower:]' '[:upper:]')
    linear_url="https://linear.app/alma-elma/issue/${ticket_uc}"
    branch_part=$(printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$linear_url" "$branch_text")
  else
    branch_part="$branch_text"
  fi
fi

# --- TPS + Cost (from OTEL receiver, per-session) ---
tps_part=""
session_id=$(echo "$input" | jq -r '.session_id // empty')
if [ -n "$session_id" ]; then
  tps_file="/tmp/claude-tps/${session_id}.json"
  if [ -f "$tps_file" ]; then
    tps_val=$(jq -r '.tps // empty' "$tps_file" 2>/dev/null)
    if [ -n "$tps_val" ] && [ "$tps_val" != "0" ]; then
      tps_part=$(printf '\033[35m%s tok/s\033[0m' "$tps_val")
    fi
  fi
fi

# --- Context window ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 40 ]; then
    ctx_part=$(printf '\033[31mctx %s%%\033[0m' "$used_int")
  else
    ctx_part=$(printf 'ctx \033[36m%s%%\033[0m' "$used_int")
  fi
else
  ctx_part=""
fi

# --- Rate limits (Max plan: 5h + 7d windows) ---

# Compact time-until-reset, e.g. 4d10h / 10h5m / 12m. Input is an epoch second.
fmt_until() {
  now=$(date +%s)
  diff=$(( $1 - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# mode (4th arg): "until" → countdown to reset; default → clock time.
fmt_limit() {
  label="$1"
  pct="$2"
  resets="$3"
  mode="$4"
  [ -z "$pct" ] && return
  pct_int=$(printf '%.0f' "$pct")
  if [ "$pct_int" -ge 80 ]; then
    color="31"  # red
  elif [ "$pct_int" -ge 50 ]; then
    color="33"  # yellow
  else
    color="36"  # cyan
  fi
  if [ -n "$resets" ] && [ "$resets" != "null" ]; then
    if [ "$mode" = "until" ]; then
      reset_str=$(fmt_until "$resets")
    else
      reset_str=$(date -r "$resets" '+%-I:%M%p' 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
    printf '%s \033[%sm%s%%\033[0m \033[2m↻%s\033[0m' "$label" "$color" "$pct_int" "$reset_str"
  else
    printf '%s \033[%sm%s%%\033[0m' "$label" "$color" "$pct_int"
  fi
}

rl5_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl5_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl7_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl7_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

rl5_part=""
rl7_part=""
[ -n "$rl5_pct" ] && rl5_part=$(fmt_limit "5h" "$rl5_pct" "$rl5_reset" "until")
# Only show 7d when elevated (>=25%) to save space
if [ -n "$rl7_pct" ]; then
  rl7_int=$(printf '%.0f' "$rl7_pct")
  if [ "$rl7_int" -ge 25 ]; then
    rl7_part=$(fmt_limit "7d" "$rl7_pct" "$rl7_reset" "until")
  fi
fi

# --- Model ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model_name" ]; then
  model_part=$(printf '\033[2m%s\033[0m' "$model_name")
else
  model_part=""
fi

# --- Assemble ---
sep=$(printf ' \033[2m|\033[0m ')
output="$dir_part"
[ -n "$branch_part" ]      && output="$output$sep$branch_part"
[ -n "$ctx_part" ]         && output="$output$sep$ctx_part"
[ -n "$rl5_part" ]         && output="$output$sep$rl5_part"
[ -n "$rl7_part" ]         && output="$output$sep$rl7_part"
[ -n "$tps_part" ]         && output="$output$sep$tps_part"
[ -n "$model_part" ]       && output="$output$sep$model_part"

printf '%b' "$output"
