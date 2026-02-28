# AGENTS.md

This file defines rules and constraints for all agents operating in this repository. Every agent (interactive Claude session in a tmux pane) MUST read this file before taking any action.

## Agent Roles

| Role | Prompt File | Responsibility |
|------|------------|----------------|
| Orchestrator | `.claude/agents/orchestrator.md` | Read GitHub issue, create implementation plan with VALIDATE commands, mandatory codebase reuse scan, post-QA sanity check |
| Dev | `.claude/agents/dev-agent.md` | Implement code changes + tests, mark assumptions with `// ASSUMPTION:`, open PR, ask for help when stuck |
| QA | `.claude/agents/qa-agent.md` | Read-only verification, Requirements Coverage Matrix with runtime proof, E2E browser testing, flag unverified assumptions |
| Merge | `.claude/agents/merge-agent.md` | CI gate, squash-merge PR, branch cleanup, can ask user about conflicts |
| Prod-QA | `.claude/agents/prod-qa-agent.md` | Verify feature is live in production, headed browser verification, close issue on pass |

---

## Worktree Rules

- **Stay inside the worktree.** All file operations MUST be within the worktree path.
- **Never modify files outside the worktree.** This includes the main working tree, other worktrees, and system files.
- **Never modify files on `main` directly.** All changes go through PRs.
- **Worktree path format**: `.worktrees/issue-<N>/`
- **Branch naming**: `issue-<N>` (matches the GitHub issue number)

---

## Data Safety

- **Never print `.env` values** in terminal output, GitHub comments, or reports.
- **Never commit secrets** (API keys, tokens, passwords) to the repository.
- **Never expose credentials** in sentinel files or agent reports.
- **`.env` files are symlinked** into worktrees — treat them as read-only references.
- **Use `.env.example`** as the template for required environment variables.
- **`browser-data/` is shared** — never commit it, never print cookie/session values.

---

## Human Interaction Protocol

Agents run as `claude --dangerously-skip-permissions` in tmux panes. The user can see all output and type into any pane.

### When to Ask the User
- Requirements are ambiguous or contradictory
- A browser login or credential entry is needed
- An external service returns unexpected errors
- You're unsure which of 2+ valid approaches to take
- A critical assumption cannot be verified at runtime

### How to Ask
1. Type your question clearly in the tmux pane — the user can see it
2. Write `NEEDS_HUMAN` to your sentinel `.done` file with a description
3. Wait for the user to respond in the pane
4. After receiving an answer, overwrite the `.done` file with your final status

### Desktop Notifications
When you write `NEEDS_HUMAN`, the bash orchestrator detects it and fires a macOS desktop notification. The user will be alerted even if they're not watching your pane.

---

## Communication Format

All agents MUST post structured comments on the GitHub issue using this format:

```markdown
**[{role}]** — Issue #{N}

{Structured content specific to the agent's role}
```

### Comment Requirements:
- Every comment MUST be **self-contained** — a human should understand it without reading other comments.
- Include **full context**: what was done, why, and what the result was.
- Use **plain English** — no jargon, no abbreviations without expansion.
- Reference specific **file paths**, **test commands**, and **results** as evidence.

---

## Sentinel File Protocol

Location: `.claude-workflow/` inside the worktree.

### Status Files (`*.done`)
- Single word: `DONE`, `STUCK`, `NEEDS_HUMAN`, `PASS`, `PASS-WITH-NITS`, `FAIL`
- `NEEDS_HUMAN` triggers a desktop notification and pauses the pipeline
- Written atomically — never partially written

### Report Files (`*.report`)
```markdown
# {Agent Role} Report — Issue #{N}

## Summary
{1-2 sentence summary}

## Actions Taken
{Numbered list}

## Results
{Test results, coverage, evidence}

## Files Changed
{List of files modified/created/deleted}

## Suggestions
{Actionable improvements beyond acceptance criteria}

## Follow-up Risks
{Concerns for downstream agents}
```

---

## Anti-Hallucination Rules

### ASSUMPTION Markers (Dev Agent)
- When you write code that depends on external behavior you cannot verify at runtime (e.g., DOM selectors, API response formats, service availability), add a comment: `// ASSUMPTION: <description>`
- List all assumptions in your `dev.report` under a "## Unverified Assumptions" section

### Runtime Proof (QA Agent)
- For every acceptance criterion in the Requirements Coverage Matrix, provide:
  - **Status**: Met / Not Met / Unverified
  - **Static evidence**: file path + line number
  - **Runtime evidence**: exact command executed + output received
- "Looks implemented" or "appears correct" is **NEVER** sufficient — runtime proof is mandatory
- Every `// ASSUMPTION:` comment must be listed as "Unverified" in the matrix
- You **cannot** write PASS if any critical criterion is "Unverified"

### Codebase Reuse Scan (Orchestrator + Dev)
- Before implementing, scan the existing codebase for reusable patterns, utilities, and helpers
- Report findings with file paths: "Reuse `src/utils/retry.ts` for retry logic"
- Do not reinvent existing functionality

### VALIDATE Commands (Orchestrator)
- Every task in the implementation plan MUST include a `VALIDATE:` field with a shell command
- Dev agent runs each VALIDATE immediately after completing that task
- If VALIDATE fails, Dev fixes the issue before moving to the next task

---

## Testing Requirements

### Dev Agent
- Write **unit tests** for all new functions/methods
- Write **integration tests** for API endpoints and data flows
- Write **E2E tests** for user-facing features (using agent-browser or Playwright)
- Run each VALIDATE command from the orchestrator's plan after implementing that task
- All tests must **pass** before writing `dev.done`

### QA Agent
- **Run the full test suite** — report pass/fail counts
- **Execute E2E browser tests** for user-facing features — open headed browser if needed
- Produce a **Requirements Coverage Matrix** with evidence for every acceptance criterion
- **NEVER modify source code** — read-only verification only
- If browser auth is needed, write `NEEDS_HUMAN` and wait for user login

---

## Project-Specific Rules

### Tech Stack
Bash/Zsh scripts + tmux + Claude Code CLI + GitHub CLI + Git. No application framework — this is a developer workflow tool.

### Build & Test Commands
```bash
# Syntax check all bash scripts
for f in scripts/*.sh scripts/lib/*.sh; do bash -n "$f"; done

# Verify prerequisites
./scripts/setup.sh

# Run pipeline on a test issue
./scripts/impl.sh #<issue-number>
```

### Architecture Notes
Bash-orchestrated pipeline. `scripts/impl.sh` creates tmux sessions, generates per-stage CLAUDE.md in worktrees, launches interactive Claude sessions, monitors sentinel files, handles Dev→QA retries. `scripts/run-all.sh` parses dependency DAG from GitHub issues and launches pipelines in order. `scripts/lib/` contains shared functions for tmux, worktree, sentinel, lock, notification, config, GitHub, DAG, and logging operations.

### Special Constraints
- All bash scripts must use `set -euo pipefail` for strict error handling
- macOS only for MVP (osascript notifications, Homebrew dependencies)
- Agents launch with `--dangerously-skip-permissions` — user monitors via tmux panes
- Worktree lock serialization required for all git push/merge/rebase operations when running parallel pipelines
- `browser-data/` must never be committed — it contains authentication cookies
