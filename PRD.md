# Universal Project Starter v2 — Product Requirements Document

## 1. Executive Summary

The Universal Project Starter is a portable `.claude/` + `scripts/` system that transforms Claude Code into an autonomous multi-agent development team. It takes a project from idea to shipped, merged PRs with minimal human intervention after the requirements phase.

v1 operated as a non-interactive pipeline — 5 agents ran as `claude -p` subprocesses that could not ask questions, could not request human help, and could not open headed browsers for the user to interact with. This led to hallucinated browser selectors, unverified assumptions treated as facts, and agents burning through retry cycles on problems a 10-second human interaction would have solved. The Niggsfield project (a Playwright automation tool) is the canonical failure case: all 118 unit tests passed, but every single browser selector was hallucinated because no agent ever opened a real browser or asked the user for credentials.

v2 replaces the non-interactive `claude -p` pipeline with **interactive Claude sessions running in tmux panes**, orchestrated by **bash scripts**. Each agent can ask questions, request human interaction (e.g., "please log in to this browser"), and the user can watch agent output in real-time and intervene when needed. The bash orchestrator handles tmux management, git worktree isolation, dependency resolution via a DAG parsed from GitHub issues, and pipeline coordination via sentinel files. The result: agents that are mostly autonomous but can call for help, running in parallel across unlimited worktrees with full visibility.

---

## 2. Mission & Core Principles

**Mission**: Build a universal, portable workflow system that turns Claude Code into a self-coordinating team of interactive AI engineers — from PRD to production-verified merge — where the human can see everything, help when needed, and trust the output.

### Core Principles

1. **Interactive When Needed, Autonomous By Default** — Agents run autonomously in tmux panes. They can ask questions when uncertain. The user can type into any pane at any time. Desktop notifications fire when an agent needs attention. The human is in the loop but not in the way.
2. **Prove Everything, Assume Nothing** — No feature ships without runtime proof. QA produces a Requirements Coverage Matrix with evidence for every criterion. Code with unverifiable assumptions is marked with `// ASSUMPTION:` comments and flagged in QA reports. The Niggsfield pattern (hallucinated selectors passing QA) is structurally impossible.
3. **Bash Orchestrates, Claude Works** — The pipeline coordination logic (tmux management, worktree creation, dependency resolution, retry loops, sentinel file monitoring) lives in deterministic bash scripts that cannot hallucinate. Claude sessions do the creative work (planning, coding, testing, reviewing).
4. **Parallel by Default** — Each issue gets its own tmux session, worktree, and branch. Run unlimited issues simultaneously. A DAG resolver ensures dependencies are respected. Worktree lock serialization prevents git race conditions.
5. **Clear & Plain English** — Every agent posts structured comments on GitHub issues. A human reading the issue thread should understand the full story without referencing terminals or log files.

---

## 3. Target Users

### Persona 1: Solo AI-Augmented Developer
- **Needs**: Run multiple GitHub issues through an autonomous pipeline while retaining the ability to help agents when they get stuck (browser logins, credential entry, ambiguous requirements)
- **Pain Points**: v1's `claude -p` agents couldn't ask questions — they hallucinated answers, burned retries, and merged code with unverified assumptions
- **Success Looks Like**: Runs `./scripts/impl.sh #42` → watches 5 tmux panes → gets a desktop notification "QA needs you to log in to Higgsfield" → logs in → watches QA verify real selectors → PR merges with full evidence

### Persona 2: Developer Managing Parallel Workstreams
- **Needs**: Run 5-10 issue pipelines simultaneously without conflicts, with dependency ordering handled automatically
- **Pain Points**: Manual dependency tracking, worktree management, switching between terminals to check status
- **Success Looks Like**: Runs `./scripts/run-all.sh` → DAG resolver starts 3 unblocked issues in parallel tmux sessions → as each completes and merges, dependent issues auto-start → GitHub issue labels show real-time pipeline state

### Persona 3: Developer Who Needs Portable Workflows
- **Needs**: Drop a folder into any project and have a working multi-agent pipeline
- **Pain Points**: Workflow systems that require global installs, specific project types, or manual configuration
- **Success Looks Like**: Copies `.claude/` and `scripts/` into a new repo → runs `./scripts/setup.sh` → system is ready

---

## 4. MVP Scope

### In Scope

| Category | Feature | Status |
|----------|---------|--------|
| Scripts | `impl.sh` — bash pipeline orchestrator with tmux, worktrees, sentinel monitoring | ✅ MVP |
| Scripts | `setup.sh` — doctor/setup script verifying all prerequisites | ✅ MVP |
| Scripts | `run-all.sh` — batch runner with DAG dependency resolution | ✅ MVP |
| Scripts | `status.sh` — quick status check of all running pipelines | ✅ MVP |
| Scripts | `lib/` — shared bash functions (tmux, worktree, sentinel, lock, notify, config) | ✅ MVP |
| Commands | `/create-prd` — stays as Claude Code slash command (updated for DAG deps + labels) | ✅ MVP |
| Commands | `/init-project` — stays as Claude Code slash command (updated for scripts/ generation) | ✅ MVP |
| Agents | 5 agent prompts rewritten for interactive mode (Orchestrator, Dev, QA, Merge, Prod-QA) | ✅ MVP |
| Config | `.claude/workflow.yaml` — pipeline configuration file | ✅ MVP |
| Infrastructure | Git worktree isolation with symlink auto-detection | ✅ MVP |
| Infrastructure | Worktree lock serialization for parallel git operations | ✅ MVP |
| Infrastructure | Sentinel file coordination (same protocol, bash-driven) | ✅ MVP |
| Infrastructure | tmux session-per-issue, pane-per-agent layout | ✅ MVP |
| Infrastructure | Desktop notifications (osascript) for human-required actions | ✅ MVP |
| Infrastructure | All agent output logged to files via tmux pipe-pane | ✅ MVP |
| Infrastructure | Pipeline resume from any stage (`--from` flag) | ✅ MVP |
| Quality | ASSUMPTION markers in code + QA flagging | ✅ MVP |
| Quality | QA Requirements Coverage Matrix with runtime proof | ✅ MVP |
| Quality | Orchestrator final sanity check after QA | ✅ MVP |
| Quality | Mandatory codebase reuse scan before implementing | ✅ MVP |
| Quality | Planning-execution separation with VALIDATE commands | ✅ MVP |
| GitHub | Structured agent comments with `[role]` prefix | ✅ MVP |
| GitHub | EPIC/TASK with "solved = executed" rule | ✅ MVP |
| GitHub | Auto-label issues by pipeline state | ✅ MVP |
| GitHub | DAG dependency resolution from `Depends on: #N` | ✅ MVP |
| GitHub | Auto-close on prod-QA pass | ✅ MVP |
| Browser | Pre-login phase + ad-hoc headed browser interaction | ✅ MVP |
| Browser | Shared browser-data/ symlinked into worktrees | ✅ MVP |
| Persistence | Agent learnings JSON capture | ✅ MVP |
| Persistence | Terminal title updates per pipeline stage | ✅ MVP |

### Out of Scope

