---
description: "Implement an entire plan autonomously — code, tests, validation"
argument-hint: "[path-to-plan]"
---

# Execute Implementation Plan

## Plan: $ARGUMENTS

If no argument provided, use the most recently modified file in `.claude/plans/`.

---

## Step 1: Read & Understand

1. **Read the ENTIRE plan file** — every section, every task, every reference
2. **Read ALL files** listed in "Context References" section:
   - Every codebase file listed (at the specified line ranges)
   - Use web fetch for external documentation URLs
3. **Read CLAUDE.md** for project conventions and rules
4. **Understand the dependency order** of tasks — what must come first?
5. **Note all validation commands** — you'll run these after implementation

---

## Step 2: Create Branch

If not already on a feature branch:

```bash
# Derive branch name from plan filename
git checkout -b feat/{plan-name-without-extension}
```

If already on a feature branch, continue on it.

---

## Step 3: Execute Tasks in Order

For EACH task in the "Step-by-Step Tasks" section:

1. **Read the existing file** if modifying (never edit blind)
2. **Implement** following the spec exactly:
   - Follow the ACTION verb (CREATE, UPDATE, ADD, REMOVE, REFACTOR, MIRROR)
   - Use the PATTERN reference for style consistency
   - Include all specified IMPORTS
   - Watch for GOTCHA warnings
3. **Maintain project conventions** from CLAUDE.md:
   - Naming conventions
   - File organization patterns
   - Error handling approaches
   - Type annotations / type safety
4. **Check syntax and imports** after each file change:
   - No syntax errors
   - All imports resolve
   - Types are correct (if typed language)

---

## Step 4: Implement Tests

1. **Create all test files** from the Testing Strategy section
2. **Implement all test cases**:
   - Unit tests for each function/component
   - Integration tests for workflows
   - Edge case tests
3. **Follow existing test patterns** from the codebase (as noted in the plan)

---

## Step 5: Run Validation Commands

Execute ALL validation commands from the plan, in order:

### Level 1: Syntax & Style
Run linter/formatter. Fix any issues.

### Level 2: Unit Tests
Run unit tests. Fix any failures.

### Level 3: Integration Tests
Run integration tests. Fix any failures.

### Level 4: E2E / Manual Validation
Run E2E tests or manual validation steps.

### Failure Handling

**Max 3 attempts per failure** (iteration limit to prevent security degradation):

1. First failure → read error, identify root cause, fix
2. Second failure → re-analyze approach, check for misunderstanding
3. Third failure → document the issue with:
   - What was attempted
   - Error messages
   - Suspected root cause
   - Suggested fix approach
   Then **move on** to the next task

---

## Step 6: Output Report

```
## Execution Complete

### Completed Tasks
- [x] {Task 1} — {files created/modified}
- [x] {Task 2} — {files created/modified}
- ...

### Files Created
- `{path}` — {purpose}

### Files Modified
- `{path}` — {what changed}

### Tests Added
- `{test file}` — {count} tests ({count} passing, {count} failing)

### Validation Results
- Level 1 (Syntax): {PASS/FAIL}
- Level 2 (Unit): {PASS/FAIL} — {X}/{Y} tests passing
- Level 3 (Integration): {PASS/FAIL}
- Level 4 (E2E): {PASS/FAIL}

### Issues
- {Any unresolved issues with details}

Next step: `/verify` to run QA gate
```
