---
description: "Initialize project from PRD — scaffold, install deps, configure tooling"
---

# Initialize Project from PRD

## Prerequisites

- `PRD.md` must exist in project root (created by `/create-prd`)

## Steps

### 1. Read PRD

Read `PRD.md` and extract:
- **Technology Stack** (Section 8) — languages, frameworks, versions
- **Directory Structure** (Section 6) — intended project layout
- **Dependencies** — all packages/libraries listed
- **Security & Configuration** (Section 9) — environment variables needed
- **Data Model** (Section 10) — database type and schema

### 2. Detect Project Type & Scaffold

Based on the PRD tech stack, run the appropriate scaffolding tool:

| Stack | Scaffold Command |
|-------|-----------------|
| Next.js | `npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"` |
| React + Vite | `npm create vite@latest . -- --template react-ts` |
| Vue + Vite | `npm create vite@latest . -- --template vue-ts` |
| Svelte | `npm create svelte@latest .` |
| Express/Node | `npm init -y` + manual setup |
| FastAPI | `uv init` or `poetry new .` |
| Django | `django-admin startproject {name} .` |
| Flask | `uv init` or `poetry new .` |
| Rust | `cargo init .` |
| Go | `go mod init {module-name}` |
| Ruby/Rails | `rails new . --api` (or full) |

**No assumptions** — scaffold choice is driven entirely by the PRD tech stack section. If the PRD specifies a non-standard setup, follow its instructions.

### 3. Create Directory Structure

Create the directory structure specified in the PRD's Core Architecture section. Create any directories that the scaffold didn't already create.

### 4. Install Dependencies

Install all dependencies listed in the PRD:
- **Node.js**: `npm install` / `pnpm install` / `yarn install` / `bun install`
- **Python**: `uv sync` / `pip install -r requirements.txt` / `poetry install`
- **Rust**: `cargo build` (fetches deps)
- **Go**: `go mod tidy`
- **Other**: follow package manager conventions for the stack

### 5. Setup Dev Tooling

Configure based on what the PRD specifies (or sensible defaults for the stack):
- **Linter**: ESLint, Ruff, clippy, golangci-lint, etc.
- **Formatter**: Prettier, Black, rustfmt, gofmt, etc.
- **Test framework**: Jest/Vitest, pytest, cargo test, go test, etc.
- Create config files if the scaffold didn't (`.eslintrc`, `ruff.toml`, etc.)

### 6. Create .env.example

From the PRD Security & Configuration section, create `.env.example` with all required environment variables:
```
# {Variable description}
{VAR_NAME}={example_value}
```

Also create `.env` as a copy of `.env.example` for local development (add `.env` to `.gitignore` if not already there).

### 7. Initialize Git

If not already a git repo:
```bash
git init
```

Ensure `.gitignore` is appropriate for the tech stack. Add common ignores:
- Language-specific build artifacts
- `node_modules/`, `__pycache__/`, `target/`, etc.
- `.env` (but NOT `.env.example`)
- OS files (`.DS_Store`, `Thumbs.db`)

Create initial commit:
```bash
git add -A
git commit -m "chore: initialize project from PRD"
```

### 8. Remote Repository (ask user)

Ask the user if they want to create a GitHub remote:
- If yes: `gh repo create {project-name} --private --source=. --push`
- If no: skip

### 9. Validate Setup

Run these checks to verify everything works:

1. **Dev server starts** (if applicable):
   - Start the dev server, wait for it to be ready, then stop it
   - Record the URL and port

2. **Linter passes**:
   - Run the linter command — should pass with zero errors on scaffolded code

3. **Test harness works**:
   - Run the test command — should succeed even with zero tests (or with scaffold's default tests)

4. **Build succeeds** (if applicable):
   - Run the build command — should produce output without errors

### 10. Report

```
## Project Initialized

**Tech Stack**: {summary}
**Scaffold**: {what was used}
**Dependencies**: {count} packages installed
**Dev Server**: {url}:{port}
**Linter**: {tool} — passing
**Tests**: {framework} — harness ready
**Git**: initialized with initial commit

**Files created**:
- .env.example
- {config files}
- {directory structure}

Next step: `/create-rules` to generate CLAUDE.md
```
