# Universal Project Starter v2 — Product Requirements Document

## 1. Executive Summary

The Universal Project Starter is a portable `.claude/` directory system that transforms Claude Code into an autonomous multi-agent development team. It takes a project from idea to shipped, merged PRs with zero human intervention after the requirements phase.

The current system (v1) operates as a single-agent sequential pipeline — one Claude Code session handles planning, implementation, verification, and merging. This creates bias (the same agent reviews its own work), prevents parallel issue work (no worktree isolation), and risks hallucination accumulation (one growing context window).

v2 replaces the runtime pipeline with 5 independent Claude Code processes (`claude -p`), each with a fresh context window, role-specific system prompt, and strict behavioral constraints. Agents communicate exclusively through GitHub issue comments and local sentinel files — never through shared memory. This delivers independent QA critique, true worktree isolation for parallel issues, and clear plain-English communication across the entire audit trail.

---

## 2. Mission & Core Principles

**Mission**: Build a universal, portable `.claude/` system that turns Claude Code into a self-coordinating team of isolated AI engineers — from PRD to production-verified merge.

### Core Principles

1. **Isolated Context = Honest Critique** — Each agent gets a fresh context window via `claude -p`. QA never sees Dev's reasoning. This eliminates confirmation bias and reduces hallucination.
2. **Fully Automated After PRD** — The only human touchpoint is requirements gathering (`/create-prd`). Everything else — scaffolding, planning, implementation, testing, verification, merging, production checks — runs autonomously.
3. **Clear & Plain English** — Every agent communicates in unambiguous English with full context. A human reading a GitHub issue comment should understand the situation without referencing other issues or prior conversations.
4. **Parallel by Default** — Each issue gets its own git worktree and its own agent pipeline. Run 20-30 issues simultaneously in separate terminal tabs with zero conflicts.
5. **Prove Everything, Assume Nothing** — No feature ships without proven acceptance criteria. QA produces a Requirements Coverage Matrix with evidence for every criterion.

---

## 3. Target Users

### Persona 1: Solo AI-Augmented Developer
- **Needs**: Manage 20-30 concurrent GitHub issues with autonomous implementation and quality gates
- **Pain Points**: Context switching between issues; reviewing AI-generated code that the same AI "verified"; worktree management overhead
- **Success Looks Like**: Types `/impl #123` in a terminal tab and comes back to a merged PR with full QA evidence on the GitHub issue

### Persona 2: Developer Who Needs an Unbiased Team
- **Needs**: A skilled, unbiased team of 5 specialized engineers to work on GitHub issues — not one agent wearing all hats
- **Pain Points**: Currently a "team of one" — one AI session plans, implements, reviews, and merges its own work. The same context window that wrote the code also "verifies" it, creating inherent confirmation bias. Bugs slip through because the reviewer already "knows" what the code was supposed to do.
- **Success Looks Like**: Types `/impl #42` and watches 5 separate terminals open sequentially — Orchestrator plans with a fresh context, Dev implements with a fresh context, QA reviews with a fresh context having never seen Dev's reasoning, Merge gates with a fresh context, Prod-QA verifies with a fresh context. Each engineer starts blank, reads only what they need, and does their job independently.

### Persona 3: Team Lead Managing AI Workflows
- **Needs**: Consistent, auditable development pipeline across projects with different tech stacks
- **Pain Points**: No standard way to structure AI agent workflows; agents produce inconsistent quality; no audit trail
- **Success Looks Like**: Drops `.claude/` into any project repo and has a working multi-agent pipeline with GitHub-native audit trails

---

## 4. MVP Scope

### In Scope

| Category | Feature | Status |
|----------|---------|--------|
| Commands | `/create-prd` — structured requirements gathering with clarity scoring | ✅ MVP |
| Commands | `/init-project` — scaffold project + generate CLAUDE.md + AGENTS.md | ✅ MVP |
| Commands | `/impl` — master orchestrator spawning 5 isolated agents | ✅ MVP |
| Agents | Orchestrator — reads issue, creates plan, coordinates pipeline | ✅ MVP |
| Agents | Dev — implements code + tests, opens PR | ✅ MVP |
| Agents | QA — read-only code review + test execution + E2E browser testing | ✅ MVP |
| Agents | Merge — CI gate + squash-merge + branch/worktree cleanup | ✅ MVP |
| Agents | Prod-QA — verifies feature is live (optional, skipped if no PROD_URL) | ✅ MVP |
| Infrastructure | Git worktree isolation per issue | ✅ MVP |
| Infrastructure | Sentinel file coordination between agents | ✅ MVP |
| Infrastructure | GitHub issue comment audit trail | ✅ MVP |
| Templates | AGENTS-template.md for per-project agent rules | ✅ MVP |
| Skills | All existing skills (agent-browser, agent-learnings, e2e-test, question-bank, requirements-clarity) | ✅ MVP |

### Out of Scope

