---
description: "Initialize project from PRD — scaffold, install deps, configure tooling, generate CLAUDE.md + AGENTS.md"
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
- **Data Model** (Section 11) — database type and schema

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
git commit -m "chore: scaffold project from PRD"
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

### 10. Generate CLAUDE.md

Now that the project is scaffolded and validated, analyze the codebase and generate CLAUDE.md.

#### 10a. Discover

**Detect project type** from config files:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `pyproject.toml` or `requirements.txt` or `setup.py` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml` or `build.gradle` | Java / Kotlin |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `Package.swift` | Swift |
| `*.csproj` or `*.sln` | C# / .NET |
| `Makefile` (alone) | C / C++ |
| `deno.json` | Deno |
| `bun.lockb` | Bun |

**Map directory structure** (3 levels deep, excluding `node_modules`, `.git`, `venv`, `__pycache__`, `target`, `.next`, `dist`, `build`).

**Identify framework** from dependency declarations:
- Next.js, React, Vue, Svelte, Angular (frontend)
- Django, FastAPI, Flask, Express, Rails, Gin, Actix, Axum (backend)

#### 10b. Analyze

**Extract tech stack** from config files:
- Languages and versions
- Frameworks and versions
- Database(s) used
- Key libraries and their purposes
- Dev tools (linter, formatter, test framework)

**Study patterns**:
- **Naming conventions**: camelCase, snake_case, kebab-case, PascalCase
- **File organization**: flat, nested by feature, nested by type
- **Error handling**: try/catch, Result types, error middleware, custom error classes
- **Type usage**: strict TypeScript, Python type hints, Go interfaces
- **Test patterns**: framework, location, naming convention
- **Import patterns**: absolute vs relative, barrel exports

**Find key files**:
- Entry points (main.py, index.ts, main.go, etc.)
- Config files (env, yaml, toml, json)
- Core business logic files
- Router/API definitions
- Database models/schemas

#### 10c. Generate

Read `.claude/templates/CLAUDE-template.md`.

Fill all `{placeholder}` values with discovered information:
- `{Project description and purpose}` — from PRD Section 1 (Executive Summary) or README
- `{tech}` / `{why it's used}` — from actual tech stack discovered
- `{dev-command}`, `{build-command}`, `{test-command}`, `{lint-command}` — from actual config
- `{root}/` directory structure — from actual structure
- Architecture description — from observed patterns and PRD Section 6
- Code patterns — from analysis
- Testing section — from test framework discovery
- Key files — from analysis
- Validation commands — from discovered build/test/lint commands
- Deployment section — from PRD Section 9, or `"N/A"` if no deployment target specified

**Adapt sections**:
- **Remove** sections that don't apply (e.g., no "On-Demand Context" if no reference docs)
- **Add** project-type-specific sections:
  - Web app → API endpoints, component patterns
  - Backend → database patterns, middleware
  - Library → public API, usage examples
  - CLI → command structure, argument patterns

Write `CLAUDE.md` to project root.

### 11. Generate AGENTS.md

Read `.claude/templates/AGENTS-template.md`.

Fill all placeholder values with project-specific information extracted during Step 10:

- `{tech_stack_summary}` — from the tech stack analysis (e.g., "Next.js 14 + TypeScript + Tailwind CSS + PostgreSQL")
- `{dev_command}` — from discovered dev server command (e.g., `npm run dev`)
- `{build_command}` — from discovered build command (e.g., `npm run build`)
- `{test_command}` — from discovered test command (e.g., `npm test`)
- `{lint_command}` — from discovered lint command (e.g., `npm run lint`)
- `{architecture_notes}` — from architecture analysis (e.g., "App Router with server components, API routes in /app/api/, Prisma ORM for database access")
- `{special_constraints}` — from PRD Security section + any project-specific constraints (e.g., "All API routes require authentication middleware. Database migrations must be run before tests.")

Write `AGENTS.md` to project root.

### 12. Copy Pipeline Infrastructure

Copy the multi-agent pipeline system into the project so it can run `impl.sh` autonomously.

**Copy these from the Project Starter source:**

1. **`scripts/`** — all top-level scripts and the `lib/` directory:
   ```bash
   cp -r /path/to/project-starter/scripts/ scripts/
   chmod +x scripts/*.sh
   ```

2. **`.claude/workflow.yaml`** — pipeline configuration with sensible defaults:
   ```yaml
   pipeline:
     stages:
       - orchestrator
       - dev
       - qa
       - merge
       - prod-qa
     max_retries: 3
     max_turns_per_agent: 200

   tmux:
     layout: tiled

   notifications:
     enabled: true
     sound: default

   worktree:
     base_dir: .worktrees
     lock_timeout: 60
     symlink_candidates:
       - node_modules
       - .env
       - browser-data

   github:
     labels:
       in_progress: "agent:in-progress"
       blocked: "agent:blocked"
       needs_human: "agent:needs-human"

   sentinel:
     poll_interval: 5

   prod_url: ""
   ```

3. **`.claude/agents/`** — all 5 agent role definitions (orchestrator.md, dev-agent.md, qa-agent.md, merge-agent.md, prod-qa-agent.md)

4. **`.claude/skills/`** — all reusable capabilities (agent-browser, agent-learnings, e2e-test, question-bank, requirements-clarity)

5. **`.claude/settings.local.json`** — restricted permissions for the orchestrator session

6. **`.claude/templates/`** — document templates (CLAUDE-template.md, AGENTS-template.md, PRD-template.md, plan-template.md)

**Note**: If `/path/to/project-starter/` is not available (e.g., the user doesn't have the Project Starter repo locally), generate the `scripts/` directory and `workflow.yaml` inline using the canonical versions from this repository. The agent definitions and skills are already in `.claude/` from the current session.

### 13. Final Commit + Report

Commit the generated documentation and pipeline infrastructure:
```bash
git add CLAUDE.md AGENTS.md scripts/ .claude/workflow.yaml .claude/agents/ .claude/skills/ .claude/settings.local.json .claude/templates/
git commit -m "chore: add CLAUDE.md, AGENTS.md, and pipeline infrastructure"
```

If a remote was created in Step 8, push:
```bash
git push
```

Report:

```
## Project Initialized

**Tech Stack**: {summary}
**Scaffold**: {what was used}
**Dependencies**: {count} packages installed
**Dev Server**: {url}:{port}
**Linter**: {tool} — passing
**Tests**: {framework} — harness ready
**Build**: passing
**Git**: initialized with initial commit
**CLAUDE.md**: generated from codebase analysis
**AGENTS.md**: generated with project-specific agent rules
**Pipeline**: scripts/ + workflow.yaml + agents + skills copied

**Files created**:
- CLAUDE.md
- AGENTS.md
- .env.example
- scripts/ (impl.sh, run-all.sh, setup.sh, status.sh, login.sh, lib/)
- .claude/workflow.yaml
- .claude/agents/ (5 agent roles)
- .claude/skills/ (5 capabilities)
- .claude/settings.local.json
- {config files}
- {directory structure}

Next step: `./scripts/setup.sh` to verify prerequisites, then `./scripts/impl.sh '#<issue-number>'` to implement the first phase
```
