---
description: "Implement a GitHub issue — spawn 5-agent pipeline: Orchestrator → Dev → QA → Merge → Prod-QA"
argument-hint: "#<issue-number>"
---

# Implement Issue — Multi-Agent Pipeline

## Input

`$ARGUMENTS` — a GitHub issue number (e.g., `#42` or `42`).

Parse the issue number by stripping any `#` prefix.

---

## Step 1: Preflight Checks

Run all checks before creating any resources. Abort on the first failure.

### 1a. Verify tools

```bash
which claude || echo "FAIL: claude CLI not found"
gh auth status || echo "FAIL: gh CLI not authenticated"
```

### 1a2. Detect tmux

Tmux mode is **on by default**. Check if disabled:
1. If environment variable `IMPL_TMUX=0` is set, or
2. If the user passes `--no-tmux` as part of `$ARGUMENTS`

If tmux mode is enabled (default):
```bash
which tmux || echo "FAIL: tmux not found but IMPL_TMUX=1"
```

Create the tmux session for this pipeline run:
```bash
SESSION_NAME="impl-issue-<N>"
tmux new-session -d -s "$SESSION_NAME" -n "pipeline"
```

The first window (`pipeline`) shows the orchestrator's `/impl` status output. Each agent gets its own named window.

### 1b. Verify project files

Check that `CLAUDE.md` and `AGENTS.md` exist in the project root. If either is missing, abort:
> "Missing {file}. Run `/init-project` first."

### 1c. Clean working tree

```bash
git status --porcelain
```
If output is non-empty, abort:
> "Working tree is not clean. Commit or stash changes before running `/impl`."

Verify current branch is `main`:
```bash
git branch --show-current
```
If not `main`, abort:
> "Must be on `main` branch. Currently on `{branch}`."

### 1d. Fetch latest

```bash
git fetch origin main
```

### 1e. Resolve repo identifier

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
```

### 1f. Verify issue exists

```bash
gh issue view <N> --repo "$REPO" --json title,body,state
```
If the issue doesn't exist or is closed, abort:
> "Issue #<N> not found or already closed."

### 1g. Resolve PROD_URL

Check in order:
1. Environment variable `$PROD_URL`
2. Parse `CLAUDE.md` for the `## Deployment` section — extract the **Production URL** value
3. Default to empty string (Prod-QA will be skipped)

Store the resolved value as `PROD_URL`.

---

## Step 2: Create Worktree

```bash
git worktree add -b issue-<N> .worktrees/issue-<N> origin/main
```

If the worktree already exists (from a previous failed run):
1. Ask the user: **Reuse existing worktree or remove and recreate?**
   - Reuse: skip creation, continue with existing worktree
   - Recreate: `git worktree remove .worktrees/issue-<N> --force && git branch -D issue-<N>`, then create fresh

Create the sentinel file directory:
```bash
mkdir -p .worktrees/issue-<N>/.claude-workflow
```

Symlink environment files (if they exist in the project root):
```bash
[ -f .env ] && ln -sf "$(pwd)/.env" .worktrees/issue-<N>/.env
```

Store the absolute worktree path:
```bash
WORKTREE_PATH="$(cd .worktrees/issue-<N> && pwd)"
```

---

## Step 3: Token Substitution Helper

Before each agent invocation, read the agent's system prompt file and substitute all placeholder tokens:

| Token | Value |
|-------|-------|
| `__ISSUE_NUM__` | The issue number (e.g., `42`) |
| `__WORKTREE_PATH__` | Absolute path to the worktree |
| `__REPO__` | GitHub repo in `owner/repo` format |
| `__PROD_URL__` | Production URL or empty string |
| `__QA_REPORT__` | Empty string on first Dev run; contents of `qa.report` on retry |

Substitution command pattern:
```bash
AGENT_PROMPT=$(cat .claude/agents/<agent>.md \
  | sed "s|__ISSUE_NUM__|<N>|g" \
  | sed "s|__WORKTREE_PATH__|$WORKTREE_PATH|g" \
  | sed "s|__REPO__|$REPO|g" \
  | sed "s|__PROD_URL__|$PROD_URL|g" \
  | sed "s|__QA_REPORT__|$QA_REPORT_CONTENT|g")
```

Agent invocation pattern:

**Important**: Claude Code blocks nested sessions by default. All `claude -p` invocations MUST unset the `CLAUDECODE` environment variable:

