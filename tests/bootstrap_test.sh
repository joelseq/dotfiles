#!/usr/bin/env bash
set -euo pipefail

run_tests() {
  local repo_root bootstrap zshrc
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  bootstrap="$repo_root/bootstrap.sh"
  zshrc="$repo_root/zshrc"

  BOOTSTRAP_TEST_DIR="$(mktemp -d)"
  export BOOTSTRAP_TEST_DIR
  trap 'rm -rf "$BOOTSTRAP_TEST_DIR"' EXIT
  export HOME="$BOOTSTRAP_TEST_DIR/home"
  mkdir -p "$HOME"
  BOOTSTRAP_PLUGIN_LOG="$BOOTSTRAP_TEST_DIR/plugin.log"
  BOOTSTRAP_HERDR_STUB="$BOOTSTRAP_TEST_DIR/herdr-stub"
  export BOOTSTRAP_PLUGIN_LOG BOOTSTRAP_HERDR_STUB
  : >"$BOOTSTRAP_PLUGIN_LOG"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'echo "$*" >>"$BOOTSTRAP_PLUGIN_LOG"' \
    'if [[ "${BOOTSTRAP_FAIL_PLUGIN:-}" == "$3" ]]; then' \
    '  echo "plugin install failed" >&2' \
    '  exit 1' \
    'fi' >"$BOOTSTRAP_HERDR_STUB"
  chmod +x "$BOOTSTRAP_HERDR_STUB"

  # Load function definitions without running bootstrap main.
  # shellcheck disable=SC1090
  source <(sed '$d' "$bootstrap")

  test_brew_does_not_install_herdr
  test_herdr_installs_directly
  test_existing_direct_herdr_skips_install
  test_herdr_installs_plugins_every_run
  test_herdr_plugin_failure_continues "$bootstrap"
  test_zshrc_adds_local_bin "$zshrc"
  test_zshrc_reports_git_branch "$zshrc"
  test_zshrc_clears_git_branch "$zshrc"
  test_main_installs_herdr_after_brew
  printf 'bootstrap tests passed\n'
}

test_brew_does_not_install_herdr() {
  BOOTSTRAP_BREW_LOG="$BOOTSTRAP_TEST_DIR/brew.log"
  export BOOTSTRAP_BREW_LOG
  : >"$BOOTSTRAP_BREW_LOG"
  touch "$HOME/.fzf.zsh"

  install_brew_packages >/dev/null

  if grep -Eq '(^|[[:space:]])herdr($|[[:space:]])' "$BOOTSTRAP_BREW_LOG"; then
    fail "Homebrew received herdr"
  fi
}

test_herdr_installs_directly() {
  BOOTSTRAP_CURL_LOG="$BOOTSTRAP_TEST_DIR/curl.log"
  export BOOTSTRAP_CURL_LOG
  : >"$BOOTSTRAP_CURL_LOG"

  declare -F install_herdr >/dev/null || fail "install_herdr missing"
  install_herdr >/dev/null

  [[ -x "$HOME/.local/bin/herdr" ]] || fail "direct binary missing"
  grep -Fxq -- '-fsSL https://herdr.dev/install.sh' "$BOOTSTRAP_CURL_LOG" || fail "wrong installer URL"
}

test_existing_direct_herdr_skips_install() {
  install_herdr >/dev/null

  [[ "$(wc -l <"$BOOTSTRAP_CURL_LOG")" -eq 1 ]] || fail "existing direct install downloaded again"
}

test_herdr_installs_plugins_every_run() {
  local expected
  expected=$'plugin install smarzban/herdr-file-viewer --yes\nplugin install persiyanov/herdr-reviewr --yes\nplugin install smarzban/herdr-file-viewer --yes\nplugin install persiyanov/herdr-reviewr --yes'

  [[ "$(cat "$BOOTSTRAP_PLUGIN_LOG")" == "$expected" ]] || fail "Herdr plugins not installed every run"
}

test_herdr_plugin_failure_continues() {
  local bootstrap="$1"
  local expected output status
  expected=$'plugin install smarzban/herdr-file-viewer --yes\nplugin install persiyanov/herdr-reviewr --yes'
  : >"$BOOTSTRAP_PLUGIN_LOG"
  export BOOTSTRAP_FAIL_PLUGIN="smarzban/herdr-file-viewer"

  set +e
  output="$(bash -s -- "$bootstrap" 2>&1 <<'SCRIPT'
set -euo pipefail
bootstrap="$1"
source <(sed '$d' "$bootstrap")
install_herdr
printf 'continued\n'
SCRIPT
)"
  status=$?
  set -e
  unset BOOTSTRAP_FAIL_PLUGIN

  [[ "$status" -eq 0 ]] || fail "plugin failure stopped bootstrap"
  [[ "$output" == *"continued"* ]] || fail "bootstrap did not continue after plugin failure"
  [[ "$output" == *"Failed to install Herdr plugin smarzban/herdr-file-viewer; continuing"* ]] || fail "plugin failure error missing"
  [[ "$(cat "$BOOTSTRAP_PLUGIN_LOG")" == "$expected" ]] || fail "later plugin skipped after failure"
}

