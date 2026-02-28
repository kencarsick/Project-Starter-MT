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
- **8 categories** with applicability rules:

| Category | When to Ask |
|----------|-------------|
| A) Problem & Stakes | Always |
| B) Success Definition | Always |
| C) Scope Boundaries | Always |
| D) Data Model | Only if persistence/data involved |
| E) Failure Modes & Safety | Always |
| F) Technology Preferences | Always |
| G) User Experience | Only if user-facing app |
| H) Manual Prerequisites | Only if external services, browser automation, or user-provided assets involved |

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

Read `.claude/templates/PRD-template.md` and fill in all 17 sections:

1. **Executive Summary** — 2-3 paragraphs: core value prop, what it does, MVP goal
2. **Mission & Core Principles** — mission statement + 3-5 principles
3. **Target Users** — personas with needs and pain points
4. **MVP Scope** — in/out table with ✅/❌
5. **User Stories** — 5-8 in "As a / I want / So that" format with examples
6. **Core Architecture & Patterns** — high-level diagram, directory structure, design patterns
7. **Features** — detailed specs per feature: routes, UI, data flows
8. **Technology Stack** — table: Technology | Version | Purpose
9. **Security & Configuration** — auth, env vars, rate limiting
10. **Manual Prerequisites** — external service access, manual setup steps, assets the user must provide
11. **Data Model** — full schema: tables, columns, types, relationships, indexes
12. **API/Interface Specification** — all endpoints with request/response formats
13. **Success Criteria** — measurable pass/fail conditions
14. **Implementation Phases** — 3-5 phases with goals, deliverables ✅, acceptance criteria (pass/fail), validation commands
15. **Future Considerations** — post-MVP enhancements
16. **Risks & Mitigations** — 3-5 key risks in table format
17. **Appendix** — key deps with doc links, reference implementations

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

For each phase in Section 14:

```bash
gh issue create \
  --title "Phase {N}: {phase goal}" \
  --label "type:task" \
  --body "Epic: #{epic-number}

## Goal
{phase goal — one sentence}

## Context
{2-3 sentences of relevant background from the PRD — what this phase builds on, what it enables}

## Deliverables
- D1: {deliverable 1}
- D2: {deliverable 2}
- D3: {deliverable 3}

## Acceptance Criteria
- AC1: {criterion} — **Pass**: {condition} / **Fail**: {condition}
- AC2: {criterion} — **Pass**: {condition} / **Fail**: {condition}
- AC3: {criterion} — **Pass**: {condition} / **Fail**: {condition}

## Validation Commands
\`\`\`bash
{commands to verify this phase is complete}
\`\`\`

## Dependencies
{List prior phases that must be completed first, or \"None\" for Phase 1}
"
```

### Create Final TASK

```bash
gh issue create \
  --title "Execution: end-to-end verification" \
  --label "type:task" \
  --body "Epic: #{epic-number}

## Goal
Run the complete application end-to-end and verify all acceptance criteria from all phases are met.

## Context
This is the final verification task. All implementation phases must be complete before this task begins.

## Deliverables
- D1: All phases completed and verified
- D2: E2E test suite passes
- D3: Screenshots/evidence posted to this issue
- D4: All TASK issues closed

## Acceptance Criteria
- AC1: All phase task issues are closed — **Pass**: \`gh issue list --label type:task --state open\` returns 0 / **Fail**: open tasks remain
- AC2: E2E test suite passes — **Pass**: all tests green / **Fail**: any test failure
- AC3: Evidence posted — **Pass**: screenshots/logs attached to this issue / **Fail**: no evidence

## Validation Commands
\`\`\`bash
gh issue list --label \"type:task\" --state open
# Expected: 0 open tasks (except this one)
\`\`\`

## Dependencies
All Phase {1..N} tasks must be complete
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
**Sections**: 17/17 complete
**Implementation Phases**: {count}

**GitHub Issues Created**:
- Epic: #{epic-number} — {project name}
- Task: #{task-1} — Phase 1: {goal}
- Task: #{task-2} — Phase 2: {goal}
- ...

**PRD written to**: ./PRD.md

Next step: `/init-project` to scaffold the project, then `/impl #<first-task-issue>` to begin implementation
```
