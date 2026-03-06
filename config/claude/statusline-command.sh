#!/usr/bin/env bash
# Claude Code status line — two-line layout with progress bar

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home dir to ~, then take just the basename for display
dir_name="$(basename "$cwd")"

# Git branch, truncate to 30 chars
git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ "${#git_branch}" -gt 50 ]; then
  git_branch="${git_branch:0:47}..."
fi

# Cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost=$(awk -v c="$cost" 'BEGIN { printf "%.2f", c }')
fi

# Duration
total_secs=$(echo "$input" | jq -r '.duration.total_seconds // empty')
duration=""
if [ -n "$total_secs" ]; then
  printf -v secs_int '%.0f' "$total_secs"
  mins=$((secs_int / 60))
  secs=$((secs_int % 60))
  if [ "$mins" -gt 0 ]; then
    duration="${mins}m ${secs}s"
  else
    duration="${secs}s"
  fi
fi

# --- Line 1: [Model] 📁 dir | 🌿 branch ---
line1=""
line1+=$(printf '\033[36m[%s]\033[0m' "$model")
line1+=$(printf '  📁 \033[34m%s\033[0m' "$dir_name")

if [ -n "$git_branch" ]; then
  line1+=$(printf '  |  🌿 \033[35m%s\033[0m' "$git_branch")
fi

# --- Line 2: progress bar + percentage | cost | duration ---
line2=""
if [ -n "$used" ]; then
  printf -v used_int '%.0f' "$used"

  # Build progress bar (20 chars wide)
  bar_width=20
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))

  if [ "$used_int" -ge 80 ]; then
    bar_color='\033[31m'  # red
  elif [ "$used_int" -ge 50 ]; then
    bar_color='\033[33m'  # yellow
  else
    bar_color='\033[32m'  # green
  fi

  bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  line2+=$(printf "${bar_color}%s\033[0m %s%%" "$bar" "$used_int")
fi

if [ -n "$cost" ] && [ "$cost" != "0.00" ]; then
  [ -n "$line2" ] && line2+="  |  "
  line2+=$(printf '\033[33m$%s\033[0m' "$cost")
fi

if [ -n "$duration" ]; then
  [ -n "$line2" ] && line2+="  |  "
  line2+=$(printf '⏱ %s' "$duration")
fi

# Output both lines
printf '%s\n%s\n' "$line1" "$line2"
