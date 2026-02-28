# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Universal Project Starter v2 — a portable `.claude/` + `scripts/` system that transforms Claude Code into an autonomous multi-agent development team. Bash scripts orchestrate interactive Claude sessions in tmux panes to take GitHub issues from plan to merged PR. Each agent can ask questions, request browser interaction, and the user can monitor and intervene via tmux.

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Bash/Zsh | Orchestration scripts — pipeline coordination, tmux management, worktree lifecycle |
| tmux 3.0+ | Terminal multiplexing — one session per issue, one pane per agent |
| Claude Code CLI | Interactive AI sessions in tmux panes (launched with `--dangerously-skip-permissions`) |
| GitHub CLI (`gh`) | Issue/PR management, structured comments, labels, CI status |
| Git 2.20+ | Version control, worktree isolation (`git worktree`) |
| jq | JSON parsing — sentinel files, agent learnings, GitHub API responses |
| yq | YAML parsing — `.claude/workflow.yaml` configuration |
| osascript | macOS desktop notifications when agents need human attention |
| Playwright | Browser automation for E2E testing (project-specific, not always needed) |
| agent-browser | Browser automation CLI (optional, for advanced E2E) |

---

## Commands

```bash
# Pipeline — run the 5-agent pipeline for a GitHub issue
./scripts/impl.sh #42
./scripts/impl.sh #42 --from qa     # Resume from a specific stage

# Batch — run all issues from an Epic with DAG dependency resolution
./scripts/run-all.sh --epic #1

# Status — check all running pipelines
./scripts/status.sh

# Setup — verify prerequisites
./scripts/setup.sh

# Pre-login — open headed browser to log into services
./scripts/login.sh

# PRD creation (Claude Code slash command — interactive)
# Inside claude: /create-prd

# Project scaffolding (Claude Code slash command)
# Inside claude: /init-project
```

---

## Project Structure

```
project-root/
├── .claude/
│   ├── commands/          # 2 slash commands (create-prd, init-project)
│   ├── agents/            # 5 agent role definitions (orchestrator, dev, qa, merge, prod-qa)
│   ├── skills/            # 5 reusable capabilities (browser, learnings, e2e, questions, clarity)
│   ├── templates/         # 4 document templates (CLAUDE, AGENTS, PRD, plan)
│   ├── workflow.yaml      # Pipeline configuration
│   ├── learnings/         # Agent learnings JSON files
│   └── plans/             # Implementation plans
├── scripts/
│   ├── impl.sh            # Single-issue pipeline orchestrator
│   ├── run-all.sh         # Multi-issue DAG runner
│   ├── setup.sh           # Doctor/prerequisite checker
│   ├── status.sh          # Pipeline status reporter
│   ├── login.sh           # Pre-login browser session manager
│   └── lib/               # Shared bash library
│       ├── config.sh      # YAML config parser
│       ├── tmux.sh        # tmux session/pane management
│       ├── worktree.sh    # Git worktree lifecycle
│       ├── sentinel.sh    # Sentinel file I/O
│       ├── lock.sh        # Git operation lock serialization
│       ├── notify.sh      # macOS desktop notifications
│       ├── github.sh      # GitHub CLI helpers
│       ├── dag.sh         # Dependency graph resolution
│       └── log.sh         # Logging + terminal titles
├── browser-data/          # Persistent browser sessions (gitignored)
├── .worktrees/            # Git worktrees per issue (gitignored)
├── PRD.md                 # Product requirements document
├── CLAUDE.md              # This file — project context for Claude Code
├── AGENTS.md              # Agent-specific rules and constraints
└── README.md              # Setup and usage documentation
```

---

## Architecture

**Bash Orchestrates, Claude Works**:
- `scripts/impl.sh` is the pipeline orchestrator. It creates tmux sessions, generates per-stage CLAUDE.md files, launches interactive Claude sessions, monitors sentinel files, handles retries, and manages worktree lifecycle.
- Each agent runs as `claude --dangerously-skip-permissions` in its own tmux pane with a fresh context. Agents communicate only through sentinel files (`.claude-workflow/*.done` and `*.report`) and GitHub issue comments.
- The DAG resolver (`scripts/run-all.sh`) parses `Depends on: #N` from issue bodies to determine execution order across multiple issues.

**Pipeline flow per issue**:
```
impl.sh #42
  → Create worktree .worktrees/issue-42/
  → Stage 1: Orchestrator (plan → orchestrator.done)
  → Stage 2: Dev (implement + PR → dev.done)
  → Stage 3: QA (verify read-only → qa.done)
     └─ if FAIL → retry Dev with QA report (max 3x)
  → Stage 4: Merge (CI gate → squash-merge → merge.done)
  → Stage 5: Prod-QA (verify production → prod-qa.done, optional)
  → Cleanup worktree on success / preserve on failure
```

