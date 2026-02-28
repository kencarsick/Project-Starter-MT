#!/usr/bin/env bash
# scripts/lib/dag.sh — Dependency graph resolution for multi-issue pipelines
# Depends on: log.sh, config.sh, github.sh
# Compatible with bash 3.2+ (uses temp files instead of associative arrays)

set -euo pipefail

[[ -n "${_LIB_DAG_SOURCED:-}" ]] && return 0
_LIB_DAG_SOURCED=1

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${_LIB_DIR}/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${_LIB_DIR}/config.sh"
# shellcheck source=scripts/lib/github.sh
source "${_LIB_DIR}/github.sh"

# ---------------------------------------------------------------------------
# DAG data — stored in temp directory as files
#   _DAG_DIR/issues     — one issue number per line
#   _DAG_DIR/deps/<N>   — space-separated deps for issue N
# ---------------------------------------------------------------------------

_DAG_DIR=""

_dag_init() {
  if [[ -n "$_DAG_DIR" && -d "$_DAG_DIR" ]]; then
    rm -rf "$_DAG_DIR"
  fi
  _DAG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dag.XXXXXX")"
  mkdir -p "${_DAG_DIR}/deps"
  : > "${_DAG_DIR}/issues"
}

_dag_cleanup() {
  if [[ -n "$_DAG_DIR" && -d "$_DAG_DIR" ]]; then
    rm -rf "$_DAG_DIR"
    _DAG_DIR=""
  fi
}

_dag_get_deps() {
  local issue="$1"
  if [[ -f "${_DAG_DIR}/deps/${issue}" ]]; then
    cat "${_DAG_DIR}/deps/${issue}"
  fi
}

_dag_set_deps() {
  local issue="$1"
  local deps="$2"
  printf '%s' "$deps" > "${_DAG_DIR}/deps/${issue}"
}

