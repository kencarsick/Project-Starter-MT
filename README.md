# Universal Project Starter

A complete `.claude/` workflow system that builds any application from scratch. You handle the PRD — Claude handles everything else.

## What This Is

A portable `.claude/` directory containing **9 commands**, **5 skills**, and **3 templates** that form an autonomous development pipeline. Copy it into any project directory and use Claude Code to go from idea to shipped features.

**The workflow:**
1. You describe your idea
2. Claude interrogates you until requirements are crystal clear (clarity score >= 90/100)
3. Claude generates an exhaustive PRD + GitHub Epic with Task issues
4. Claude autonomously: scaffolds the project -> plans features -> implements -> tests -> verifies -> commits -> opens PRs

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git installed

## Setup

```bash
# 1. Clone this repo (or copy the .claude/ folder into your project)
git clone <this-repo-url> my-new-project
cd my-new-project

# 2. Verify gh is authenticated
gh auth status

# 3. Start Claude Code
claude
```

That's it. The commands and skills are automatically available in Claude Code.

## Quick Start — Build an App from Scratch

```
# Step 1: Create the PRD (interactive — you answer questions)
/create-prd "my-project-name"

# Step 2: Initialize the project (autonomous)
/init-project

# Step 3: Generate CLAUDE.md rules (autonomous)
/create-rules

# Step 4: Ship features phase by phase (fully autonomous)
/ship "Phase 1"
/ship "Phase 2"
/ship "Phase 3"
# ...repeat for each phase in the PRD
```

## Commands Reference

### `/create-prd` — Create Product Requirements Document
**Usage**: `/create-prd "project-name"`
**User interaction**: Yes (this is the only command requiring user input)

Transforms a vague idea into a decision-complete PRD through structured interrogation.

**What happens:**
1. Scores your initial idea's clarity (0-100)
2. Asks structured multiple-choice questions across 7 categories until clarity >= 90
3. Proposes minimal approach with alternatives (Devil's Advocate)
4. Scans for reusable patterns
5. Generates a 16-section PRD document
6. Creates GitHub Epic issue + Task issues (one per implementation phase)
7. Gets your final approval

**Output:**
- `PRD.md` — local PRD document
- GitHub Epic issue (label: `type:epic`)
- GitHub Task issues (label: `type:task`, one per phase)

**Question categories:**
- A) Problem & stakes — what's the problem and why does it matter?
- B) Success definition — what does "done" look like?
- C) Scope boundaries — what's in and what's out?
- D) Data model — what data do we store? (only if applicable)
- E) Failure modes — what can go wrong?
- F) Technology preferences — what stack?
- G) User experience — how should it look/feel? (only if user-facing)

---

### `/init-project` — Initialize Project
**Usage**: `/init-project`
**User interaction**: Minimal (may ask about remote repo creation)

Reads the PRD and scaffolds the project with the right tech stack.

**What happens:**
1. Reads PRD.md for tech stack, directory structure, dependencies
2. Runs appropriate scaffold command (create-next-app, cargo new, uv init, etc.)
3. Installs dependencies
4. Sets up linter, formatter, test framework
5. Creates `.env.example`
6. `git init` + initial commit
7. Validates everything works (dev server, linter, tests)

---

### `/create-rules` — Generate CLAUDE.md
**Usage**: `/create-rules`
**User interaction**: None

Analyzes the codebase and generates a `CLAUDE.md` file with full project context.

**What happens:**
1. Discovers project type from config files
2. Analyzes code patterns, naming conventions, file organization
3. Generates `CLAUDE.md` from universal template
4. Writes to project root and commits

---

### `/plan-feature` — Create Implementation Plan
**Usage**: `/plan-feature "Phase 1"` or `/plan-feature #42` or `/plan-feature "add user auth"`
**User interaction**: None (may ask if requirements are ambiguous)

Creates an information-dense, implementation-ready plan. Philosophy: "Context is King."

**What happens:**
1. Reads PRD phase or GitHub issue
2. Deep codebase analysis (patterns, conventions, dependencies)
3. External research (library docs, best practices)
4. Strategic planning (architecture, edge cases, security)
5. Generates step-by-step plan with validation commands

**Output**: `.claude/plans/{feature-name}.md`

---

### `/execute` — Implement from Plan
**Usage**: `/execute .claude/plans/phase-1-feature.md`
**User interaction**: None

Autonomously implements a plan file.

**What happens:**
1. Reads entire plan + all referenced files
2. Creates feature branch
3. Executes tasks in dependency order
4. Implements tests
5. Runs 4-level validation (syntax -> unit -> integration -> E2E)
6. Max 3 retries per validation failure

---

### `/verify` — QA Gate
**Usage**: `/verify` or `/verify .claude/plans/phase-1-feature.md`
**User interaction**: None

Proves every acceptance criterion with evidence. "Assume nothing. Prove everything."

**What happens:**
1. Builds Requirements Coverage Matrix (Met/Not Met/Unverified for each criterion)
2. Runs full test suite
3. E2E verification (browser for web, API calls for backends, CLI for tools)
4. Security spot-check
5. Issues verdict: **PASS**, **PASS-WITH-NITS**, or **FAIL**
6. Comments on GitHub issue with evidence

