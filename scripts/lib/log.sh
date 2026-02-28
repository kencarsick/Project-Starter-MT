#!/usr/bin/env bash
# scripts/lib/log.sh — Colored logging utilities and terminal title control
# No dependencies. Source this first.

set -euo pipefail

[[ -n "${_LIB_LOG_SOURCED:-}" ]] && return 0
_LIB_LOG_SOURCED=1

# ---------------------------------------------------------------------------
# ANSI color codes
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

export RED GREEN YELLOW BLUE CYAN MAGENTA BOLD DIM RESET

# ---------------------------------------------------------------------------
# Logging functions
# ---------------------------------------------------------------------------

_log_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
  local msg="$1"
  printf "${BLUE}[%s] [INFO]${RESET} %s\n" "$(_log_timestamp)" "$msg"
}

log_warn() {
  local msg="$1"
  printf "${YELLOW}[%s] [WARN]${RESET} %s\n" "$(_log_timestamp)" "$msg" >&2
}

log_error() {
  local msg="$1"
  printf "${RED}[%s] [ERROR]${RESET} %s\n" "$(_log_timestamp)" "$msg" >&2
}

log_debug() {
  local msg="$1"
  [[ "${LOG_DEBUG:-0}" == "1" ]] || return 0
  printf "${DIM}${CYAN}[%s] [DEBUG]${RESET} %s\n" "$(_log_timestamp)" "$msg" >&2
}

# ---------------------------------------------------------------------------
# Terminal title
# ---------------------------------------------------------------------------

set_terminal_title() {
  local title="$1"
  # No-op if not in a terminal
  [[ -z "${TERM:-}" || "${TERM:-}" == "dumb" ]] && return 0
  printf '\033]2;%s\a' "$title"
}