| Category | Feature | Reason |
|----------|---------|--------|
| Budget | Per-agent token/cost budgets | ❌ Trust agents to act efficiently |
| Multi-tool | Support for Codex CLI, Cursor, etc. | ❌ Claude Code only — leverage its specific features |
| Parallelism | Single-session multi-issue management | ❌ Use separate terminal tabs instead |
| Learning | Automated learning-to-CLAUDE.md promotion (agents discover patterns/preferences during implementation and auto-suggest additions to CLAUDE.md project rules — e.g., "this project always uses `zod` for validation" gets proposed as a new CLAUDE.md rule after appearing in 3+ issues) | ❌ Phase 2 — for now, learnings are captured as JSON files in `.claude/learnings/` but require manual review via `/learnings review` before being promoted to project rules |
| Dashboard | Web UI for monitoring pipeline status | ❌ GitHub issue threads serve this purpose |

---

## 5. User Stories

1. **As a** developer, **I want to** run `/create-prd "my-idea"` and be interrogated until my requirements are crystal clear, **so that** downstream agents have unambiguous specifications.
   - _Example_: Developer types `/create-prd "task management app"`. Claude asks structured multiple-choice questions across 7 categories, scores clarity each round, and doesn't generate the PRD until score >= 90/100. Output: `PRD.md` + GitHub Epic with Task issues.

2. **As a** developer, **I want to** run `/init-project` and have my entire project scaffolded with CLAUDE.md and AGENTS.md, **so that** agents have full project context from day one.
   - _Example_: After PRD is approved, developer runs `/init-project`. Claude reads the PRD, runs `create-next-app` (or equivalent), installs deps, sets up linting/testing, generates CLAUDE.md and AGENTS.md, initializes git, and validates everything works.

3. **As a** developer, **I want to** run `/impl #42` in a terminal tab and have 5 independent agents — each with a completely fresh context window and zero knowledge of what previous agents thought — implement, verify, and merge the feature, **so that** I get unbiased work from each engineer and can trust the pipeline's output.
   - _Example_: Developer opens a terminal tab, starts `claude`, types `/impl #42`. The command creates a worktree at `.worktrees/issue-42/`, then spawns 5 agents sequentially — each as a separate `claude -p` process with its own fresh context window. The Orchestrator reads the issue cold and creates a plan. Dev reads only the plan (not the Orchestrator's reasoning) and implements. QA reads only the PR diff and issue requirements (not Dev's thought process or internal notes) and verifies independently. Merge reads only the QA verdict. Prod-QA reads only the merge result. No agent inherits another agent's context, biases, or assumptions.

4. **As a** developer, **I want to** run `/impl` on 5 different issues simultaneously in 5 terminal tabs, **so that** I can parallelize my work across the sprint.
   - _Example_: Five terminal tabs, each running `/impl #42`, `/impl #43`, `/impl #44`, `/impl #45`, `/impl #46`. Each creates its own worktree. No conflicts. Developer checks GitHub for progress across all issues.

5. **As a** developer, **I want** the QA agent to independently verify code it has never seen before, **so that** verification is unbiased and catches issues the Dev agent missed.
   - _Example_: QA agent spawns with a fresh context. It reads the PR diff, runs the test suite, executes E2E browser tests for user-facing features, and produces a Requirements Coverage Matrix. It never modifies code — only reports findings.

6. **As a** developer, **I want** failed QA to automatically loop back to Dev with a concrete fix list, **so that** issues self-heal without my intervention (up to 3 attempts).
   - _Example_: QA returns FAIL with a fix list. The `/impl` command removes sentinel files and re-spawns Dev with the QA report injected. Dev fixes, QA re-verifies. After 3 failures, the pipeline halts and posts a detailed comment on the GitHub issue with a suggested fix.

7. **As a** developer, **I want** every agent to post structured comments on the GitHub issue, **so that** I have a complete audit trail without needing to read terminal output.
   - _Example_: GitHub issue #42 shows comments from `[orchestrator]`, `[dev]`, `[qa]`, `[merge]`, each with clear context, actions taken, and results. Reading the issue thread tells the full story.

8. **As a** developer, **I want** the system to work with any tech stack, **so that** I can drop `.claude/` into a Next.js project, a Rust CLI, a Python API, or anything else.
   - _Example_: The same `.claude/` directory works unchanged across projects. `/init-project` detects the tech stack from the PRD. Agent prompts contain no tech-stack assumptions.

9. **As a** developer, **I want** each agent to include actionable suggestions for improving the project or the specific solution at the end of their work, **so that** the codebase continuously improves beyond just meeting acceptance criteria.
   - _Example_: After Dev finishes implementation, its report includes a "Suggestions" section: "Consider extracting the date formatting logic into a shared utility — it's duplicated in 3 components." QA's report includes: "The error handling in the API route returns raw error messages to the client — consider wrapping in a sanitized error response for production." These suggestions are posted on the GitHub issue alongside the agent's main report, giving the developer a backlog of improvements to consider.

---

## 6. Core Architecture & Patterns

### High-Level Architecture

