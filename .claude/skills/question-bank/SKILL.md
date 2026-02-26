---
name: question-bank
description: Structured question categories (A-G) for PRD interrogation. Provides multiple-choice format for fast user responses.
---

# PRD Question Bank

Answer every section that applies. If something is unknown, label it **ASSUMPTION** and specify a default.

## Format Rule (required)

For every decision question, provide options using this format so users can answer quickly like `1a, 2c, 3b (+ note...)`:

```
1. The question (what decision we are making)
   a) Option A (Recommended) — why recommended
   b) Option B — tradeoff
   c) Option C — tradeoff
   d) Other — user free-form
```

Ask 2-4 questions per round. Target highest-impact gaps first.

---

## A) Problem & Stakes (required — always ask)

Establish WHY this project exists before anything else.

- What does the user/system observe today? (1 sentence)
- Why is that a problem? (impact/risk, 1 sentence)
- What is the goal? (WHY + expected behavior)
- What happens if we do nothing for 30 days?
- What is explicitly out of scope?

**Key question patterns:**
```
1. What is the core problem this solves?
   a) {Specific problem A based on user's idea}
   b) {Alternative framing B}
   c) {Broader/narrower framing C}
   d) Other — describe in your own words

2. Who feels this pain most?
   a) {User type A} — {why}
   b) {User type B} — {why}
   c) Both equally
   d) Other
```

---

## B) Success Definition (required — always ask)

Define what "done" looks like with pass/fail criteria.

- What are the pass/fail acceptance criteria? (bullet list)
  - Include at least one negative test ("should NOT...")
- What is the required proof plan? (commands + expected outputs)
- What artifacts are produced? (files/paths, dashboards, reports)

**Key question patterns:**
```
1. How do we know this is working correctly?
   a) {Specific test A} passes
   b) {Observable behavior B} is visible
   c) {Metric C} reaches target
   d) Other

2. What should this explicitly NOT do?
   a) {Negative constraint A}
   b) {Negative constraint B}
   c) Both of the above
   d) Other
```

---

## C) Scope Boundaries (required — always ask)

Draw clear lines around what changes and what doesn't.

- What must NOT change? (explicit "do-not-change" list)
  - Examples: production configuration, historical data, existing API contracts, schema constraints
- What is allowed to change?
- What is a hard requirement vs. a nice-to-have?

**Key question patterns:**
```
1. Which existing systems should this NOT touch?
   a) {System A} — it's stable and unrelated
   b) {System B} — it has external dependencies
   c) None — greenfield project
   d) Other

2. What is the minimum viable version?
   a) {Minimal scope A} — core feature only
   b) {Medium scope B} — core + one enhancement
   c) {Full scope C} — everything described
   d) Other
```

---

## D) Data Model (required if persistence/data — skip if no storage needed)

Define what data exists, how it's structured, and how it flows.

- What data entities exist? (list with key fields)
- What are the relationships between entities?
- What are the required fields vs. optional fields? (explicit list, no "examples")
- What is the data lifecycle? (created when, updated when, deleted when)
- Time handling: UTC vs local, date vs datetime semantics
- What are the storage requirements? (DB type, estimated volume)

**Key question patterns:**
```
1. What is the primary data entity?
   a) {Entity A with key fields}
   b) {Entity B with key fields}
   c) Multiple entities: {list}
   d) Other

2. How much data do we expect?
   a) Small (< 10K records) — SQLite/simple storage is fine
   b) Medium (10K-1M) — need indexed DB
   c) Large (1M+) — need optimized queries and caching
   d) Other
```

---

## E) Failure Modes & Safety (required — always ask)

Identify what can go wrong and how to handle it.

- What can go wrong? (rate limits, partial runs, retries, data corruption, network failures)
- What is the safe testing/dry-run plan? (sample size, what gets logged, how we verify no damage)
- What is the rollback plan? (how to revert safely, how to re-run idempotently)
- What are the security boundaries? (auth required? data sensitivity? PII?)

**Key question patterns:**
```
1. What is the worst thing that could happen if this has a bug?
   a) {Low impact} — user sees an error, retries
   b) {Medium impact} — data is incorrect but recoverable
   c) {High impact} — data loss or security breach
   d) Other

2. How should errors be handled?
   a) Fail fast — show error, stop processing
   b) Graceful degradation — partial results, log warning
   c) Retry with backoff — transient failures expected
   d) Other
```

---

## F) Technology Preferences (required — always ask)

Establish the technical foundation.

- Programming language(s)?
- Framework(s)?
- Database/storage?
- Hosting/deployment target?
- CI/CD approach?
- Testing framework?
- Package manager?
- Linter/formatter?

**Key question patterns:**
```
1. What is the primary language/framework?
   a) {Option A} (Recommended for this use case) — {reason}
   b) {Option B} — {tradeoff}
   c) {Option C} — {tradeoff}
   d) Other — specify

2. Where will this be deployed?
   a) Vercel/Netlify — serverless, auto-deploy from git
   b) AWS/GCP/Azure — more control, more setup
   c) Self-hosted/Docker — full control
   d) Other / not decided yet
```

---

## G) User Experience (required if user-facing — skip for CLI tools, libraries, backend-only)

Define how users interact with the application.

- What are the key user interactions? (list the main flows)
- What does the UI look like? (wireframe description, reference apps, design system)
- Accessibility requirements? (WCAG level, screen reader support)
- Responsive requirements? (mobile, tablet, desktop breakpoints)
- Design system or component library preference?

**Key question patterns:**
```
1. What is the most important user interaction?
   a) {Flow A} — {description}
   b) {Flow B} — {description}
   c) {Flow C} — {description}
   d) Other

2. What should it look like?
   a) Clean/minimal — like {reference app}
   b) Feature-rich dashboard — like {reference app}
   c) Mobile-first — like {reference app}
   d) Other / I'll provide designs
```

---

## Applicability Rules

| Category | When to Ask |
|----------|-------------|
| A) Problem & Stakes | Always |
| B) Success Definition | Always |
| C) Scope Boundaries | Always |
| D) Data Model | Only if the project involves persistence, storage, or data processing |
| E) Failure Modes & Safety | Always |
| F) Technology Preferences | Always |
| G) User Experience | Only if the project has a user-facing interface (web app, mobile app, desktop app) |

## ASSUMPTION Labeling

When a question has no answer from the user, label it:

```
**ASSUMPTION**: {assumption text} (default: {default value})
```

Assumptions are NOT requirements. They must be confirmed or overridden before PRD generation.
