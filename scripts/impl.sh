#!/usr/bin/env bash
# scripts/impl.sh — Single-issue pipeline orchestrator
# Orchestrates the 5-agent pipeline for a single GitHub issue:
#   Orchestrator → Dev → QA (→ retry Dev→QA if FAIL) → Merge → Prod-QA
#
# Each agent runs as `claude --dangerously-skip-permissions` in its own tmux pane.
# Communication is via sentinel files (.claude-workflow/*.done, *.report).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=scripts/lib/tmux.sh
source "${SCRIPT_DIR}/lib/tmux.sh"
# shellcheck source=scripts/lib/worktree.sh
source "${SCRIPT_DIR}/lib/worktree.sh"
# shellcheck source=scripts/lib/sentinel.sh
source "${SCRIPT_DIR}/lib/sentinel.sh"
# shellcheck source=scripts/lib/lock.sh
source "${SCRIPT_DIR}/lib/lock.sh"
# shellcheck source=scripts/lib/notify.sh
source "${SCRIPT_DIR}/lib/notify.sh"
# shellcheck source=scripts/lib/github.sh
source "${SCRIPT_DIR}/lib/github.sh"
# shellcheck source=scripts/lib/claudemd.sh
source "${SCRIPT_DIR}/lib/claudemd.sh"

# ---------------------------------------------------------------------------
# Constants & configuration
# ---------------------------------------------------------------------------

STAGES=()
while IFS= read -r stage; do
  [[ -n "$stage" ]] && STAGES+=("$stage")
done < <(get_config_array pipeline.stages 2>/dev/null || printf '%s\n' orchestrator dev qa merge prod-qa)

MAX_RETRIES="$(get_config pipeline.max_retries 2>/dev/null || echo "3")"

# Pipeline state
ISSUE_NUM=""
FROM_STAGE=""
DRY_RUN=false
REPO=""
WORKTREE_PATH=""
TMUX_SESSION=""

# ---------------------------------------------------------------------------
# Helper functions (bash 3.2 compatible — no associative arrays)
# ---------------------------------------------------------------------------

_stage_pane_prefix() {
  case "$1" in
    orchestrator) printf '%s' "ORCH" ;;
    dev)          printf '%s' "DEV" ;;
    qa)           printf '%s' "QA" ;;
    merge)        printf '%s' "MERGE" ;;
    prod-qa)      printf '%s' "PROD-QA" ;;
    *)            printf '%s' "$1" ;;
  esac
}

_stage_label_key() {
  case "$1" in
    orchestrator) printf '%s' "planning" ;;
    dev)          printf '%s' "dev" ;;
    qa)           printf '%s' "qa" ;;
    merge)        printf '%s' "merging" ;;
    prod-qa)      printf '%s' "prod_qa" ;;
    *)            printf '%s' "$1" ;;
  esac
}

_get_pane_id() {
  local stage="$1"
  local var_name="PANE_${stage//-/_}"
  eval "printf '%s' \"\${${var_name}:-}\""
}