```
┌──────────────────────────────────────────────────┐
│                USER INTERACTION                   │
│                                                   │
│  Terminal Tab 1: claude → /create-prd "idea"      │
│  Terminal Tab 1: claude → /init-project           │
│                                                   │
│  Terminal Tab 1: claude → /impl #42               │
│  Terminal Tab 2: claude → /impl #43               │
│  Terminal Tab 3: claude → /impl #44               │
│  (each runs independently)                        │
└───────────────────┬──────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│              /impl #42 PIPELINE                   │
│                                                   │
│  1. Create worktree: .worktrees/issue-42/         │
│  2. claude -p (Orchestrator) → plan               │
│  3. claude -p (Dev) → implement + PR              │
│  4. claude -p (QA) → verify (read-only)           │
│     └─ if FAIL → loop to Dev (max 3x)            │
│  5. claude -p (Merge) → squash-merge + cleanup    │
│  6. claude -p (Prod-QA) → verify production       │
│                                                   │
│  Communication:                                   │
│  ├─ GitHub issue comments (audit trail)           │
│  └─ Sentinel files (agent handoffs)               │
│     .worktrees/issue-42/.claude-workflow/          │
│     ├── orchestrator.done                         │
│     ├── orchestrator.report                       │
│     ├── dev.done          (DONE | STUCK)          │
│     ├── dev.report                                │
│     ├── qa.done           (PASS | PASS-WITH-NITS  │
│     │                      | FAIL)                │
│     ├── qa.report                                 │
│     ├── merge.done                                │
│     └── prod-qa.done                              │
└──────────────────────────────────────────────────┘
```

### Directory Structure

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
│   │   └── SKILL.md
│   ├── agent-learnings/   # Cross-session knowledge capture
│   │   └── SKILL.md
│   ├── e2e-test/          # Comprehensive E2E testing
│   │   └── SKILL.md
│   ├── question-bank/     # PRD interrogation categories (A-G)
│   │   └── SKILL.md
│   └── requirements-clarity/  # 0-100 scoring rubric
│       └── SKILL.md
├── templates/             # Document templates
│   ├── CLAUDE-template.md # Project context template
│   ├── AGENTS-template.md # Agent rules template (NEW)
│   └── PRD-template.md    # 16-section PRD template
├── learnings/             # Auto-populated JSON knowledge base
│   └── .gitkeep
└── plans/                 # Auto-populated implementation plans
    └── .gitkeep
