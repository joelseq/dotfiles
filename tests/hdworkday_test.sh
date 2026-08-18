#!/usr/bin/env bash
set -euo pipefail

run_tests() {
  local repo_root hdworkday
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  hdworkday="$repo_root/bin/hdworkday"

  HDWORKDAY_TEST_DIR="$(mktemp -d)"
  export HDWORKDAY_TEST_DIR
  trap 'rm -rf "$HDWORKDAY_TEST_DIR"' EXIT
  export HOME="$HDWORKDAY_TEST_DIR/home"
  mkdir -p "$HOME/.config/herdr-mirror" "$HDWORKDAY_TEST_DIR/bin"
  cat >"$HOME/.config/herdr-mirror/hosts.toml" <<'CONFIG'
[hosts.devbox-1]
target = "target-1"
[hosts.devbox-2]
target = "target-2"
[hosts.devbox-3]
target = "target-3"
CONFIG
  HDWORKDAY_EVENT_LOG="$HDWORKDAY_TEST_DIR/events.log"
  export HDWORKDAY_EVENT_LOG
  : >"$HDWORKDAY_EVENT_LOG"
  create_stubs
  export PATH="$HDWORKDAY_TEST_DIR/bin:/usr/bin:/bin"

  test_open_workday_opens_local_first_then_starts_mirror
  test_local_target_opens_local_herdr
  printf 'hdworkday tests passed\n'
}

create_stubs() {
  cat >"$HDWORKDAY_TEST_DIR/bin/herdr" <<'STUB'
#!/bin/sh
printf 'herdr %s\n' "$*" >>"$HDWORKDAY_EVENT_LOG"
STUB
  cat >"$HDWORKDAY_TEST_DIR/bin/osascript" <<'STUB'
#!/bin/sh
printf 'osascript %s\n' "$*" >>"$HDWORKDAY_EVENT_LOG"
STUB
  cat >"$HDWORKDAY_TEST_DIR/bin/ssh" <<'STUB'
#!/bin/sh
printf 'ssh %s\n' "$*" >>"$HDWORKDAY_EVENT_LOG"
exit 0
STUB
  cat >"$HDWORKDAY_TEST_DIR/bin/pgrep" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$HDWORKDAY_TEST_DIR/bin/"*
}

test_open_workday_opens_local_first_then_starts_mirror() {
  local expected
  : >"$HDWORKDAY_EVENT_LOG"

  zsh "$hdworkday" open >/dev/null

  expected=$'osascript '"$(dirname "$hdworkday")/hdworkday.applescript $hdworkday workday local local false devbox-1 target-1 false devbox-2 target-2 false devbox-3 target-3 false"$'\nherdr plugin action invoke mirror.start\nherdr plugin action invoke mirror.once'
  [[ "$(cat "$HDWORKDAY_EVENT_LOG")" == "$expected" ]] || fail "workday launch order wrong"
}

test_local_target_opens_local_herdr() {
  : >"$HDWORKDAY_EVENT_LOG"

  zsh "$hdworkday" connect-target local local >/dev/null

  [[ "$(cat "$HDWORKDAY_EVENT_LOG")" == "herdr " ]] || fail "local tab did not open local Herdr"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_tests "$@"