_is_stage_success() {
  local stage="$1"
  local status="$2"

  case "$stage" in
    orchestrator|dev)
      [[ "$status" == "$SENTINEL_DONE" ]]
      ;;
    qa)
      [[ "$status" == "$SENTINEL_PASS" || "$status" == "$SENTINEL_PASS_WITH_NITS" ]]
      ;;
    merge)
      # Merge writes the commit SHA on success; failure statuses are known keywords
      [[ "$status" != "CI_FAILED" \
        && "$status" != "CONFLICT" \
        && "$status" != "BLOCKED" \
        && "$status" != "NO_PR" \
        && "$status" != "$SENTINEL_STUCK" \
        && "$status" != "$SENTINEL_NEEDS_HUMAN" ]]
      ;;
    prod-qa)
      [[ "$status" == "$SENTINEL_PASS" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") <issue-number> [options]

Pipeline orchestrator for a single GitHub issue.
Runs the 5-agent pipeline: Orchestrator → Dev → QA → Merge → Prod-QA.

Arguments:
  <issue-number>    GitHub issue number (with or without #)

Options:
  --from <stage>    Resume from a specific stage
                    Valid stages: ${STAGES[*]}
  --dry-run         Show what would happen without executing
  -h, --help        Show this help message

Examples:
  $(basename "$0") #42
  $(basename "$0") 42 --from qa
  $(basename "$0") --dry-run #42
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
      --from)
        shift
        FROM_STAGE="${1:-}"
        if [[ -z "$FROM_STAGE" ]]; then
          log_error "Missing stage argument after --from"
          exit 2
        fi
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        # Extract issue number, stripping # prefix
        ISSUE_NUM="${1#\#}"
        shift
        ;;
    esac
  done

  if [[ -z "$ISSUE_NUM" ]]; then
    log_error "Missing issue number. Usage: $(basename "$0") <issue-number>"
    exit 2
  fi

  if ! [[ "$ISSUE_NUM" =~ ^[0-9]+$ ]]; then
    log_error "Invalid issue number: $ISSUE_NUM (must be numeric)"
    exit 2
  fi

  # Validate --from stage
  if [[ -n "$FROM_STAGE" ]]; then
    local valid=false
    for s in "${STAGES[@]}"; do
      [[ "$s" == "$FROM_STAGE" ]] && valid=true && break
    done
    if [[ "$valid" != "true" ]]; then
      log_error "Invalid stage: $FROM_STAGE. Valid stages: ${STAGES[*]}"
      exit 2
    fi
  fi
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

preflight_checks() {
  log_info "Running preflight checks for issue #${ISSUE_NUM}..."

  local tools=("claude" "gh" "git" "tmux" "jq" "yq")
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

  if [[ ! -f "$WORKFLOW_YAML" ]]; then
    log_error "Workflow config not found: $WORKFLOW_YAML"
    exit 2
  fi

  # Verify agent files
  for stage in "${STAGES[@]}"; do
    local agent_file
    agent_file="$(_resolve_agent_file "$stage")"
    if [[ ! -f "${PROJECT_ROOT}/.claude/agents/${agent_file}" ]]; then
      log_error "Agent file missing: .claude/agents/${agent_file}"
      exit 2
    fi
  done

  # Verify issue exists and is OPEN
  local state
  state="$(get_issue_state "$ISSUE_NUM" 2>/dev/null || echo "")"
  if [[ -z "$state" ]]; then
    log_error "Issue #${ISSUE_NUM} not found or not accessible"
    exit 2
  fi
  if [[ "$state" != "OPEN" ]]; then
    log_error "Issue #${ISSUE_NUM} is $state (expected OPEN)"
    exit 2
  fi

  log_info "Preflight checks passed"
}

# ---------------------------------------------------------------------------
# Repository detection
# ---------------------------------------------------------------------------

detect_repo() {
  REPO="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")"
  if [[ -z "$REPO" ]]; then
    log_error "Cannot detect repository. Ensure you're in a git repo with a GitHub remote."
    exit 2
  fi
  log_debug "Detected repository: $REPO"
}

# ---------------------------------------------------------------------------
# Worktree setup
# ---------------------------------------------------------------------------

setup_worktree() {
  WORKTREE_PATH="$(get_worktree_path "$ISSUE_NUM")"

  if [[ -n "$FROM_STAGE" && -d "$WORKTREE_PATH" ]]; then
    log_info "Reusing existing worktree: $WORKTREE_PATH"
  else
    acquire_lock
    create_worktree "$ISSUE_NUM"
    release_lock
  fi

  # Ensure workflow directories exist
  local workflow_dir
  workflow_dir="$(get_config sentinel.workflow_dir 2>/dev/null || echo ".claude-workflow")"
  mkdir -p "${WORKTREE_PATH}/${workflow_dir}"
  mkdir -p "${WORKTREE_PATH}/${workflow_dir}/logs"

  log_info "Worktree ready: $WORKTREE_PATH"
}

# ---------------------------------------------------------------------------
# Tmux session + pane creation
# ---------------------------------------------------------------------------

setup_tmux() {
  TMUX_SESSION="issue-${ISSUE_NUM}"

  create_tmux_session "$TMUX_SESSION"

  # Determine which stages need panes
  local start_index=0
  if [[ -n "$FROM_STAGE" ]]; then
    for i in "${!STAGES[@]}"; do
      if [[ "${STAGES[$i]}" == "$FROM_STAGE" ]]; then
        start_index=$i
        break
      fi
    done
  fi

  local workflow_dir
  workflow_dir="$(get_config sentinel.workflow_dir 2>/dev/null || echo ".claude-workflow")"

  # First pane — reuse the default pane created with the session
  local first_stage="${STAGES[$start_index]}"
  local first_pane_title
  first_pane_title="$(_stage_pane_prefix "$first_stage") #${ISSUE_NUM}"
  local first_pane_id
  first_pane_id="$(tmux list-panes -t "$TMUX_SESSION" -F '#{pane_id}' | head -1)"
  set_pane_title "$TMUX_SESSION" "$first_pane_id" "$first_pane_title"
  eval "PANE_${first_stage//-/_}=$first_pane_id"
  tmux_pipe_pane "$TMUX_SESSION" "$first_pane_id" \
    "${WORKTREE_PATH}/${workflow_dir}/logs/${first_stage}.log"

  # Create panes for remaining stages
  for ((i = start_index + 1; i < ${#STAGES[@]}; i++)); do
    local stage="${STAGES[$i]}"

    # Skip prod-qa if no prod_url configured
    if [[ "$stage" == "prod-qa" ]]; then
      local prod_url
      prod_url="$(get_config prod_url 2>/dev/null || echo "")"
      if [[ -z "$prod_url" ]]; then
        log_info "Skipping prod-qa pane (no prod_url configured)"
        continue
      fi
    fi

    local pane_title
    pane_title="$(_stage_pane_prefix "$stage") #${ISSUE_NUM}"
    local pane_id
    pane_id="$(create_tmux_pane "$TMUX_SESSION" "$pane_title")"
    eval "PANE_${stage//-/_}=$pane_id"
    tmux_pipe_pane "$TMUX_SESSION" "$pane_id" \
      "${WORKTREE_PATH}/${workflow_dir}/logs/${stage}.log"
  done

  set_terminal_title "impl #${ISSUE_NUM}"
  log_info "Tmux session ready: $TMUX_SESSION"
}

# ---------------------------------------------------------------------------
# Initial prompt builder
# ---------------------------------------------------------------------------

_build_initial_prompt() {
  local stage="$1"

  case "$stage" in
    orchestrator)
      printf '%s' "Read the GitHub issue #${ISSUE_NUM} from repository ${REPO} and create a detailed implementation plan. Follow the instructions in your CLAUDE.md precisely."
      ;;
    dev)
      printf '%s' "Read the orchestrator report at .claude-workflow/orchestrator.report and implement the plan for issue #${ISSUE_NUM}. Follow the instructions in your CLAUDE.md precisely."
      ;;
    qa)
      printf '%s' "Verify the implementation for issue #${ISSUE_NUM} against the requirements. Read the dev report at .claude-workflow/dev.report. Follow the instructions in your CLAUDE.md precisely."
      ;;
    merge)
      printf '%s' "Merge the PR for issue #${ISSUE_NUM}. Verify QA passed, check CI, and squash-merge. Follow the instructions in your CLAUDE.md precisely."
      ;;
    prod-qa)
      printf '%s' "Verify the merged changes for issue #${ISSUE_NUM} are live and working in production. Follow the instructions in your CLAUDE.md precisely."
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Agent launcher
# ---------------------------------------------------------------------------

