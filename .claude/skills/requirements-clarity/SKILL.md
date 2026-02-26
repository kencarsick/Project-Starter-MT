---
name: requirements-clarity
description: Scores requirement clarity 0-100 across 4 dimensions. Used by create-prd to drive structured interrogation until clarity reaches 90+.
---

# Requirements Clarity Scoring

## Purpose

Score the clarity of a requirement or project idea on a 0-100 scale. Used to determine when a PRD is ready for generation (threshold: 90/100).

## Scoring Rubric

```
TOTAL: /100 points

Functional Clarity: /30 points
├── Clear inputs/outputs defined:     /10
├── User interaction flow defined:    /10
└── Success criteria stated:          /10

Technical Specificity: /25 points
├── Technology stack specified:        /8
├── Integration points identified:     /8
└── Constraints specified:             /9

Implementation Completeness: /25 points
├── Edge cases considered:             /8
├── Error handling mentioned:          /9
└── Data validation specified:         /8

Business Context: /20 points
├── Problem statement clear:           /7
├── Target users identified:           /7
└── Success metrics defined:           /6
```

## Gap Analysis Dimensions

After scoring, analyze gaps across these 4 dimensions:

1. **Functional Scope** — What is the core functionality? What are the boundaries? What is out of scope? What are edge cases?
2. **User Interaction** — How do users interact? What are inputs/outputs? What are success/failure scenarios?
3. **Technical Constraints** — Performance requirements? Compatibility? Security considerations? Scalability?
4. **Business Value** — What problem does this solve? Who are the target users? What are success metrics?

## Anti-Vagueness Detection

Auto-flag these words when used without measurable criteria:

- "works" — works HOW? What is the expected behavior?
- "robust" — what failure modes does it handle?
- "fast" — what is the target latency/throughput?
- "better" — better than what? By what measure?
- "handle" — handle what cases, specifically?
- "should" — under what conditions? What if it doesn't?
- "fix" — fix what symptom? What is the root cause?
- "improve" — improve what metric? By how much?
- "scalable" — to what scale? What is the target?
- "secure" — against what threats? To what standard?

When detected: re-ask the question with a request for specific, measurable criteria.

## Score Reporting Format

### Initial Score

```markdown
**Current Clarity Score**: X/100

**Breakdown**:
- Functional Clarity: X/30
- Technical Specificity: X/25
- Implementation Completeness: X/25
- Business Context: X/20

**Clear Aspects**:
- {What is already well-defined}

**Needs Clarification**:
- {Highest-impact gaps, in priority order}
```

### Score Update (after each round)

```markdown
**Clarity Score Update**: X/100 → Y/100 (+Z)

**Breakdown**:
- Functional Clarity: X/30 → Y/30
- Technical Specificity: X/25 → Y/25
- Implementation Completeness: X/25 → Y/25
- Business Context: X/20 → Y/20

**Newly Clarified**:
- {Summary of new information}

**Remaining Gaps** (if score < 90):
- {Gaps in priority order}
```

## Behavioral Guidelines

### DO
- Ask 2-3 questions per round (not more)
- Target highest-impact gaps first
- Build context progressively across rounds
- Use user's language and terminology
- Provide examples when helpful
- Flag vague language immediately with specific alternatives

### DON'T
- Ask all questions at once
- Make assumptions without confirmation
- Proceed to PRD generation before score reaches 90
- Skip any scoring dimension
- Accept vague language without measurable criteria

## Threshold

- **< 50**: Barely an idea — need fundamental clarity on problem, users, and scope
- **50-69**: Partial understanding — significant gaps in implementation or technical details
- **70-89**: Almost there — missing specific constraints, edge cases, or acceptance criteria
- **>= 90**: Ready for PRD generation — all dimensions adequately covered