```

### Design Patterns

- **Process Isolation**: Each agent is a separate `claude -p` process with its own context window. No shared state except files on disk and GitHub.
- **Sentinel File Coordination**: Agents write `.claude-workflow/*.done` and `*.report` files. The orchestrating `/impl` command reads these to determine next steps.
- **GitHub as System of Record**: Every agent posts structured comments on the GitHub issue with a role prefix (`[orchestrator]`, `[dev]`, `[qa]`, `[merge]`, `[prod-qa]`). This creates a permanent, human-readable audit trail.
- **Placeholder Token Substitution**: Agent prompts contain tokens like `__ISSUE_NUM__`, `__WORKTREE_PATH__`, `__REPO__` that the `/impl` command replaces with actual values before passing to `claude -p`.
- **Fail-Safe Retry Loop**: Dev→QA cycles up to 3 times. On persistent failure, pipeline halts, preserves worktree, and posts suggested fix to GitHub issue.

---

## 7. Features

### Feature 1: `/create-prd` — Structured Requirements Gathering

**Description**: Transforms a vague project idea into a decision-complete PRD through multi-round structured interrogation. The only command requiring human interaction.

**Entry Point**: User types `/create-prd "project-name"` in Claude Code

**Data Flow**:
1. Check for existing PRD.md — offer to archive, update, or replace
2. Read existing project context (CLAUDE.md, README.md, package.json, etc.)
3. Verify GitHub CLI authentication (`gh auth status`)
4. Accept user's project idea (1 sentence to 1 paragraph)
5. Score initial clarity using requirements-clarity skill (0-100 across 4 dimensions)
6. Enter interrogation loop using question-bank skill:
   - Ask 2-4 multiple-choice questions per round targeting highest-impact gaps
   - Apply anti-vagueness detection (flag: "works", "robust", "fast", "better", etc.)
   - Update and report clarity score after each round
   - Continue until score >= 90/100
7. Devil's Advocate phase: propose minimal plan with 1-2 alternatives, apply YAGNI
8. Get user approval on approach
9. Codebase reuse scan (or greenfield research)
10. Generate 16-section PRD from PRD-template.md
11. Create GitHub Epic issue + Task issues (one per implementation phase)
12. Get user final approval
13. Write PRD.md to project root

### Feature 2: `/init-project` — Project Scaffolding + Agent Configuration

**Description**: Reads the PRD and scaffolds the project with the correct tech stack, then generates CLAUDE.md and AGENTS.md so agents have full context.

**Entry Point**: User types `/init-project` in Claude Code

**Data Flow**:
1. Read PRD.md for tech stack, directory structure, dependencies
2. Run appropriate scaffold command (create-next-app, cargo new, uv init, etc.)
3. Install dependencies
4. Set up linter, formatter, test framework
5. Create `.env.example` with required environment variables
6. Generate CLAUDE.md from CLAUDE-template.md (filled with actual project details)
7. Generate AGENTS.md from AGENTS-template.md (filled with project-specific agent rules)
8. Initialize git repository
9. Create initial commit
10. Optionally create GitHub remote via `gh repo create`
11. Run validation checks: dev server starts, linter passes, tests pass, build succeeds

### Feature 3: `/impl` — Multi-Agent Implementation Pipeline

**Description**: The master orchestrator. Creates a worktree for the given issue, then spawns 5 independent Claude Code processes to implement, verify, and merge the feature.

**Entry Point**: User types `/impl #<issue-number>` in Claude Code

**Data Flow**:
1. **Pre-flight checks**:
   - Verify `claude` CLI is available
   - Verify `gh` CLI is authenticated
   - Verify CLAUDE.md and AGENTS.md exist
   - Verify current directory is on `main` with clean working tree
   - Read the GitHub issue to confirm it exists
2. **Worktree setup**:
   - Create git worktree: `git worktree add -b issue-<N> .worktrees/issue-<N> origin/main`
   - Copy/symlink `.env*` files into worktree
   - Create `.claude-workflow/` directory in worktree for sentinel files
3. **Spawn Orchestrator agent** (`claude -p` with `.claude/agents/orchestrator.md`):
   - Reads GitHub issue, CLAUDE.md, AGENTS.md, README.md
   - Creates implementation plan
   - Writes `orchestrator.done` + `orchestrator.report`
4. **Spawn Dev agent** (`claude -p` with `.claude/agents/dev-agent.md`):
   - Reads orchestrator.report for the plan
   - Implements code changes in the worktree
   - Writes tests (unit + integration + E2E)
   - Opens PR with `Fixes #<N>` in description
   - Writes `dev.done` (DONE or STUCK) + `dev.report`
5. **Spawn QA agent** (`claude -p` with `.claude/agents/qa-agent.md`):
   - Reads GitHub issue requirements
   - Reviews PR diff (read-only — NEVER modifies code)
   - Runs test suite
   - Executes E2E browser tests for user-facing features
   - Produces Requirements Coverage Matrix
   - Writes `qa.done` (PASS, PASS-WITH-NITS, or FAIL) + `qa.report`
6. **If QA = FAIL** (retry loop, max 3):
   - Remove dev.done, dev.report, qa.done, qa.report
   - Re-spawn Dev with QA fix list injected into prompt
   - Re-spawn QA from scratch
7. **If QA = PASS**: Spawn Merge agent (`claude -p` with `.claude/agents/merge-agent.md`):
   - Verify CI checks pass
   - Verify no merge conflicts (rebase if needed)
   - Squash-merge PR
   - Delete remote branch
   - Write `merge.done`
8. **Spawn Prod-QA agent** (optional, only if PROD_URL exists in CLAUDE.md):
   - Wait for deployment to match merge commit SHA
   - Run production verification tests
   - Write `prod-qa.done` (PASS or FAIL)
   - If PASS: close GitHub issue
9. **Cleanup on success**: Remove worktree (`.worktrees/issue-<N>/`)
10. **On failure**: Preserve worktree, post detailed comment with suggested fix to GitHub issue, label issue `blocked`
11. **Capture learnings**: Write agent-learnings JSON entries for insights discovered during the pipeline
12. **Report**: Display final status in the Claude Code chat window

### Feature 4: Agent Prompts (5 agents)

**Description**: System prompts for each of the 5 independent agents, designed for `claude -p --system-prompt`.

#### Orchestrator Agent
- Reads: GitHub issue, CLAUDE.md, AGENTS.md, README.md, codebase structure
- Produces: Implementation plan with step-by-step tasks, each with VALIDATE commands
- Writes: `orchestrator.done`, `orchestrator.report`
- Posts: `[orchestrator]` comment on GitHub issue with the plan
- Key constraint: Does NOT implement code — only plans

#### Dev Agent
- Reads: `orchestrator.report` (plan), CLAUDE.md, AGENTS.md
- Produces: Code changes, tests, PR
- Writes: `dev.done` (DONE | STUCK), `dev.report` (files changed, tests run, PR link)
- Posts: `[dev]` comment on GitHub issue with implementation summary
- Key constraints: Stay in worktree. Minimal changes. 80/20 rule. If stuck, write STUCK to `dev.done`.
- On retry: Also reads `qa.report` for the fix list

#### QA Agent
- Reads: GitHub issue, PR diff, test suite, CLAUDE.md, AGENTS.md
- Produces: Requirements Coverage Matrix, E2E evidence, verdict
- Writes: `qa.done` (PASS | PASS-WITH-NITS | FAIL), `qa.report` (matrix, evidence, fix list if FAIL)
- Posts: `[qa]` comment on GitHub issue with verdict and evidence
- Key constraints: **NEVER modify source code.** Read-only. Must provide evidence for every criterion (file path + test command + result).

#### Merge Agent
- Reads: PR, CI status, `qa.done`, CLAUDE.md
- Produces: Merged PR, cleaned up branch
- Writes: `merge.done` (merge SHA or CI_FAILED | CONFLICT)
- Posts: `[merge]` comment on GitHub issue with merge confirmation
- Key constraints: Never merge unless `qa.done` contains PASS. Always squash-merge. Always delete branch after merge.

#### Prod-QA Agent
- Reads: Merged PR, CLAUDE.md (for PROD_URL), deployment status
- Produces: Production verification results
- Writes: `prod-qa.done` (PASS | FAIL)
- Posts: `[prod-qa]` comment on GitHub issue with production evidence
- Key constraints: Wait for deployment SHA to match merge commit. Only close the issue after production verification passes.

### Feature 5: AGENTS.md Template + Generation

**Description**: A project-level file (like CLAUDE.md) that defines agent-specific rules, worktree boundaries, and data safety constraints. Generated by `/init-project`.

**Contents**:
- Agent roles and responsibilities
- Worktree rules ("Stay inside the worktree. Do not edit files outside it.")
- Data safety ("Never print .env values. Never commit secrets.")
- Communication format ("Post GitHub comments with `[role]` prefix. Include full context.")
- Testing requirements per agent role
- Project-specific constraints (extracted from CLAUDE.md and PRD)

### Feature 6: Sentinel File System

**Description**: File-based coordination between agents. Each agent writes status and report files that subsequent agents read.

**Location**: `.worktrees/issue-<N>/.claude-workflow/`

**File Format**:
- `*.done` files: Single word status (e.g., `DONE`, `STUCK`, `PASS`, `FAIL`, `PASS-WITH-NITS`)
- `*.report` files: Structured markdown with full details

**Report Structure** (common format):
```markdown
# {Agent Role} Report — Issue #{N}

## Summary
{1-2 sentence summary of what was done}

## Actions Taken
{Numbered list of actions}

## Results
{Test results, coverage, evidence}

## Files Changed
{List of files modified/created/deleted}

## Follow-up Risks
{Any concerns for downstream agents}
```

### Feature 7: Worktree Lifecycle Management

**Description**: Automated creation, coordination, and cleanup of git worktrees.

**Creation** (by `/impl`):
```bash
git worktree add -b issue-<N> .worktrees/issue-<N> origin/main
```

**During pipeline**: All agents work exclusively within `.worktrees/issue-<N>/`

**Cleanup on success** (by Merge agent or `/impl`):
```bash
git worktree remove .worktrees/issue-<N>
git branch -d issue-<N>
```

**Preservation on failure**: Worktree is kept for manual inspection. A comment on the GitHub issue notes the worktree path.

---

## 8. Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Claude Code CLI | Latest | Primary AI interface — interactive sessions and `claude -p` for agents |
| GitHub CLI (`gh`) | Latest | Issue management, PR creation, CI status, comments |
| Git | 2.20+ | Version control, worktree management (`git worktree`) |
| Bash/Zsh | System | Shell for `claude -p` subprocess invocation |
| agent-browser | Latest | Browser automation for E2E testing (used by QA agent) |

---

## 9. Security & Configuration

### Authentication Approach

- GitHub CLI (`gh`) must be authenticated before any command runs
- Claude Code must be authenticated (API key)
- No additional auth — the system inherits the user's credentials

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `PROD_URL` | Production URL for Prod-QA verification (optional) | `https://myapp.vercel.app` |
| `AGENT_MAX_RETRIES` | Max Dev→QA retry loops (default: 3) | `3` |

### Security Measures

- **Secrets Protection**: `.env*` files are symlinked into worktrees (not copied). Agents are instructed never to print or commit secret values.
- **Worktree Isolation**: Each issue's code changes are confined to its worktree. Agents cannot modify files outside the worktree.
- **QA Read-Only**: QA agent system prompt explicitly forbids code modification.
- **PR-Based Merge**: All changes go through PRs. Direct pushes to `main` are never performed by agents.
- **AGENTS.md Constraints**: Project-specific safety rules are enforced via the AGENTS.md file read by every agent.

---

## 10. Data Model

### Sentinel Files (`.claude-workflow/`)

| File | Type | Values | Written By | Read By |
|------|------|--------|------------|---------|
| `orchestrator.done` | Status | `DONE` \| `STUCK` | Orchestrator | /impl |
| `orchestrator.report` | Markdown | Implementation plan | Orchestrator | Dev |
| `dev.done` | Status | `DONE` \| `STUCK` | Dev | /impl |
| `dev.report` | Markdown | Implementation summary | Dev | /impl |
| `qa.done` | Status | `PASS` \| `PASS-WITH-NITS` \| `FAIL` | QA | /impl |
| `qa.report` | Markdown | Coverage matrix + fix list | QA | Dev (on retry) |
| `merge.done` | Status | `<SHA>` \| `CI_FAILED` \| `CONFLICT` | Merge | /impl |
| `prod-qa.done` | Status | `PASS` \| `FAIL` | Prod-QA | /impl |

### Agent Learnings (`.claude/learnings/`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts_utc` | ISO 8601 string | Yes | Timestamp of discovery |
| `category` | Enum | Yes | `owner-preference` \| `decision-pattern` \| `architecture` \| `workflow` \| `anti-pattern` \| `technical-gotcha` |
| `text` | String (2-5 lines) | Yes | The insight |
| `issue` | String | No | GitHub issue reference |
| `pointers` | String[] | No | File paths or URLs for context |

### GitHub Issue Comments

Each agent posts comments with a consistent format:
```markdown
**[{role}]** — Issue #{N}

{Structured content specific to the agent's role}
```

---

## 11. API/Interface Specification

### Command: `/create-prd`

**Input**: `"project-name"` (string argument)

**Interactive**: Yes — multi-round Q&A with the user

**Output**:
- `PRD.md` written to project root
- GitHub Epic issue created (label: `type:epic`)
- GitHub Task issues created (label: `type:task`, one per implementation phase)

### Command: `/init-project`

**Input**: None (reads `PRD.md` from project root)

**Interactive**: Minimal (may ask about GitHub remote creation)

**Output**:
- Scaffolded project with dependencies installed
- `CLAUDE.md` generated
- `AGENTS.md` generated
- Git initialized with initial commit

### Command: `/impl`

**Input**: `#<issue-number>` (GitHub issue number)

**Interactive**: No — fully autonomous

**Output**:
- Merged PR (on success)
- GitHub issue comments (audit trail)
- Sentinel files in `.worktrees/issue-<N>/.claude-workflow/`
- Agent learnings in `.claude/learnings/`
- Cleaned up worktree (on success) or preserved worktree (on failure)

### `claude -p` Agent Invocation Format

```bash
claude -p "<task prompt with __TOKENS__ replaced>" \
  --system-prompt "$(cat .claude/agents/<agent-name>.md)" \
  -C "<worktree-path>"
```

**Placeholder Tokens**:
- `__ISSUE_NUM__` → GitHub issue number
- `__WORKTREE_PATH__` → Absolute path to the worktree
- `__REPO__` → GitHub repo in `owner/repo` format
- `__PROD_URL__` → Production URL (if available)
- `__QA_REPORT__` → Content of `qa.report` (for Dev retry)

---

## 12. Success Criteria

### Pass/Fail Conditions

- [ ] **Agent isolation**: Each of the 5 agents spawns as an independent `claude -p` process with a fresh context window — **Pass**: agent processes run independently / **Fail**: agents share context or run as sub-agents
- [ ] **Worktree isolation**: Each `/impl` call creates a separate git worktree — **Pass**: `.worktrees/issue-<N>/` is created with its own branch / **Fail**: changes happen on the main working tree
- [ ] **QA independence**: QA agent produces a verdict without having seen Dev's reasoning — **Pass**: QA's context contains only the PR diff, issue requirements, and test results / **Fail**: QA has access to Dev's chat history
- [ ] **QA read-only**: QA agent never modifies source code — **Pass**: no file writes in QA's report / **Fail**: QA modifies files
- [ ] **Retry loop**: When QA returns FAIL, Dev is re-spawned with the fix list and QA re-runs — **Pass**: sentinel files are cleared and agents re-run (up to 3x) / **Fail**: pipeline stops on first QA failure
- [ ] **Failure escalation**: After 3 failed QA cycles, pipeline halts and posts a detailed comment with suggested fix — **Pass**: GitHub issue has a structured `blocked` comment / **Fail**: pipeline loops indefinitely or exits silently
- [ ] **GitHub audit trail**: Every agent posts at least one structured comment on the GitHub issue — **Pass**: issue thread shows `[orchestrator]`, `[dev]`, `[qa]`, `[merge]` comments / **Fail**: no comments or missing agent roles
- [ ] **End-to-end**: Running `/create-prd` → `/init-project` → `/impl` on a test project results in a merged PR with QA evidence — **Pass**: PR is merged and issue has coverage matrix / **Fail**: pipeline does not complete
- [ ] **Parallel execution**: Two `/impl` calls on different issues in separate terminals run without conflicts — **Pass**: both complete independently / **Fail**: worktree or branch conflicts

### Quality Indicators

- Clarity score of generated PRDs: >= 90/100
- QA Requirements Coverage Matrix: every criterion has evidence
- Agent communication: every GitHub comment is self-contained and understandable without external context

---

## 13. Implementation Phases

### Phase 1: Agent Prompts + Templates

**Goal**: Create the 5 agent system prompts and the AGENTS-template.md — the foundation everything else builds on.

**Deliverables**:
- ✅ `.claude/agents/orchestrator.md` — Orchestrator agent system prompt
- ✅ `.claude/agents/dev-agent.md` — Dev agent system prompt
- ✅ `.claude/agents/qa-agent.md` — QA agent system prompt
- ✅ `.claude/agents/merge-agent.md` — Merge agent system prompt
- ✅ `.claude/agents/prod-qa-agent.md` — Prod-QA agent system prompt
- ✅ `.claude/templates/AGENTS-template.md` — Template for project-level AGENTS.md

**Acceptance Criteria**:
- [ ] Each agent prompt defines: role, inputs, outputs, constraints, communication format, sentinel file writes — **Pass**: all 6 sections present in each prompt / **Fail**: missing sections
- [ ] Each agent prompt includes placeholder tokens (`__ISSUE_NUM__`, `__WORKTREE_PATH__`, etc.) — **Pass**: tokens present and documented / **Fail**: hardcoded values
- [ ] QA agent prompt explicitly forbids code modification — **Pass**: "NEVER modify source code" rule present / **Fail**: no read-only constraint
- [ ] AGENTS-template.md includes sections for: roles, worktree rules, data safety, communication format — **Pass**: all sections present / **Fail**: missing sections

**Validation Commands**:
```bash
# Verify all agent files exist
ls -la .claude/agents/orchestrator.md .claude/agents/dev-agent.md .claude/agents/qa-agent.md .claude/agents/merge-agent.md .claude/agents/prod-qa-agent.md .claude/templates/AGENTS-template.md

# Verify placeholder tokens are present
grep -l "__ISSUE_NUM__" .claude/agents/*.md
grep -l "__WORKTREE_PATH__" .claude/agents/*.md

# Verify QA read-only constraint
grep -i "never modify" .claude/agents/qa-agent.md
```

---

### Phase 2: Core Commands — `/create-prd` + `/init-project`

**Goal**: Rebuild the two setup commands to work cohesively with the new multi-agent system.

**Deliverables**:
- ✅ `.claude/commands/create-prd.md` — Rebuilt PRD command (structured interrogation → PRD.md + GitHub Epic/Tasks)
- ✅ `.claude/commands/init-project.md` — Rebuilt init command (scaffold + CLAUDE.md + AGENTS.md + git)
- ✅ Updated `.claude/skills/requirements-clarity/SKILL.md` (if changes needed)
- ✅ Updated `.claude/skills/question-bank/SKILL.md` (if changes needed)
- ✅ Updated `.claude/templates/PRD-template.md` (if changes needed)
- ✅ Updated `.claude/templates/CLAUDE-template.md` (if changes needed)

**Acceptance Criteria**:
- [ ] `/create-prd` scores clarity, interrogates, and generates PRD with >= 90/100 score — **Pass**: PRD.md is generated with clarity score in footer / **Fail**: PRD generated below 90 or score not reported
- [ ] `/create-prd` creates GitHub Epic + Task issues — **Pass**: `gh issue list` shows epic and task issues / **Fail**: no issues created
- [ ] `/init-project` generates both CLAUDE.md and AGENTS.md — **Pass**: both files exist after running / **Fail**: either file missing
- [ ] `/init-project` validates the scaffold works (dev server, linter, tests, build) — **Pass**: all 4 checks pass / **Fail**: any check fails

**Validation Commands**:
```bash
# After /create-prd
test -f PRD.md && echo "PASS: PRD exists" || echo "FAIL: PRD missing"
gh issue list --label "type:epic" --json number,title

# After /init-project
test -f CLAUDE.md && echo "PASS: CLAUDE.md exists" || echo "FAIL"
test -f AGENTS.md && echo "PASS: AGENTS.md exists" || echo "FAIL"
```

---

### Phase 3: Pipeline Command — `/impl`

**Goal**: Build the master orchestrator command that creates worktrees and spawns the 5-agent pipeline.

**Deliverables**:
- ✅ `.claude/commands/impl.md` — The full `/impl` command with worktree management, agent spawning, retry loop, cleanup, and error handling
- ✅ Sentinel file coordination logic
- ✅ Placeholder token substitution
- ✅ Worktree lifecycle management (create, preserve on failure, clean on merge)
- ✅ GitHub issue comment posting at each stage
- ✅ Dev→QA retry loop (max 3)
- ✅ Failure escalation with suggested fix

**Acceptance Criteria**:
- [ ] `/impl #<N>` creates a worktree at `.worktrees/issue-<N>/` — **Pass**: directory exists with correct branch / **Fail**: no worktree created
- [ ] `/impl` spawns each agent as a separate `claude -p` process — **Pass**: each agent runs independently / **Fail**: agents run inline
- [ ] Sentinel files are written and read correctly — **Pass**: `.claude-workflow/` contains expected files after each stage / **Fail**: missing sentinel files
- [ ] QA FAIL triggers Dev re-spawn with fix list — **Pass**: dev runs again with QA report / **Fail**: pipeline stops on first failure
- [ ] After 3 failures, pipeline halts and posts to GitHub — **Pass**: issue has `blocked` comment / **Fail**: pipeline loops beyond 3 or exits silently
- [ ] On success, worktree is cleaned up — **Pass**: `.worktrees/issue-<N>/` removed after merge / **Fail**: worktree persists
- [ ] On failure, worktree is preserved — **Pass**: worktree exists for manual inspection / **Fail**: worktree deleted on failure

**Validation Commands**:
```bash
# Test worktree creation
git worktree list | grep "issue-"

# Test sentinel file creation (after a run)
ls .worktrees/issue-*/. claude-workflow/

