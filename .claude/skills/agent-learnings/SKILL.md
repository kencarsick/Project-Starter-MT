---
name: agent-learnings
description: Log durable agent learnings as JSON entries for reuse across tasks. Captures institutional knowledge — owner preferences, decision patterns, architecture rationale, and hard-won lessons.
---

# Agent Learnings

Use this skill whenever you discover durable institutional knowledge while working on this project.

## Core Rules (must follow)

- **Log immediately on discovery** — do not wait until the end of the task.
- **Institutional value only** — capture owner preferences, decision patterns, architecture rationale, and hard-won lessons.
- **Quality over volume** — **1 good preference > 5 CLI gotchas**.
- **Soft cap** — aim for **~5 entries per TASK**. If you need more, consolidate.
- **Promote when universal** — if a learning applies project-wide, consider adding it to `CLAUDE.md` instead.

## Where to Write

- Create a new `*.json` file under: `.claude/learnings/`.
- Use a short, unique filename: `{timestamp}-{topic}.json` (e.g., `20260226-auth-pattern.json`).

## Required JSON Fields

```json
{
  "ts_utc": "2026-02-26T18:12:34Z",
  "category": "owner-preference|decision-pattern|architecture|workflow|anti-pattern|technical-gotcha",
  "text": "2-5 lines. Explain the insight, why it matters, and the preferred action."
}
```

### Categories

| Category | What to Capture |
|----------|----------------|
| `owner-preference` | How the user likes things done (diff size, review style, naming) |
| `decision-pattern` | Recurring choice patterns (visible vs hidden, simple vs flexible) |
| `architecture` | Structural decisions and rationale (why X over Y) |
| `workflow` | Process insights (what order works, what to skip) |
| `anti-pattern` | Things that failed or should be avoided (with reason) |
| `technical-gotcha` | Non-obvious technical traps (library quirks, env issues) |

### Optional Fields

- `issue`: issue link or ID (for traceability)
- `pointers`: array of strings (file paths, commands, PR/issue links)

## Good Entry Examples

```json
{
  "ts_utc": "2026-02-07T11:00:00Z",
  "category": "owner-preference",
  "text": "Owner prefers the smallest safe diff that proves behavior end-to-end.\nWhen a change can be split, ship the risk-reducing piece first.\nThis keeps review latency low and rollback simple."
}
```

```json
{
  "ts_utc": "2026-02-07T11:05:00Z",
  "category": "decision-pattern",
  "text": "When choosing between hidden script filters vs a visible, shareable query (view/dashboard), default to the visible option.\nIt makes state understandable to humans and reduces magic.\nUse script filters only for narrow per-run constraints."
}
```

```json
{
  "ts_utc": "2026-02-07T11:10:00Z",
  "category": "anti-pattern",
  "text": "Do not mutate historical inputs that would change past results.\nIf a previous run exists, prefer creating a new variant/version instead.\nThis preserves auditability and makes rollbacks possible.",
  "pointers": ["src/pipeline/runner.py", "docs/data-integrity.md"]
}
```

## Validation

Validate JSON with a quick check:
```bash
python3 -m json.tool <file>
# or
jq . <file>
```
