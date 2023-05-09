#!/bin/zsh

# Specify default editor. Possible values: vim, nano, ed etc.
export EDITOR=nvim

# Golang
export GO111MODULE=on

# File search functions
function f() { find . -iname "*$1*" ${@:2} }
function r() { grep "$1" ${@:2} -R . }

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
alias ls='exa' # Use exa instead of ls
alias pn='pnpm'
alias mux='tmuxinator'
alias tf='terraform'

# Quickly start a tmuxinator project in given directory
function proj() {
  NAME=$(basename $@)
  mux s project --name=${NAME} "$@"
}

# Git aliases and functions
alias g='git'
alias gundo='git reset --soft HEAD~1'

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
