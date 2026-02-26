---
description: "QA gate — prove every acceptance criterion with evidence. Assume nothing."
argument-hint: "[path-to-plan]"
---

# Verify Implementation — QA Gate

## Plan: $ARGUMENTS

If no argument provided, use the most recently modified file in `.claude/plans/`.

**Philosophy: "Assume nothing. Prove everything."**
If ANY requirement is unproven, the verdict cannot be PASS. If manual/UI steps are needed and can't be automated, mark as Unverified.

---

## Step 1: Extract the Contract

1. **Read the plan file** — extract ALL acceptance criteria
2. **Read the PRD phase** (if applicable) — extract additional requirements
3. **Read the GitHub issue** (if applicable) — `gh issue view {number}`
4. **Rewrite as a numbered checklist** with clear "done" conditions:

```
1. {Criterion} — Done when: {specific measurable condition}
2. {Criterion} — Done when: {specific measurable condition}
...
```

List assumptions separately — **assumptions are NOT met requirements**.

---

## Step 2: Requirements Coverage Matrix

For EACH criterion from the checklist:

| # | Requirement | Status | Static Evidence | Runtime Evidence |
|---|-------------|--------|-----------------|------------------|
| 1 | {criterion} | {Met/Partially Met/Not Met/Unverified} | {file path + exact function/class/const} | {exact test command or E2E step that proves it} |
| 2 | {criterion} | {status} | {evidence} | {evidence} |

### Rules

- **"Looks implemented" is NEVER enough** — must have proof (test output, command result, screenshot)
- **Met**: code exists AND test/command proves it works
- **Partially Met**: code exists but incomplete or untested edge cases
- **Not Met**: requirement not implemented
- **Unverified**: can't be proven automatically (needs manual testing)
- **Missing requirement = FAIL**

---

## Step 3: Run Full Test Suite

1. Run the project's full test suite (not just feature tests):
   ```bash
   {test command from CLAUDE.md or plan}
   ```
2. Record exact commands and results
3. Note any test failures with file paths and error messages
4. Run linter/type checker:
   ```bash
   {lint command from CLAUDE.md or plan}
   ```

---

## Step 4: E2E Verification

Adaptive by project type:

### Web App with UI
Use the `agent-browser` skill:
- **1 happy path**: complete the primary user flow end-to-end
- **3 negative scenarios**: invalid input, unauthorized access, edge cases
- Take screenshots as evidence
- Save to `e2e-screenshots/verify/`

### API / Backend
```bash
# Happy path
curl -X {METHOD} http://localhost:{port}/{endpoint} \
  -H "Content-Type: application/json" \
  -d '{request body}'
# Expected: {status code} + {response shape}

# Negative: missing auth
curl -X {METHOD} http://localhost:{port}/{endpoint}
# Expected: 401/403

# Negative: invalid input
curl -X {METHOD} http://localhost:{port}/{endpoint} \
  -d '{invalid body}'
# Expected: 400/422 with error message
```

### CLI Tool
```bash
# Happy path
{command} {valid args}
# Expected: {output}

# Negative: invalid args
{command} {invalid args}
# Expected: {error message}

# Edge case
{command} {edge case args}
# Expected: {behavior}
```

### Library
```bash
# Import test
{language-specific import command}

# Usage test
{minimal usage example}

# Edge case
{edge case usage}
```

If E2E is not feasible, explain why and provide the closest integration test + a concrete E2E plan with exact steps.

---

## Step 5: Security Spot-Check

Scan for common vulnerabilities:

- [ ] **Unsanitized user input** — any user input used in queries, commands, or HTML without sanitization?
- [ ] **Missing auth on protected routes** — any endpoint that should require auth but doesn't?
- [ ] **Exposed secrets** — any API keys, passwords, tokens hardcoded or logged?
- [ ] **SQL/NoSQL injection** — any raw query string concatenation?
- [ ] **XSS vectors** — any unsanitized data rendered in HTML?
- [ ] **Hardcoded credentials** — any test credentials left in production code?
- [ ] **Insecure dependencies** — any known vulnerable package versions?

Report findings with file paths and line numbers.

---

## Step 6: Cleanliness Assessment

Is this the simplest correct implementation? (3-6 bullets max)

- **Cleanliness Verdict**: {Clean / Acceptable / Needs Refactor}
- {Assessment point 1}
- {Assessment point 2}
- {Assessment point 3}

---

## Step 7: Final Verdict

### PASS
All criteria **Met**, all tests pass, E2E succeeded, no critical security issues.
```
## QA Verdict: PASS ✅

All {count} acceptance criteria met with evidence.
Tests: {X}/{Y} passing
E2E: {count} scenarios verified
Security: No critical issues

Suggest: /commit
```

### PASS-WITH-NITS
All criteria **Met**, but minor non-functional suggestions exist.
```
## QA Verdict: PASS-WITH-NITS ✅

All {count} acceptance criteria met.
Tests: {X}/{Y} passing

Nits (non-blocking):
- {nit 1}
- {nit 2}

Suggest: /commit (nits logged for future cleanup)
```

### FAIL
Any criterion **Not Met** or **Unverified** with no justification.
```
## QA Verdict: FAIL ❌

{count}/{total} criteria met. Issues:

### Fix List
1. **{Criterion}** — {what's wrong}
   - File: `{path}:{line}`
   - Fix: {specific fix description}

2. **{Criterion}** — {what's wrong}
   - File: `{path}:{line}`
   - Fix: {specific fix description}

Suggest: Fix the issues above, then re-run /verify
```

---

## Step 8: GitHub Issue Comment

If a GitHub issue is associated with this work, post the verdict:

```bash
gh issue comment {number} --body "## QA Verdict: {PASS/FAIL}

{Summary of evidence}

### Requirements Coverage
{Abbreviated matrix}

### Test Results
{Summary}

### E2E Results
{Summary}
"
```