# Test GitHub comments
gh issue view <N> --comments
```

---

### Phase 4: Integration Testing + Skill Updates

**Goal**: End-to-end test the complete pipeline on a sample project. Update skills as needed for agent compatibility.

**Deliverables**:
- ✅ Updated `.claude/skills/e2e-test/SKILL.md` (if changes needed for agent context)
- ✅ Updated `.claude/skills/agent-browser/SKILL.md` (if changes needed)
- ✅ Updated `.claude/skills/agent-learnings/SKILL.md` (if changes needed)
- ✅ End-to-end test: `/create-prd` → `/init-project` → `/impl` on a sample project
- ✅ Verify all 5 agents spawn, coordinate, and produce correct outputs
- ✅ Verify GitHub issue audit trail is complete
- ✅ Verify worktree isolation works
- ✅ Clean up old/removed command files (plan-feature.md, execute.md, verify.md, commit.md, ship.md, learnings.md, create-rules.md)

**Acceptance Criteria**:
- [ ] Complete pipeline runs end-to-end on a test project — **Pass**: PR is merged with QA evidence / **Fail**: pipeline fails at any stage
- [ ] GitHub issue thread shows comments from all 5 agent roles — **Pass**: `[orchestrator]`, `[dev]`, `[qa]`, `[merge]`, `[prod-qa]` all present / **Fail**: any role missing
- [ ] QA Requirements Coverage Matrix is present and complete — **Pass**: every acceptance criterion has a Met/Not Met status with evidence / **Fail**: missing criteria or evidence
- [ ] Old command files are removed — **Pass**: only `create-prd.md`, `init-project.md`, `impl.md` exist in `.claude/commands/` / **Fail**: stale files remain

**Validation Commands**:
```bash
# Verify only new commands exist
ls .claude/commands/
# Expected: create-prd.md  init-project.md  impl.md