| Category | Feature | Reason |
|----------|---------|--------|
| Dashboard | Pipeline status dashboard tmux pane | ❌ Phase 2 — tmux session names + terminal titles sufficient for MVP |
| Visualization | Mermaid dependency graph in EPIC issue | ❌ Phase 2 — DAG resolver works without visual graph |
| E2E Research | 3 parallel research sub-agents before E2E testing | ❌ Phase 2 — QA does single-pass research for MVP |
| Rollback | Auto-revert on prod-QA failure | ❌ Phase 2 — too dangerous without battle-testing; manual revert for MVP |
| Budget | Per-agent budget caps (`--max-budget-usd`) | ❌ Not applicable — interactive sessions don't support this flag |
| Phone | Phone monitoring via WebSocket | ❌ Phase 2 — desktop notifications sufficient for MVP |
| Multi-OS | Linux/Windows support | ❌ macOS only for MVP |
| GUI | Electron desktop application | ❌ Out of scope — bash + tmux is the UI |

---

## 5. User Stories

1. **As a** developer, **I want to** run `./scripts/impl.sh #42` and see 5 agents work in tmux panes where I can interact with any of them, **so that** agents can ask me questions instead of hallucinating answers.
   - _Example_: Dev agent opens a headed browser for E2E testing, realizes the page requires authentication, and types in the tmux pane: "I need to log in to Higgsfield to verify selectors. Please log in at the browser window and press Enter when ready." A desktop notification fires. You switch to the tmux pane, log in in the browser, press Enter. Dev continues with verified selectors.

2. **As a** developer, **I want to** run `./scripts/run-all.sh` and have the DAG resolver start unblocked issues in parallel while holding back issues with unmet dependencies, **so that** I don't need to manually track which issue can start when.
   - _Example_: Issue #3 depends on #2. Issue #4 has no dependencies. `run-all.sh` starts #2 and #4 in parallel. When #2 merges, the resolver automatically starts #3 in a new tmux session.

3. **As a** developer, **I want** QA to produce a Requirements Coverage Matrix where every criterion has runtime proof (not just "looks correct"), **so that** hallucinated implementations are caught before merge.
   - _Example_: QA reports: "AC3: Browser navigates to /create → Status: NOT MET → Evidence: `page.goto('/create')` returns 404. Actual URL is `/image/nano_banana_2`. Dev must update SELECTORS.CREATE_URL." This would have caught the Niggsfield failure.

4. **As a** developer, **I want** Dev to mark unverifiable code with `// ASSUMPTION:` comments and QA to flag them as "Unverified" in the coverage matrix, **so that** I know exactly what hasn't been proven.
   - _Example_: Dev writes `// ASSUMPTION: Higgsfield uses standard file input for image upload` in `automation/higgsfield.ts`. QA's matrix shows: "Assumption: file input upload → UNVERIFIED — requires live browser test with real session."

5. **As a** developer, **I want to** resume a failed pipeline from the exact stage it failed at with `./scripts/impl.sh #42 --from qa`, **so that** I don't re-run orchestrator and dev when only QA needs a retry.
   - _Example_: QA failed because the test database wasn't seeded. You seed it manually, then run `./scripts/impl.sh #42 --from qa`. QA re-runs in its tmux pane with the existing worktree and dev output.

6. **As a** developer, **I want** the system to work with any tech stack by dropping `.claude/` and `scripts/` into any repo, **so that** I can use it on a Next.js app, a Python CLI, a Rust library, or anything else.
   - _Example_: Copy `.claude/` and `scripts/` into a fresh Django project. Run `./scripts/setup.sh`. It detects missing dependencies, verifies `claude`, `gh`, `git`, `tmux` are available, and reports readiness.

7. **As a** developer, **I want** every agent to post structured comments on the GitHub issue, **so that** I have a complete audit trail without reading terminal output.
   - _Example_: Issue #42 shows: `[orchestrator]` — plan with 5 tasks, `[dev]` — 12 files changed + PR #57 link, `[qa]` — coverage matrix with all criteria MET + runtime evidence, `[merge]` — squash-merged as SHA abc123.

8. **As a** developer, **I want** agents to capture institutional knowledge as JSON learnings when they discover patterns, preferences, or gotchas, **so that** future issues benefit from past experience.
   - _Example_: Dev discovers that the project uses `zod` for all validation. It writes a learning: `{"category": "architecture", "text": "This project uses zod for all schema validation. Do not use joi, yup, or manual validation."}`. Future Dev agents read this and follow the convention.

---

