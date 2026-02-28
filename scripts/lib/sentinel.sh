#!/usr/bin/env bash
# scripts/lib/sentinel.sh — Sentinel file I/O for inter-agent communication
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_SENTINEL_SOURCED:-}" ]] && return 0
_LIB_SENTINEL_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# Valid sentinel status values
readonly SENTINEL_DONE="DONE"
readonly SENTINEL_STUCK="STUCK"
readonly SENTINEL_NEEDS_HUMAN="NEEDS_HUMAN"
readonly SENTINEL_PASS="PASS"
readonly SENTINEL_PASS_WITH_NITS="PASS-WITH-NITS"
readonly SENTINEL_FAIL="FAIL"

# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------

_sentinel_dir() {
  local worktree_path="$1"
  local workflow_dir
  workflow_dir="$(get_config sentinel.workflow_dir 2>/dev/null || echo ".claude-workflow")"
  printf '%s/%s' "$worktree_path" "$workflow_dir"
}

_sentinel_file() {
  local worktree_path="$1"
  local agent_name="$2"
  printf '%s/%s.done' "$(_sentinel_dir "$worktree_path")" "$agent_name"
}

_report_file() {
  local worktree_path="$1"
  local agent_name="$2"
  printf '%s/%s.report' "$(_sentinel_dir "$worktree_path")" "$agent_name"
}

# ---------------------------------------------------------------------------
# Sentinel write/read
# ---------------------------------------------------------------------------

write_sentinel() {
  local worktree_path="$1"
  local agent_name="$2"
  local status="$3"
  local message="${4:-}"

  local sentinel_dir
  sentinel_dir="$(_sentinel_dir "$worktree_path")"
  mkdir -p "$sentinel_dir"

  local target_file
  target_file="$(_sentinel_file "$worktree_path" "$agent_name")"

  # Atomic write via temp file + mv
  local tmpfile
  tmpfile="$(mktemp "${target_file}.XXXXXX")"
  if [[ -n "$message" ]]; then
    printf '%s\n%s\n' "$status" "$message" > "$tmpfile"
  else
    printf '%s\n' "$status" > "$tmpfile"
  fi
  mv "$tmpfile" "$target_file"

  log_debug "Wrote sentinel: $agent_name -> $status"
}

read_sentinel() {
  local worktree_path="$1"
  local agent_name="$2"
  local sentinel_file
  sentinel_file="$(_sentinel_file "$worktree_path" "$agent_name")"

  if [[ ! -f "$sentinel_file" ]]; then
    return 1
  fi

  # Return only the first line (the status word)
  head -n 1 "$sentinel_file"
}

# ---------------------------------------------------------------------------
# Polling
# ---------------------------------------------------------------------------

poll_sentinel() {
  local worktree_path="$1"
  local agent_name="$2"
  local callback="${3:-}"

  local poll_interval
  poll_interval="$(get_config sentinel.poll_interval 2>/dev/null || echo "3")"

  log_debug "Polling for sentinel: $agent_name (interval: ${poll_interval}s)"

  while true; do
    local status
    if status="$(read_sentinel "$worktree_path" "$agent_name" 2>/dev/null)"; then
      log_debug "Sentinel appeared: $agent_name -> $status"
      if [[ -n "$callback" ]]; then
        "$callback" "$agent_name" "$status"
      fi
      printf '%s' "$status"
      return 0
    fi
    sleep "$poll_interval"
  done
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clear_sentinels() {
  local worktree_path="$1"
  local sentinel_dir
  sentinel_dir="$(_sentinel_dir "$worktree_path")"

  if [[ -d "$sentinel_dir" ]]; then
    rm -f "${sentinel_dir}"/*.done "${sentinel_dir}"/*.report 2>/dev/null || true
    log_debug "Cleared all sentinels in $sentinel_dir"
  fi
}

# ---------------------------------------------------------------------------
# Reports
# ---------------------------------------------------------------------------

write_report() {
  local worktree_path="$1"
  local agent_name="$2"
  local content="$3"

  local sentinel_dir
  sentinel_dir="$(_sentinel_dir "$worktree_path")"
  mkdir -p "$sentinel_dir"

  local target_file
  target_file="$(_report_file "$worktree_path" "$agent_name")"

  # Atomic write
  local tmpfile
  tmpfile="$(mktemp "${target_file}.XXXXXX")"
  printf '%s\n' "$content" > "$tmpfile"
  mv "$tmpfile" "$target_file"

  log_debug "Wrote report: $agent_name"
}

read_report() {
  local worktree_path="$1"
  local agent_name="$2"
  local report_file
  report_file="$(_report_file "$worktree_path" "$agent_name")"

  if [[ ! -f "$report_file" ]]; then
    log_warn "read_report: report file not found: $report_file"
    return 1
  fi

  cat "$report_file"
}
