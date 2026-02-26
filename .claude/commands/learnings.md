---
description: "Capture or review institutional knowledge from development sessions"
argument-hint: "[capture|review]"
---

# Institutional Learnings

## Mode: $ARGUMENTS

Determine mode from arguments. Default to `capture` if no argument provided.

---

## Capture Mode (`/learnings capture` or `/learnings`)

Log a new insight using the `agent-learnings` skill.

### Steps

1. **Read** `.claude/skills/agent-learnings/SKILL.md` for the JSON format and rules
2. **Identify** the insight to capture — what was learned, why it matters, what to do differently
3. **Categorize** using one of: `owner-preference`, `decision-pattern`, `architecture`, `workflow`, `anti-pattern`, `technical-gotcha`
4. **Write** a new JSON file to `.claude/learnings/{timestamp}-{topic}.json`
5. **Validate** the JSON: `python3 -m json.tool .claude/learnings/{filename}` or `jq . .claude/learnings/{filename}`
6. **Consider promotion**: if the learning is universally applicable to this project, suggest adding it to `CLAUDE.md`

### Quality Rules

- Quality > volume — 1 good insight > 5 trivial ones
- 2-5 lines of text explaining insight, why it matters, and preferred action
- Include `pointers` (file paths, commands) when relevant
- Log immediately on discovery, don't batch

---

## Review Mode (`/learnings review`)

Summarize and analyze all captured learnings.

### Steps

1. **Read all** JSON files in `.claude/learnings/`
2. **Group by category**:
   - Owner Preferences
   - Decision Patterns
   - Architecture
   - Workflow
   - Anti-Patterns
   - Technical Gotchas
3. **Present summary** with key insights per category
4. **Identify promotions**: which learnings should become `CLAUDE.md` rules?
5. **Identify conflicts**: any learnings that contradict each other?
6. **Suggest cleanup**: any learnings that are outdated or superseded?

### Output Format

```markdown
## Learnings Review

**Total entries**: {count}
**Categories**: {breakdown}

### Owner Preferences ({count})
- {Summary of key preferences}

### Decision Patterns ({count})
- {Summary of key patterns}

### Architecture ({count})
- {Summary of key decisions}

### Workflow ({count})
- {Summary of key process insights}

### Anti-Patterns ({count})
- {Summary of things to avoid}

### Technical Gotchas ({count})
- {Summary of non-obvious traps}

### Recommended CLAUDE.md Promotions
- {Learning} → suggested CLAUDE.md section: {section}

### Conflicts / Outdated
- {Any issues found}
```
