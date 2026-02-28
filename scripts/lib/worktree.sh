#!/usr/bin/env bash
# scripts/lib/worktree.sh — Git worktree lifecycle management
# Depends on: log.sh, config.sh

set -euo pipefail

[[ -n "${_LIB_WORKTREE_SOURCED:-}" ]] && return 0
_LIB_WORKTREE_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"

# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------

get_worktree_path() {
  local issue_number="$1"
  printf '%s/.worktrees/issue-%s' "$PROJECT_ROOT" "$issue_number"
}

# ---------------------------------------------------------------------------
# Create worktree
# ---------------------------------------------------------------------------

create_worktree() {
  local issue_number="$1"
  local branch_name="issue-${issue_number}"
  local worktree_path
  worktree_path="$(get_worktree_path "$issue_number")"

  log_info "Creating worktree for issue #${issue_number} at ${worktree_path}"

  # Prune stale worktree entries
  git -C "$PROJECT_ROOT" worktree prune 2>/dev/null || true

  # Create .worktrees directory
  mkdir -p "${PROJECT_ROOT}/.worktrees"

  # Fetch latest before branching
  git -C "$PROJECT_ROOT" fetch origin main 2>/dev/null || \
    git -C "$PROJECT_ROOT" fetch origin 2>/dev/null || true

  # Create worktree: reuse branch if it exists, else create from origin/main
  if git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/heads/${branch_name}"; then
    log_debug "Branch $branch_name exists — reusing"
    git -C "$PROJECT_ROOT" worktree add "$worktree_path" "$branch_name"
  else
    local base_ref="origin/main"
    if ! git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/remotes/origin/main"; then
      base_ref="main"
    fi
    log_debug "Creating branch $branch_name from $base_ref"
    git -C "$PROJECT_ROOT" worktree add -b "$branch_name" "$worktree_path" "$base_ref"
  fi

  # Symlink candidates from config
  _symlink_worktree_candidates "$worktree_path"

  log_info "Worktree ready: $worktree_path (branch: $branch_name)"
  printf '%s' "$worktree_path"
}

# ---------------------------------------------------------------------------
# Symlink shared resources into worktree
# ---------------------------------------------------------------------------

_symlink_worktree_candidates() {
  local worktree_path="$1"

  local candidates=()
  while IFS= read -r item; do
    [[ -n "$item" ]] && candidates+=("$item")
  done < <(get_config_array worktree.symlink_candidates 2>/dev/null || true)

  local candidate src dest
  for candidate in "${candidates[@]:-}"; do
    [[ -z "$candidate" ]] && continue
    src="${PROJECT_ROOT}/${candidate}"
    dest="${worktree_path}/${candidate}"

    if [[ ! -e "$src" ]]; then
      log_debug "Symlink candidate '$candidate' does not exist in project root — skipping"
      continue
    fi

    # Don't overwrite a real file/dir (only replace existing symlinks)
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      log_warn "Symlink target '$dest' already exists as a real file/dir — skipping"
      continue
    fi

    ln -sfn "$src" "$dest"
    log_debug "Symlinked: $dest -> $src"
  done
}

# ---------------------------------------------------------------------------
# Cleanup worktree
# ---------------------------------------------------------------------------

cleanup_worktree() {
  local issue_number="$1"
  local branch_name="issue-${issue_number}"
  local worktree_path
  worktree_path="$(get_worktree_path "$issue_number")"

  if [[ ! -d "$worktree_path" ]]; then
    log_warn "cleanup_worktree: worktree does not exist at $worktree_path"
    return 0
  fi

  log_info "Cleaning up worktree for issue #${issue_number}"

  git -C "$PROJECT_ROOT" worktree remove --force "$worktree_path" 2>/dev/null || \
    rm -rf "$worktree_path"

  git -C "$PROJECT_ROOT" worktree prune 2>/dev/null || true

  # Delete the local branch
  if git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/heads/${branch_name}"; then
    git -C "$PROJECT_ROOT" branch -D "$branch_name" 2>/dev/null || true
    log_debug "Deleted local branch: $branch_name"
  fi

  log_info "Worktree cleaned up: $worktree_path"
}
