#!/usr/bin/env bash
# scripts/setup.sh — Doctor/prerequisite checker for Universal Project Starter v2
# Verifies all tools, authentication, and configuration are ready.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# ---------------------------------------------------------------------------
# Check helpers
# ---------------------------------------------------------------------------

check() {
  local name="$1"
  local cmd="$2"
  local required="${3:-true}"

  if eval "$cmd" &>/dev/null; then
    printf "  ${GREEN}PASS${RESET}  %s\n" "$name"
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [[ "$required" == "true" ]]; then
    printf "  ${RED}FAIL${RESET}  %s\n" "$name"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    printf "  ${YELLOW}WARN${RESET}  %s (optional)\n" "$name"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

check_version() {
  local name="$1"
  local min_version="$2"
  local version_cmd="$3"

  local actual_version
  actual_version="$(eval "$version_cmd" 2>/dev/null | head -1 || echo "0.0.0")"

  if printf '%s\n%s\n' "$min_version" "$actual_version" | sort -V | head -1 | grep -q "^${min_version}$"; then
    printf "  ${GREEN}PASS${RESET}  %s (%s)\n" "$name" "$actual_version"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  ${RED}FAIL${RESET}  %s — need >= %s, got %s\n" "$name" "$min_version" "$actual_version"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

check_version_optional() {
  local name="$1"
  local min_version="$2"
  local version_cmd="$3"

  local actual_version
  actual_version="$(eval "$version_cmd" 2>/dev/null | head -1 || echo "0.0.0")"

  if printf '%s\n%s\n' "$min_version" "$actual_version" | sort -V | head -1 | grep -q "^${min_version}$"; then
    printf "  ${GREEN}PASS${RESET}  %s (%s)\n" "$name" "$actual_version"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  ${YELLOW}WARN${RESET}  %s — have %s, recommend >= %s\n" "$name" "$actual_version" "$min_version"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ---------------------------------------------------------------------------
# Run checks
# ---------------------------------------------------------------------------

printf '\n'
printf "  ${BOLD}Universal Project Starter v2 — Setup Doctor${RESET}\n"
printf "  =============================================\n"
printf '\n'

# --- CLI Tools ---
printf "  ${BOLD}CLI Tools:${RESET}\n"
check "claude CLI" "command -v claude"
check "gh CLI" "command -v gh"
check_version "git >= 2.20" "2.20" "git --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'"
check "tmux" "command -v tmux"
check "jq" "command -v jq"
check "yq" "command -v yq"
check "osascript (macOS)" "command -v osascript"
printf '\n'

# --- Bash version ---
printf "  ${BOLD}Shell:${RESET}\n"
check_version_optional "bash >= 4.0 (recommended)" "4.0" "bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'"
printf '\n'

# --- Authentication ---
printf "  ${BOLD}Authentication:${RESET}\n"
check "gh authenticated" "gh auth status"
printf '\n'

# --- Configuration ---
printf "  ${BOLD}Configuration:${RESET}\n"
check ".claude/workflow.yaml exists" "[ -f '${PROJECT_ROOT}/.claude/workflow.yaml' ]"
check "workflow.yaml is valid YAML" "yq e '.' '${PROJECT_ROOT}/.claude/workflow.yaml'"
printf '\n'

# --- Agent files ---
printf "  ${BOLD}Agent Files:${RESET}\n"
for agent in orchestrator dev-agent qa-agent merge-agent prod-qa-agent; do
  check ".claude/agents/${agent}.md" "[ -f '${PROJECT_ROOT}/.claude/agents/${agent}.md' ]"
done
printf '\n'

# --- Git repository ---
printf "  ${BOLD}Git Repository:${RESET}\n"
check "Inside git repo" "git rev-parse --is-inside-work-tree"
check "Git remote configured" "git remote get-url origin" "false"
printf '\n'

# --- Optional tools ---
printf "  ${BOLD}Optional Tools:${RESET}\n"
check "playwright" "command -v playwright" "false"
check "agent-browser" "command -v agent-browser" "false"
printf '\n'

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf "  =============================================\n"
printf "  Results: ${GREEN}PASS=${PASS_COUNT}${RESET}  ${RED}FAIL=${FAIL_COUNT}${RESET}  ${YELLOW}WARN=${WARN_COUNT}${RESET}\n"
printf '\n'

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  printf "  ${RED}Fix the FAIL items above before running the pipeline.${RESET}\n\n"
  exit 1
else
  printf "  ${GREEN}All required checks passed. System is ready.${RESET}\n\n"
  exit 0
fi
