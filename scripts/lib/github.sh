#!/usr/bin/env bash
# scripts/lib/github.sh — GitHub CLI helpers
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_GITHUB_SOURCED:-}" ]] && return 0
_LIB_GITHUB_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# ---------------------------------------------------------------------------
# Issue operations
# ---------------------------------------------------------------------------

get_issue_body() {
  local issue_number="$1"
  issue_number="${issue_number#\#}"

  gh issue view "$issue_number" --json body --jq '.body'
}

get_issue_state() {
  local issue_number="$1"
  issue_number="${issue_number#\#}"

  gh issue view "$issue_number" --json state --jq '.state'
}

# ---------------------------------------------------------------------------
# Comments
# ---------------------------------------------------------------------------

post_comment() {
  local issue_number="$1"
  local role="$2"
  local body="$3"
  issue_number="${issue_number#\#}"

  local formatted_body
  formatted_body="$(printf '**[%s]** — Issue #%s\n\n%s' "$role" "$issue_number" "$body")"

  gh issue comment "$issue_number" --body "$formatted_body"
  log_debug "Posted comment as [$role] on issue #$issue_number"
}

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------

_resolve_label() {
  local label_key="$1"
  get_config "github.labels.${label_key}" 2>/dev/null || {
    log_warn "_resolve_label: unknown label key '$label_key' — using as literal"
    printf '%s' "$label_key"
  }
}

set_label() {
  local issue_number="$1"
  local label_key="$2"
  issue_number="${issue_number#\#}"

  local label_name
  label_name="$(_resolve_label "$label_key")"

  gh issue edit "$issue_number" --add-label "$label_name"
  log_debug "Added label '$label_name' to issue #$issue_number"
}

remove_label() {
  local issue_number="$1"
  local label_key="$2"
  issue_number="${issue_number#\#}"

  local label_name
  label_name="$(_resolve_label "$label_key")"

  gh issue edit "$issue_number" --remove-label "$label_name" 2>/dev/null || true
  log_debug "Removed label '$label_name' from issue #$issue_number"
}

# ---------------------------------------------------------------------------
# Pull requests
# ---------------------------------------------------------------------------

create_pr() {
  local branch="$1"
  local title="$2"
  local body="$3"

  gh pr create --head "$branch" --base main --title "$title" --body "$body"
}

get_pr_status() {
  local pr_number="$1"

  gh pr checks "$pr_number" 2>/dev/null || \
    gh pr view "$pr_number" --json statusCheckRollup --jq '.statusCheckRollup'
}

merge_pr() {
  local pr_number="$1"

  gh pr merge "$pr_number" --squash --delete-branch
  log_info "Squash-merged PR #$pr_number"
}