**Without tmux**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "<task-specific prompt>" \
  --system-prompt "$AGENT_PROMPT" \
  -C "$WORKTREE_PATH"
```

**With tmux** (default):
```bash
WINDOW_NAME="<agent-role>"  # e.g., "orchestrator", "dev", "qa", "merge", "prod-qa"
tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME"
tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME" \
  "unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p '<task-specific prompt>' --system-prompt \"\$AGENT_PROMPT\" -C \"$WORKTREE_PATH\"; exit" Enter
```

Then wait for the agent to finish by polling for the sentinel file:
```bash
while [ ! -f "$WORKTREE_PATH/.claude-workflow/<agent-role>.done" ]; do
  sleep 5
done
```

This gives each agent its own visible tmux window. The user can attach to the session to watch all agents:
```bash
tmux attach -t impl-issue-<N>
```

Use `Ctrl-b n` / `Ctrl-b p` to switch between agent windows.

If the command exits with a non-zero status (timeout or crash), treat as STUCK — write the appropriate `.done` sentinel and proceed to failure handling.

---

## Step 4: Run Pipeline

Initialize the retry counter:
```
RETRY_COUNT=0
MAX_RETRIES=${AGENT_MAX_RETRIES:-3}
QA_REPORT_CONTENT=""
```

### Stage 1: Orchestrator

**Invoke**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "Read GitHub issue #<N> and create an implementation plan. Follow your system prompt instructions exactly." \
  --system-prompt "$ORCHESTRATOR_PROMPT" \
  -C "$WORKTREE_PATH"
```

**Gate** — read `$WORKTREE_PATH/.claude-workflow/orchestrator.done`:

| Value | Action |
|-------|--------|
| `DONE` | Read `orchestrator.report`, display plan summary to user, proceed to Stage 2 |
| `STUCK` | Go to **Failure Escalation** with stage=`orchestrator`, reason from `orchestrator.report` |
| Missing/other | Go to **Failure Escalation** with stage=`orchestrator`, reason=`"Agent exited without writing sentinel file"` |

---

### Stage 2: Dev

**Invoke**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "Implement issue #<N> per the orchestrator plan. Follow your system prompt instructions exactly." \
  --system-prompt "$DEV_PROMPT" \
  -C "$WORKTREE_PATH"
```

On the first run, `__QA_REPORT__` is empty. On retries, it contains the QA fix list.

**Gate** — read `$WORKTREE_PATH/.claude-workflow/dev.done`:

| Value | Action |
|-------|--------|
| `DONE` | Read `dev.report`, display summary, proceed to Stage 3 |
| `STUCK` | Go to **Failure Escalation** with stage=`dev` |
| Missing/other | Go to **Failure Escalation** with stage=`dev`, reason=`"Agent exited without writing sentinel file"` |

---

### Stage 3: QA

**Invoke**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "Verify the implementation for issue #<N>. Follow your system prompt instructions exactly." \
  --system-prompt "$QA_PROMPT" \
  -C "$WORKTREE_PATH"
```

**Gate** — read `$WORKTREE_PATH/.claude-workflow/qa.done`:

| Value | Action |
|-------|--------|
| `PASS` | Display QA report summary, proceed to Stage 4 |
| `PASS-WITH-NITS` | Display QA report + nits, proceed to Stage 4 |
| `FAIL` | Go to **Retry Loop** |
| Missing/other | Go to **Failure Escalation** with stage=`qa`, reason=`"Agent exited without writing sentinel file"` |

#### Retry Loop

1. Increment `RETRY_COUNT`
2. If `RETRY_COUNT >= MAX_RETRIES`: go to **Failure Escalation** with stage=`qa`, reason=`"QA failed after $MAX_RETRIES attempts"`
3. Display to user: `"QA failed (attempt $RETRY_COUNT/$MAX_RETRIES). Retrying Dev with fix list..."`
4. Read `qa.report` content into `QA_REPORT_CONTENT`
5. Remove stale sentinel files:
   ```bash
   rm -f "$WORKTREE_PATH/.claude-workflow/dev.done"
   rm -f "$WORKTREE_PATH/.claude-workflow/dev.report"
   rm -f "$WORKTREE_PATH/.claude-workflow/qa.done"
   rm -f "$WORKTREE_PATH/.claude-workflow/qa.report"
   ```
