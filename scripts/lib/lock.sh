#!/usr/bin/env bash
# scripts/lib/lock.sh — PID-based git operation lock serialization
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_LOCK_SOURCED:-}" ]] && return 0
_LIB_LOCK_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

LOCK_FILE="${PROJECT_ROOT}/.git/workflow.lock"
export LOCK_FILE

# ---------------------------------------------------------------------------
# Lock acquire/release
# ---------------------------------------------------------------------------

acquire_lock() {
  local timeout
  timeout="$(get_config worktree.lock_timeout 2>/dev/null || echo "60")"
  local elapsed=0

  log_debug "Attempting to acquire lock: $LOCK_FILE (timeout: ${timeout}s)"

  while true; do
    # Try to create lock file atomically via noclobber
    if ( set -o noclobber && printf '%s\n' "$$" > "$LOCK_FILE" ) 2>/dev/null; then
      log_debug "Lock acquired (PID: $$)"
      return 0
    fi

    # Lock file exists — check if the holding PID is still alive
    if [[ -f "$LOCK_FILE" ]]; then
      local holder_pid
      holder_pid="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"

      if [[ -n "$holder_pid" ]] && ! kill -0 "$holder_pid" 2>/dev/null; then
        log_warn "Removing stale lock held by dead PID $holder_pid"
        rm -f "$LOCK_FILE"
        continue
      fi
    fi

    if [[ "$elapsed" -ge "$timeout" ]]; then
      log_error "acquire_lock: timed out after ${timeout}s"
      return 1
    fi

    log_debug "Lock held — waiting... (${elapsed}s / ${timeout}s)"
    sleep 1
    elapsed=$((elapsed + 1))
  done
}

release_lock() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    log_debug "release_lock: lock file does not exist (already released?)"
    return 0
  fi

  local holder_pid
  holder_pid="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"

  if [[ "$holder_pid" != "$$" ]]; then
    log_warn "release_lock: lock held by PID $holder_pid, not current process $$"
    return 1
  fi

  rm -f "$LOCK_FILE"
  log_debug "Lock released (PID: $$)"
}
