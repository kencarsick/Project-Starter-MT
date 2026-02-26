---
description: "Create atomic git commit with conventional tags and push to feature branch"
---

# Git Commit

## Steps

1. **Review changes**:
   ```bash
   git status
   git diff HEAD
   git status --porcelain
   ```

2. **Stage files**: Add untracked and changed files relevant to current work. Exclude:
   - `.env` and `.env.*` (secrets)
   - Credentials, API keys, tokens
   - Large binary files
   - OS files (`.DS_Store`, `Thumbs.db`)

3. **Determine commit tag** based on the nature of changes:
   - `feat` — new feature or capability
   - `fix` — bug fix
   - `docs` — documentation only
   - `refactor` — code restructuring without behavior change
   - `test` — adding or updating tests
   - `chore` — maintenance, deps, tooling

4. **Create commit** with descriptive message:
   ```
   {tag}: {concise description of what changed and why}
   ```

5. **Push to current branch** (if on a feature branch, not main):
   ```bash
   git push origin HEAD
   ```

## Rules

- One commit per logical change (atomic commits)
- Message describes the "what" and "why", not the "how"
- Never commit secrets, credentials, or .env files
- If on `main` branch, warn before pushing and suggest creating a feature branch instead