# Verify agents directory
ls .claude/agents/
# Expected: orchestrator.md  dev-agent.md  qa-agent.md  merge-agent.md  prod-qa-agent.md

# End-to-end evidence
gh issue view <epic-N> --comments | head -100
```

---

## 14. Future Considerations

Post-MVP enhancements to consider:

1. **Single-session multi-issue management**: Run `/impl #42 #43 #44` from one terminal and have all three pipelines run in the background simultaneously.
2. **Automated learning promotion**: When the same learning appears across 3+ issues, automatically propose it as a CLAUDE.md update.
3. **Cost tracking dashboard**: Track token usage per agent per issue and report trends.
4. **Custom agent roles**: Allow users to define additional agent roles (e.g., Security Auditor, Performance Tester) via `.claude/agents/` convention.
5. **Worktree cleanup command**: `/impl --cleanup` to prune all merged/stale worktrees at once.
6. **Agent confidence scoring**: Each agent self-reports a confidence score. Low confidence triggers additional review.
7. **Cross-issue dependency awareness**: Detect when issues share file changes and warn about potential conflicts.

---

## 15. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `claude -p` subprocess hangs or crashes mid-pipeline | Medium | High | Configurable timeout per agent (default: 10 min via `timeout` command). On timeout, write STUCK to sentinel and escalate. |
| QA and Dev disagree in infinite loop | Low | High | Hard cap at 3 retries. After 3 failures, halt, preserve worktree, post detailed GitHub comment with suggested fix. |
| Worktree accumulation fills disk | Medium | Low | Document cleanup procedure. Future: `/impl --cleanup` command. |
| Merge conflicts with `main` when multiple worktrees merge concurrently | Medium | Medium | Merge agent rebases before merge. If conflicts, halt and post to GitHub issue for manual resolution. |
| Agent prompts are too long for `claude -p --system-prompt` | Low | High | Keep prompts concise. Use AGENTS.md (read by the agent at runtime) for project-specific details rather than embedding in system prompt. |
| Claude Code CLI changes `claude -p` behavior in future updates | Low | Medium | Document the exact CLI flags used. Test against new versions before upgrading. |

