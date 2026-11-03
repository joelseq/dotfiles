#!/usr/bin/env bash
set -euo pipefail

run_tests() {
  local repo_root scenario
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  REX_TEST_SETUP="$repo_root/bin/setup-rex"
  REX_TEST_DIR="$(mktemp -d)"
  export REX_TEST_SETUP REX_TEST_DIR
  trap 'rm -rf "$REX_TEST_DIR"' EXIT

  for scenario in missing existing existing-large-help unrelated download-failed install-failed unavailable start-failed proxy-install-failed proxy-start-failed environment-missing disabled login existing-session wrong-os; do
    test_setup "$scenario"
  done

  printf 'Rex bootstrap tests passed (15 cases).\n'
}

test_setup() (
  local scenario="$1" status=0 output
  local test_dir="$REX_TEST_DIR/$scenario"
  mkdir -p "$test_dir"
  export REX_TEST_SCENARIO="$scenario"
  export REX_TEST_AVAILABLE="$test_dir/available"
  export REX_TEST_LOG="$test_dir/calls"
  export CODER_WORKSPACE_NAME="devbox-2"
  export ANTHROPIC_API_KEY="fixture-ai-secret"
  export GIT_ASKPASS="/fixture/coder-askpass"
  export CUSTOM_CODER_SETTING="fixture-custom"
  export SSH_AUTH_SOCK="/fixture/transient-agent"
  export TERM_PROGRAM="fixture-terminal"
  : >"$REX_TEST_LOG"

  if [[ "$scenario" != "missing" && "$scenario" != "unrelated" && "$scenario" != "download-failed" && "$scenario" != "install-failed" && "$scenario" != "unavailable" ]]; then
    touch "$REX_TEST_AVAILABLE"
  fi

  # Load definitions without running the setup entry point.
  # shellcheck disable=SC1090
  source <(sed '$d' "$REX_TEST_SETUP")

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  uname() {
    if [[ "$scenario" == "wrong-os" ]]; then
      printf 'Darwin\n'
    else
      printf 'Linux\n'
    fi
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  command() {
    if [[ "$*" == "-v rex" ]]; then
      [[ -f "$REX_TEST_AVAILABLE" || "$scenario" == "unrelated" ]]
    else
      builtin command "$@"
    fi
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  mktemp() {
    : >"$test_dir/installer"
    printf '%s\n' "$test_dir/installer"
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  curl() {
    printf 'download\n' >>"$REX_TEST_LOG"
    [[ "$1" == "-fsSL" && "$2" == "https://pkgs.superlogical.com/rex/install.sh" && "$3" == "-o" ]] || fail 'Wrong installer request'

    if [[ "$scenario" == "download-failed" ]]; then
      return 1
    fi

    cat >"$4" <<'INSTALLER'
#!/bin/sh
printf 'install %s\n' "$*" >>"$REX_TEST_LOG"
if [ "$REX_TEST_SCENARIO" = install-failed ]; then
  exit 1
fi
if [ "$REX_TEST_SCENARIO" != unavailable ]; then
  touch "$REX_TEST_AVAILABLE"
fi
INSTALLER
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  install_rex_proxy() {
    [[ "$scenario" != "proxy-install-failed" ]]
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  start_rex_proxy() {
    if [[ "$scenario" == "proxy-start-failed" ]]; then
      return 1
    fi

    printf 'socks5://127.0.0.1:17296\n'
  }

  # Only the process-environment validation is mocked; the launch arguments
  # and secret handling are checked by the Rex stub below.
  # shellcheck disable=SC2329
  python3() {
    if [[ "$scenario" == "environment-missing" || "$scenario" == "disabled" ]]; then
      printf 'Existing sessions were preserved.\n' >&2
      return 1
    fi
  }

  # Called by the sourced Rex setup.
  # shellcheck disable=SC2329
  rex() {
    case "$1" in
      --help)
        if [[ -f "$REX_TEST_AVAILABLE" ]]; then
          printf 'The multiplexer for all work.\n'

          if [[ "$scenario" == "existing-large-help" ]]; then
            sleep 0.05
            printf '%10000s\n' 'Remaining help text'
          fi
        else
          printf '(R)?ex automation framework\n'
        fi
        ;;
      server)
        printf '%s\n' "$*" >>"$REX_TEST_LOG"
        [[ "$*" == 'server start --tailscale --tailscale-hostname rex-devbox-2 '* ]] || fail 'Wrong server flags'
        [[ "$*" != *'--allow-anonymous'* && "$*" != *'--extra-listen'* ]] || fail 'Native setup opened an anonymous listener'
        [[ "$ALL_PROXY" == 'socks5://127.0.0.1:17296' && "$*" == *'--env ALL_PROXY'* ]] || fail 'Native proxy was not configured'
        [[ "$*" == *'--env ANTHROPIC_API_KEY'* && "$*" == *'--env GIT_ASKPASS'* && "$*" == *'--env CODER_WORKSPACE_NAME'* && "$*" == *'--env CUSTOM_CODER_SETTING'* ]] || fail 'Coder environment was not forwarded'
        [[ "$*" != *'fixture-ai-secret'* && "$*" != *'fixture-custom'* ]] || fail 'Secret values leaked into arguments'
        [[ "$*" != *'--env SSH_AUTH_SOCK'* && "$*" != *'--env TERM_PROGRAM'* && "$*" != *'--env REX_TEST_'* ]] || fail 'Transient terminal environment was forwarded'

        if [[ "$scenario" == "start-failed" ]]; then
          return 1
        fi

        printf '{"instance_id":"server-1","session_count":2}\n'
        ;;
      api)
        [[ "$*" == 'api call server.tailscale.login {}' ]] || fail 'Unexpected native API call'
        printf '{"tailscale":{"state":"needs_login","auth_url":"https://login.tailscale.com/a/test"}}\n'
        ;;
      *) fail 'Unexpected Rex command; existing servers must not stop' ;;
    esac
  }

  output="$(main 2>&1)" || status=$?

  case "$scenario" in
    missing|unrelated)
      [[ "$status" -eq 0 ]] || fail "$scenario installation failed"
      grep -Fxq 'install --channel snapshot' "$REX_TEST_LOG" || fail 'Wrong install channel'
      grep -q '^server start ' "$REX_TEST_LOG" || fail 'Server was not started'
      ;;
    existing|existing-large-help|existing-session)
      [[ "$status" -eq 0 ]] || fail 'Existing installation failed'
      ! grep -q '^download' "$REX_TEST_LOG" || fail 'Existing Rex downloaded again'
      grep -q '^server start ' "$REX_TEST_LOG" || fail 'Existing installation did not start server'
      ;;
    download-failed|install-failed|unavailable)
      [[ "$status" -ne 0 ]] || fail "$scenario was ignored"
      ! grep -q '^server start ' "$REX_TEST_LOG" || fail 'Server started after install failure'
      ;;
    start-failed|environment-missing|disabled)
      [[ "$status" -ne 0 ]] || fail "$scenario was ignored"
      [[ "$output" == *'Cannot start'* || "$output" == *'sessions were preserved'* ]] || fail 'Missing startup error'
      ;;
    proxy-install-failed|proxy-start-failed)
      [[ "$status" -ne 0 ]] || fail "$scenario was ignored"
      ! grep -q '^server start ' "$REX_TEST_LOG" || fail 'Server started after proxy failure'
      ;;
    login)
      [[ "$status" -eq 0 && "$output" == *'https://login.tailscale.com/a/test'* ]] || fail 'Sign-in link was lost'
      ;;
    wrong-os)
      [[ "$status" -ne 0 && ! -s "$REX_TEST_LOG" ]] || fail 'Unsupported OS changed the machine'
      ;;
  esac

  [[ ! -e "$test_dir/installer" ]] || fail 'Installer temporary file was not removed'
)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_tests "$@"
