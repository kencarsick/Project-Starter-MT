#!/usr/bin/env bash
# scripts/status.sh — Pipeline status reporter
# Shows status of all running pipelines (tmux sessions matching issue-*).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=scripts/lib/sentinel.sh
source "${SCRIPT_DIR}/lib/sentinel.sh"
# shellcheck source=scripts/lib/worktree.sh
source "${SCRIPT_DIR}/lib/worktree.sh"

STAGES=(orchestrator dev qa merge prod-qa)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

printf '\n'
printf "  ${BOLD}Pipeline Status${RESET}\n"
printf "  ===============\n"
printf '\n'

# ---------------------------------------------------------------------------
# Find active pipelines
# ---------------------------------------------------------------------------

sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^issue-' || true)"

if [[ -z "$sessions" ]]; then
  printf "  No active pipelines found.\n\n"
  exit 0
fi

# Table header
printf "  ${BOLD}%-12s  %-14s  %-18s  %-12s  %s${RESET}\n" \
  "Issue" "Stage" "Status" "Elapsed" "Worktree"
printf "  %-12s  %-14s  %-18s  %-12s  %s\n" \
  "------------" "--------------" "------------------" "------------" "--------"

# ---------------------------------------------------------------------------
# Report each pipeline
# ---------------------------------------------------------------------------

while IFS= read -r session; do
  [[ -z "$session" ]] && continue

  issue_num="${session#issue-}"
  worktree_path="$(get_worktree_path "$issue_num")"

  # Determine current stage and status from sentinel files
  current_stage=""
  current_status=""
  last_completed_stage=""

  for stage in "${STAGES[@]}"; do
    status_val="$(read_sentinel "$worktree_path" "$stage" 2>/dev/null || true)"
    if [[ -n "$status_val" ]]; then
      last_completed_stage="$stage"
      current_stage="$stage"
      current_status="$status_val"
    else
      # First stage without a sentinel is the currently running one
      # (only if a previous stage completed)
      if [[ -n "$last_completed_stage" ]]; then
        current_stage="$stage"
        current_status="running"
      fi
      break
    fi
  done

  # If no sentinels at all, first stage is running
  if [[ -z "$current_stage" ]]; then
    current_stage="${STAGES[0]}"
    current_status="running"
  fi

  # Elapsed time from tmux session creation
  created_at="$(tmux display-message -t "$session" -p '#{session_created}' 2>/dev/null || echo "0")"
  now="$(date +%s)"
  elapsed_secs=$((now - created_at))
  elapsed_min=$((elapsed_secs / 60))
  elapsed_sec=$((elapsed_secs % 60))
  elapsed_display="$(printf '%dm %02ds' "$elapsed_min" "$elapsed_sec")"

  # Color-code the status
  case "$current_status" in
    DONE|PASS)           status_colored="${GREEN}${current_status}${RESET}" ;;
    PASS-WITH-NITS)      status_colored="${YELLOW}${current_status}${RESET}" ;;
    FAIL|STUCK|CI_FAILED|CONFLICT|BLOCKED|NO_PR)
                         status_colored="${RED}${current_status}${RESET}" ;;
    NEEDS_HUMAN)         status_colored="${MAGENTA}${current_status}${RESET}" ;;
    running)             status_colored="${CYAN}running${RESET}" ;;
    *)                   status_colored="$current_status" ;;
  esac

  # Worktree exists?
  if [[ -d "$worktree_path" ]]; then
    wt_indicator="${GREEN}yes${RESET}"
  else
    wt_indicator="${RED}no${RESET}"
  fi

  printf "  %-12s  %-14s  %-18b  %-12s  %b\n" \
    "#${issue_num}" "$current_stage" "$status_colored" "$elapsed_display" "$wt_indicator"

done <<< "$sessions"

printf '\n'
