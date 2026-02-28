#!/usr/bin/env bash
# scripts/run-all.sh — Multi-issue DAG runner
# Reads an Epic, resolves dependencies between task issues, and launches
# parallel impl.sh pipelines in dependency order.
#
# Usage:
#   ./scripts/run-all.sh [options]
#   ./scripts/run-all.sh --epic #1
#   ./scripts/run-all.sh --epic #1 --max-parallel 3
#   ./scripts/run-all.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Pre-pass: --config must be resolved before sourcing libraries
# ---------------------------------------------------------------------------

_prev_arg=""
for arg in "$@"; do
  if [[ "$_prev_arg" == "--config" ]]; then
    export WORKFLOW_YAML="$arg"
  fi
  _prev_arg="$arg"
done
unset _prev_arg

# Source libraries
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=scripts/lib/github.sh
source "${SCRIPT_DIR}/lib/github.sh"
# shellcheck source=scripts/lib/dag.sh
source "${SCRIPT_DIR}/lib/dag.sh"
# shellcheck source=scripts/lib/notify.sh
source "${SCRIPT_DIR}/lib/notify.sh"

# ---------------------------------------------------------------------------
# State variables
# ---------------------------------------------------------------------------

EPIC_NUM=""
MAX_PARALLEL=0      # 0 = unlimited
DRY_RUN=false

# Run tracking directory (temp)
_RUN_DIR=""

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Multi-issue DAG runner. Reads an Epic, resolves dependencies, and launches
parallel impl.sh pipelines in dependency order.

Options:
  --epic <number>       GitHub Epic issue number (auto-detects if omitted)
  --max-parallel <N>    Maximum concurrent pipelines (default: unlimited)
  --config <path>       Override workflow.yaml path
  --dry-run             Show DAG and execution plan without running
  -h, --help            Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --epic #1
  $(basename "$0") --epic #1 --max-parallel 3
  $(basename "$0") --dry-run --epic #1
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        ;;
      --epic)
        shift
        EPIC_NUM="${1:-}"
        if [[ -z "$EPIC_NUM" ]]; then
          log_error "Missing argument after --epic"
          exit 2
        fi
        EPIC_NUM="${EPIC_NUM#\#}"
        shift
        ;;
      --max-parallel)
        shift
        MAX_PARALLEL="${1:-}"
        if [[ -z "$MAX_PARALLEL" ]]; then
          log_error "Missing argument after --max-parallel"
          exit 2
        fi
        if ! [[ "$MAX_PARALLEL" =~ ^[0-9]+$ ]]; then
          log_error "Invalid --max-parallel value: $MAX_PARALLEL (must be numeric)"
          exit 2
        fi
        shift
        ;;
      --config)
        # Already handled in pre-pass
        shift; shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Run directory management (temp files for tracking)
# ---------------------------------------------------------------------------

_run_init() {
  _RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/run-all.XXXXXX")"
  mkdir -p "${_RUN_DIR}/pids"
  mkdir -p "${_RUN_DIR}/status"
  : > "${_RUN_DIR}/started"
  : > "${_RUN_DIR}/completed"
  : > "${_RUN_DIR}/failed"
}

