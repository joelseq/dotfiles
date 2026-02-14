#!/usr/bin/env bash
# Claude Code status line — mirrors default Starship prompt style

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home dir to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip optional locks, suppress errors)
git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

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

printf '%s\n' "$(IFS=' '; echo "${parts[*]}")"