test_zshrc_adds_local_bin() {
  local zshrc="$1"
  local configured_path
  configured_path="$(
    HOME="$BOOTSTRAP_TEST_DIR/zsh-home" PATH="/usr/bin:/bin" zsh -dfc '
      source "$1" >/dev/null 2>&1 || true
      print -r -- "$PATH"
    ' zsh "$zshrc"
  )"

  [[ ":$configured_path:" == *":$BOOTSTRAP_TEST_DIR/zsh-home/.local/bin:"* ]] || fail "zshrc does not add ~/.local/bin to PATH"
}

test_zshrc_reports_git_branch() {
  local zshrc="$1"
  local fake_bin="$BOOTSTRAP_TEST_DIR/fake-bin"
  local metadata_log="$BOOTSTRAP_TEST_DIR/metadata.log"
  mkdir -p "$fake_bin"
  : >"$metadata_log"
  printf '%s\n' '#!/bin/sh' 'printf '\''%s\n'\'' "$FAKE_GIT_BRANCH"' >"$fake_bin/git"
  printf '%s\n' '#!/bin/sh' 'printf '\''%s\n'\'' "$*" >>"$HERDR_METADATA_LOG"' >"$fake_bin/herdr"
  chmod +x "$fake_bin/git" "$fake_bin/herdr"

  if ! HOME="$BOOTSTRAP_TEST_DIR/zsh-home" \
    PATH="$fake_bin:/usr/bin:/bin" \
    HERDR_WORKSPACE_ID="workspace-1" \
    FAKE_GIT_BRANCH="feature/test" \
    HERDR_METADATA_LOG="$metadata_log" \
    zsh -dfc 'source "$1" >/dev/null 2>&1 || true; _herdr_report_git_branch' zsh "$zshrc"; then
    fail "zshrc does not report Git branch metadata"
  fi

  [[ "$(cat "$metadata_log")" == "workspace report-metadata workspace-1 --source user:shell-git --token branch=feature/test" ]] || fail "wrong Git branch metadata"
}

test_zshrc_clears_git_branch() {
  local zshrc="$1"
  local fake_bin="$BOOTSTRAP_TEST_DIR/fake-clear-bin"
  local metadata_log="$BOOTSTRAP_TEST_DIR/metadata-clear.log"
  mkdir -p "$fake_bin"
  : >"$metadata_log"
  printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_bin/git"
  printf '%s\n' '#!/bin/sh' 'printf '\''%s\n'\'' "$*" >>"$HERDR_METADATA_LOG"' >"$fake_bin/herdr"
  chmod +x "$fake_bin/git" "$fake_bin/herdr"

  if ! HOME="$BOOTSTRAP_TEST_DIR/zsh-home" \
    PATH="$fake_bin:/usr/bin:/bin" \
    HERDR_WORKSPACE_ID="workspace-1" \
    HERDR_METADATA_LOG="$metadata_log" \
    zsh -dfc 'source "$1" >/dev/null 2>&1 || true; _herdr_report_git_branch' zsh "$zshrc"; then
    fail "zshrc does not clear Git branch metadata"
  fi

  [[ "$(cat "$metadata_log")" == "workspace report-metadata workspace-1 --source user:shell-git --clear-token branch" ]] || fail "stale Git branch metadata not cleared"
}

test_main_installs_herdr_after_brew() {
  BOOTSTRAP_MAIN_LOG="$BOOTSTRAP_TEST_DIR/main.log"
  export BOOTSTRAP_MAIN_LOG
  : >"$BOOTSTRAP_MAIN_LOG"

  stub_main_dependencies
  main >/dev/null

  [[ "$(cat "$BOOTSTRAP_MAIN_LOG")" == $'brew\nherdr' ]] || fail "main does not install Herdr after Brew packages"
}

stub_main_dependencies() {
  detect_os() { :; }
  install_prerequisites() { :; }
  install_homebrew() { :; }
  install_brew_packages() { printf 'brew\n' >>"$BOOTSTRAP_MAIN_LOG"; }
  install_herdr() { printf 'herdr\n' >>"$BOOTSTRAP_MAIN_LOG"; }
  install_oh_my_zsh() { :; }
  install_nvm() { :; }
  bridge_mise_rbenv() { :; }
  set_default_shell() { :; }
  backup_existing_dotfiles() { :; }
  run_dotbot() { :; }
  install_nvim_plugins() { :; }
  install_work_config() { :; }
  configure_global_git() { :; }
  configure_figma_git() { :; }
  info() { :; }
  ok() { :; }
}

brew() {
  printf '%s\n' "$*" >>"$BOOTSTRAP_BREW_LOG"
}

curl() {
  printf '%s\n' "$*" >>"$BOOTSTRAP_CURL_LOG"
  printf '%s\n' \
    '#!/bin/sh' \
    'mkdir -p "$HERDR_INSTALL_DIR"' \
    'cp "$BOOTSTRAP_HERDR_STUB" "$HERDR_INSTALL_DIR/herdr"' \
    'chmod +x "$HERDR_INSTALL_DIR/herdr"'
}

tmuxinator() {
  :
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_tests "$@"