## 6. Core Architecture & Patterns

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         USER LAYER                                │
│                                                                   │
│  Terminal 1: claude → /create-prd "my idea"   (interactive)       │
│  Terminal 1: claude → /init-project            (interactive)      │
│                                                                   │
│  Terminal 2: ./scripts/impl.sh #42             (launches tmux)    │
│  Terminal 3: ./scripts/impl.sh #43             (launches tmux)    │
│  Terminal 4: ./scripts/run-all.sh              (DAG resolver)     │
│  Terminal 5: ./scripts/status.sh               (quick check)      │
└───────────────────┬──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────────┐
│              BASH ORCHESTRATION LAYER                              │
│                                                                   │
│  scripts/                                                         │
│  ├── impl.sh              # Single-issue pipeline orchestrator    │
│  ├── run-all.sh           # Multi-issue DAG resolver + launcher   │
│  ├── setup.sh             # Doctor/prerequisite checker           │
│  ├── status.sh            # Pipeline status reporter              │
│  └── lib/                 # Shared bash functions                 │
│      ├── tmux.sh          # Session/pane creation, send-keys      │
│      ├── worktree.sh      # Create, symlink, cleanup worktrees    │
│      ├── sentinel.sh      # Read/write/poll sentinel files        │
│      ├── lock.sh          # Git operation serialization           │
│      ├── notify.sh        # macOS desktop notifications           │
│      ├── config.sh        # YAML config parser                    │
│      ├── dag.sh           # Dependency graph resolution           │
│      ├── github.sh        # Issue/PR/comment helpers              │
│      └── log.sh           # Logging + terminal title utilities    │
└───────────────────┬──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────────┐
│              TMUX LAYER (one session per issue)                    │
│                                                                   │
│  tmux session: issue-42                                           │
│  ┌─────────────┬─────────────┬─────────────┐                     │
│  │ orchestrator│    dev      │     qa      │                     │
│  │   (pane 0)  │  (pane 1)  │  (pane 2)   │                     │
│  │ Interactive │ Interactive │ Interactive  │                     │
│  │   claude    │   claude   │   claude     │                     │
│  ├─────────────┼─────────────┤             │                     │
│  │   merge     │  prod-qa    │             │                     │
│  │  (pane 3)   │  (pane 4)  │             │                     │
│  └─────────────┴─────────────┴─────────────┘                     │
│                                                                   │
│  Communication:                                                   │
│  ├── Sentinel files: .worktrees/issue-42/.claude-workflow/        │
│  ├── GitHub issue comments: [role] structured posts               │
│  ├── CLAUDE.md per worktree: agent-specific role instructions     │
│  └── tmux pipe-pane: all output logged to .claude-workflow/logs/  │
└──────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
project-root/
├── .claude/
│   ├── commands/              # Claude Code slash commands (user-facing)
│   │   ├── create-prd.md      # PRD creation (interactive, stays as slash command)
│   │   └── init-project.md    # Project scaffolding (stays as slash command)
│   ├── agents/                # 5 agent role definitions
│   │   ├── orchestrator.md    # Planning agent instructions
│   │   ├── dev-agent.md       # Implementation agent instructions
│   │   ├── qa-agent.md        # Verification agent instructions
│   │   ├── merge-agent.md     # Merge/CI agent instructions
│   │   └── prod-qa-agent.md   # Production verification agent instructions
│   ├── skills/                # Reusable capabilities (consumed by agents)
│   │   ├── agent-browser/SKILL.md
│   │   ├── agent-learnings/SKILL.md
│   │   ├── e2e-test/SKILL.md
│   │   ├── question-bank/SKILL.md
│   │   └── requirements-clarity/SKILL.md
│   ├── templates/             # Document templates
│   │   ├── CLAUDE-template.md
│   │   ├── AGENTS-template.md
│   │   ├── PRD-template.md
│   │   └── plan-template.md
│   ├── workflow.yaml          # Pipeline configuration
│   ├── learnings/             # Agent learnings JSON files
│   └── plans/                 # Implementation plans
├── scripts/
│   ├── impl.sh                # Single-issue pipeline orchestrator
│   ├── run-all.sh             # Multi-issue DAG runner
│   ├── setup.sh               # Doctor/prerequisite checker
│   ├── status.sh              # Pipeline status reporter
│   └── lib/                   # Shared bash library
│       ├── tmux.sh
│       ├── worktree.sh
│       ├── sentinel.sh
│       ├── lock.sh
│       ├── notify.sh
│       ├── config.sh
│       ├── dag.sh
│       ├── github.sh
│       └── log.sh
├── browser-data/              # Shared persistent browser sessions
├── .worktrees/                # Git worktrees (one per issue)
│   └── issue-42/
│       ├── .claude-workflow/  # Sentinel files + logs
│       │   ├── orchestrator.done
│       │   ├── orchestrator.report
│       │   ├── dev.done
│       │   ├── dev.report
│       │   ├── qa.done
│       │   ├── qa.report
│       │   ├── merge.done
│       │   ├── prod-qa.done
│       │   └── logs/
│       │       ├── orchestrator.log
│       │       ├── dev.log
│       │       ├── qa.log
│       │       ├── merge.log
│       │       └── prod-qa.log
│       └── CLAUDE.md          # Agent-specific CLAUDE.md (generated per stage)
└── PRD.md
```

### Design Patterns

- **Bash Orchestration**: All pipeline coordination (tmux, worktrees, retries, dependency resolution) lives in deterministic bash scripts. No AI makes routing decisions — the bash script reads sentinel files and follows a fixed control flow.
- **Interactive Agent Sessions**: Each agent runs as `claude --dangerously-skip-permissions` (interactive mode with auto-approved tool use) in a tmux pane. The `--dangerously-skip-permissions` flag ensures agents are not blocked waiting for permission approvals, since the user can monitor and intervene via the tmux pane directly. Agents can ask questions, request human interaction, and the user can type into any pane. This eliminates the "hallucinate instead of ask" failure mode.
- **CLAUDE.md Injection**: Before each agent stage, the bash script generates a stage-specific `CLAUDE.md` in the worktree containing the agent's role instructions (from `.claude/agents/*.md`), project context, and task-specific details. Claude Code auto-reads this file.
- **Sentinel File Coordination**: Same protocol as v1 — agents write `.done` and `.report` files. The bash monitor loop polls these to detect stage completion and advance the pipeline.
- **Worktree Isolation**: Each issue gets its own git worktree with symlinked shared resources (`.claude/`, `node_modules/`, `.env`, `browser-data/`).
- **Lock Serialization**: A repo-level lock file serializes concurrent git push/merge/rebase operations across parallel pipelines, preventing race conditions.
- **DAG Resolution**: The `run-all.sh` script parses `Depends on: #N` from GitHub issue bodies, builds a dependency graph, and starts issues only when their dependencies are closed.

---

## 7. Features

### Feature 1: `impl.sh` — Single-Issue Pipeline Orchestrator

**Description**: The core bash script. Takes a GitHub issue number, creates a worktree, launches a tmux session, and drives 5 agent stages to completion.

**Entry Point**: `./scripts/impl.sh #42` or `./scripts/impl.sh #42 --from qa`

**Data Flow**:
1. **Parse arguments**: Issue number, optional `--from` stage for resume
2. **Preflight checks**: Verify `claude`, `gh`, `git`, `tmux` are available and authenticated. Verify CLAUDE.md or AGENTS.md exists. Verify issue exists and is open.
3. **Worktree setup** (skip if `--from` and worktree exists):
   - `git worktree add -b issue-<N> .worktrees/issue-<N> origin/main`
   - Auto-detect and symlink: `.claude/`, `node_modules/`, `.env*`, `browser-data/`, other gitignored directories
   - Create `.claude-workflow/` and `.claude-workflow/logs/` directories
4. **Tmux session creation**:
   - Create session `issue-<N>` with 5 panes (or fewer if resuming)
   - Set pane titles: `ORCH #N`, `DEV #N`, `QA #N`, `MERGE #N`, `PROD-QA #N`
   - Enable `tmux pipe-pane` on each pane for output logging
5. **For each stage** (Orchestrator → Dev → QA → Merge → Prod-QA):
   a. Generate stage-specific `CLAUDE.md` in worktree (merge agent prompt + project CLAUDE.md + task context)
   b. Launch `claude --dangerously-skip-permissions` in the stage's tmux pane via `tmux send-keys` (auto-approves tool use so agents don't block on permissions)
   c. Send initial task prompt via `tmux send-keys` (with the issue details, plan reference, etc.)
   d. Enter monitor loop: poll sentinel file every 3 seconds
   e. On sentinel detected: read result, decide next action
6. **QA retry loop** (if QA writes FAIL):
   - Increment retry counter (max from `workflow.yaml`, default 3)
   - Clear dev and qa sentinel files
   - Re-generate Dev CLAUDE.md with QA report injected
   - Re-run Dev → QA cycle in existing tmux panes
7. **Post-pipeline**:
   - Label issue with final state
   - Capture agent learnings
   - On success: clean up worktree and branch
   - On failure: preserve worktree, post detailed comment to GitHub issue
   - Send desktop notification with result

### Feature 2: `run-all.sh` — Multi-Issue DAG Runner

**Description**: Reads all open task issues from the GitHub Epic, builds a dependency DAG, and launches `impl.sh` for each issue in dependency order.

**Entry Point**: `./scripts/run-all.sh` or `./scripts/run-all.sh --epic #1`

**Data Flow**:
1. Find the Epic issue (by `type:epic` label or explicit `--epic` flag)
2. List all open task issues linked to the Epic
3. For each issue, parse `Depends on: #N` from the issue body
4. Build dependency DAG
5. Identify all issues with no unmet dependencies (ready to start)
6. For each ready issue: launch `./scripts/impl.sh #N` in background
7. Enter monitor loop:
   - Poll for completed pipelines (check for merged PRs or closed issues)
   - When an issue completes: re-evaluate DAG, start newly unblocked issues
   - Continue until all issues are complete or all remaining are blocked
8. Report final status

### Feature 3: `setup.sh` — Doctor/Prerequisite Checker

**Description**: Verifies all tools, authentication, and configuration are ready.

**Entry Point**: `./scripts/setup.sh`

**Checks**:
- `claude` CLI exists and is authenticated
- `gh` CLI exists and is authenticated
- `git` version >= 2.20 (worktree support)
- `tmux` is installed
- `jq` is installed (for JSON parsing)
- `yq` is installed (for YAML parsing) — or fallback to basic parsing
- `.claude/workflow.yaml` exists and is valid
- `.claude/agents/*.md` files exist (all 5)
- macOS version supports `osascript`
- Optionally: `playwright` / `agent-browser` for E2E projects

### Feature 4: `status.sh` — Pipeline Status Reporter

**Description**: Quick snapshot of all running and completed pipelines.

**Entry Point**: `./scripts/status.sh`

**Output**: Table showing for each active issue: issue number, current stage, status (running/waiting/stuck), elapsed time, last sentinel file written. Reads from tmux sessions and sentinel files.

### Feature 5: Revised Agent Prompts (5 agents)

**Description**: All 5 agent prompts rewritten for interactive mode. Key changes from v1:
- Remove all references to `claude -p` behavior
- Add explicit instructions for asking questions when uncertain
- Add instructions for requesting headed browser interaction
- Add ASSUMPTION marker requirements (Dev)
- Add runtime proof requirements (QA)
- Add mandatory codebase reuse scan (Dev)
- Add VALIDATE command requirements for each plan task (Orchestrator)
- Add final sanity check instructions (Orchestrator post-QA)

#### Orchestrator Agent (Revised)
- **Reads**: GitHub issue, CLAUDE.md, AGENTS.md, codebase structure
- **Produces**: Implementation plan where each task has: description, files to modify, actions, VALIDATE command
- **New**: If requirements are ambiguous, ASK the user in the tmux pane instead of guessing
- **New**: Mandatory codebase reuse scan — list existing patterns/utilities/helpers to reuse with file paths
- **New**: After QA PASS, do a final sanity check confirming every acceptance criterion has runtime proof in QA's report

#### Dev Agent (Revised)
- **Reads**: `orchestrator.report`, CLAUDE.md, AGENTS.md, codebase
- **Produces**: Code changes, tests, PR
- **New**: Mark unverifiable code with `// ASSUMPTION: <description>` comments
- **New**: When hitting an obstacle requiring human help (auth, credentials, unclear spec), ASK in the tmux pane and wait
- **New**: For browser automation: open headed browser, pause for user login if needed, then verify selectors against real DOM
- **New**: Run each VALIDATE command from the plan immediately after implementing that task

#### QA Agent (Revised)
- **Reads**: GitHub issue, PR diff, test suite, `dev.report`
- **Produces**: Requirements Coverage Matrix with runtime proof
- **New**: For every acceptance criterion: Status (Met/Not Met/Unverified), static evidence (file:line), AND runtime evidence (exact command + output)
- **New**: Flag every `// ASSUMPTION:` in code as "Unverified" in the matrix
- **New**: Cannot write PASS if any critical criterion is "Unverified" — must flag as PASS-WITH-NITS or FAIL
- **Still read-only**: NEVER modifies source code

#### Merge Agent (Revised)
- Same as v1 with minor updates for interactive mode
- Can ask user to resolve merge conflicts instead of auto-failing

#### Prod-QA Agent (Revised)
- Same as v1 with interactive browser support
- Can open headed browser for production verification
- Can ask user to verify something visually

### Feature 6: CLAUDE.md-Per-Worktree Generation

**Description**: Before each agent stage, the bash script generates a customized `CLAUDE.md` in the worktree that contains:
1. The project's base `CLAUDE.md` content (if it exists)
2. The agent's role instructions (from `.claude/agents/<role>.md`)
3. Task-specific context (issue number, worktree path, repo, stage)
4. References to relevant sentinel files from previous stages
5. The project's `AGENTS.md` content (appended)

This replaces v1's `--system-prompt` flag approach. Claude Code automatically reads `CLAUDE.md` from the working directory. The only CLI flag needed is `--dangerously-skip-permissions` to ensure agents don't block on permission prompts.

### Feature 7: Workflow Configuration (`workflow.yaml`)

**Description**: Central configuration file for pipeline behavior.

**Location**: `.claude/workflow.yaml`

**Schema**:
```yaml
pipeline:
  stages:
    - orchestrator
    - dev
    - qa
    - merge
    - prod-qa
  max_retries: 3          # Dev→QA retry limit
  max_turns_per_agent: 200 # Safety cap per agent

tmux:
  layout: tiled            # tmux layout for panes
  pane_titles: true        # Show stage name in pane titles

notifications:
  enabled: true
  sound: true              # macOS notification sound

worktree:
  symlink_candidates:      # Directories to auto-symlink into worktrees
    - .claude
    - node_modules
    - .env
    - .env.local
    - browser-data
  lock_timeout: 60         # Seconds to wait for git lock

github:
  labels:
    planning: "status:planning"
    dev: "status:dev"
    qa: "status:qa"
    merging: "status:merging"
    prod_qa: "status:prod-qa"
    blocked: "status:blocked"
    needs_human: "needs-human-action"

prod_url: ""               # Production URL for Prod-QA (empty = skip Prod-QA)
```

### Feature 8: Worktree Lock Serialization

**Description**: Prevents race conditions when multiple parallel pipelines perform git operations (push, merge, rebase) simultaneously.

**Mechanism**: Before any git operation that modifies the remote (push, merge), acquire a lock file at `.git/workflow.lock`. If the lock is held, wait up to `lock_timeout` seconds (default 60) with a retry loop. Release the lock after the operation completes.

**Implementation**: `scripts/lib/lock.sh` provides `acquire_lock()` and `release_lock()` functions with PID-based stale lock detection.

### Feature 9: Desktop Notifications

**Description**: macOS desktop notifications via `osascript` when agents need human attention.

**Triggers**:
- Agent asks a question in the tmux pane (detected by sentinel file: `NEEDS_HUMAN`)
- Agent completes a stage
- Pipeline fails
- Pipeline completes successfully

**Format**: "Issue #42 — [QA] needs your attention: Please log in to the browser window"

### Feature 10: Browser Interaction Model

**Description**: Two-phase browser interaction.

**Phase 1 — Pre-login** (manual, before pipeline):
- User runs `./scripts/login.sh <service-name>` which opens a headed Chromium browser with persistent context stored in `browser-data/`
- User logs into required services
- Browser closes, session is saved

**Phase 2 — Agent interaction** (during pipeline):
- Dev/QA agents can open headed browsers using the shared `browser-data/` session
- If the session is expired or a new service needs auth, the agent:
  1. Opens a headed browser window
  2. Writes `NEEDS_HUMAN` sentinel with a message: "Please log in to [service] at the browser window"
  3. The bash monitor detects this, fires a desktop notification
  4. User logs in, returns to tmux pane, presses Enter
  5. Agent continues

---

## 8. Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Claude Code CLI | Latest | Interactive AI sessions in tmux panes |
| GitHub CLI (`gh`) | Latest | Issue/PR management, comments, labels |
| Git | 2.20+ | Worktree management, version control |
| tmux | 3.0+ | Terminal multiplexing, session/pane management |
| Bash/Zsh | macOS default | Orchestration scripts |
| jq | Latest | JSON parsing (sentinel files, agent learnings, GitHub API responses) |
| yq | Latest | YAML parsing (workflow.yaml configuration) |
| osascript | macOS built-in | Desktop notifications |
| Playwright | Latest | Browser automation (when project requires E2E) |
| agent-browser | Latest | Browser automation CLI (optional, for advanced E2E) |

---

## 9. Security & Configuration

### Authentication Approach

- GitHub CLI (`gh`) must be authenticated — verified by `setup.sh`
- Claude Code must be authenticated (API key) — verified by `setup.sh`
- No additional auth — the system inherits the user's credentials
- Browser sessions stored in `browser-data/` with persistent cookies

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `PROD_URL` | Production URL for Prod-QA (overrides workflow.yaml) | `https://myapp.vercel.app` |
| `WORKFLOW_CONFIG` | Override path to workflow.yaml | `.claude/workflow.yaml` |

### Security Measures

- **Secrets Protection**: `.env*` files are symlinked into worktrees (not copied). `browser-data/` is gitignored. Agents are instructed never to print or commit secret values.
- **Worktree Isolation**: Each issue's code changes are confined to its worktree.
- **QA Read-Only**: QA agent instructions explicitly forbid code modification.
- **Lock Serialization**: Git lock prevents concurrent push/merge corruption.
- **PR-Based Merge**: All changes go through PRs. Direct pushes to `main` are never performed.
- **Stale Lock Detection**: Lock files include PID — stale locks from crashed processes are auto-cleaned.

---

## 10. Manual Prerequisites

### External Service Access

| Service | What's Needed | When |
|---------|--------------|------|
| Claude Code | Authenticated CLI (`claude` command works) | Before any pipeline run |
| GitHub CLI | Authenticated (`gh auth status` passes) | Before any pipeline run |
| tmux | Installed via Homebrew (`brew install tmux`) | Before first run |
| jq | Installed via Homebrew (`brew install jq`) | Before first run |
| yq | Installed via Homebrew (`brew install yq`) | Before first run |

### Manual Setup Steps

1. Run `./scripts/setup.sh` to verify all prerequisites
2. If using browser automation: run `./scripts/login.sh <service>` to pre-login to required services

### Assets to Provide

| Asset | Location | Format | Purpose |
|-------|----------|--------|---------|
| Browser login sessions | `browser-data/` | Chrome profile | Pre-authenticated browser sessions for E2E agents |
| Project-specific reference files | Varies | Varies | Any files the project needs that can't be auto-generated |

---

## 11. Data Model

### Sentinel Files (`.claude-workflow/`)

| File | Type | Values | Written By | Read By |
|------|------|--------|------------|---------|
| `orchestrator.done` | Status | `DONE` \| `STUCK` \| `NEEDS_HUMAN` | Orchestrator | impl.sh |
| `orchestrator.report` | Markdown | Implementation plan with VALIDATE commands | Orchestrator | Dev (via CLAUDE.md) |
| `dev.done` | Status | `DONE` \| `STUCK` \| `NEEDS_HUMAN` | Dev | impl.sh |
| `dev.report` | Markdown | Implementation summary with ASSUMPTION list | Dev | impl.sh |
| `qa.done` | Status | `PASS` \| `PASS-WITH-NITS` \| `FAIL` \| `NEEDS_HUMAN` | QA | impl.sh |
| `qa.report` | Markdown | Requirements Coverage Matrix + fix list | QA | Dev (on retry via CLAUDE.md) |
| `merge.done` | Status | `<SHA>` \| `CI_FAILED` \| `CONFLICT` \| `NEEDS_HUMAN` | Merge | impl.sh |
| `prod-qa.done` | Status | `PASS` \| `FAIL` \| `DEPLOY_TIMEOUT` \| `NEEDS_HUMAN` | Prod-QA | impl.sh |

All sentinel files now support `NEEDS_HUMAN` — when detected, the bash orchestrator fires a desktop notification and waits for the agent to write a final status.

### Agent Log Files (`.claude-workflow/logs/`)

| File | Source | Purpose |
|------|--------|---------|
| `orchestrator.log` | tmux pipe-pane | Full terminal output for post-mortem |
| `dev.log` | tmux pipe-pane | Full terminal output for post-mortem |
| `qa.log` | tmux pipe-pane | Full terminal output for post-mortem |
| `merge.log` | tmux pipe-pane | Full terminal output for post-mortem |
| `prod-qa.log` | tmux pipe-pane | Full terminal output for post-mortem |

### Agent Learnings (`.claude/learnings/`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts_utc` | ISO 8601 string | Yes | Timestamp of discovery |
| `category` | Enum | Yes | `owner-preference` \| `decision-pattern` \| `architecture` \| `workflow` \| `anti-pattern` \| `technical-gotcha` |
| `text` | String (2-5 lines) | Yes | The insight |
| `issue` | String | No | GitHub issue reference |
| `pointers` | String[] | No | File paths or URLs for context |

### Workflow Configuration (`.claude/workflow.yaml`)

See Feature 7 for full schema.

### GitHub Issue Labels

| Label | Meaning | Applied When |
|-------|---------|-------------|
| `type:epic` | Epic parent issue | Created by `/create-prd` |
| `type:task` | Implementation task | Created by `/create-prd` |
| `status:planning` | Orchestrator is working | Orchestrator stage starts |
| `status:dev` | Dev is implementing | Dev stage starts |
| `status:qa` | QA is verifying | QA stage starts |
| `status:merging` | Merge in progress | Merge stage starts |
| `status:prod-qa` | Production verification | Prod-QA stage starts |
| `status:blocked` | Pipeline failed, needs human | Terminal failure |
| `needs-human-action` | Agent needs human input | `NEEDS_HUMAN` sentinel detected |

---

## 12. API/Interface Specification

### Script: `impl.sh`

**Usage**:
```bash
./scripts/impl.sh <issue-number> [options]
```

**Arguments**:
| Argument | Required | Description |
|----------|----------|-------------|
| `<issue-number>` | Yes | GitHub issue number (with or without `#`) |

**Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--from <stage>` | Resume from a specific stage | Start from orchestrator |
| `--config <path>` | Override workflow.yaml path | `.claude/workflow.yaml` |
| `--dry-run` | Show what would happen without executing | Off |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Pipeline completed successfully |
| 1 | Pipeline failed (worktree preserved) |
| 2 | Preflight check failed |
| 3 | User interrupted (Ctrl+C) |

### Script: `run-all.sh`

**Usage**:
```bash
./scripts/run-all.sh [options]
```

**Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--epic <number>` | GitHub Epic issue number | Auto-detect from `type:epic` label |
| `--max-parallel <N>` | Maximum concurrent pipelines | Unlimited |
| `--config <path>` | Override workflow.yaml path | `.claude/workflow.yaml` |

### Script: `setup.sh`

**Usage**:
```bash
./scripts/setup.sh
```

**Output**: PASS/FAIL for each prerequisite check. Exit code 0 if all pass, 1 if any fail.

### Script: `status.sh`

**Usage**:
```bash
./scripts/status.sh
```

**Output**: Table of all running pipelines with issue number, stage, status, elapsed time.

### Script: `login.sh`

**Usage**:
```bash
./scripts/login.sh [service-name]
```

**Behavior**: Opens a headed Chromium browser with persistent context at `browser-data/`. User logs in. Browser closes on user exit. Session is saved.

### Agent CLAUDE.md Injection Format

Before each stage, `impl.sh` generates a `CLAUDE.md` in the worktree, then launches the agent:

**Launch command** (sent via `tmux send-keys`):
```bash
claude --dangerously-skip-permissions
```

**Generated CLAUDE.md contents**:
```markdown
# Project Context
{Content from project's actual CLAUDE.md, if it exists}

# Your Role
{Content from .claude/agents/<stage>.md}

# Task Context
- Issue: #<N>
- Worktree: <absolute-path>
- Repository: <owner/repo>
- Stage: <orchestrator|dev|qa|merge|prod-qa>
- Retry: <N of max> (if applicable)

# Previous Stage Output
{Content from previous stage's .report file}

# Agent Rules
{Content from AGENTS.md, if it exists}
```

The `--dangerously-skip-permissions` flag auto-approves all tool calls (file edits, bash commands, etc.) so agents never block waiting for permission. Since agents run in visible tmux panes, the user provides oversight by watching and intervening directly rather than through permission prompts.

---

## 13. Success Criteria

### Pass/Fail Conditions

- [ ] **Interactive agents**: Each agent runs as `claude --dangerously-skip-permissions` in a tmux pane — **Pass**: user can type into the pane, agent responds, and tool calls are auto-approved / **Fail**: agent runs as `claude -p`, cannot receive user input, or blocks on permission prompts
- [ ] **Agent can ask questions**: When an agent encounters ambiguity, it asks in the tmux pane and a desktop notification fires — **Pass**: notification received and agent waits for response / **Fail**: agent guesses or hallucinates an answer
- [ ] **Browser interaction**: Dev/QA agents can open headed browsers and pause for user login — **Pass**: browser opens, user logs in, agent continues with verified session / **Fail**: headless-only or agent assumes login succeeded
- [ ] **ASSUMPTION markers**: Dev marks unverifiable code with `// ASSUMPTION:` comments — **Pass**: QA coverage matrix lists all assumptions as "Unverified" / **Fail**: assumptions unmarked or QA ignores them
- [ ] **QA runtime proof**: QA's coverage matrix has runtime evidence for every criterion — **Pass**: every row has a command + output / **Fail**: any row says "looks correct" without proof
- [ ] **Worktree isolation**: Each issue gets its own worktree with symlinked shared resources — **Pass**: `.worktrees/issue-<N>/` exists with correct symlinks / **Fail**: changes happen on main or symlinks are missing
- [ ] **DAG resolution**: Issues with `Depends on: #N` only start after dependencies are closed — **Pass**: `run-all.sh` holds back blocked issues / **Fail**: dependent issue starts before its dependency merges
- [ ] **Pipeline resume**: `./scripts/impl.sh #42 --from qa` resumes from QA without re-running prior stages — **Pass**: QA runs in existing worktree with existing dev output / **Fail**: pipeline restarts from scratch
- [ ] **Parallel safety**: Two simultaneous `impl.sh` runs on different issues don't corrupt each other's git state — **Pass**: both complete independently / **Fail**: git operation race condition
- [ ] **End-to-end**: Full pipeline on a real project produces a merged PR with QA evidence — **Pass**: PR merged, issue closed with coverage matrix / **Fail**: pipeline doesn't complete
- [ ] **Portability**: `.claude/` + `scripts/` dropped into a fresh repo works after `setup.sh` — **Pass**: setup passes on a new project / **Fail**: hard-coded paths or missing dependencies

### Quality Indicators

- QA Requirements Coverage Matrix: every criterion has runtime evidence
- Agent GitHub comments: self-contained, understandable without terminal access
- Agent learnings: at least 1 learning captured per successful pipeline
- Zero hallucinated selectors/URLs in browser automation projects (the Niggsfield test)

---

## 14. Implementation Phases

### Phase 1: Bash Library + Configuration Foundation

**Goal**: Build the shared bash function library and configuration system that everything else depends on.

**Deliverables**:
- ✅ `scripts/lib/config.sh` — YAML config parser for `.claude/workflow.yaml`
- ✅ `scripts/lib/tmux.sh` — tmux session/pane creation, send-keys, pipe-pane, title setting
- ✅ `scripts/lib/worktree.sh` — worktree create, symlink auto-detection, cleanup
- ✅ `scripts/lib/sentinel.sh` — sentinel file read/write/poll/clear functions
- ✅ `scripts/lib/lock.sh` — git operation lock acquire/release with stale detection
- ✅ `scripts/lib/notify.sh` — macOS desktop notification via osascript
- ✅ `scripts/lib/github.sh` — issue read, comment post, label set/remove, PR helpers
- ✅ `scripts/lib/log.sh` — logging utilities, terminal title setting, color output
- ✅ `scripts/lib/dag.sh` — dependency graph parsing and resolution from GitHub issues
- ✅ `scripts/setup.sh` — doctor/prerequisite checker
- ✅ `.claude/workflow.yaml` — default configuration file

**Acceptance Criteria**:
- [ ] Each lib/*.sh file is sourceable and provides documented functions — **Pass**: `source scripts/lib/tmux.sh && type create_tmux_session` succeeds / **Fail**: source error or function missing
- [ ] `setup.sh` checks all prerequisites and reports PASS/FAIL per item — **Pass**: running on a configured machine shows all green / **Fail**: misses a check or false positive
- [ ] `workflow.yaml` is parseable by config.sh — **Pass**: `source scripts/lib/config.sh && get_config pipeline.max_retries` returns `3` / **Fail**: parse error
- [ ] `dag.sh` correctly resolves a 3-issue dependency chain — **Pass**: given issues A (no deps), B (depends on A), C (depends on B), returns [A] as ready / **Fail**: wrong resolution order

**Validation Commands**:
```bash
# Verify all library files exist and are sourceable
for f in scripts/lib/*.sh; do bash -n "$f" && echo "PASS: $f" || echo "FAIL: $f"; done

# Verify setup.sh runs
./scripts/setup.sh

# Verify config parser
source scripts/lib/config.sh && get_config pipeline.max_retries
```

---

### Phase 2: Agent Prompts + CLAUDE.md Generation

**Goal**: Rewrite all 5 agent prompts for interactive mode and build the CLAUDE.md-per-worktree generation system.

**Deliverables**:
- ✅ `.claude/agents/orchestrator.md` — Revised for interactive mode: asks questions when ambiguous, mandatory codebase reuse scan, VALIDATE commands per task, post-QA sanity check
- ✅ `.claude/agents/dev-agent.md` — Revised for interactive mode: ASSUMPTION markers, asks for help when stuck, headed browser interaction, runs VALIDATE after each task
- ✅ `.claude/agents/qa-agent.md` — Revised for interactive mode: Requirements Coverage Matrix with runtime proof, flags ASSUMPTION markers, can open headed browser
- ✅ `.claude/agents/merge-agent.md` — Revised for interactive mode: can ask user about conflicts
- ✅ `.claude/agents/prod-qa-agent.md` — Revised for interactive mode: headed browser production verification
- ✅ CLAUDE.md generation function in `scripts/lib/` — assembles agent role + project context + task context into worktree CLAUDE.md

**Acceptance Criteria**:
- [ ] Each agent prompt includes sections for: role, inputs, outputs, constraints, communication format, sentinel files, human interaction protocol — **Pass**: all sections present / **Fail**: missing sections
- [ ] Orchestrator prompt requires VALIDATE commands for each plan task — **Pass**: "VALIDATE" keyword present in plan format spec / **Fail**: missing
- [ ] Dev prompt requires ASSUMPTION markers — **Pass**: `// ASSUMPTION:` instruction present / **Fail**: missing
- [ ] QA prompt requires runtime proof for every criterion — **Pass**: "runtime evidence" requirement present, "looks correct" explicitly forbidden / **Fail**: missing
- [ ] QA prompt explicitly forbids code modification — **Pass**: "NEVER modify source code" present / **Fail**: missing
- [ ] All prompts include NEEDS_HUMAN sentinel writing instructions — **Pass**: each prompt documents when/how to write NEEDS_HUMAN / **Fail**: missing
- [ ] CLAUDE.md generation produces valid output combining agent role + project context — **Pass**: generated CLAUDE.md contains both agent instructions and project details / **Fail**: missing either component

**Validation Commands**:
```bash
# Verify all agent files exist
ls -la .claude/agents/{orchestrator,dev-agent,qa-agent,merge-agent,prod-qa-agent}.md

# Verify key requirements in prompts
grep -l "VALIDATE" .claude/agents/orchestrator.md
grep -l "ASSUMPTION" .claude/agents/dev-agent.md
grep -l "runtime.*evidence\|runtime.*proof" .claude/agents/qa-agent.md
grep -li "never modify" .claude/agents/qa-agent.md
grep -l "NEEDS_HUMAN" .claude/agents/*.md
```

---

### Phase 3: Pipeline Orchestrator (`impl.sh`)

**Goal**: Build the main pipeline orchestrator script that creates worktrees, manages tmux sessions, spawns interactive Claude agents, monitors sentinel files, handles retries, and manages the full lifecycle.

**Deliverables**:
- ✅ `scripts/impl.sh` — Full pipeline orchestrator with: argument parsing, preflight checks, worktree setup, tmux session creation, CLAUDE.md generation per stage, agent spawning via tmux send-keys, sentinel monitoring loop, QA retry loop, NEEDS_HUMAN detection + notification, pipeline resume (`--from`), GitHub label updates, agent learnings capture, cleanup on success, preservation on failure
- ✅ `scripts/login.sh` — Pre-login browser session manager
- ✅ `scripts/status.sh` — Pipeline status reporter

**Acceptance Criteria**:
- [ ] `impl.sh #N` creates a worktree at `.worktrees/issue-<N>/` with correct symlinks — **Pass**: directory exists with `.claude/` symlink / **Fail**: no worktree or missing symlinks
- [ ] `impl.sh #N` creates a tmux session `issue-<N>` with correctly titled panes — **Pass**: `tmux list-panes -t issue-<N>` shows panes / **Fail**: no session
- [ ] Each agent launches as `claude --dangerously-skip-permissions` (interactive, not `claude -p`) — **Pass**: `tmux capture-pane` shows Claude interactive prompt with no permission blocks / **Fail**: non-interactive process or blocked on permissions
- [ ] Sentinel monitoring detects stage completion within 5 seconds — **Pass**: pipeline advances promptly after sentinel write / **Fail**: significant lag or missed sentinel
- [ ] NEEDS_HUMAN triggers desktop notification — **Pass**: notification appears / **Fail**: silent
- [ ] QA FAIL triggers Dev retry (up to max_retries) — **Pass**: dev pane re-activates with QA report / **Fail**: pipeline stops or loops beyond max
- [ ] `--from qa` resumes pipeline at QA stage — **Pass**: QA runs without re-running orchestrator/dev / **Fail**: starts from beginning
- [ ] GitHub labels update at each stage transition — **Pass**: `gh issue view #N --json labels` shows current stage / **Fail**: stale labels
- [ ] On success: worktree removed, issue labeled appropriately — **Pass**: `.worktrees/issue-<N>/` gone / **Fail**: worktree persists
- [ ] On failure: worktree preserved, GitHub comment posted with details — **Pass**: worktree exists, issue has failure comment / **Fail**: worktree deleted or no comment

**Validation Commands**:
```bash
# Test preflight (should pass on configured machine)
./scripts/impl.sh --dry-run #1

# Test tmux session creation (requires a valid issue)
./scripts/impl.sh #<test-issue> && tmux list-sessions | grep "issue-"

# Test status reporter
./scripts/status.sh
```

---

### Phase 4: Dependency Resolution + Parallel Execution

**Goal**: Build the multi-issue DAG runner that resolves dependencies and launches parallel pipelines.

**Deliverables**:
- ✅ `scripts/run-all.sh` — Multi-issue DAG runner: reads Epic, parses dependencies, builds DAG, launches unblocked issues, monitors completions, starts newly unblocked issues
- ✅ Enhanced `scripts/lib/dag.sh` — Full DAG implementation with cycle detection, topological sorting, and progress tracking
- ✅ Enhanced `scripts/lib/lock.sh` — Battle-tested lock serialization under parallel load

**Acceptance Criteria**:
- [ ] `run-all.sh` correctly identifies unblocked issues from Epic — **Pass**: issues with no deps start immediately / **Fail**: wrong issues start or none start
- [ ] Dependent issues wait until their dependencies merge — **Pass**: issue with `Depends on: #N` doesn't start until #N is closed / **Fail**: starts prematurely
- [ ] Circular dependency detected and reported — **Pass**: `run-all.sh` reports cycle and exits cleanly / **Fail**: infinite hang or crash
- [ ] Multiple parallel `impl.sh` runs don't corrupt git state — **Pass**: all pipelines complete without git errors / **Fail**: merge conflicts or corruption from race conditions
- [ ] `--max-parallel` flag limits concurrency — **Pass**: at most N tmux sessions active / **Fail**: exceeds limit

**Validation Commands**:
```bash
# Test DAG resolution (requires Epic with tasks)
./scripts/run-all.sh --dry-run

# Test parallel safety (requires 2+ independent issues)
./scripts/impl.sh #<issue-a> &
./scripts/impl.sh #<issue-b> &
wait
```

---

### Phase 5: Integration Testing + Documentation + Portability

**Goal**: End-to-end validation on 2 real projects, documentation, and portability proof.

**Deliverables**:
- ✅ End-to-end test on Project A (web app with browser automation) — full pipeline from PRD to merged PR
- ✅ End-to-end test on Project B (CLI tool or API, no browser) — full pipeline from PRD to merged PR
- ✅ Updated `/create-prd` command — adds `Depends on: #N` to task issues, auto-labels with `type:epic`/`type:task`
- ✅ Updated `/init-project` command — generates `scripts/` folder alongside `.claude/`, creates `workflow.yaml`
- ✅ Updated `README.md` — setup instructions, quick start, architecture overview
- ✅ Remove stale v1 files (`.claude/commands/impl.md` if replaced, old agent prompt versions)
- ✅ Portability test: fresh repo + copy .claude/ + scripts/ + run setup.sh

**Acceptance Criteria**:
- [ ] Project A (web app): full pipeline completes with browser interaction — **Pass**: PR merged, QA coverage matrix shows runtime browser evidence / **Fail**: pipeline fails or selectors unverified
- [ ] Project B (CLI/API): full pipeline completes — **Pass**: PR merged, QA coverage matrix shows runtime test evidence / **Fail**: pipeline fails
- [ ] Dependency ordering works in Project A — **Pass**: at least one issue with `Depends on:` waited correctly / **Fail**: wrong order
- [ ] Portability: fresh repo with `.claude/` + `scripts/` works — **Pass**: `setup.sh` passes, `impl.sh` creates worktree and tmux session / **Fail**: hard-coded paths or missing deps
- [ ] README explains setup in under 5 minutes of reading — **Pass**: new developer can understand and run the system / **Fail**: unclear or missing steps

**Validation Commands**:
```bash
# Verify no stale v1 files
ls .claude/commands/
# Expected: create-prd.md, init-project.md (no impl.md)

# Verify scripts exist
ls scripts/
# Expected: impl.sh, run-all.sh, setup.sh, status.sh, login.sh, lib/

# Portability test
mkdir /tmp/test-portability && cd /tmp/test-portability
git init && cp -r /path/to/project/.claude . && cp -r /path/to/project/scripts .
./scripts/setup.sh
```

---

## 15. Future Considerations

Post-MVP enhancements to consider:

1. **Pipeline status dashboard pane**: A dedicated tmux pane showing a live table of all pipelines — issue, stage, status, elapsed time. Polls sentinel files every 5 seconds.
2. **Mermaid dependency graph in EPIC**: Auto-generate and update a Mermaid diagram in the Epic issue body showing the task DAG with completion status.
3. **3 parallel research sub-agents before E2E**: Spawn 3 sub-agents simultaneously (structure, database, bug hunting) before E2E testing begins. Smarter test setup.
4. **Auto-revert on prod-QA failure**: If production verification fails after merge, automatically create a revert PR. Requires battle-testing before enabling.
5. **Phone monitoring via WebSocket**: Stream tmux output to a mobile browser over Wi-Fi/Tailscale for remote monitoring.
6. **Automated learning promotion**: When the same learning appears across 3+ issues, auto-propose it as a CLAUDE.md rule.
7. **Budget per agent role**: If Claude Code adds `--max-budget-usd` to interactive mode, set per-agent spending limits.
8. **Linux/Windows support**: Cross-platform compatibility for notifications, shell scripting, and tmux alternatives.
9. **Custom agent roles**: Allow users to define additional agents (Security Auditor, Performance Tester) via `.claude/agents/` convention.
10. **Agent confidence scoring**: Each agent self-reports a 1-5 confidence score. Low confidence triggers additional review or human checkpoint.

---

## 16. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Interactive Claude sessions are slower and more expensive than `claude -p` | High | Medium | Accept the tradeoff — correctness (asking questions vs hallucinating) is worth the cost. Monitor spending per issue. |
| tmux `send-keys` races — prompt sent before Claude is ready | Medium | Medium | Wait for Claude's prompt indicator (`❯` or `>`) in pane output before sending. Retry with 2-second backoff. |
| Agent merges broken code to main | Low | High | QA requires runtime proof. Merge agent checks CI. GitHub branch protection (require PR review) as ultimate safety net. |
| Agent hallucinates selectors/URLs (Niggsfield pattern) | Medium | High | ASSUMPTION markers in code. QA flags unverified assumptions. Headed browser verification. Cannot PASS with critical unverified assumptions. |
| Worktree corruption from parallel git operations | Medium | High | Lock serialization in `scripts/lib/lock.sh`. PID-based stale lock detection. Lock timeout with clear error message. |
| CLAUDE.md per worktree gets stale if project CLAUDE.md changes mid-pipeline | Low | Low | Regenerate CLAUDE.md before each stage (not just once at pipeline start). |
| User doesn't notice desktop notification when agent needs help | Medium | Medium | Notification includes sound. Agent writes NEEDS_HUMAN sentinel so monitor loop keeps alerting every 30 seconds until resolved. |
| DAG resolver misparses `Depends on:` syntax variations | Medium | Medium | Strict regex with documented format. `run-all.sh --dry-run` shows parsed DAG for verification before execution. |
| Agent exceeds max_turns and exits mid-task | Low | Medium | Sentinel file check — if agent exits without writing sentinel, mark as STUCK. Preserve worktree. Notify user. |

---

## 17. Appendix

### Key Dependencies

| Dependency | Version | Documentation |
|-----------|---------|---------------|
| Claude Code CLI | Latest | [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code) |
| GitHub CLI (`gh`) | 2.0+ | [GitHub CLI Manual](https://cli.github.com/manual/) |
| Git | 2.20+ | [Git Worktree Docs](https://git-scm.com/docs/git-worktree) |
| tmux | 3.0+ | [tmux Wiki](https://github.com/tmux/tmux/wiki) |
| jq | 1.6+ | [jq Manual](https://stedolan.github.io/jq/manual/) |
| yq | 4.0+ | [yq Docs](https://mikefarah.gitbook.io/yq/) |
| osascript | macOS built-in | [osascript Man Page](https://ss64.com/osx/osascript.html) |
| agent-browser | Latest | [agent-browser npm](https://www.npmjs.com/package/@anthropic-ai/agent-browser) |

### Reference Implementations

- **Example_Claude2** (`references/Example_Claude2/`) — Shell-orchestrated multi-agent pipeline with zsh functions, sentinel files, worktree management, terminal title updates, budget controls. Primary inspiration for the bash orchestration pattern.
- **ai-coding-workflow** (`references/ai-coding-workflow-main/`) — Skills-based workflow with EPIC/TASK hierarchy, agent learnings, codebase reuse scans, DAG resolution. Primary inspiration for quality gates and institutional knowledge.
- **Example_Claude** (`references/Example_Claude/`) — Planning-execution separation with VALIDATE commands, agent-browser E2E testing with 3 parallel sub-agents. Primary inspiration for anti-hallucination measures.
- **parallel-code** (`references/parallel-code-main/`) — Electron GUI with worktree lock serialization, symlink auto-detection, agent status detection from PTY output. Primary inspiration for parallel infrastructure.

### Niggsfield Post-Mortem (Key Lessons)

The Niggsfield project (`/Users/kenneth.farhan/Niggsfield`) is the canonical failure case that motivates v2. Key failures:
1. **No human interaction**: Agents couldn't ask for credentials → placeholder API key never replaced
2. **Hallucinated selectors**: No real browser opened → all CSS selectors were invented → QA passed on unit tests alone
3. **Wrong workflow model**: Agent assumed upload-from-scratch; real workflow is "Recreate from existing"
4. **contenteditable vs textarea**: `.fill()` doesn't work on Lexical editors — would have been caught with any real browser test
5. **QA skipped E2E**: "Skipped — requires headed display" → marked PASS-WITH-NITS → merged

All 5 failures are structurally prevented by v2's interactive agents + ASSUMPTION markers + runtime proof requirements.

### Sentinel File Quick Reference

| File | Written By | Values | Read By |
|------|------------|--------|---------|
| `orchestrator.done` | Orchestrator | DONE, STUCK, NEEDS_HUMAN | impl.sh |
| `orchestrator.report` | Orchestrator | Markdown plan with VALIDATE commands | Dev (via CLAUDE.md) |
| `dev.done` | Dev | DONE, STUCK, NEEDS_HUMAN | impl.sh |
| `dev.report` | Dev | Markdown summary with ASSUMPTION list | impl.sh |
| `qa.done` | QA | PASS, PASS-WITH-NITS, FAIL, NEEDS_HUMAN | impl.sh |
| `qa.report` | QA | Coverage Matrix + fix list | Dev (retry via CLAUDE.md) |
| `merge.done` | Merge | SHA, CI_FAILED, CONFLICT, NEEDS_HUMAN | impl.sh |
| `prod-qa.done` | Prod-QA | PASS, FAIL, DEPLOY_TIMEOUT, NEEDS_HUMAN | impl.sh |

### `Depends on:` Syntax Reference

In GitHub issue bodies, dependencies are declared as:
```
Depends on: #42
Depends on: #42, #43
```

The DAG resolver parses these with regex: `Depends on:\s*#(\d+)(?:,\s*#(\d+))*`

---

**Clarity Score**: 92/100
**Clarification Rounds**: 8
**Created**: 2026-02-28
**Document Version**: 2.0
