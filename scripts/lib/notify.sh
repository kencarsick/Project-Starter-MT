#!/usr/bin/env bash
# scripts/lib/notify.sh — macOS desktop notifications via osascript
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_NOTIFY_SOURCED:-}" ]] && return 0
_LIB_NOTIFY_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# ---------------------------------------------------------------------------
# Core notification
# ---------------------------------------------------------------------------

send_notification() {
  local title="$1"
  local message="$2"

  # Check if notifications are enabled in config
  local enabled
  enabled="$(get_config notifications.enabled 2>/dev/null || echo "true")"
  if [[ "$enabled" != "true" ]]; then
    log_debug "Notifications disabled in config — skipping"
    return 0
  fi

  # macOS only
  if ! command -v osascript >/dev/null 2>&1; then
    log_warn "send_notification: osascript not found — skipping (not macOS?)"
    return 0
  fi

  # Determine sound from config
  local play_sound
  play_sound="$(get_config notifications.sound 2>/dev/null || echo "true")"

  # Escape double quotes for AppleScript
  local safe_title="${title//\"/\\\"}"
  local safe_message="${message//\"/\\\"}"

  if [[ "$play_sound" == "true" ]]; then
    osascript -e "display notification \"${safe_message}\" with title \"${safe_title}\" sound name \"Default\"" 2>/dev/null || true
  else
    osascript -e "display notification \"${safe_message}\" with title \"${safe_title}\"" 2>/dev/null || true
  fi

  log_debug "Notification sent: [$title] $message"
}

# ---------------------------------------------------------------------------
# Convenience wrappers
# ---------------------------------------------------------------------------

notify_needs_human() {
  local issue_number="$1"
  local agent_name="$2"
  local message="$3"

  send_notification \
    "Issue #${issue_number} — [${agent_name}] needs your attention" \
    "$message"
  log_warn "NEEDS_HUMAN: Issue #${issue_number} [${agent_name}]: $message"
}

notify_stage_complete() {
  local issue_number="$1"
  local stage="$2"

  send_notification \
    "Issue #${issue_number} — Stage complete" \
    "${stage} stage finished for issue #${issue_number}"
}

notify_pipeline_result() {
  local issue_number="$1"
  local result="$2"

  local title body
  if [[ "$result" == "success" || "$result" == "DONE" || "$result" == "PASS" ]]; then
    title="Issue #${issue_number} — Pipeline complete"
    body="All stages passed. PR merged successfully."
  else
    title="Issue #${issue_number} — Pipeline failed"
    body="Pipeline stopped: $result"
  fi

  send_notification "$title" "$body"
}