_dag_get_issues() {
  cat "${_DAG_DIR}/issues" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Parse dependencies from a single issue
# ---------------------------------------------------------------------------

parse_dependencies() {
  local issue_number="$1"
  issue_number="${issue_number#\#}"

  local body
  body="$(get_issue_body "$issue_number" 2>/dev/null || echo "")"

  if [[ -z "$body" ]]; then
    log_debug "parse_dependencies: empty body for issue #$issue_number"
    return 0
  fi

  local deps=""
  while IFS= read -r line; do
    if [[ "$line" =~ [Dd]epends[[:space:]]+on:[[:space:]]*(.*) ]]; then
      local dep_part="${BASH_REMATCH[1]}"
      while [[ "$dep_part" =~ \#([0-9]+) ]]; do
        deps="${deps}${BASH_REMATCH[1]} "
        dep_part="${dep_part#*"#${BASH_REMATCH[1]}"}"
      done
    fi
  done <<< "$body"

  printf '%s' "${deps% }"
}

# ---------------------------------------------------------------------------
# Build the full DAG for a set of issues
# ---------------------------------------------------------------------------

build_dag() {
  _dag_init

  local issue
  for issue in "$@"; do
    issue="${issue#\#}"
    printf '%s\n' "$issue" >> "${_DAG_DIR}/issues"
    local deps
    deps="$(parse_dependencies "$issue")"
    _dag_set_deps "$issue" "$deps"
    log_debug "DAG: issue #$issue depends on: [${deps:-none}]"
  done

  if ! detect_cycles; then
    log_error "build_dag: circular dependencies detected"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Get issues ready to start (all dependencies satisfied)
# ---------------------------------------------------------------------------

get_ready_issues() {
  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    local deps
    deps="$(_dag_get_deps "$issue")"
    local all_satisfied=true

    if [[ -n "$deps" ]]; then
      for dep in $deps; do
        local state
        state="$(get_issue_state "$dep" 2>/dev/null || echo "OPEN")"
        if [[ "$state" != "CLOSED" ]]; then
          all_satisfied=false
          log_debug "Issue #$issue blocked: dependency #$dep is $state"
          break
        fi
      done
    fi

    if [[ "$all_satisfied" == "true" ]]; then
      printf '%s\n' "$issue"
    fi
  done < <(_dag_get_issues)
}

# ---------------------------------------------------------------------------
# Cycle detection (DFS using temp files for visited/stack tracking)
# ---------------------------------------------------------------------------

detect_cycles() {
  local visited_dir="${_DAG_DIR}/visited"
  local stack_dir="${_DAG_DIR}/stack"
  mkdir -p "$visited_dir" "$stack_dir"

  _dfs_visit() {
    local node="$1"
    : > "${visited_dir}/${node}"
    : > "${stack_dir}/${node}"

    local deps
    deps="$(_dag_get_deps "$node")"
    local dep
    for dep in $deps; do
      # Only visit nodes that are in our tracked set
      if ! grep -q "^${dep}$" "${_DAG_DIR}/issues" 2>/dev/null; then
        continue
      fi
      if [[ ! -f "${visited_dir}/${dep}" ]]; then
        if ! _dfs_visit "$dep"; then
          return 1
        fi
      elif [[ -f "${stack_dir}/${dep}" ]]; then
        log_error "detect_cycles: cycle detected involving issue #$node -> #$dep"
        return 1
      fi
    done

    rm -f "${stack_dir}/${node}"
    return 0
  }

  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    if [[ ! -f "${visited_dir}/${issue}" ]]; then
      if ! _dfs_visit "$issue"; then
        return 1
      fi
    fi
  done < <(_dag_get_issues)

  return 0
}

# ---------------------------------------------------------------------------
# Topological sort (Kahn's algorithm — bash 3.2 compatible)
# ---------------------------------------------------------------------------

get_topological_order() {
  local topo_dir="${_DAG_DIR}/topo"
  rm -rf "$topo_dir"
  mkdir -p "$topo_dir"

  # Calculate in-degree for each issue (count deps that are in the DAG)
  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    local deps count=0
    deps="$(_dag_get_deps "$issue")"
    for dep in $deps; do
      if grep -q "^${dep}$" "${_DAG_DIR}/issues" 2>/dev/null; then
        count=$((count + 1))
      fi
    done
    printf '%s' "$count" > "${topo_dir}/indeg_${issue}"
  done < <(_dag_get_issues)

  # Seed queue with zero-indegree nodes
  local queue="${topo_dir}/queue"
  : > "$queue"
  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    local indeg
    indeg="$(cat "${topo_dir}/indeg_${issue}" 2>/dev/null || echo "0")"
    [[ "$indeg" -eq 0 ]] && printf '%s\n' "$issue" >> "$queue"
  done < <(_dag_get_issues)

  # BFS — process queue
  local result="${topo_dir}/result"
  : > "$result"
  while [[ -s "$queue" ]]; do
    local node
    node="$(head -1 "$queue")"
    tail -n +2 "$queue" > "${queue}.tmp" && mv "${queue}.tmp" "$queue"

    printf '%s\n' "$node" >> "$result"

    # Decrease indegree for issues that depend on this node
    while IFS= read -r other; do
      [[ -z "$other" ]] && continue
      local other_deps
      other_deps="$(_dag_get_deps "$other")"
      for d in $other_deps; do
        if [[ "$d" == "$node" ]]; then
          local cur
          cur="$(cat "${topo_dir}/indeg_${other}")"
          printf '%s' "$((cur - 1))" > "${topo_dir}/indeg_${other}"
          [[ "$((cur - 1))" -eq 0 ]] && printf '%s\n' "$other" >> "$queue"
          break
        fi
      done
    done < <(_dag_get_issues)
  done

  cat "$result"
}

# ---------------------------------------------------------------------------
# Ready issues — checks against a local completed set (avoids API calls)
# ---------------------------------------------------------------------------

get_ready_issues_local() {
  local completed_file="$1"
  local started_file="$2"

  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    # Skip already started issues
    grep -q "^${issue}$" "$started_file" 2>/dev/null && continue

    local deps
    deps="$(_dag_get_deps "$issue")"
    local all_satisfied=true

    if [[ -n "$deps" ]]; then
      for dep in $deps; do
        # Check local completed set first
        if grep -q "^${dep}$" "$completed_file" 2>/dev/null; then
          continue
        fi
        # If dep is in our DAG but not completed, it's blocking
        if grep -q "^${dep}$" "${_DAG_DIR}/issues" 2>/dev/null; then
          all_satisfied=false
          break
        fi
        # External dep (not in DAG) — query GitHub
        local state
        state="$(get_issue_state "$dep" 2>/dev/null || echo "OPEN")"
        if [[ "$state" != "CLOSED" ]]; then
          all_satisfied=false
          break
        fi
      done
    fi

    [[ "$all_satisfied" == "true" ]] && printf '%s\n' "$issue"
  done < <(_dag_get_issues)
}

# ---------------------------------------------------------------------------
# DAG summary — human-readable (for --dry-run)
# ---------------------------------------------------------------------------

dag_print_summary() {
  printf '\n'
  printf "  ${BOLD}DAG — Dependency Graph${RESET}\n"
  printf "  =====================\n\n"
  printf "  %-10s  %s\n" "Issue" "Depends on"
  printf "  %-10s  %s\n" "----------" "----------"

  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    local deps
    deps="$(_dag_get_deps "$issue")"
    if [[ -z "$deps" ]]; then
      printf "  %-10s  %s\n" "#${issue}" "(none — ready)"
    else
      local formatted=""
      for d in $deps; do formatted="${formatted}#${d} "; done
      printf "  %-10s  %s\n" "#${issue}" "${formatted% }"
    fi
  done < <(_dag_get_issues)

  printf "\n  ${BOLD}Execution Order (topological):${RESET}\n"
  local i=1
  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue
    printf "    %d. #%s\n" "$i" "$issue"
    i=$((i + 1))
  done < <(get_topological_order)
  printf '\n'
}
