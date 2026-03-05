#!/usr/bin/env bash
# Claude Code status line — mirrors default Starship prompt style

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home dir to ~, truncate if too long
home="$HOME"
short_cwd="${cwd/#$home/\~}"
if [ "${#short_cwd}" -gt 30 ]; then
  short_cwd="$(basename "$cwd")"
fi

# Git branch (skip optional locks, suppress errors), truncate to 30 chars
git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ "${#git_branch}" -gt 30 ]; then
  git_branch="${git_branch:0:27}..."
fi

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost=$(awk -v c="$cost" 'BEGIN { printf "%.4f", c }')
fi

# Build output
parts=()
parts+=("$(printf '\033[34m%s\033[0m' "$short_cwd")")

if [ -n "$git_branch" ]; then
  parts+=("$(printf '\033[35m(%s)\033[0m' "$git_branch")")
fi

parts+=("$(printf '\033[33m%s\033[0m' "$model")")

if [ -n "$used" ]; then
  printf -v used_int '%.0f' "$used"
  if [ "$used_int" -ge 80 ]; then
    color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then
    color='\033[33m'
  else
    color='\033[32m'
  fi
  parts+=("$(printf "${color}ctx:%s%%\033[0m" "$used_int")")
fi

if [ -n "$cost" ] && [ "$cost" != "0.0000" ]; then
  parts+=("$(printf '\033[36m$%s\033[0m' "$cost")")
fi

printf '%s\n' "$(IFS=' '; echo "${parts[*]}")"
