#!/usr/bin/env bash
# scripts/lib/config.sh — YAML configuration reader via yq
# Depends on: log.sh

set -euo pipefail

[[ -n "${_LIB_CONFIG_SOURCED:-}" ]] && return 0
_LIB_CONFIG_SOURCED=1

# shellcheck source=scripts/lib/log.sh
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# ---------------------------------------------------------------------------
# Project root detection
# ---------------------------------------------------------------------------

_detect_project_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local root
  root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" || {
    log_error "config.sh: not inside a git repository"
    return 1
  }

  # Strip .worktrees suffix — always return the main repo root
  if [[ "$root" == *"/.worktrees/"* ]]; then
    root="${root%%/.worktrees/*}"
  fi

  printf '%s' "$root"
}

PROJECT_ROOT="${PROJECT_ROOT:-$(_detect_project_root)}"
export PROJECT_ROOT

WORKFLOW_YAML="${PROJECT_ROOT}/.claude/workflow.yaml"
export WORKFLOW_YAML

# ---------------------------------------------------------------------------
# Config accessors
# ---------------------------------------------------------------------------

get_config() {
  local dotpath="$1"

  if [[ ! -f "$WORKFLOW_YAML" ]]; then
    log_error "get_config: workflow.yaml not found at $WORKFLOW_YAML"
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    log_error "get_config: yq is not installed"
    return 1
  fi

  local selector=".${dotpath}"
  local value
  value="$(yq e "$selector" "$WORKFLOW_YAML" 2>/dev/null)"

  # yq returns "null" for missing keys
  if [[ "$value" == "null" || -z "$value" ]]; then
    log_warn "get_config: key '$dotpath' not found in $WORKFLOW_YAML"
    return 1
  fi

  printf '%s' "$value"
}

get_config_array() {
  local dotpath="$1"

  if [[ ! -f "$WORKFLOW_YAML" ]]; then
    log_error "get_config_array: workflow.yaml not found"
    return 1
  fi

  # Output one item per line
  yq e ".${dotpath}[]" "$WORKFLOW_YAML" 2>/dev/null
}
