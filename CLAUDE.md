# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Universal Project Starter v2 — a portable `.claude/` directory system that transforms Claude Code into an autonomous multi-agent development team. It takes a project from idea to shipped, merged PRs through 5 independent Claude Code processes (`claude -p`), each with a fresh context window and role-specific system prompt. Agents communicate exclusively through GitHub issue comments and local sentinel files.

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Claude Code CLI (`claude -p`) | Primary AI interface — interactive sessions and headless agent processes |
| GitHub CLI (`gh`) | Issue management, PR creation, CI status checks, structured comments |
| Git (2.20+) | Version control, worktree management (`git worktree`) for parallel issue isolation |
| Bash/Zsh | Shell for `claude -p` subprocess invocation and pipeline orchestration |
| agent-browser | Browser automation for E2E testing (used by QA agent) |

---

## Commands

```bash
# Slash commands (run inside Claude Code)
/create-prd "project idea"   # Structured requirements gathering → PRD.md + GitHub Epic
/init-project                 # Scaffold project from PRD → CLAUDE.md + AGENTS.md + git
/impl #<issue-number>         # Multi-agent pipeline: Orchestrator → Dev → QA → Merge → Prod-QA

# Agent invocation (used by /impl internally)
claude -p "<task>" --system-prompt "$(cat .claude/agents/<agent>.md)" -C <worktree-path>

# Worktree management
git worktree add -b issue-<N> .worktrees/issue-<N> origin/main
git worktree remove .worktrees/issue-<N>

# GitHub operations
gh issue view <N>
gh issue comment <N> --body "<structured comment>"
gh pr create --title "..." --body "Fixes #<N>"
gh pr merge <N> --squash --delete-branch
```

---

## Project Structure

```
.claude/
├── commands/              # 3 slash commands (user-facing)
│   ├── create-prd.md      # Structured requirements → PRD + GitHub Epic
│   ├── init-project.md    # Scaffold + CLAUDE.md + AGENTS.md
│   └── impl.md            # Master orchestrator: worktree + 5-agent pipeline
├── agents/                # 5 agent system prompts (passed to claude -p)
│   ├── orchestrator.md    # Reads issue, creates plan, coordinates
│   ├── dev-agent.md       # Implements code + tests, opens PR
│   ├── qa-agent.md        # Read-only verification + E2E browser testing
│   ├── merge-agent.md     # CI gate + squash-merge + cleanup
│   └── prod-qa-agent.md   # Verifies feature is live in production
├── skills/                # Reusable capabilities (used by agents)
│   ├── agent-browser/     # Browser automation for QA/E2E
│   ├── agent-learnings/   # Cross-session knowledge capture
│   ├── e2e-test/          # Comprehensive E2E testing
│   ├── question-bank/     # PRD interrogation categories (A-G)
│   └── requirements-clarity/  # 0-100 scoring rubric
├── templates/             # Document templates
│   ├── CLAUDE-template.md # Project context template
│   ├── AGENTS-template.md # Agent rules template
│   └── PRD-template.md    # 16-section PRD template
├── learnings/             # Auto-populated JSON knowledge base
└── plans/                 # Auto-populated implementation plans
```

---

## Architecture

### Multi-Agent Pipeline

The system uses **process isolation** — each agent runs as a separate `claude -p` process with its own fresh context window. No shared memory. Communication is through:

1. **Sentinel files** (`.claude-workflow/`) — status and report files in the worktree
2. **GitHub issue comments** — structured audit trail with `[role]` prefixes

### Pipeline Flow

```
/impl #<N>
  → Create worktree (.worktrees/issue-<N>/)
  → Orchestrator: read issue → create plan → write orchestrator.report
  → Dev: read plan → implement + test → open PR → write dev.report
  → QA: read PR diff + issue → verify (read-only) → write qa.report
     └─ if FAIL → loop to Dev with fix list (max 3x)
  → Merge: verify CI → squash-merge → cleanup
  → Prod-QA: verify deployment (optional, if PROD_URL set)
```

### Placeholder Token Substitution

Agent prompts use tokens that `/impl` replaces at runtime:
- `__ISSUE_NUM__` → GitHub issue number
- `__WORKTREE_PATH__` → Absolute path to the worktree
- `__REPO__` → GitHub repo in `owner/repo` format
- `__PROD_URL__` → Production URL (if available)
- `__QA_REPORT__` → Content of `qa.report` (for Dev retry)

---

## Code Patterns

### Naming Conventions
- Agent prompts: `.claude/agents/<role>.md` (e.g., `dev-agent.md`, `qa-agent.md`)
- Sentinel files: `<role>.done` (status) and `<role>.report` (details)
- Worktrees: `.worktrees/issue-<N>/`
- GitHub comments: prefix with `[role]` (e.g., `[orchestrator]`, `[dev]`, `[qa]`)

### Sentinel File Protocol
- `*.done` files contain a single word: `DONE`, `STUCK`, `PASS`, `PASS-WITH-NITS`, `FAIL`
- `*.report` files contain structured markdown with: Summary, Actions Taken, Results, Files Changed, Follow-up Risks

### Error Handling
- Dev→QA retry loop: max 3 attempts, then halt with `blocked` label on GitHub issue
- Agent timeout: configurable per agent, defaults to 10 minutes
- On failure: preserve worktree for manual inspection, post detailed comment to GitHub issue

---

## Testing

- **Agent prompts**: Verify placeholder tokens are present, verify section structure
- **Pipeline**: End-to-end test via `/create-prd` → `/init-project` → `/impl` on a sample project
- **Validation commands**: See PRD Phase validation commands

---

## Validation

```bash
# Verify agent files exist
ls .claude/agents/orchestrator.md .claude/agents/dev-agent.md .claude/agents/qa-agent.md .claude/agents/merge-agent.md .claude/agents/prod-qa-agent.md

# Verify placeholder tokens
grep -l "__ISSUE_NUM__" .claude/agents/*.md
grep -l "__WORKTREE_PATH__" .claude/agents/*.md

# Verify QA read-only constraint
grep -i "never modify" .claude/agents/qa-agent.md

# Verify command files
ls .claude/commands/create-prd.md .claude/commands/init-project.md .claude/commands/impl.md
```

---

## Key Files

| File | Purpose |
|------|---------|
| `PRD.md` | Product requirements document — source of truth for all implementation |
| `CLAUDE.md` | This file — project context for Claude Code |
| `AGENTS.md` | Agent-specific rules, worktree boundaries, data safety constraints |
| `.env.example` | Required environment variables template |
| `.claude/commands/impl.md` | The master orchestrator command |
| `.claude/agents/*.md` | System prompts for the 5 independent agents |

---

## Notes

- This is a **meta-project**: the `.claude/` directory IS the product. It's designed to be portable — drop it into any project repo.
- All agent prompts must be tech-stack agnostic. Project-specific details come from CLAUDE.md and AGENTS.md at runtime.
- QA agent must NEVER modify source code — read-only verification only.
- Each agent gets a fresh context window via `claude -p`. No agent inherits another's context or biases.
- The only human touchpoint is `/create-prd`. Everything after that is fully autonomous.
