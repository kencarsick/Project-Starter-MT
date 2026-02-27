# AGENTS.md

This file defines rules and constraints for all agents operating in this repository. Every agent (`claude -p` process) MUST read this file before taking any action.

## Agent Roles

| Role | System Prompt | Responsibility |
|------|--------------|----------------|
| Orchestrator | `.claude/agents/orchestrator.md` | Read GitHub issue, create implementation plan, coordinate pipeline |
| Dev | `.claude/agents/dev-agent.md` | Implement code changes + tests, open PR |
| QA | `.claude/agents/qa-agent.md` | Read-only code review, test execution, E2E browser testing |
| Merge | `.claude/agents/merge-agent.md` | CI gate, squash-merge PR, branch/worktree cleanup |
| Prod-QA | `.claude/agents/prod-qa-agent.md` | Verify feature is live in production |

---

## Worktree Rules

- **Stay inside the worktree.** All file operations MUST be within the assigned worktree path.
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

Location: `.worktrees/issue-<N>/.claude-workflow/`

### Status Files (`*.done`)
- Single word: `DONE`, `STUCK`, `PASS`, `PASS-WITH-NITS`, `FAIL`
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

## Testing Requirements

### Dev Agent
- Write **unit tests** for all new functions/methods
- Write **integration tests** for API endpoints and data flows
- Write **E2E tests** for user-facing features (using agent-browser skill)
- All tests must **pass** before writing `dev.done`

### QA Agent
- **Run the full test suite** — report pass/fail counts
- **Execute E2E browser tests** for user-facing features
- Produce a **Requirements Coverage Matrix** with evidence for every acceptance criterion
- **NEVER modify source code** — read-only verification only

---

## Project-Specific Rules

### Tech Stack
This is a meta-project: the `.claude/` directory IS the product. The system consists of markdown files (agent prompts, command definitions, skill definitions, templates) orchestrated via shell commands. No traditional app framework.

- **Claude Code CLI** (`claude -p`): Headless agent process invocation
- **GitHub CLI** (`gh`): Issue/PR management, structured comments
- **Git** (2.20+): Version control, worktree isolation
- **Bash/Zsh**: Pipeline orchestration, subprocess management
- **agent-browser**: E2E browser automation (used by QA agent)

### Build & Test Commands
```bash
# No traditional build — this is a markdown/shell system
# Validation is done via structural checks:

# Verify all agent prompts exist
ls .claude/agents/orchestrator.md .claude/agents/dev-agent.md .claude/agents/qa-agent.md .claude/agents/merge-agent.md .claude/agents/prod-qa-agent.md

# Verify placeholder tokens
grep -l "__ISSUE_NUM__" .claude/agents/*.md

# Verify QA read-only constraint
grep -i "never modify" .claude/agents/qa-agent.md

# Verify command files
ls .claude/commands/create-prd.md .claude/commands/init-project.md .claude/commands/impl.md
```

### Architecture Notes
- Each agent runs as an independent `claude -p` process with a fresh context window
- Agents communicate only through sentinel files and GitHub issue comments — never shared memory
- The `/impl` command orchestrates the full pipeline: worktree creation → 5 sequential agents → cleanup
- Placeholder tokens (`__ISSUE_NUM__`, `__WORKTREE_PATH__`, etc.) are substituted at runtime by `/impl`

### Special Constraints
- **Portability**: The `.claude/` directory must work when dropped into any project repo, regardless of tech stack
- **Agent prompts must be tech-stack agnostic**: Project-specific details come from CLAUDE.md and AGENTS.md at runtime
- **QA independence**: QA agent never sees Dev's reasoning — only the PR diff and issue requirements
- **Max 3 retries**: Dev→QA loop halts after 3 failures with a `blocked` label on the GitHub issue
