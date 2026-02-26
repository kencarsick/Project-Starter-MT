---
description: "Analyze codebase and generate CLAUDE.md project rules"
---

# Generate CLAUDE.md from Codebase Analysis

Create a `CLAUDE.md` file that gives Claude full context about this project's conventions, patterns, and structure.

## Phase 1: DISCOVER

### Detect Project Type

Check for these config files to determine project type:

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

### Map Structure

```bash
# Get directory structure (3 levels deep, excluding common noise)
find . -maxdepth 3 -type d \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/venv/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/target/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  | head -50
```

### Identify Framework

Look inside config files for framework indicators:
- **Next.js**: `next` in package.json dependencies
- **React**: `react` in package.json
- **Vue**: `vue` in package.json
- **Django**: `django` in requirements/pyproject
- **FastAPI**: `fastapi` in requirements/pyproject
- **Flask**: `flask` in requirements/pyproject
- **Express**: `express` in package.json
- **Rails**: `rails` in Gemfile
- **Actix/Axum/Rocket**: in Cargo.toml dependencies
- **Gin/Echo/Fiber**: in go.mod

## Phase 2: ANALYZE

### Extract Tech Stack

From config files, extract:
- Languages and versions
- Frameworks and versions
- Database(s) used
- Key libraries and their purposes
- Dev tools (linter, formatter, test framework)

### Study Patterns

Search the codebase for:
- **Naming conventions**: are files `camelCase`, `snake_case`, `kebab-case`, `PascalCase`?
- **File organization**: flat, nested by feature, nested by type?
- **Error handling**: try/catch, Result types, error middleware, custom error classes?
- **Type usage**: strict TypeScript, Python type hints, Go interfaces?
- **Test patterns**: what framework, where do tests live, naming convention?
- **Import patterns**: absolute vs relative, barrel exports?

### Find Key Files

Identify:
- Entry points (main.py, index.ts, main.go, etc.)
- Config files (env, yaml, toml, json)
- Core business logic files
- Router/API definitions
- Database models/schemas

## Phase 3: GENERATE

Read the template at `.claude/templates/CLAUDE-template.md`.

Fill in all `{placeholder}` values with discovered information:
- Replace `{Project description and purpose}` with actual project description (from README or package.json)
- Replace `{tech}` / `{why it's used}` with actual tech stack
- Replace `{dev-command}`, `{build-command}`, etc. with actual commands from config
- Replace `{root}/` directory structure with actual structure
- Fill in architecture description based on observed patterns
- Fill in code patterns based on analysis
- Fill in testing section based on test framework discovery
- Fill in key files based on analysis

### Adapt Sections

- **Remove** sections that don't apply (e.g., no "On-Demand Context" if there are no reference docs)
- **Add** project-type-specific sections:
  - Web app → API endpoints, component patterns
  - Backend → database patterns, middleware
  - Library → public API, usage examples
  - CLI → command structure, argument patterns

## Phase 4: OUTPUT

1. **Write** `CLAUDE.md` to project root
2. **Commit**: `git add CLAUDE.md && git commit -m "docs: generate CLAUDE.md from codebase analysis"`
3. **Report** what was discovered:
   ```
   ## CLAUDE.md Generated

   **Project Type**: {type}
   **Tech Stack**: {stack summary}
   **Structure**: {pattern detected}
   **Key Patterns**: {conventions found}

   Written to: ./CLAUDE.md
   Next step: /plan-feature or /ship
   ```