6. Re-substitute tokens (with updated `__QA_REPORT__`) and go back to **Stage 2: Dev**

---

### Stage 4: Merge

**Invoke**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "Merge the PR for issue #<N>. Follow your system prompt instructions exactly." \
  --system-prompt "$MERGE_PROMPT" \
  -C "$WORKTREE_PATH"
```

**Gate** — read `$WORKTREE_PATH/.claude-workflow/merge.done`:

| Value | Action |
|-------|--------|
| 40-char hex SHA | Merge succeeded. Store `MERGE_SHA`. Proceed to Stage 5. |
| `CI_FAILED` | Go to **Failure Escalation** with stage=`merge`, reason=`"CI checks failed"` |
| `CONFLICT` | Go to **Failure Escalation** with stage=`merge`, reason=`"Merge conflict with main"` |
| `BLOCKED` | Go to **Failure Escalation** with stage=`merge`, reason=`"QA gate not passed"` |
| `NO_PR` | Go to **Failure Escalation** with stage=`merge`, reason=`"No open PR found for branch issue-<N>"` |
| Missing/other | Go to **Failure Escalation** with stage=`merge`, reason=`"Agent exited without writing sentinel file"` |

To detect a SHA: check if the value matches `^[0-9a-f]{40}$`.

---

### Stage 5: Prod-QA (conditional)

**Skip condition**: If `PROD_URL` is empty, skip this stage entirely. Display:
> "Prod-QA skipped — no PROD_URL configured."

**Invoke**:
```bash
unset CLAUDECODE && timeout ${AGENT_TIMEOUT:-600} claude -p \
  "Verify issue #<N> is live in production. Follow your system prompt instructions exactly." \
  --system-prompt "$PROD_QA_PROMPT" \
  -C "$WORKTREE_PATH"
```

**Gate** — read `$WORKTREE_PATH/.claude-workflow/prod-qa.done`:

| Value | Action |
|-------|--------|
| `PASS` | Display verification summary, proceed to **Cleanup** |
| `FAIL` | Go to **Failure Escalation** with stage=`prod-qa`, reason from `prod-qa.report` |
| `DEPLOY_TIMEOUT` | Go to **Failure Escalation** with stage=`prod-qa`, reason=`"Deployment not detected within timeout"` |
| Missing/other | Go to **Failure Escalation** with stage=`prod-qa`, reason=`"Agent exited without writing sentinel file"` |

---

## Step 5: Cleanup (Success Path)

Only reached when all stages pass.

### 5a. Cleanup tmux session (if active)

If tmux mode was enabled:
```bash
tmux kill-session -t "impl-issue-<N>" 2>/dev/null
```

### 5b. Remove worktree

```bash
git worktree remove .worktrees/issue-<N> --force
git branch -d issue-<N> 2>/dev/null
```

### 5c. Capture learnings

Write a JSON learning entry to `.claude/learnings/`:

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > .claude/learnings/${TIMESTAMP}-issue-<N>.json << 'EOF'
{
  "ts_utc": "<timestamp>",
  "category": "pipeline-success",
  "issue": <N>,
  "text": "Issue #<N> completed successfully via autonomous pipeline. Stages: Orchestrator → Dev → QA (attempts: <RETRY_COUNT+1>) → Merge (SHA: <MERGE_SHA>) → Prod-QA (<PASS|skipped>).",
  "pointers": []
}
EOF
```

### 5d. Post final summary to GitHub

```bash
gh issue comment <N> --repo "$REPO" --body "**[impl]** — Issue #<N>

## Pipeline Complete

All stages passed. Issue implemented, reviewed, merged, and verified.

| Stage | Status | Details |
|-------|--------|---------|
| Orchestrator | DONE | Plan created |
| Dev | DONE | Implementation complete |
| QA | $(cat qa.done) | $(if RETRY_COUNT > 0: '$RETRY_COUNT retries' else 'First attempt') |
| Merge | DONE | SHA: \`$MERGE_SHA\` |
| Prod-QA | $(cat prod-qa.done or 'SKIPPED') | $(if PROD_URL: 'Verified at $PROD_URL' else 'No PROD_URL configured') |

**Worktree**: cleaned up
**Total QA attempts**: $((RETRY_COUNT + 1))
"
```

### 5e. Display success report

