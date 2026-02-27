# Universal Project Starter v2

A portable `.claude/` directory that transforms Claude Code into an autonomous multi-agent development team. You describe the idea — 5 independent AI agents handle everything else.

## What This Is

Drop the `.claude/` folder into any empty project directory. It gives Claude Code **3 commands**, **5 agent roles**, **5 skills**, and **4 templates** that form a fully autonomous development pipeline — from idea to merged PR.

**The workflow:**
1. You describe your idea
2. Claude interrogates you until requirements are crystal clear (clarity score >= 90/100)
3. Claude generates an exhaustive PRD + GitHub Epic with Task issues
4. Claude scaffolds the project, generates CLAUDE.md + AGENTS.md
5. For each task issue: 5 independent agents plan, implement, test, merge, and verify in production

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git 2.20+ (for worktree support)

## Setup

```bash
# 1. Create your project directory
mkdir my-new-project && cd my-new-project

# 2. Copy the .claude/ folder into it
cp -r /path/to/project-starter/.claude/ .claude/

# 3. Start Claude Code
claude
```

That's it. The commands are automatically available.

## Quick Start

```
# Step 1: Create the PRD (interactive — you answer questions)
/create-prd "my-project-name"

# Step 2: Initialize the project (autonomous — scaffolds, generates CLAUDE.md + AGENTS.md)
/init-project

# Step 3: Implement issues via multi-agent pipeline (fully autonomous)
/impl #1
/impl #2
/impl #3
# ...repeat for each task issue created by /create-prd
```

## Commands

### `/create-prd` — Create Product Requirements Document
**Usage**: `/create-prd "project-name"`
**Interaction**: Yes (the only command requiring user input)

Transforms a vague idea into a decision-complete PRD through structured interrogation.

1. Scores your idea's clarity (0-100) across 4 dimensions
2. Asks multiple-choice questions across 7 categories until clarity >= 90
3. Proposes minimal approach with alternatives (Devil's Advocate)
4. Generates a 16-section PRD
5. Creates GitHub Epic + Task issues (one per implementation phase)

**Output**: `PRD.md`, GitHub Epic (label: `type:epic`), Task issues (label: `type:task`)

---

### `/init-project` — Scaffold & Configure
**Usage**: `/init-project`
**Interaction**: Minimal (asks about GitHub remote creation)

Reads the PRD and sets up the entire project.

1. Detects tech stack from PRD, runs appropriate scaffold (Next.js, Django, Rust, Go, etc.)
2. Installs dependencies, configures linter/formatter/test framework
3. Creates `.env.example` and `.gitignore`
4. Initializes git with initial commit
5. Validates setup (dev server, linter, tests, build)
6. **Generates `CLAUDE.md`** from codebase analysis
7. **Generates `AGENTS.md`** with project-specific agent rules

---

### `/impl` — Multi-Agent Pipeline
**Usage**: `/impl #42` (GitHub issue number)
**Interaction**: None (fully autonomous)

Spawns 5 independent `claude -p` processes in an isolated git worktree.

**Pipeline stages:**

| Stage | Agent | What It Does |
|-------|-------|-------------|
| 1 | **Orchestrator** | Reads issue, creates implementation plan |
| 2 | **Dev** | Implements code + tests, opens PR |
| 3 | **QA** | Read-only verification, E2E browser testing, requirements coverage matrix |
| 4 | **Merge** | Waits for CI, squash-merges PR |
| 5 | **Prod-QA** | Verifies feature is live in production (if PROD_URL set) |

**Key behaviors:**
- QA failure triggers Dev retry with fix list (max 3 cycles)
- Each agent posts structured comments on the GitHub issue
- On success: worktree cleaned up, issue closed
- On failure: worktree preserved for manual inspection, `blocked` label added

## Architecture

Each agent runs as a **separate `claude -p` process** with its own fresh context window. No shared memory. Agents communicate through:

1. **Sentinel files** — `.claude-workflow/*.done` and `*.report` in the worktree
2. **GitHub issue comments** — structured audit trail with `[role]` prefixes

```
/impl #42
  → Create worktree (.worktrees/issue-42/)
  → Orchestrator: read issue → create plan
  → Dev: implement + test → open PR
  → QA: verify (read-only) → pass/fail
     └─ if FAIL → Dev retry with fix list (max 3x)
  → Merge: CI gate → squash-merge
  → Prod-QA: verify deployment (optional)
  → Cleanup worktree
```

## Skills

Skills are specialized capabilities used by agents. You don't invoke them directly.

| Skill | Purpose | Used By |
|-------|---------|---------|
| `requirements-clarity` | 0-100 clarity scoring rubric | `/create-prd` |
| `question-bank` | Structured question categories (A-G) | `/create-prd` |
| `agent-browser` | Browser automation (navigate, click, fill, screenshot) | QA, Prod-QA agents |
| `e2e-test` | E2E testing with parallel research sub-agents | QA, Dev agents |
| `agent-learnings` | JSON institutional knowledge capture | All agents |

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `AGENT_TIMEOUT` | `600` (10 min) | Seconds before an agent is killed |
| `AGENT_MAX_RETRIES` | `3` | Max Dev→QA retry cycles |
| `PROD_URL` | (empty) | Production URL for Prod-QA verification |

## Project Structure

```
.claude/
├── commands/           # 3 slash commands (user-facing)
│   ├── create-prd.md   # PRD generation with structured interrogation
│   ├── init-project.md # Scaffold + CLAUDE.md + AGENTS.md generation
│   └── impl.md         # Multi-agent pipeline orchestrator
├── agents/             # 5 agent system prompts (passed to claude -p)
│   ├── orchestrator.md
│   ├── dev-agent.md
│   ├── qa-agent.md
│   ├── merge-agent.md
│   └── prod-qa-agent.md
├── skills/             # 5 reusable capabilities
│   ├── agent-browser/
│   ├── agent-learnings/
│   ├── e2e-test/
│   ├── question-bank/
│   └── requirements-clarity/
├── templates/          # 4 document templates
│   ├── CLAUDE-template.md
│   ├── AGENTS-template.md
│   ├── PRD-template.md
│   └── plan-template.md
├── learnings/          # Auto-populated knowledge base (JSON)
└── plans/              # Auto-populated implementation plans
```

## Design Principles

1. **PRD is the bottleneck by design** — the only human touchpoint. Thoroughness here prevents issues downstream.
2. **Process isolation** — each agent gets a fresh context window. No inherited biases or stale state.
3. **Prove everything, assume nothing** — QA produces a Requirements Coverage Matrix with evidence for every criterion.
4. **Fail safely** — on failure, worktrees are preserved, GitHub issues are labeled `blocked`, and detailed recovery instructions are posted.
5. **Universal** — zero tech-stack assumptions. Everything detected at runtime from the PRD and codebase analysis.
6. **Self-improving** — agents capture learnings as JSON, building institutional knowledge across issues.
