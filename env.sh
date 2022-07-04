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

function proj() {
  NAME=$(basename $PWD)
  mux s project --name=${NAME} "$@"
}

# Convenient alias for sourcing zshrc
alias sdf='source ~/.zshrc';

# Example aliases
alias cppcompile='c++ -std=c++11 -stdlib=libc++'
alias g='git'

alias doc='docker'
alias dcp='docker-compose'
alias dm='docker-machine'
alias k='kubectl'
alias ls='exa' # Use exa instead of ls
alias pn='pnpm'
alias mux='tmuxinator'
