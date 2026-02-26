---
description: "Deep codebase analysis → implementation-ready plan. Context is King."
argument-hint: "[phase-number|#issue-number|feature-description]"
---

# Plan Feature Implementation

## Feature: $ARGUMENTS

## Mission

Transform a feature request into a **comprehensive implementation plan** through systematic codebase analysis, external research, and strategic planning.

**Core Principle**: We do NOT write code in this phase. Our goal is to create a context-rich plan that enables one-pass implementation success.

**Key Philosophy**: Context is King. The plan must contain ALL information needed for implementation — patterns, mandatory reading, documentation, validation commands — so the execution phase succeeds on the first attempt.

---

## Input Resolution

Determine what to plan from the arguments:

- **Phase number** (e.g., "Phase 1", "Phase 2") → read the corresponding phase from `PRD.md` Section 13
- **GitHub issue** (e.g., "#42") → `gh issue view 42` to get the issue body
- **Feature description** (e.g., "add user authentication") → use as-is

Extract from the resolved input:
- Goal / feature description
- Acceptance criteria
- Deliverables
- Validation steps

---

## Phase 1: Feature Understanding

### Deep Feature Analysis

- Extract the core problem being solved
- Identify user value and business impact
- Determine feature type: **New Capability / Enhancement / Refactor / Bug Fix**
- Assess complexity: **Low / Medium / High**
- Map affected systems and components

### Create User Story

```
As a {type of user}
I want to {action/goal}
So that {benefit/value}
```

---

## Phase 2: Codebase Intelligence Gathering

### 1. Project Structure Analysis

- Read `CLAUDE.md` for project-specific rules and conventions
- Detect primary language(s), frameworks, and runtime versions
- Map directory structure and architectural patterns
- Identify service/component boundaries and integration points
- Locate configuration files
- Find environment setup and build processes

### 2. Pattern Recognition

Use parallel sub-agents when beneficial:

- Search for **similar implementations** in the codebase
- Identify coding conventions: naming, file organization, error handling, logging, types
- Extract common patterns for the feature's domain
- Document anti-patterns to avoid

### 3. Dependency Analysis

- Catalog external libraries relevant to the feature
- Understand how libraries are integrated (check imports, configs)
- Find relevant internal documentation (docs/, README files)
- Note library versions and compatibility requirements

### 4. Testing Patterns

- Identify test framework and structure
- Find similar test examples for reference
- Understand test organization (unit vs integration)
- Note coverage requirements and testing standards

### 5. Integration Points

- Identify existing files that need updates
- Determine new files that need creation and their locations
- Map router/API registration patterns
- Understand database/model patterns if applicable
- Identify authentication/authorization patterns if relevant

### Clarify Ambiguities

- Resolve ambiguities from PRD first (re-read relevant sections)
- Only ask the user if truly unclear after exhausting PRD and codebase context
- Get specific implementation preferences if multiple valid approaches exist

---

## Phase 3: External Research

Use sub-agents for external research when beneficial:

### Documentation Gathering

- Research latest library versions and best practices
- Find official documentation with specific **section anchors**
- Locate implementation examples and tutorials
- Identify common gotchas and known issues
- Check for breaking changes and migration guides

### Compile References

```markdown
## Relevant Documentation

- [Library Official Docs](url#section) — Why: {needed for X}
- [Framework Guide](url#section) — Why: {shows Y pattern}
```

---

## Phase 4: Strategic Thinking

### Architecture Analysis

- How does this feature fit into the existing architecture?
- What are the critical dependencies and order of operations?
- What could go wrong? (edge cases, race conditions, errors)
- How will this be tested comprehensively?
- What performance implications exist?
- Are there security considerations?

### Iteration Awareness

If the plan requires **>3-4 distinct implementation rounds**, break it into sub-plans. Each sub-plan should be independently shippable.

### Design Decisions

- Choose between alternative approaches with clear rationale
- Document tradeoffs for each decision
- Plan for the simplest correct implementation (KISS/YAGNI)

---

## Phase 5: Plan Generation

Read `.claude/templates/plan-template.md` and generate the plan with all sections filled in.

### Output

Write to: `.claude/plans/{kebab-case-descriptive-name}.md`

Examples:
- `.claude/plans/phase-1-project-setup.md`
- `.claude/plans/phase-2-user-authentication.md`
- `.claude/plans/add-search-api.md`

### Required Sections

1. **Feature Description** — detailed purpose and value
2. **User Story** — As a / I want / So that
3. **Problem / Solution Statements**
4. **Feature Metadata** — type, complexity, systems affected, dependencies
5. **Context References**:
   - Files to read: `file:line` + why (actual codebase files)
   - New files to create
   - Docs to read: `URL#section` + why
   - Patterns to follow: actual code examples from codebase
6. **Implementation Plan** — phased breakdown
7. **Step-by-Step Tasks** — each with:
   - ACTION verb: CREATE, UPDATE, ADD, REMOVE, REFACTOR, MIRROR
   - IMPLEMENT: specific detail
   - PATTERN: reference to existing code (file:line)
   - IMPORTS: required imports
   - GOTCHA: known issues to avoid
   - VALIDATE: executable command to verify
8. **Testing Strategy** — unit, integration, edge cases
9. **Validation Commands** — 4 levels (syntax → unit → integration → E2E)
10. **Acceptance Criteria** — checkboxes with pass/fail conditions
11. **Completion Checklist**

---

## Report

After creating the plan, provide:

```
## Plan Created

**Feature**: {name}
**Type**: {New Capability / Enhancement / Refactor / Bug Fix}
**Complexity**: {Low / Medium / High}
**Plan**: .claude/plans/{filename}.md
**Tasks**: {count} tasks in {count} phases
**Key Risks**: {1-2 sentence summary}
**Confidence Score**: {X}/10 that execution will succeed on first attempt

Next step: `/execute .claude/plans/{filename}.md`
```
