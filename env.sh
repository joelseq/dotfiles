#!/bin/zsh

# Specify default editor. Possible values: vim, nano, ed etc.
export EDITOR=nvim

# Golang
export GO111MODULE=on

# File search functions
function f() { find . -iname "*$1*" ${@:2}; }
function r() { grep "$1" ${@:2} -R .; }

# Kill process running on a given port
function killport() {
	if [[ -z "$1" ]]; then
		echo "Usage: killport <port>" >&2
		return 1
	fi
	local -a pids
	pids=(${(fu)"$(lsof -ti :"$1")"})
	if ((${#pids} == 0)); then
		echo "No process found on port $1"
		return 1
	fi
	echo "Killing PIDs ${(j: :)pids} on port $1"
	kill -9 -- "${pids[@]}"
}

# Create a folder and move into it in one command
function mkcd() { mkdir -p "$@" && cd "$_"; }

# After cd-ing into a directory, ls
function cdls() { cd "$@" && ls; }

# Convenient alias for sourcing zshrc
alias sdf='source ~/.zshrc'

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

# Quickly create/focus a Herdr workspace in a project directory
function hdw() {
	local folder selected_name existing workspace_out workspace_id agent_tab agent_pane editor_out editor_pane terms_out terms_pane

	if [[ -n "$1" ]]; then
		folder="$1"
	else
		folder=$(find ~/Code -mindepth 1 -maxdepth 3 -type d | fzf)
	fi
	[[ -z "$folder" ]] && return 1

	selected_name=$(basename "$folder" | tr . _)
	existing=$(herdr workspace list | jq -r --arg name "$selected_name" '.result.workspaces[]? | select(.label == $name) | .workspace_id' | head -n1)

	if [[ -n "$existing" ]]; then
		herdr workspace focus "$existing" >/dev/null
	else
		workspace_out=$(herdr workspace create --cwd "$folder" --label "$selected_name" --focus)
		workspace_id=$(jq -r '.result.workspace.workspace_id' <<<"$workspace_out")
		agent_tab=$(jq -r '.result.tab.tab_id' <<<"$workspace_out")
		agent_pane=$(jq -r '.result.root_pane.pane_id' <<<"$workspace_out")

		herdr tab rename "$agent_tab" agent >/dev/null
		herdr pane rename "$agent_pane" agent >/dev/null

		editor_out=$(herdr tab create --workspace "$workspace_id" --cwd "$folder" --label editor --no-focus)
		editor_pane=$(jq -r '.result.root_pane.pane_id' <<<"$editor_out")
		herdr pane run "$editor_pane" nvim

		terms_out=$(herdr tab create --workspace "$workspace_id" --cwd "$folder" --label terms --no-focus)
		terms_pane=$(jq -r '.result.root_pane.pane_id' <<<"$terms_out")
		herdr pane split "$terms_pane" --direction right --ratio 0.5 --cwd "$folder" --no-focus >/dev/null

		herdr tab focus "$agent_tab" >/dev/null
	fi

	# If called outside Herdr, attach/open the Herdr client after preparing the workspace.
	[[ -z "$HERDR_ENV" ]] && herdr
}

# fbr - checkout git branch (including remote branches)
function fbra() {
	local branches branch
	branches=$(git branch --all | grep -v HEAD) &&
		branch=$(echo "$branches" |
			fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m) &&
		git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fco - checkout git branch/tag
function fco() {
	local tags branches target
	branches=$(
		git --no-pager branch --all \
			--format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" |
			sed '/^$/d'
	) || return
	tags=$(
		git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}'
	) || return
	target=$(
		(
			echo "$branches"
			echo "$tags"
		) |
			fzf --no-hscroll --no-multi -n 2 \
				--ansi
	) || return
	git checkout $(awk '{print $2}' <<<"$target")
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
	IFS= read -r -d '' cwd <"$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Forward TCP port(s) from a coder workspace to localhost (same port both sides).
# Targets the devcontainer agent by default; override with AGENT env var
# (e.g. AGENT=workspace coder-forward joel-devbox-1 8080).
# Usage: coder-forward <workspace> <port> [port...]
function coder-forward() {
	local workspace="$1"
	shift
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
