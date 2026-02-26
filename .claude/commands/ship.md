---
description: "Full autonomous pipeline: plan → execute → verify → commit → PR. Ships one PRD phase."
argument-hint: "[phase-number|#issue-number|feature-description]"
---

# Ship Feature — Full Autonomous Pipeline

## Target: $ARGUMENTS

The master orchestrator. Runs the complete development cycle for one feature/phase.

---

## Step 1: Prime

Read context to understand current state:

1. **Read CLAUDE.md** — project rules, commands, conventions
2. **Read PRD.md** — overall project requirements
3. **Check git state**:
   ```bash
   git log -10 --oneline
   git status
   git branch
   ```
4. **Resolve input** to determine what to ship:
   - Phase number (e.g., "Phase 1") → find in PRD.md Section 13
   - GitHub issue (e.g., "#42") → `gh issue view 42`
   - Feature description → use as-is
5. **Identify** the goal, deliverables, and acceptance criteria

---

## Step 2: Branch

Create a feature branch from main:

```bash
git checkout main
git pull origin main 2>/dev/null || true
git checkout -b feat/{phase-or-feature-name}
```

If a feature branch already exists for this work, reuse it:
```bash
git checkout feat/{existing-branch}
```

---

## Step 3: Plan

Run the plan-feature logic (as defined in `.claude/commands/plan-feature.md`):

- Deep codebase analysis
- External research
- Strategic planning
- Generate plan to `.claude/plans/{name}.md`

**Check**: Does the plan have a confidence score >= 7/10?
- If yes → proceed to execution
- If < 7 → identify missing context, attempt to resolve. If truly blocked, report to user.

---

## Step 4: Execute

Run the execute logic (as defined in `.claude/commands/execute.md`):

- Read entire plan + all referenced files
- Execute tasks in dependency order
- Implement tests
- Run 4-level validation
- Max 3 retries per validation failure

---

## Step 5: Verify

Run the verify logic (as defined in `.claude/commands/verify.md`):

- Build Requirements Coverage Matrix
- Run full test suite
- E2E verification
- Security spot-check
- Issue verdict

### If FAIL

1. Read the fix list from the verify output
2. Implement each fix
3. Re-run verify

**Max 3 verify-fix cycles** (iteration limit from Gemini security research — vulnerability rates increase 37.6% after 5+ automated iterations).

If still failing after 3 cycles:
- Stop the pipeline
- Comment on GitHub issue (if applicable):
  ```bash
  gh issue comment {number} --body "## Ship Pipeline: Stopped after 3 QA cycles

  The following issues could not be resolved automatically:
  {remaining issues}

  Manual intervention required."
  ```
- Report to user with details

### If PASS or PASS-WITH-NITS

Proceed to Step 6.

---

## Step 6: Commit + Push

Run the commit logic (as defined in `.claude/commands/commit.md`):

1. Stage all relevant changes
2. Create commit(s) with conventional tags
3. Push to feature branch:
   ```bash
   git push -u origin HEAD
   ```

---

## Step 7: Open Pull Request

Create a PR that references the TASK issue:

```bash
gh pr create \
  --title "{feat/fix}: {concise description}" \
  --body "$(cat <<'EOF'
## Summary

{1-3 bullet points describing what was implemented}

## Changes

{List of key files created/modified}

## Test Results

{Test suite results summary}

## Verification Evidence

{QA verdict and key evidence points}

## Linked Issues

Fixes #{task-issue-number}

---

Shipped autonomously via `/ship` pipeline.
EOF
)"
```

---

## Step 8: Learn

Capture insights from this shipping cycle using the `agent-learnings` skill:

- Any unexpected patterns or gotchas encountered
- Decisions made during implementation
- Things that should be added to CLAUDE.md
- Anti-patterns discovered

Write ~3-5 learnings to `.claude/learnings/`.

Consider if any learnings warrant updating CLAUDE.md directly.

---

## Step 9: Report

```
## Ship Complete 🚀

**Feature**: {name}
**Branch**: feat/{branch-name}
**PR**: {PR URL}
**TASK Issue**: #{issue-number}

### What Shipped
- {Summary of implementation}

### Test Results
- Unit: {X}/{Y} passing
- Integration: {status}
- E2E: {status}
- QA Verdict: {PASS/PASS-WITH-NITS}

### Verify-Fix Cycles
- {count}/3 cycles used

### Learnings Captured
- {count} new entries in .claude/learnings/

### What's Next
- /ship "Phase {N+1}" (or /ship #{next-issue-number})
- {count} remaining phases in PRD
```