launch_agent() {
  local stage="$1"
  local qa_report="${2:-}"

  local pane_id
  pane_id="$(_get_pane_id "$stage")"
  if [[ -z "$pane_id" ]]; then
    log_error "No pane found for stage: $stage"
    return 1
  fi

  local prod_url
  prod_url="$(get_config prod_url 2>/dev/null || echo "")"

  # Generate stage-specific CLAUDE.md
  generate_claudemd "$WORKTREE_PATH" "$stage" "$ISSUE_NUM" "$REPO" "$prod_url" "$qa_report"

  # Launch Claude in the pane
  tmux_send_keys "$TMUX_SESSION" "$pane_id" "cd ${WORKTREE_PATH} && claude --dangerously-skip-permissions"

  # Wait for Claude to fully start (needs time to load CLAUDE.md and show prompt)
  local wait_secs=10
  log_info "Waiting ${wait_secs}s for Claude to start..."
  sleep "$wait_secs"

  # Send the initial task prompt
  local prompt
  prompt="$(_build_initial_prompt "$stage")"
  tmux_send_keys "$TMUX_SESSION" "$pane_id" "$prompt"

  log_info "Launched $stage agent in pane $pane_id"
}

# ---------------------------------------------------------------------------
# Sentinel monitoring with NEEDS_HUMAN handling
# ---------------------------------------------------------------------------

