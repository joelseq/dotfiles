#!/usr/bin/env bash
set -euo pipefail

run_tests() {
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  layout_action="$repo_root/bin/herdr-layout-action"

  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  trap 'rm -rf "$TEST_DIR"' EXIT
  export HOME="$TEST_DIR/home"
  mkdir -p "$HOME/.local/bin" "$TEST_DIR/bin"
  ACTION_LOG="$TEST_DIR/actions.log"
  export ACTION_LOG
  create_stubs
  export PATH="$TEST_DIR/bin:/usr/bin:/bin"

  test_remote_tab_uses_native_action
  test_remote_workspace_and_splits_use_native_actions
  test_controller_actions_use_mirror
  printf 'herdr layout action tests passed\n'
}

create_stubs() {
  cat >"$TEST_DIR/bin/herdr" <<'STUB'
#!/bin/sh
printf 'herdr %s\n' "$*" >>"$ACTION_LOG"
STUB
  cat >"$HOME/.local/bin/herdr-mirror" <<'STUB'
#!/bin/sh
printf 'mirror %s\n' "$*" >>"$ACTION_LOG"
STUB
  chmod +x "$TEST_DIR/bin/herdr"
  chmod +x "$HOME/.local/bin/herdr-mirror"
}

test_remote_tab_uses_native_action() {
  : >"$ACTION_LOG"

  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 \
    HERDR_ACTIVE_PANE_ID=pane-1 \
    HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" tab

  [[ "$(cat "$ACTION_LOG")" == "herdr tab create --workspace workspace-1 --cwd /repo --focus" ]] ||
    fail "remote tab did not use native Herdr action"
}

test_remote_workspace_and_splits_use_native_actions() {
  local expected
  : >"$ACTION_LOG"

  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" workspace
  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" split-right
  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" split-down

  expected=$'herdr workspace create --cwd /repo --focus\nherdr pane split --pane pane-1 --direction right --cwd /repo --focus\nherdr pane split --pane pane-1 --direction down --cwd /repo --focus'
  [[ "$(cat "$ACTION_LOG")" == "$expected" ]] ||
    fail "remote workspace or split did not use native Herdr action"
}

test_controller_actions_use_mirror() {
  local expected
  mkdir -p "$HOME/.config/herdr-mirror"
  touch "$HOME/.config/herdr-mirror/hosts.toml"
  : >"$ACTION_LOG"

  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" tab
  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" workspace
  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" split-right
  HERDR_ACTIVE_WORKSPACE_ID=workspace-1 HERDR_ACTIVE_PANE_ID=pane-1 HERDR_ACTIVE_PANE_CWD=/repo \
    "$layout_action" split-down

  expected=$'mirror remote-tab\nmirror remote-workspace\nmirror remote-split right\nmirror remote-split down'
  [[ "$(cat "$ACTION_LOG")" == "$expected" ]] ||
    fail "controller action did not use Mirror"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_tests "$@"
