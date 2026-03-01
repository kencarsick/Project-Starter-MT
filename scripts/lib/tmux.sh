#!/usr/bin/env bash
# scripts/lib/tmux.sh — tmux session and pane management
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_TMUX_SOURCED:-}" ]] && return 0
_LIB_TMUX_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# ---------------------------------------------------------------------------
# Session management
# ---------------------------------------------------------------------------

create_tmux_session() {
  local session_name="$1"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    log_debug "tmux session '$session_name' already exists"
    return 0
  fi

  tmux new-session -d -s "$session_name"
  log_info "Created tmux session: $session_name"
}

# ---------------------------------------------------------------------------
# Pane management
# ---------------------------------------------------------------------------

create_tmux_pane() {
  local session_name="$1"
  local pane_title="$2"

  local pane_id
  pane_id=$(tmux split-window -t "$session_name" -d -P -F "#{pane_id}")

  # Apply layout from config
  local layout
  layout="$(get_config tmux.layout 2>/dev/null || echo "tiled")"
  tmux select-layout -t "$session_name" "$layout" 2>/dev/null || true

  # Set pane title if enabled
  local titles_enabled
  titles_enabled="$(get_config tmux.pane_titles 2>/dev/null || echo "true")"
  if [[ "$titles_enabled" == "true" ]]; then
    set_pane_title "$session_name" "$pane_id" "$pane_title"
  fi

  log_debug "Created pane $pane_id in session $session_name"
  printf '%s' "$pane_id"
}

set_pane_title() {
  local session_name="$1"
  local pane_id="$2"
  local title="$3"

  tmux select-pane -t "$pane_id" -T "$title" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Pane interaction
# ---------------------------------------------------------------------------

tmux_send_keys() {
  local session_name="$1"
  local pane_id="$2"
  local command="$3"
  local is_tui="${4:-false}"

  if [[ "$is_tui" == "true" ]]; then
    # For TUI apps (Claude Code): send text, pause for input to register, then Enter
    tmux send-keys -t "$pane_id" -l "$command"
    sleep 1
    tmux send-keys -t "$pane_id" Enter
  else
    # For shell commands: send text + Enter together
    tmux send-keys -t "$pane_id" "$command" Enter
  fi
  log_debug "Sent to pane $pane_id: $command"
}

tmux_pipe_pane() {
  local session_name="$1"
  local pane_id="$2"
  local log_file="$3"

  mkdir -p "$(dirname "$log_file")"
  tmux pipe-pane -t "$pane_id" -o "cat >> '${log_file}'"
  log_debug "Piping pane $pane_id output to $log_file"
}
