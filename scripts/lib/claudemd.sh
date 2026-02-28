#!/usr/bin/env bash
# scripts/lib/claudemd.sh — CLAUDE.md generation for worktree-specific agent context
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_CLAUDEMD_SOURCED:-}" ]] && return 0
_LIB_CLAUDEMD_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# ---------------------------------------------------------------------------
# Agent file resolution
# ---------------------------------------------------------------------------

_resolve_agent_file() {
  local stage="$1"

  case "$stage" in
    orchestrator) printf '%s' "orchestrator.md" ;;
    dev)          printf '%s' "dev-agent.md" ;;
    qa)           printf '%s' "qa-agent.md" ;;
    merge)        printf '%s' "merge-agent.md" ;;
    prod-qa)      printf '%s' "prod-qa-agent.md" ;;
    *)
      log_error "_resolve_agent_file: unknown stage '$stage'"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Placeholder substitution
# ---------------------------------------------------------------------------

_substitute_tokens() {
  local content="$1"
  local issue_num="$2"
  local worktree_path="$3"
  local repo="$4"
  local prod_url="$5"
  local qa_report="$6"

  # Use printf + sed for safe substitution (avoid issues with special chars in paths)
  printf '%s' "$content" \
    | sed "s|__ISSUE_NUM__|${issue_num}|g" \
    | sed "s|__WORKTREE_PATH__|${worktree_path}|g" \
    | sed "s|__REPO__|${repo}|g" \
    | sed "s|__PROD_URL__|${prod_url}|g" \
    | sed "s|__QA_REPORT__|${qa_report}|g"
}

# ---------------------------------------------------------------------------
# Main generation function
# ---------------------------------------------------------------------------

generate_claudemd() {
  local worktree_path="$1"
  local stage="$2"
  local issue_num="$3"
  local repo="$4"
  local prod_url="${5:-}"
  local qa_report="${6:-}"

  log_info "Generating CLAUDE.md for stage '$stage' (issue #${issue_num})"

  # Resolve agent prompt file
  local agent_filename
  agent_filename="$(_resolve_agent_file "$stage")"

  local agent_prompt_path="${PROJECT_ROOT}/.claude/agents/${agent_filename}"
  local project_claudemd_path="${PROJECT_ROOT}/CLAUDE.md"
  local agents_md_path="${PROJECT_ROOT}/AGENTS.md"

  # Validate required files exist
  if [[ ! -f "$agent_prompt_path" ]]; then
    log_error "Agent prompt not found: $agent_prompt_path"
    return 1
  fi

  if [[ ! -f "$project_claudemd_path" ]]; then
    log_error "Project CLAUDE.md not found: $project_claudemd_path"
    return 1
  fi

  if [[ ! -f "$agents_md_path" ]]; then
    log_error "AGENTS.md not found: $agents_md_path"
    return 1
  fi

  # Read source files
  local agent_content project_content agents_content
  agent_content="$(cat "$agent_prompt_path")"
  project_content="$(cat "$project_claudemd_path")"
  agents_content="$(cat "$agents_md_path")"

  # Substitute placeholder tokens in agent content
  local substituted_agent
  substituted_agent="$(_substitute_tokens "$agent_content" "$issue_num" "$worktree_path" "$repo" "$prod_url" "$qa_report")"

  # Assemble the combined CLAUDE.md
  local output_path="${worktree_path}/CLAUDE.md"
  local tmpfile
  tmpfile="$(mktemp "${output_path}.XXXXXX")"

  cat > "$tmpfile" <<CLAUDEMD_EOF
${substituted_agent}

---

# Project Context

${project_content}

---

# Agent Rules

${agents_content}
CLAUDEMD_EOF

  mv "$tmpfile" "$output_path"

  log_info "CLAUDE.md written to $output_path"
  log_debug "Assembled: agent=$agent_filename + CLAUDE.md + AGENTS.md → $output_path"
}