---

## 16. Appendix

### Key Dependencies

| Dependency | Version | Documentation |
|-----------|---------|---------------|
| Claude Code CLI | Latest | [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code) |
| GitHub CLI (`gh`) | 2.0+ | [GitHub CLI Manual](https://cli.github.com/manual/) |
| Git | 2.20+ | [Git Worktree Docs](https://git-scm.com/docs/git-worktree) |
| agent-browser | Latest | [agent-browser npm](https://www.npmjs.com/package/@anthropic-ai/agent-browser) |

### Reference Implementations

- `ai-coding-workflow-main/` — Original multi-agent workflow for Codex CLI. Provides the Orchestrator→Dev→QA→Merge pattern and the skill-based architecture.
- `Example_Claude2/` — Shell-orchestrated multi-agent pipeline for Claude Code. Provides the `claude -p` subprocess pattern, sentinel file coordination, and Zsh function architecture.
- `Example_Claude/` — Single-agent Claude Code workflow. Provides the plan-before-execute pattern, e2e-test skill with parallel sub-agents, and the CLAUDE-template structure.

### `claude -p` Usage Reference

```bash
# Basic agent invocation
claude -p "Your task prompt here" --system-prompt "System prompt content"

# With working directory
claude -p "..." --system-prompt "..." -C /path/to/worktree

# With timeout (via shell)
timeout 600 claude -p "..." --system-prompt "..."
```

### Sentinel File Quick Reference

| File | Written By | Values | Read By |
|------|------------|--------|---------|
| `orchestrator.done` | Orchestrator | DONE, STUCK | /impl |
| `orchestrator.report` | Orchestrator | Markdown plan | Dev |
| `dev.done` | Dev | DONE, STUCK | /impl |
| `dev.report` | Dev | Markdown summary | /impl |
| `qa.done` | QA | PASS, PASS-WITH-NITS, FAIL | /impl |
| `qa.report` | QA | Markdown matrix + fix list | Dev (retry) |
| `merge.done` | Merge | SHA, CI_FAILED, CONFLICT | /impl |
| `prod-qa.done` | Prod-QA | PASS, FAIL | /impl |

---

**Clarity Score**: 95/100
**Clarification Rounds**: 5
**Created**: 2026-02-27
**Document Version**: 1.0