```
## Implementation Complete — Issue #<N>

**Orchestrator**: Plan created
**Dev**: Implementation complete
**QA**: {PASS|PASS-WITH-NITS} (attempt {RETRY_COUNT+1}/{MAX_RETRIES})
**Merge**: Squash-merged (SHA: {MERGE_SHA})
**Prod-QA**: {PASS|skipped}

**Worktree**: cleaned up
**GitHub**: issue #{N} closed, comments posted at each stage

Pipeline finished successfully.
```

---

## Step 6: Failure Escalation

Reached when any stage fails terminally (STUCK, timeout, max retries, merge failure).

### 6a. Add blocked label

```bash
gh issue edit <N> --repo "$REPO" --add-label "blocked"
```

### 6b. Post failure comment

```bash
gh issue comment <N> --repo "$REPO" --body "**[impl]** — Issue #<N>

## Pipeline Halted

**Stage**: {stage}
**Reason**: {reason}

$(if QA_REPORT_CONTENT is non-empty:)
### Last QA Fix List
$QA_REPORT_CONTENT
$(end if)

### Worktree Preserved

The worktree has been preserved for manual inspection:

\`\`\`bash
cd .worktrees/issue-<N>/
ls .claude-workflow/     # sentinel files
cat .claude-workflow/<stage>.report  # last agent report
\`\`\`

### Recovery Options

1. **Fix manually** and re-run: \`cd .worktrees/issue-<N>/\`, fix the issue, then run \`/impl #<N>\` again
2. **Clean up** the failed worktree: \`git worktree remove .worktrees/issue-<N> --force && git branch -D issue-<N>\`
"
```

### 6c. Preserve worktree

Do NOT remove the worktree on failure. Leave `.worktrees/issue-<N>/` intact for manual inspection.

### 6d. Display failure report

```
## Pipeline Failed — Issue #<N>

**Stage**: {stage}
**Reason**: {reason}
**Worktree**: preserved at .worktrees/issue-<N>/
**GitHub**: failure posted to issue, 'blocked' label added

Review the sentinel files in .worktrees/issue-<N>/.claude-workflow/ for details.
```

---

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `AGENT_TIMEOUT` | `600` (10 min) | Seconds before an agent process is killed |
| `AGENT_MAX_RETRIES` | `3` | Max Dev→QA retry cycles before halting |
| `PROD_URL` | (empty) | Production URL for Prod-QA verification |
| `IMPL_TMUX` | `1` (on) | Set to `0` to run agents headlessly without tmux windows |

---

## Pipeline Diagram

```
/impl #<N>
│
├── Preflight checks
├── Detect tmux (if IMPL_TMUX=1, create session "impl-issue-<N>")
├── Create worktree (.worktrees/issue-<N>/)
│
├── Stage 1: Orchestrator  [tmux window: "orchestrator"]
│   ├── DONE → continue
│   └── STUCK → halt
│
├── Stage 2: Dev (attempt 1)          [tmux window: "dev"]
│   ├── DONE → continue
│   └── STUCK → halt
│
├── Stage 3: QA                        [tmux window: "qa"]
│   ├── PASS / PASS-WITH-NITS → continue
│   └── FAIL → retry (up to MAX_RETRIES)
│       ├── Dev retry (with QA fix list)
│       ├── QA retry
│       └── ... (max 3 cycles)
│           └── All failed → halt
│
├── Stage 4: Merge                     [tmux window: "merge"]
│   ├── SHA → continue
│   └── CI_FAILED / CONFLICT / BLOCKED / NO_PR → halt
│
├── Stage 5: Prod-QA (if PROD_URL set) [tmux window: "prod-qa"]
│   ├── PASS → continue
│   └── FAIL / DEPLOY_TIMEOUT → halt
│
└── Cleanup
    ├── Kill tmux session (if active)
    ├── Remove worktree
    ├── Capture learnings
    ├── Post summary to GitHub
    └── Display success report
```

### tmux Usage

When `IMPL_TMUX=1`, attach to the session from another terminal to watch agents work:

```bash
# Attach to the pipeline session
tmux attach -t impl-issue-<N>

# Navigation
Ctrl-b n    # Next agent window
Ctrl-b p    # Previous agent window
Ctrl-b w    # List all windows
Ctrl-b d    # Detach (pipeline keeps running)
```

Each window is named after its agent role: `pipeline`, `orchestrator`, `dev`, `qa`, `merge`, `prod-qa`.