_run_cleanup() {
  if [[ -n "${_RUN_DIR:-}" && -d "${_RUN_DIR:-}" ]]; then
    rm -rf "$_RUN_DIR"
    _RUN_DIR=""
  fi
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

preflight_checks() {
  log_info "Running preflight checks..."

  local tools=("gh" "git" "tmux" "jq" "yq")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log_error "Required tool not found: $tool. Run ./scripts/setup.sh for details."
      exit 2
    fi
  done

  if ! gh auth status &>/dev/null; then
    log_error "GitHub CLI not authenticated. Run: gh auth login"
    exit 2
  fi

  if [[ ! -x "${SCRIPT_DIR}/impl.sh" ]]; then
    log_error "impl.sh not found or not executable at ${SCRIPT_DIR}/impl.sh"
    exit 2
  fi

  log_info "Preflight checks passed"
}

# ---------------------------------------------------------------------------
# Count currently running pipelines
# ---------------------------------------------------------------------------

_count_running() {
  local count=0
  for pidfile in "${_RUN_DIR}/pids"/*; do
    [[ -f "$pidfile" ]] || continue
    local pid
    pid="$(cat "$pidfile")"
    if kill -0 "$pid" 2>/dev/null; then
      count=$((count + 1))
    fi
  done
  printf '%s' "$count"
}

# ---------------------------------------------------------------------------
# Launch a single pipeline
# ---------------------------------------------------------------------------

launch_pipeline() {
  local issue_number="$1"

  log_info "Launching pipeline for issue #${issue_number}"
  printf '%s\n' "$issue_number" >> "${_RUN_DIR}/started"

  # Launch impl.sh as a background process
  "${SCRIPT_DIR}/impl.sh" "#${issue_number}" &
  local pid=$!

  printf '%s' "$pid" > "${_RUN_DIR}/pids/${issue_number}"
  printf 'running' > "${_RUN_DIR}/status/${issue_number}"

  log_info "Pipeline #${issue_number} started (PID: $pid)"
}

# ---------------------------------------------------------------------------
# Check for completed pipelines and harvest exit codes
# ---------------------------------------------------------------------------

_check_completions() {
  local any_completed=false

  for pidfile in "${_RUN_DIR}/pids"/*; do
    [[ -f "$pidfile" ]] || continue
    local issue
    issue="$(basename "$pidfile")"
    local pid
    pid="$(cat "$pidfile")"
    local current_status
    current_status="$(cat "${_RUN_DIR}/status/${issue}" 2>/dev/null || echo "unknown")"

    # Skip already finalized
    [[ "$current_status" == "running" ]] || continue

    # Check if still alive
    if kill -0 "$pid" 2>/dev/null; then
      continue
    fi

    # Process exited — harvest exit code
    local exit_code=0
    wait "$pid" 2>/dev/null || exit_code=$?

    if [[ "$exit_code" -eq 0 ]]; then
      log_info "Pipeline #${issue} completed SUCCESSFULLY"
      printf 'success' > "${_RUN_DIR}/status/${issue}"
      printf '%s\n' "$issue" >> "${_RUN_DIR}/completed"
      notify_pipeline_result "$issue" "success"
    else
      log_error "Pipeline #${issue} FAILED (exit code: $exit_code)"
      printf "failed:${exit_code}" > "${_RUN_DIR}/status/${issue}"
      printf '%s\n' "$issue" >> "${_RUN_DIR}/failed"
      notify_pipeline_result "$issue" "failure: exit code $exit_code"
    fi

    any_completed=true
  done

  [[ "$any_completed" == "true" ]]
}

# ---------------------------------------------------------------------------
# Start newly unblocked issues (respecting --max-parallel)
# ---------------------------------------------------------------------------

_start_ready_issues() {
  local ready_issues
  ready_issues="$(get_ready_issues_local "${_RUN_DIR}/completed" "${_RUN_DIR}/started")"

  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue

    # Respect max-parallel limit
    if [[ "$MAX_PARALLEL" -gt 0 ]]; then
      local running
      running="$(_count_running)"
      if [[ "$running" -ge "$MAX_PARALLEL" ]]; then
        log_debug "Max parallel limit reached ($running/$MAX_PARALLEL) — holding #${issue}"
        return 0
      fi
    fi

    launch_pipeline "$issue"
  done <<< "$ready_issues"
}

# ---------------------------------------------------------------------------
# Check if all work is done
# ---------------------------------------------------------------------------

_all_finished() {
  local total started_count finished_count

  total="$(wc -l < "${_DAG_DIR}/issues" | tr -d ' ')"
  started_count="$(wc -l < "${_RUN_DIR}/started" | tr -d ' ')"

  local completed_count failed_count
  completed_count="$(wc -l < "${_RUN_DIR}/completed" | tr -d ' ')"
  failed_count="$(wc -l < "${_RUN_DIR}/failed" | tr -d ' ')"
  finished_count=$((completed_count + failed_count))

  [[ "$started_count" -ge "$total" && "$finished_count" -ge "$started_count" ]]
}

# Check if remaining unstarted issues are permanently blocked
_are_remaining_blocked() {
  local total started_count completed_count failed_count

  total="$(wc -l < "${_DAG_DIR}/issues" | tr -d ' ')"
  started_count="$(wc -l < "${_RUN_DIR}/started" | tr -d ' ')"
  completed_count="$(wc -l < "${_RUN_DIR}/completed" | tr -d ' ')"
  failed_count="$(wc -l < "${_RUN_DIR}/failed" | tr -d ' ')"
  local finished_count=$((completed_count + failed_count))

  # If all started have finished but there are unstarted ones with no ready issues
  if [[ "$finished_count" -ge "$started_count" && "$started_count" -lt "$total" ]]; then
    local ready
    ready="$(get_ready_issues_local "${_RUN_DIR}/completed" "${_RUN_DIR}/started" | wc -l | tr -d ' ')"
    [[ "$ready" -eq 0 ]]
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Monitor loop
# ---------------------------------------------------------------------------

run_monitor_loop() {
  local poll_interval
  poll_interval="$(get_config sentinel.poll_interval 2>/dev/null || echo "3")"

  log_info "Entering monitor loop (poll interval: ${poll_interval}s)..."

  while true; do
    # Check for completions
    if _check_completions; then
      # Something finished — try to start newly unblocked issues
      _start_ready_issues
    fi

    # Check if all done
    if _all_finished; then
      log_info "All pipelines have completed"
      return 0
    fi

    # Check for deadlock (remaining blocked by failures)
    if _are_remaining_blocked; then
      local running
      running="$(_count_running)"
      if [[ "$running" -eq 0 ]]; then
        log_warn "Remaining issues are blocked (dependencies failed or unresolvable)"
        return 1
      fi
    fi

    sleep "$poll_interval"
  done
}

# ---------------------------------------------------------------------------
# Final status report
# ---------------------------------------------------------------------------

print_report() {
  printf '\n'
  printf "  ${BOLD}Run-All Summary — Epic #${EPIC_NUM}${RESET}\n"
  printf "  ==============================\n\n"

  local total completed_count failed_count started_count skipped_count
  total="$(wc -l < "${_DAG_DIR}/issues" | tr -d ' ')"
  completed_count="$(wc -l < "${_RUN_DIR}/completed" | tr -d ' ')"
  failed_count="$(wc -l < "${_RUN_DIR}/failed" | tr -d ' ')"
  started_count="$(wc -l < "${_RUN_DIR}/started" | tr -d ' ')"
  skipped_count=$((total - started_count))

  printf "  Total issues:     %s\n" "$total"
  printf "  ${GREEN}Succeeded:        %s${RESET}\n" "$completed_count"
  printf "  ${RED}Failed:           %s${RESET}\n" "$failed_count"
  if [[ "$skipped_count" -gt 0 ]]; then
    printf "  ${YELLOW}Blocked/Skipped:  %s${RESET}\n" "$skipped_count"
  fi
  printf '\n'

  # List failures
  if [[ -s "${_RUN_DIR}/failed" ]]; then
    printf "  ${RED}Failed issues:${RESET}\n"
    while IFS= read -r issue; do
      [[ -z "$issue" ]] && continue
      local status
      status="$(cat "${_RUN_DIR}/status/${issue}" 2>/dev/null || echo "unknown")"
      printf "    - #%s (%s)\n" "$issue" "$status"
    done < "${_RUN_DIR}/failed"
    printf '\n'
  fi

  # List blocked
  if [[ "$skipped_count" -gt 0 ]]; then
    printf "  ${YELLOW}Blocked issues (dependencies not met):${RESET}\n"
    while IFS= read -r issue; do
      [[ -z "$issue" ]] && continue
      if ! grep -q "^${issue}$" "${_RUN_DIR}/started" 2>/dev/null; then
        local deps
        deps="$(_dag_get_deps "$issue")"
        printf "    - #%s (depends on: %s)\n" "$issue" "${deps:-none}"
      fi
    done < <(_dag_get_issues)
    printf '\n'
  fi
}

# ---------------------------------------------------------------------------
# Trap — interrupt all child pipelines
# ---------------------------------------------------------------------------

_cleanup_on_interrupt() {
  log_warn ""
  log_warn "Run-all interrupted — terminating child pipelines..."

  # Send SIGTERM to all running impl.sh processes
  if [[ -n "${_RUN_DIR:-}" && -d "${_RUN_DIR}/pids" ]]; then
    for pidfile in "${_RUN_DIR}/pids"/*; do
      [[ -f "$pidfile" ]] || continue
      local pid
      pid="$(cat "$pidfile")"
      if kill -0 "$pid" 2>/dev/null; then
        log_warn "Terminating pipeline PID $pid"
        kill -TERM "$pid" 2>/dev/null || true
      fi
    done

    # Brief pause to let children clean up
    sleep 2
    print_report
  fi

  _run_cleanup
  _dag_cleanup
  set_terminal_title "run-all [INTERRUPTED]"
  exit 3
}

trap _cleanup_on_interrupt INT TERM

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  parse_args "$@"

  log_info "=========================================="
  log_info "Run-All — Multi-issue DAG runner"
  log_info "=========================================="

  preflight_checks

  # Detect or validate Epic
  if [[ -z "$EPIC_NUM" ]]; then
    log_info "Auto-detecting Epic..."
    EPIC_NUM="$(detect_epic)" || exit 1
  fi
  log_info "Epic: #${EPIC_NUM}"

  # Discover task issues
  local task_issues
  task_issues="$(list_epic_tasks "$EPIC_NUM")"

  if [[ -z "$task_issues" ]]; then
    log_error "No open task issues found for Epic #${EPIC_NUM}"
    exit 1
  fi

  # Build task list
  local issue_count=0
  local issue_args=()
  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    issue_args+=("$issue")
    issue_count=$((issue_count + 1))
  done <<< "$task_issues"

  log_info "Found $issue_count task issue(s): ${issue_args[*]}"

  # Build the DAG
  if ! build_dag "${issue_args[@]}"; then
    log_error "DAG construction failed (circular dependencies?)"
    _dag_cleanup
    exit 1
  fi
  log_info "DAG built successfully (no cycles)"

  # Dry run — print DAG and exit
  if [[ "$DRY_RUN" == "true" ]]; then
    dag_print_summary

    printf "  ${BOLD}Configuration:${RESET}\n"
    if [[ "$MAX_PARALLEL" -gt 0 ]]; then
      printf "    Max parallel:   %s\n" "$MAX_PARALLEL"
    else
      printf "    Max parallel:   unlimited\n"
    fi
    printf "    Epic:           #%s\n" "$EPIC_NUM"
    printf "    Issues:         %s\n" "$issue_count"
    printf '\n'

    _dag_cleanup
    exit 0
  fi

  # Initialize run tracking
  _run_init
  set_terminal_title "run-all Epic #${EPIC_NUM}"

  # Start initially ready issues
  _start_ready_issues

  # Enter monitor loop
  local monitor_exit=0
  run_monitor_loop || monitor_exit=$?

  # Print final report (before cleanup so _RUN_DIR is still accessible)
  print_report

  # Capture final counts before cleanup
  local final_failed
  final_failed="$(wc -l < "${_RUN_DIR}/failed" | tr -d ' ')"

  # Cleanup
  _run_cleanup
  _dag_cleanup

  # Exit code
  if [[ "$monitor_exit" -ne 0 || "$final_failed" -gt 0 ]]; then
    set_terminal_title "run-all [DONE — some failed]"
    send_notification "Run-All Complete" "Epic #${EPIC_NUM}: ${final_failed} pipeline(s) failed"
    exit 1
  else
    set_terminal_title "run-all [DONE — all passed]"
    send_notification "Run-All Complete" "Epic #${EPIC_NUM}: All pipelines succeeded"
    exit 0
  fi
}

main "$@"
