#!/bin/zsh

# Specify default editor. Possible values: vim, nano, ed etc.
export EDITOR=nvim

# Golang
export GO111MODULE=on

# File search functions
function f() { find . -iname "*$1*" ${@:2} }
function r() { grep "$1" ${@:2} -R . }

# Kill process running on a given port
function killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port>" >&2
    return 1
  fi
  local pid=$(lsof -ti :"$1")
  if [[ -z "$pid" ]]; then
    echo "No process found on port $1"
    return 1
  fi
  echo "Killing PID $pid on port $1"
  kill -9 $pid
}

# Create a folder and move into it in one command
function mkcd() { mkdir -p "$@" && cd "$_"; }

# After cd-ing into a directory, ls
function cdls() { cd "$@" && ls; }

# Convenient alias for sourcing zshrc
alias sdf='source ~/.zshrc';

# Example aliases
alias cppcompile='c++ -std=c++11 -stdlib=libc++'

alias doc='docker'
alias dcp='docker compose'
alias dm='docker-machine'
alias k='kubectl'
alias ls='eza' # Use exa instead of ls
alias pn='pnpm'
alias pni='pnpm install'
alias pnb='pnpm build'
alias pnp='pnpm pack'
alias pnpx='pnpm dlx'
alias mux='tmuxinator'
alias tf='terraform'
alias nvimc='nvim --no-restore'

# Quickly start a tmuxinator project in given directory
function proj() {
  NAME=$(basename $@)
  mux s project --name=${NAME} "$@"
}

# Git aliases and functions
alias g='git'
alias gundo='git reset --soft HEAD~1'

# Override l alias
alias l='ls -lah --icons=always'

# fbr - checkout git branch
function fbr() {
  local branches branch
  branches=$(git --no-pager branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

function tms() {
  local folder selected_name
  folder=$(find ~/Code -mindepth 1 -maxdepth 3 -type d | fzf)
  selected_name=$(basename "$folder" | tr . _)
  mux s project --name=${selected_name} "$folder"
}

# fbr - checkout git branch (including remote branches)
function fbra() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fco - checkout git branch/tag
function fco() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi) || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

function linux-clean() {
  sudo apt autoclean
  sudo apt autoremove
  sudo apt clean
  # Remove flatpak apps which take up a lot of space
  flatpak uninstall --unused
  # Remove docker things
  docker system prune
  # Remove stale lock files and outdated downloads for all formulae and casks,
  # and remove old versions of installed formulae.
  # Pass in -s flag for for scrubbing the entire cache
  brew cleanup
  # Clear unreferenced packages from pnpm store
  pnpm store prune
  # Clear npm cache
  npm cache clean
}

# Orchestra - Claude Code session orchestrator
function orch() { tmux display-popup -E -w 80% -h 80% "orchestra"; }

# yazi - a terminal file manager
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Forward TCP port(s) from a coder workspace to localhost (same port both sides).
# Targets the devcontainer agent by default; override with AGENT env var
# (e.g. AGENT=workspace coder-forward joel-devbox-1 8080).
# Usage: coder-forward <workspace> <port> [port...]
function coder-forward() {
  local workspace="$1"; shift
  if [[ -z "$workspace" || $# -eq 0 ]]; then
    echo "Usage: coder-forward <workspace> <port> [port...]" >&2
    return 1
  fi
  local target="${workspace}.${AGENT:-devcontainer}"
  local args=()
  for p in "$@"; do args+=(--tcp "${p}:${p}"); done
  coder port-forward "$target" "${args[@]}"
}

# Open today's daily note in nvim
function dn() {
  local note="$HOME/Dropbox (Personal)/vaults/personal-vault/journal/daily/$(date +%Y-%m-%d).md"
  if [[ -f "$note" ]]; then
    nvim "$note"
  else
    echo "No daily note for today: $(date +%Y-%m-%d)"
  fi
}