**Agent CLAUDE.md injection**: Before each stage, `impl.sh` writes a customized `CLAUDE.md` into the worktree containing: project context + agent role instructions (from `.claude/agents/*.md`) + task-specific details (issue number, previous stage output). Claude Code auto-reads this on startup.

---

## Code Patterns

### Naming Conventions
- Bash scripts: `kebab-case.sh` for top-level, `snake_case.sh` for lib/
- Bash functions: `snake_case` (e.g., `create_tmux_session`, `acquire_lock`)
- Sentinel files: `agent-name.done`, `agent-name.report`
- Agent prompts: `agent-name.md` in `.claude/agents/`
- Config: YAML with `snake_case` keys

### File Organization
- Top-level scripts in `scripts/` — user-facing entry points
- Shared functions in `scripts/lib/` — sourced by top-level scripts
- Agent role definitions in `.claude/agents/` — consumed by CLAUDE.md generation
- Skills in `.claude/skills/` — consumed by agents at runtime
- Templates in `.claude/templates/` — consumed by `/create-prd` and `/init-project`

### Error Handling
- Bash scripts use `set -euo pipefail` for strict error handling
- Functions return exit codes (0 = success, non-zero = failure)
- Failed pipeline stages write sentinel files (`STUCK`, `FAIL`, etc.) and post GitHub comments
- Worktrees are preserved on failure for manual inspection

---

## Testing

- **Test approach**: This project is tested via end-to-end pipeline runs on real projects
- **Validation**: `./scripts/setup.sh` verifies all prerequisites
- **Bash syntax check**: `for f in scripts/lib/*.sh; do bash -n "$f"; done`
- **Integration test**: Run `./scripts/impl.sh #<test-issue>` on a sample project and verify the full pipeline completes

---

## Validation

```bash
# Verify all bash scripts have valid syntax
for f in scripts/*.sh scripts/lib/*.sh; do bash -n "$f" && echo "PASS: $f" || echo "FAIL: $f"; done

# Verify prerequisites
./scripts/setup.sh

# Verify config is parseable
source scripts/lib/config.sh && get_config pipeline.max_retries
```

---

## Deployment

- **Production URL**: N/A — this is a development workflow tool, not a deployed service
- **Deploy method**: Copy `.claude/` + `scripts/` into any project repo
- **Portability test**: `./scripts/setup.sh` in a fresh repo confirms readiness

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/impl.sh` | Core pipeline orchestrator — the main entry point for issue implementation |
| `scripts/run-all.sh` | Batch runner with DAG dependency resolution |
| `scripts/lib/tmux.sh` | tmux session/pane management functions |
| `scripts/lib/worktree.sh` | Git worktree create, symlink, cleanup |
| `scripts/lib/sentinel.sh` | Sentinel file read/write/poll |
| `scripts/lib/dag.sh` | Dependency graph parsing and resolution |
| `.claude/workflow.yaml` | Pipeline configuration (retries, timeouts, labels, symlinks) |
| `.claude/agents/*.md` | Agent role definitions consumed during CLAUDE.md generation |
| `.claude/commands/create-prd.md` | PRD creation slash command |
| `.claude/commands/init-project.md` | Project scaffolding slash command |
| `PRD.md` | Product requirements document (the source of truth) |

---

## On-Demand Context

| Topic | File |
|-------|------|
| PRD (full requirements) | `PRD.md` |
| Agent rules and constraints | `AGENTS.md` |
| Pipeline configuration | `.claude/workflow.yaml` |
| Orchestrator agent role | `.claude/agents/orchestrator.md` |
| Dev agent role | `.claude/agents/dev-agent.md` |
| QA agent role | `.claude/agents/qa-agent.md` |
| Merge agent role | `.claude/agents/merge-agent.md` |
| Prod-QA agent role | `.claude/agents/prod-qa-agent.md` |
| Browser automation reference | `.claude/skills/agent-browser/SKILL.md` |
| E2E testing reference | `.claude/skills/e2e-test/SKILL.md` |
| v1 PRD (archived) | `PRD-v1.md` |
| Reference workflows | `references/` |

---

## Notes

- All agents launch with `--dangerously-skip-permissions` so they don't block on permission prompts. User oversight is provided via tmux pane visibility.
- The `.claude/settings.local.json` restricts the orchestrating Claude session to `git` and `gh` commands only. Agents in tmux panes have full permissions via the skip flag.
- Sentinel files use `NEEDS_HUMAN` as a status value to trigger desktop notifications when an agent needs user interaction (e.g., browser login).
- The `browser-data/` directory stores persistent Chromium session data (cookies, local storage). It is gitignored and symlinked into worktrees so all agents share the same login state.
- When this system is copied into a target project, `/init-project` regenerates CLAUDE.md and AGENTS.md with that project's specific details. The files in THIS repo describe the workflow system itself.
