---
description: "Create exhaustive PRD through structured interrogation — the only command requiring user interaction"
argument-hint: "[project-name]"
---

# Create Product Requirements Document

## Project: $ARGUMENTS

This is the most critical command in the workflow. The PRD drives everything downstream — scaffolding, planning, implementation, testing. Thoroughness here prevents issues everywhere else.

---

## Phase 0: Preflight

1. **Check for existing PRD**: if `PRD.md` exists, ask the user:
   - a) Create new version (archive current as `PRD-v{N}.md`)
   - b) Update existing PRD
   - c) Start fresh (delete and recreate)

2. **Read existing context** (if any):
   - `CLAUDE.md` — project rules and conventions
   - `README.md` — project description
   - `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` — existing tech stack
   - Any existing code structure

3. **Verify GitHub CLI**:
   ```bash
   gh auth status
   ```
   If not authenticated, warn: "GitHub CLI is not authenticated. Run `gh auth login` to enable GitHub issue creation. You can continue without it, but issues won't be created automatically."

---

## Phase 1: Initial Intake

1. Accept the user's project idea (can be one sentence or a paragraph)
2. Read `.claude/skills/requirements-clarity/SKILL.md` for the scoring rubric
3. Score the initial idea across all 4 dimensions using the rubric
4. Report the initial score with breakdown and identified gaps

---

## Phase 2: Structured Interrogation

Use `.claude/skills/question-bank/SKILL.md` for systematic questioning.

### Rules

- **Multiple-choice format** for every question: `1a, 2c, 3b + note`
- **2-4 questions per round**, targeting highest-impact gaps
- **7 categories** with applicability rules:

| Category | When to Ask |
|----------|-------------|
| A) Problem & Stakes | Always |
| B) Success Definition | Always |
| C) Scope Boundaries | Always |
| D) Data Model | Only if persistence/data involved |
| E) Failure Modes & Safety | Always |
| F) Technology Preferences | Always |
| G) User Experience | Only if user-facing app |

### Anti-Vagueness Enforcement

Auto-flag these words without measurable criteria — re-ask with specifics:
- "works", "robust", "fast", "better", "handle", "should", "fix", "improve", "scalable", "secure"

### Iteration

- Update and report clarity score after EACH round
- Continue until score **>= 90/100**
- **No round limit** — thoroughness beats speed
- Build context progressively; don't re-ask resolved questions

---

## Phase 3: Devil's Advocate + Simplification

Once enough context is gathered (score approaching 80+):

1. **Propose recommended minimal plan** with 1-2 alternatives:
   - Option A (Recommended): {minimal approach} — {tradeoffs}
   - Option B: {alternative} — {tradeoffs}
   - Option C: {alternative} — {tradeoffs}

2. **Identify failure modes** with mitigations for the recommended approach

3. **Apply YAGNI** — identify what can be cut from MVP:
   - "Do we really need X for v1?"
   - "Can Y be added in Phase 2 instead?"

4. **Get user approval** on the approach before generating the PRD

---

## Phase 4: Codebase Reuse Scan

### If existing codebase:
- Scan for reusable patterns, utilities, components
- Report with file paths: "Found {pattern} in {file} that can be reused for {purpose}"

### If greenfield:
- Research the chosen tech stack's ecosystem
- Identify recommended project structure patterns
- Find starter templates or reference implementations

---

## Phase 5: PRD Generation

Read `.claude/templates/PRD-template.md` and fill in all 16 sections:

1. **Executive Summary** — 2-3 paragraphs: core value prop, what it does, MVP goal
2. **Mission & Core Principles** — mission statement + 3-5 principles
3. **Target Users** — personas with needs and pain points
4. **MVP Scope** — in/out table with ✅/❌
5. **User Stories** — 5-8 in "As a / I want / So that" format with examples
6. **Core Architecture & Patterns** — high-level diagram, directory structure, design patterns
7. **Features** — detailed specs per feature: routes, UI, data flows
8. **Technology Stack** — table: Technology | Version | Purpose
9. **Security & Configuration** — auth, env vars, rate limiting
10. **Data Model** — full schema: tables, columns, types, relationships, indexes
11. **API/Interface Specification** — all endpoints with request/response formats
12. **Success Criteria** — measurable pass/fail conditions
13. **Implementation Phases** — 3-5 phases with goals, deliverables ✅, acceptance criteria (pass/fail), validation commands
14. **Future Considerations** — post-MVP enhancements
15. **Risks & Mitigations** — 3-5 key risks in table format
16. **Appendix** — key deps with doc links, reference implementations

**Each Implementation Phase MUST include:**
- Specific, measurable acceptance criteria with pass/fail conditions
- Validation commands or verification steps
- What "done" looks like (including tests)

---

## Phase 6: Decomposition into GitHub Issues

If `gh` CLI is authenticated:

### Create EPIC Issue

```bash
gh issue create \
  --title "{Project Name} — Epic" \
  --label "type:epic" \
  --body "$(cat PRD.md)"
```

Record the epic issue number.

### Create TASK Issues (one per Implementation Phase)

For each phase in Section 13:

```bash
gh issue create \
  --title "Phase {N}: {phase goal}" \
  --label "type:task" \
  --body "Epic: #{epic-number}

## Goal
{phase goal}

## Deliverables
{deliverables list}

## Acceptance Criteria
{acceptance criteria with pass/fail}

## Validation Steps
{validation commands}
"
```

### Create Final TASK

```bash
gh issue create \
  --title "Execution: run end-to-end + post evidence" \
  --label "type:task" \
  --body "Epic: #{epic-number}

## Goal
Run the complete application end-to-end and post evidence that all acceptance criteria are met.

## Acceptance Criteria
- [ ] All phases completed and verified
- [ ] E2E test suite passes
- [ ] Screenshots/evidence posted
- [ ] All TASK issues closed
"
```

### Update EPIC with Checklist

Update the EPIC issue body to include a checklist linking to all TASK issues:

```markdown
## Task Tracking

- [ ] #{task-1} — Phase 1: {goal}
- [ ] #{task-2} — Phase 2: {goal}
- [ ] #{task-N} — Phase N: {goal}
- [ ] #{final-task} — Execution: run end-to-end
```

---

## Phase 7: Review & Lock

1. **Present** the complete PRD to the user with final clarity score
2. **Show** the list of created GitHub issues (if any)
3. **Label assumptions** explicitly: `ASSUMPTION: {assumption} (default: {value})`
4. **Get user final approval** — "Does this PRD accurately capture your requirements? Any changes before we lock it?"
5. **Write** `PRD.md` to project root
6. **Report** next step:

```
## PRD Complete

**Clarity Score**: {score}/100
**Clarification Rounds**: {count}
**Sections**: 16/16 complete
**Implementation Phases**: {count}

**GitHub Issues Created**:
- Epic: #{epic-number} — {project name}
- Task: #{task-1} — Phase 1: {goal}
- Task: #{task-2} — Phase 2: {goal}
- ...

**PRD written to**: ./PRD.md

Next step: `/init-project` to scaffold the project
```