monitor_stage() {
  local stage="$1"

  log_info "Monitoring $stage stage for issue #${ISSUE_NUM}..."
  set_terminal_title "impl #${ISSUE_NUM} [$stage]"

  local needs_human_notified=false
  local poll_interval
  poll_interval="$(get_config sentinel.poll_interval 2>/dev/null || echo "3")"

  while true; do
    local status
    if status="$(read_sentinel "$WORKTREE_PATH" "$stage" 2>/dev/null)"; then
      if [[ "$status" == "$SENTINEL_NEEDS_HUMAN" ]]; then
        if [[ "$needs_human_notified" != "true" ]]; then
          # Extract the message from the sentinel file (line 2+)
          local sentinel_file
          sentinel_file="$(_sentinel_file "$WORKTREE_PATH" "$stage")"
          local message
          message="$(tail -n +2 "$sentinel_file" 2>/dev/null | head -1 || echo "Agent needs your attention")"

          notify_needs_human "$ISSUE_NUM" "$stage" "$message"
          set_label "$ISSUE_NUM" "needs_human" 2>/dev/null || true
          needs_human_notified=true
          log_warn "NEEDS_HUMAN: $stage — $message"
        fi
        # Continue polling — agent will overwrite sentinel when user responds
        sleep "$poll_interval"
        continue
      fi

      # Non-NEEDS_HUMAN status — stage complete
      if [[ "$needs_human_notified" == "true" ]]; then
        remove_label "$ISSUE_NUM" "needs_human" 2>/dev/null || true
      fi

      notify_stage_complete "$ISSUE_NUM" "$stage"
      log_info "Stage $stage completed: $status"
      printf '%s' "$status"
      return 0
    fi

    sleep "$poll_interval"
  done
}

# ---------------------------------------------------------------------------
# GitHub label management
# ---------------------------------------------------------------------------

_update_label() {
  local stage="$1"
  local label_key
  label_key="$(_stage_label_key "$stage")"

  # Remove other stage labels
  for s in "${STAGES[@]}"; do
    local other_key
    other_key="$(_stage_label_key "$s")"
    [[ "$other_key" != "$label_key" ]] && remove_label "$ISSUE_NUM" "$other_key" 2>/dev/null || true
  done
  remove_label "$ISSUE_NUM" "blocked" 2>/dev/null || true
  remove_label "$ISSUE_NUM" "needs_human" 2>/dev/null || true

  set_label "$ISSUE_NUM" "$label_key"
  log_debug "Updated label to: $label_key"
}

# ---------------------------------------------------------------------------
# QA retry loop
# ---------------------------------------------------------------------------

