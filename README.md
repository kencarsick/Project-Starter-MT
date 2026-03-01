# Universal Project Starter v2

A portable `.claude/` + `scripts/` system that transforms Claude Code into an autonomous multi-agent development team. You describe the idea — 5 interactive AI agents handle everything else.

## What Changed in v2

v1 used non-interactive `claude -p` agents that couldn't ask questions, couldn't open headed browsers, and hallucinated when stuck. v2 fixes this:

- **Interactive agents in tmux panes** — agents can ask you questions and you can see everything
- **Bash scripts orchestrate** — deterministic coordination that can't hallucinate
- **`--dangerously-skip-permissions`** — agents don't block on permission prompts
- **Headed browser interaction** — agents pause and ask you to log in when auth is needed
- **ASSUMPTION markers** — unverifiable code is explicitly flagged, QA enforces runtime proof
- **DAG dependency resolution** — issues run in correct order automatically
- **Unlimited parallelism** — one tmux session per issue, worktree isolation

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git 2.20+ (for worktree support)
- tmux 3.0+ (`brew install tmux`)
- jq (`brew install jq`)
- yq (`brew install yq`)
- macOS (for desktop notifications via osascript)

## Setup

```bash
# 1. Create your project directory
mkdir my-new-project && cd my-new-project

# 2. Copy the .claude/ and scripts/ folders into it
cp -r /path/to/project-starter/.claude/ .claude/
cp -r /path/to/project-starter/scripts/ scripts/

# 3. Verify prerequisites
./scripts/setup.sh

# 4. Start Claude Code
claude
```

## Quick Start

```
# Step 1: Create the PRD (interactive — you answer questions)
/create-prd

# Step 2: Initialize the project (scaffolds, generates CLAUDE.md + AGENTS.md)
/init-project

# Step 3: Implement issues via multi-agent pipeline (autonomous with human interaction)
./scripts/impl.sh '#2'
./scripts/impl.sh '#3'
./scripts/impl.sh '#4'

# Or run all issues with dependency resolution
./scripts/run-all.sh --epic '#1'
```

## Pipeline

Each issue runs through 5 stages in its own tmux session:

| Stage | Agent | What It Does |
|-------|-------|-------------|
| 1 | **Orchestrator** | Reads issue, scans codebase for reuse, creates plan with VALIDATE commands |
| 2 | **Dev** | Implements code + tests, marks assumptions, opens PR, asks for help when stuck |
| 3 | **QA** | Read-only verification, Requirements Coverage Matrix with runtime proof |
| 4 | **Merge** | Waits for CI, squash-merges PR |
| 5 | **Prod-QA** | Verifies feature is live in production (if PROD_URL set) |

**Key behaviors:**
- Agents run as interactive `claude --dangerously-skip-permissions` in tmux panes
- You can see all agent output and type into any pane
- Desktop notifications fire when an agent needs your attention
- QA failure triggers Dev retry with fix list (max 3 cycles)
- All output logged to `.claude-workflow/logs/` for post-mortem
- Resume failed pipelines: `./scripts/impl.sh '#42' --from qa`

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/impl.sh '#N'` | Run the 5-agent pipeline for a single issue |
| `scripts/run-all.sh` | Run all issues from an Epic with dependency resolution |
| `scripts/setup.sh` | Verify all prerequisites are installed and configured |
| `scripts/status.sh` | Check status of all running pipelines |
| `scripts/login.sh` | Open headed browser to pre-login to services |

## Configuration

Edit `.claude/workflow.yaml` to tune pipeline behavior:

| Setting | Default | Purpose |
|---------|---------|---------|
| `pipeline.max_retries` | `3` | Dev→QA retry cycles before halting |
| `pipeline.max_turns_per_agent` | `200` | Safety cap per agent session |
| `notifications.enabled` | `true` | macOS desktop notifications |
| `worktree.lock_timeout` | `60` | Seconds to wait for git operation lock |
| `prod_url` | `""` | Production URL for Prod-QA (empty = skip) |

## Architecture

```
./scripts/impl.sh '#42'
  → Create worktree .worktrees/issue-42/
  → Create tmux session "issue-42" with 5 panes
  → For each stage:
      Generate CLAUDE.md with agent role + task context
      Launch "claude --dangerously-skip-permissions" in pane
      Send initial prompt via tmux send-keys
      Monitor sentinel files for completion
  → On QA FAIL: retry Dev with QA report (max 3x)
  → On success: cleanup worktree, close issue
  → On failure: preserve worktree, label issue "blocked"
```

Agents communicate through:
1. **Sentinel files** — `.claude-workflow/*.done` and `*.report` in the worktree
2. **GitHub issue comments** — structured audit trail with `[role]` prefixes
3. **CLAUDE.md** — agent role instructions injected per stage

## Anti-Hallucination Measures

Preventing the Niggsfield pattern (hallucinated selectors passing QA):

1. **ASSUMPTION markers**: Dev adds `// ASSUMPTION: <desc>` for unverifiable code
2. **QA Runtime Proof**: Every criterion needs a command + output, not "looks correct"
3. **Headed browser interaction**: Agents can open visible browsers, ask you to log in
4. **Codebase reuse scan**: Mandatory scan for existing patterns before implementing
5. **VALIDATE commands**: Each plan task has a verification command run immediately after

## Project Structure

```
.claude/
├── commands/           # 2 slash commands (create-prd, init-project)
├── agents/             # 5 agent role definitions
├── skills/             # 5 reusable capabilities
├── templates/          # 4 document templates
├── workflow.yaml       # Pipeline configuration
├── learnings/          # Agent learnings JSON
└── plans/              # Implementation plans
scripts/
├── impl.sh             # Pipeline orchestrator
├── run-all.sh          # DAG runner
├── setup.sh            # Doctor script
├── status.sh           # Status reporter
├── login.sh            # Browser pre-login
└── lib/                # Shared bash library (9 modules)
```

## Design Principles

1. **PRD is the bottleneck by design** — the only human touchpoint for requirements
2. **Interactive when needed, autonomous by default** — agents ask instead of hallucinating
3. **Bash orchestrates, Claude works** — deterministic coordination, creative AI work
4. **Prove everything, assume nothing** — QA needs runtime proof, not "looks correct"
5. **Fail safely** — worktrees preserved, issues labeled, recovery instructions posted
6. **Universal** — zero tech-stack assumptions, everything detected at runtime
