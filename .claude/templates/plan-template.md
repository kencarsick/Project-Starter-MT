# Feature: {feature-name}

The following plan should be complete, but validate documentation and codebase patterns before implementing.

Pay special attention to naming of existing utils, types, and models. Import from the right files.

## Feature Description

{Detailed description of the feature, its purpose, and value to users}

## User Story

As a {type of user}
I want to {action/goal}
So that {benefit/value}

## Problem Statement

{Clearly define the specific problem or opportunity this feature addresses}

## Solution Statement

{Describe the proposed solution approach and how it solves the problem}

## Feature Metadata

**Feature Type**: {New Capability / Enhancement / Refactor / Bug Fix}
**Estimated Complexity**: {Low / Medium / High}
**Primary Systems Affected**: {List of main components/services}
**Dependencies**: {External libraries or services required}

---

## CONTEXT REFERENCES

### Relevant Codebase Files — READ THESE BEFORE IMPLEMENTING

{List files with line numbers and relevance}

- `path/to/file.ext` (lines X-Y) — Why: {Contains pattern for X that we'll mirror}
- `path/to/model.ext` (lines X-Y) — Why: {Data model structure to follow}
- `path/to/test.ext` — Why: {Test pattern example}

### New Files to Create

- `path/to/new_file.ext` — {Purpose description}
- `tests/path/to/test_file.ext` — {Test coverage description}

### Relevant Documentation — READ THESE BEFORE IMPLEMENTING

- [{Documentation Title}]({url}#{section})
  - Specific section: {Section name}
  - Why: {Required for implementing X}
- [{Documentation Title}]({url}#{section})
  - Specific section: {Section name}
  - Why: {Shows proper Y pattern}

### Patterns to Follow

{Specific patterns extracted from codebase — include actual code examples from the project}

**Naming Conventions:**
```
{example from codebase}
```

**Error Handling:**
```
{example from codebase}
```

**Other Relevant Patterns:**
```
{example from codebase}
```

---

## IMPLEMENTATION PLAN

### Phase 1: Foundation

{Describe foundational work needed before main implementation}

**Tasks:**
- Set up base structures (schemas, types, interfaces)
- Configure necessary dependencies
- Create foundational utilities or helpers

### Phase 2: Core Implementation

{Describe the main implementation work}

**Tasks:**
- Implement core business logic
- Create service layer components
- Add API endpoints or interfaces
- Implement data models

### Phase 3: Integration

{Describe how feature integrates with existing functionality}

**Tasks:**
- Connect to existing routers/handlers
- Register new components
- Update configuration files
- Add middleware or interceptors if needed

### Phase 4: Testing & Validation

{Describe testing approach}

**Tasks:**
- Implement unit tests for each component
- Create integration tests for feature workflow
- Add edge case tests
- Validate against acceptance criteria

---

## STEP-BY-STEP TASKS

IMPORTANT: Execute every task in order, top to bottom. Each task is atomic and independently testable.

### Task Format Keywords

- **CREATE**: New files or components
- **UPDATE**: Modify existing files
- **ADD**: Insert new functionality into existing code
- **REMOVE**: Delete deprecated code
- **REFACTOR**: Restructure without changing behavior
- **MIRROR**: Copy pattern from elsewhere in codebase

### {ACTION} `{target_file}`

- **IMPLEMENT**: {Specific implementation detail}
- **PATTERN**: {Reference to existing pattern — file:line}
- **IMPORTS**: {Required imports and dependencies}
- **GOTCHA**: {Known issues or constraints to avoid}
- **VALIDATE**: `{executable validation command}`

{Continue with all tasks in dependency order...}

---

## TESTING STRATEGY

### Unit Tests

{Scope and requirements based on project standards}

Design unit tests with fixtures and assertions following existing testing approaches.

### Integration Tests

{Scope and requirements based on project standards}

### Edge Cases

{List specific edge cases that must be tested for this feature}

- {Edge case 1}: {How to test it}
- {Edge case 2}: {How to test it}

---

## VALIDATION COMMANDS

Execute every command to ensure zero regressions and 100% feature correctness.

### Level 1: Syntax & Style

```bash
{Project-specific linting and formatting commands}
```

### Level 2: Unit Tests

```bash
{Project-specific unit test commands}
```

### Level 3: Integration Tests

```bash
{Project-specific integration test commands}
```

### Level 4: E2E / Manual Validation

```bash
{Feature-specific E2E or manual testing steps}
```

---

## ACCEPTANCE CRITERIA

- [ ] Feature implements all specified functionality
- [ ] All validation commands pass with zero errors
- [ ] Unit test coverage meets project requirements
- [ ] Integration tests verify end-to-end workflows
- [ ] Code follows project conventions and patterns
- [ ] No regressions in existing functionality
- [ ] Documentation updated (if applicable)
- [ ] Performance meets requirements (if applicable)
- [ ] Security considerations addressed (if applicable)

---

## COMPLETION CHECKLIST

- [ ] All tasks completed in order
- [ ] Each task validation passed
- [ ] All validation commands executed successfully
- [ ] Full test suite passes (unit + integration)
- [ ] No linting or type checking errors
- [ ] Manual testing confirms feature works
- [ ] Acceptance criteria all met
- [ ] Code reviewed for quality and maintainability

---

## NOTES

{Additional context, design decisions, trade-offs, iteration warnings}