run_qa_retry_loop() {
  local qa_status="$1"
  local retry_count=0

  while [[ "$qa_status" == "$SENTINEL_FAIL" && "$retry_count" -lt "$MAX_RETRIES" ]]; do
    retry_count=$((retry_count + 1))
    log_warn "QA FAIL — retry $retry_count of $MAX_RETRIES"

    # Read QA report for injection into Dev's CLAUDE.md
    local qa_report
    qa_report="$(read_report "$WORKTREE_PATH" "qa" 2>/dev/null || echo "QA report unavailable")"

    # Clear dev + qa sentinels for the retry
    local sentinel_dir
    sentinel_dir="$(_sentinel_dir "$WORKTREE_PATH")"
    rm -f "${sentinel_dir}/dev.done" \
          "${sentinel_dir}/dev.report" \
          "${sentinel_dir}/qa.done" \
          "${sentinel_dir}/qa.report" 2>/dev/null || true

    # Re-run Dev with QA report injected
    launch_agent "dev" "$qa_report"
    _update_label "dev"
    local dev_status
    dev_status="$(monitor_stage "dev")"

    if ! _is_stage_success "dev" "$dev_status"; then
      log_error "Dev stage failed during retry $retry_count: $dev_status"
      return 1
    fi

    # Re-run QA
    launch_agent "qa"
    _update_label "qa"
    qa_status="$(monitor_stage "qa")"
  done

  if _is_stage_success "qa" "$qa_status"; then
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Pipeline execution
# ---------------------------------------------------------------------------

run_pipeline() {
  local start_index=0

  if [[ -n "$FROM_STAGE" ]]; then
    for i in "${!STAGES[@]}"; do
      if [[ "${STAGES[$i]}" == "$FROM_STAGE" ]]; then
        start_index=$i
        break
      fi
    done
    log_info "Resuming pipeline from stage: $FROM_STAGE"
  fi

  local pipeline_success=true
  local final_status=""

  for ((i = start_index; i < ${#STAGES[@]}; i++)); do
    local stage="${STAGES[$i]}"

    # Skip prod-qa if no prod_url configured
    if [[ "$stage" == "prod-qa" ]]; then
      local prod_url
      prod_url="$(get_config prod_url 2>/dev/null || echo "")"
      if [[ -z "$prod_url" ]]; then
        log_info "Skipping prod-qa stage (no prod_url configured)"
        continue
      fi
    fi

    log_info "=========================================="
    log_info "Starting stage: $stage (issue #${ISSUE_NUM})"
    log_info "=========================================="

    _update_label "$stage"
    launch_agent "$stage"

    local status
    status="$(monitor_stage "$stage")"

    # QA failure → retry loop
    if [[ "$stage" == "qa" && "$status" == "$SENTINEL_FAIL" ]]; then
      if run_qa_retry_loop "$status"; then
        log_info "QA passed after retry"
        continue
      else
        log_error "QA exhausted all retries ($MAX_RETRIES)"
        pipeline_success=false
        final_status="qa:FAIL_MAX_RETRIES"
        break
      fi
    fi

    if ! _is_stage_success "$stage" "$status"; then
      log_error "Stage $stage failed: $status"
      pipeline_success=false
      final_status="${stage}:${status}"
      break
    fi

    log_info "Stage $stage completed successfully"
  done

  if [[ "$pipeline_success" == "true" ]]; then
    _pipeline_success
  else
    _pipeline_failure "$final_status"
  fi
}

# ---------------------------------------------------------------------------
# Success / failure handlers
# ---------------------------------------------------------------------------

_pipeline_success() {
  log_info "=========================================="
  log_info "Pipeline SUCCEEDED for issue #${ISSUE_NUM}"
  log_info "=========================================="

  # Remove all stage labels
  for s in "${STAGES[@]}"; do
    local key
    key="$(_stage_label_key "$s")"
    remove_label "$ISSUE_NUM" "$key" 2>/dev/null || true
  done
  remove_label "$ISSUE_NUM" "blocked" 2>/dev/null || true
  remove_label "$ISSUE_NUM" "needs_human" 2>/dev/null || true

  # Clean up worktree
  acquire_lock
  cleanup_worktree "$ISSUE_NUM"
  release_lock

  notify_pipeline_result "$ISSUE_NUM" "success"
  set_terminal_title "impl #${ISSUE_NUM} [DONE]"
}

_pipeline_failure() {
  local reason="$1"

  log_error "=========================================="
  log_error "Pipeline FAILED for issue #${ISSUE_NUM}: $reason"
  log_error "=========================================="

  set_label "$ISSUE_NUM" "blocked" 2>/dev/null || true

  post_comment "$ISSUE_NUM" "pipeline" \
    "Pipeline failed at **${reason}**.\n\nWorktree preserved at: \`.worktrees/issue-${ISSUE_NUM}/\`\n\nSentinel files and logs available in \`.claude-workflow/\` within the worktree." \
    2>/dev/null || true

  log_warn "Worktree preserved for inspection: $(get_worktree_path "$ISSUE_NUM")"

  notify_pipeline_result "$ISSUE_NUM" "failure: $reason"
  set_terminal_title "impl #${ISSUE_NUM} [FAILED]"
}

# ---------------------------------------------------------------------------
# Trap handler
# ---------------------------------------------------------------------------

_cleanup_on_interrupt() {
  log_warn ""
  log_warn "Pipeline interrupted for issue #${ISSUE_NUM}"

  post_comment "$ISSUE_NUM" "pipeline" \
    "Pipeline interrupted by user. Worktree preserved at \`.worktrees/issue-${ISSUE_NUM}/\`." \
    2>/dev/null || true

  set_terminal_title "impl #${ISSUE_NUM} [INTERRUPTED]"
  exit 3
}

trap _cleanup_on_interrupt INT TERM

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  parse_args "$@"

  log_info "=========================================="
  log_info "Pipeline starting for issue #${ISSUE_NUM}"
  log_info "=========================================="

  preflight_checks
  detect_repo

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Repository: $REPO"
    log_info "[DRY RUN] Worktree: $(get_worktree_path "$ISSUE_NUM")"
    log_info "[DRY RUN] Tmux session: issue-${ISSUE_NUM}"
    log_info "[DRY RUN] Stages: ${STAGES[*]}"
    if [[ -n "$FROM_STAGE" ]]; then
      log_info "[DRY RUN] Starting from: $FROM_STAGE"
    fi
    local prod_url
    prod_url="$(get_config prod_url 2>/dev/null || echo "")"
    if [[ -z "$prod_url" ]]; then
      log_info "[DRY RUN] Prod-QA: skipped (no prod_url)"
    fi
    exit 0
  fi

  setup_worktree
  setup_tmux
  run_pipeline
}

main "$@"
