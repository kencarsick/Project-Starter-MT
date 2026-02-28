# {Project Name} — Product Requirements Document

## 1. Executive Summary

{2-3 paragraphs covering: core value proposition, what this project does, MVP goal, target outcome}

---

## 2. Mission & Core Principles

**Mission**: {One-sentence mission statement}

### Core Principles

1. **{Principle Name}** — {Description}
2. **{Principle Name}** — {Description}
3. **{Principle Name}** — {Description}
4. **{Principle Name}** — {Description (optional)}
5. **{Principle Name}** — {Description (optional)}

---

## 3. Target Users

### Persona 1: {Name/Role}
- **Needs**: {What they need}
- **Pain Points**: {Current frustrations}
- **Success Looks Like**: {Desired outcome}

### Persona 2: {Name/Role}
- **Needs**: {What they need}
- **Pain Points**: {Current frustrations}
- **Success Looks Like**: {Desired outcome}

---

## 4. MVP Scope

### In Scope

| Category | Feature | Status |
|----------|---------|--------|
| {category} | {feature description} | ✅ MVP |
| {category} | {feature description} | ✅ MVP |

### Out of Scope

| Category | Feature | Reason |
|----------|---------|--------|
| {category} | {feature description} | ❌ {reason} |
| {category} | {feature description} | ❌ {reason} |

---

## 5. User Stories

1. **As a** {user type}, **I want to** {action/goal}, **so that** {benefit/value}.
   - _Example_: {Concrete scenario}

2. **As a** {user type}, **I want to** {action/goal}, **so that** {benefit/value}.
   - _Example_: {Concrete scenario}

3. **As a** {user type}, **I want to** {action/goal}, **so that** {benefit/value}.
   - _Example_: {Concrete scenario}

4. **As a** {user type}, **I want to** {action/goal}, **so that** {benefit/value}.
   - _Example_: {Concrete scenario}

5. **As a** {user type}, **I want to** {action/goal}, **so that** {benefit/value}.
   - _Example_: {Concrete scenario}

{Add more user stories as needed (5-8 recommended)}

---

## 6. Core Architecture & Patterns

### High-Level Architecture

```
{Architecture diagram using ASCII art or description}
```

### Directory Structure

```
{project-name}/
├── {dir}/     # {description}
├── {dir}/     # {description}
├── {dir}/     # {description}
└── {dir}/     # {description}
```

### Design Patterns

- **{Pattern}**: {How it's used and why}
- **{Pattern}**: {How it's used and why}

---

## 7. Features

### Feature 1: {Feature Name}

**Description**: {What this feature does}

**Routes/Endpoints**: {List relevant routes or entry points}

**UI Description**: {How it looks and behaves, if applicable}

**Data Flow**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

### Feature 2: {Feature Name}

**Description**: {What this feature does}

**Routes/Endpoints**: {List relevant routes or entry points}

**UI Description**: {How it looks and behaves, if applicable}

**Data Flow**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

{Continue for each feature...}

---

## 8. Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| {tech} | {version} | {why it's used} |
| {tech} | {version} | {why it's used} |
| {tech} | {version} | {why it's used} |

---

## 9. Security & Configuration

### Authentication Approach

{Describe auth strategy: JWT, session-based, OAuth, API keys, etc.}

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `{VAR_NAME}` | {description} | `{example value}` |
| `{VAR_NAME}` | {description} | `{example value}` |

### Security Measures

- **Rate Limiting**: {Approach}
- **Input Validation**: {Approach}
- **CORS**: {Configuration}
- **Secrets Management**: {How secrets are handled}

---

## 10. Manual Prerequisites

Steps that require human action — these cannot be automated by the agent pipeline.

### External Service Access

| Service | What's Needed | When |
|---------|--------------|------|
| {service name} | {account, API key, OAuth setup, etc.} | {before Phase N / before first run} |

### Manual Setup Steps

1. {Step description — e.g., "Log into service X in the automation browser"}
2. {Step description — e.g., "Add reference images to models/{name}/refs/"}

### Assets to Provide

| Asset | Location | Format | Purpose |
|-------|----------|--------|---------|
| {asset name} | {where it goes} | {file type} | {why it's needed} |

> **Note**: If no manual prerequisites exist, write "None — this project is fully automatable."

---

## 11. Data Model

### {Table/Collection Name}

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `{field}` | {type} | {PK, FK, NOT NULL, UNIQUE, etc.} | {description} |
| `{field}` | {type} | {constraints} | {description} |

### {Table/Collection Name}

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `{field}` | {type} | {constraints} | {description} |
| `{field}` | {type} | {constraints} | {description} |

### Relationships

- {Table A} → {Table B}: {relationship type and description}

### Indexes

- `{index_name}` on `{table}({columns})` — {reason}

---

## 12. API/Interface Specification

### `{METHOD} {/path}`

**Description**: {What this endpoint does}

**Request**:
```json
{
  "{field}": "{type — description}"
}
```

**Response** (`{status code}`):
```json
{
  "{field}": "{type — description}"
}
```

**Error Responses**:
- `{status}`: {description}

{Continue for each endpoint...}

---

## 13. Success Criteria

### Pass/Fail Conditions

- [ ] {Criterion}: {Measurable condition} — **Pass**: {what passes} / **Fail**: {what fails}
- [ ] {Criterion}: {Measurable condition} — **Pass**: {what passes} / **Fail**: {what fails}
- [ ] {Criterion}: {Measurable condition} — **Pass**: {what passes} / **Fail**: {what fails}

### Quality Indicators

- {Quality metric}: {Target value}
- {Quality metric}: {Target value}

---

## 14. Implementation Phases

### Phase 1: {Phase Goal}

**Goal**: {One sentence describing what this phase achieves}

**Deliverables**:
- ✅ {Deliverable 1}
- ✅ {Deliverable 2}
- ✅ {Deliverable 3}

**Acceptance Criteria**:
- [ ] {Criterion} — **Pass**: {condition} / **Fail**: {condition}
- [ ] {Criterion} — **Pass**: {condition} / **Fail**: {condition}

**Validation Commands**:
```bash
{command to verify this phase is complete}
```

### Phase 2: {Phase Goal}

**Goal**: {One sentence}

**Deliverables**:
- ✅ {Deliverable 1}
- ✅ {Deliverable 2}

**Acceptance Criteria**:
- [ ] {Criterion} — **Pass**: {condition} / **Fail**: {condition}
- [ ] {Criterion} — **Pass**: {condition} / **Fail**: {condition}

**Validation Commands**:
```bash
{command to verify this phase is complete}
```

{Continue for 3-5 phases...}

---

## 15. Future Considerations

Post-MVP enhancements to consider:

1. **{Enhancement}**: {Description and value}
2. **{Enhancement}**: {Description and value}
3. **{Enhancement}**: {Description and value}

---

## 16. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| {risk description} | {Low/Medium/High} | {Low/Medium/High} | {mitigation strategy} |
| {risk description} | {Low/Medium/High} | {Low/Medium/High} | {mitigation strategy} |
| {risk description} | {Low/Medium/High} | {Low/Medium/High} | {mitigation strategy} |

---

## 17. Appendix

### Key Dependencies

| Dependency | Version | Documentation |
|-----------|---------|---------------|
| {package} | {version} | [{docs link}]({url}) |
| {package} | {version} | [{docs link}]({url}) |

### Reference Implementations

- [{Reference name}]({url}) — {What to learn from it}

---

**Clarity Score**: {score}/100
**Clarification Rounds**: {count}
**Created**: {timestamp}
**Document Version**: {version}