---

### `/commit` — Git Commit
**Usage**: `/commit`
**User interaction**: None

Creates an atomic commit with conventional commit format and pushes to feature branch.

---

### `/ship` — Full Autonomous Pipeline
**Usage**: `/ship "Phase 1"` or `/ship #42`
**User interaction**: None

The master orchestrator. Runs the complete cycle for one PRD phase.

**What happens:**
1. Reads project context (CLAUDE.md, PRD, git state)
2. Creates feature branch
3. Plans the feature (`/plan-feature`)
4. Implements it (`/execute`)
5. Verifies it (`/verify`) — max 3 fix-verify cycles
6. Commits and pushes (`/commit`)
7. Opens PR on GitHub (references Task issue)
8. Captures learnings
9. Reports results and suggests next phase

---

### `/learnings` — Institutional Knowledge
**Usage**: `/learnings capture` or `/learnings review`
**User interaction**: Minimal

Captures and reviews insights that improve the system over time.

**Capture mode**: Logs insights as JSON to `.claude/learnings/`
**Review mode**: Summarizes all learnings, suggests CLAUDE.md promotions

---

## Skills Reference

Skills are specialized capabilities used by commands. You typically don't invoke them directly.

| Skill | Purpose | Used By |
|-------|---------|---------|
| `requirements-clarity` | 0-100 scoring rubric for requirement clarity | `/create-prd` |
| `question-bank` | Structured question categories (A-G) for PRD interrogation | `/create-prd` |
| `agent-browser` | Browser automation for testing (navigate, click, fill, screenshot) | `/verify`, `/e2e-test` |
| `e2e-test` | Comprehensive E2E testing with parallel research sub-agents | Standalone (`/e2e-test`) |
| `agent-learnings` | JSON-based institutional knowledge capture | `/ship`, `/learnings` |

## Quality Gates

| Gate | Threshold | What Happens if Failed |
|------|-----------|----------------------|
| PRD Clarity Score | >= 90/100 | More questions asked (no limit) |
| Plan Confidence | >= 7/10 | Identifies missing context |
| Validation Commands | Must all pass | Max 3 retries, then documents issue |
| QA Verdict | Must be PASS | Fix list generated, re-verify (max 3 cycles) |
| Security Check | No critical vulns | Flagged and fixed |
| Ship Cycle Limit | Max 3 verify-fix cycles | Stop, report to user |

## How It Adapts to Any Tech Stack

This system makes **zero assumptions** about your technology:

- **init-project** reads the PRD and scaffolds accordingly (Next.js, Django, Rust, Go, etc.)
- **create-rules** detects your project type from config files
- **plan-feature** discovers patterns from your actual codebase
- **verify** adapts testing approach (browser for web, API calls for backends, CLI for tools)
- **question-bank** conditionally asks data model questions only if persistence is needed, UX questions only if user-facing

## Project Structure

```
.claude/
├── commands/        # 9 workflow commands (invoked via /command-name)
├── skills/          # 5 specialized capabilities (used by commands)
├── templates/       # 3 structural templates (CLAUDE.md, PRD, plan)
├── learnings/       # Auto-populated institutional knowledge (JSON)
└── plans/           # Auto-populated feature plans (Markdown)
```

## Workflow Diagram

```
┌─────────────────────────────────────────┐
│           USER INTERACTION ZONE          │
│                                          │
│  /create-prd ──> PRD.md + GitHub Epic    │
│  (clarity scoring, structured questions) │
│  (takes as long as needed)               │
└──────────────────┬──────────────────────┘
                   │
                   v
┌─────────────────────────────────────────┐
│          SETUP ZONE (autonomous)         │
│                                          │
│  /init-project ──> scaffolded project    │
│  /create-rules ──> CLAUDE.md             │
└──────────────────┬──────────────────────┘
                   │
                   v
┌─────────────────────────────────────────┐
│     AUTONOMOUS SHIPPING ZONE             │
│     (repeat per PRD phase)               │
│                                          │
│  /ship "Phase N"                         │
│    ├─ branch ──> feat/phase-n-*          │
│    ├─ plan   ──> .claude/plans/*.md      │
│    ├─ execute ──> code + tests           │
│    ├─ verify ──> PASS/FAIL               │
│    │   └─ (max 3 fix cycles)             │
│    ├─ commit ──> push to branch          │
│    ├─ PR     ──> "Fixes #task-issue"     │
│    └─ learn  ──> .claude/learnings/      │
└─────────────────────────────────────────┘
```

## Design Principles

1. **PRD is the bottleneck by design** — the only place requiring user input. Thoroughness here prevents issues downstream.
2. **Context is King** — plans are so information-dense that execution succeeds in one pass.
3. **Prove everything, assume nothing** — no feature ships without proven acceptance criteria.
4. **Self-improving** — the system captures learnings and refines its own rules over time.
5. **Iteration limits** — max 3 automated fix cycles per feature to prevent security degradation (research shows 37.6% vulnerability increase after 5+ iterations).
6. **Universal** — no tech-stack assumptions. Everything detected at runtime from the PRD.
