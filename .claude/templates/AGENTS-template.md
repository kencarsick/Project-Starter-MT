# AGENTS.md Template

A template for generating project-level agent rules. Filled by `/init-project` with project-specific details.

---

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

- **Stay inside the worktree.** All file operations MUST be within `__WORKTREE_PATH__`.
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

Location: `__WORKTREE_PATH__/.claude-workflow/`

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

<!-- Filled by /init-project with details from CLAUDE.md and PRD -->

### Tech Stack
{tech_stack_summary}

### Build & Test Commands
```bash
{dev_command}
{build_command}
{test_command}
{lint_command}
```

### Architecture Notes
{architecture_notes}

### Special Constraints
{special_constraints}
