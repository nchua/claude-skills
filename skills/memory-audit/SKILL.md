---
name: memory-audit
description: Audits Claude Code memory files for staleness — verifies that file paths, function names, code patterns, and API endpoints referenced in memory still exist in the actual codebase.
user_invocable: true
argument: Optional project name filter (loose match on directory name, e.g. "Fitness-App")
---

# Memory Audit

Scan all Claude Code memory files across projects, extract verifiable claims (file paths, symbols, endpoints, patterns), verify each against the live codebase, and produce a staleness report with suggested fixes.

**This skill is read-only — it NEVER modifies any memory files.**

## Process

### Step 1: Discover Memory Files

Glob `~/.claude/projects/*/memory/*` to find all memory files across all projects.

**Exclude** `session-state.md` files — they are ephemeral by design and would always appear stale.

If an `argument` was provided, filter to only projects whose directory name contains the argument string (case-insensitive). For example, argument `Fitness` matches `-Users-nickchua-Desktop-AI-Fitness-App`.

Report total file count and list each file with its line count.

### Step 2: Resolve Project Roots

For each project directory found (e.g., `-Users-nickchua-Desktop-AI-Fitness-App`):

1. Decode the directory name to a filesystem path by replacing leading `-` with `/` and internal `-` with `/`, but be smart about it — the encoding replaces `/` with `-`, so `-Users-nickchua-Desktop-AI-Fitness-App` becomes `/Users/nickchua/Desktop/AI/Fitness-App/`
2. Verify the resolved path exists using `ls`
3. If it doesn't exist, try common variations (with/without trailing segments)
4. Record the mapping: `encoded_name → resolved_path`

This resolved path is the project root used for all verification in subsequent steps.

### Step 3: Extract Verifiable Claims

Read each memory file and extract claims in 5 categories:

| Category | How to Identify | Examples |
|----------|----------------|----------|
| **File paths** | Backtick-wrapped strings with file extensions (`.py`, `.swift`, `.ts`, `.json`, `.md`, `.html`, `.sql`, `.yaml`) | `backend/app/models/user.py`, `ios/FitnessApp/Views/WorkoutView.swift` |
| **Functions/classes/structs** | Identifiers followed by `()`, PascalCase names, UPPER_SNAKE_CASE constants | `create_workout()`, `WorkoutView`, `MAX_RETRY_COUNT` |
| **Code patterns** | Code blocks labeled "Correct Pattern", "Safe Pattern", "Always use", "Never use" — extract the model/class/function names referenced within | `UserModel.query`, `session.execute()` |
| **API endpoints** | Paths starting with `/` that look like routes (contain path segments, may have `{params}`) | `/api/v1/workouts`, `/auth/login`, `/users/{user_id}` |
| **Schema/field references** | Type-annotated field names, column definitions, model fields | `workout_id: int`, `Column(String)`, `@Published var name` |

For each claim, record:
- The **claim text** (exact string from memory)
- The **source file** (which memory file it came from)
- The **line number** in the memory file
- The **category** (from the 5 above)

**Deduplication**: If the same claim appears in multiple files, verify it once but report it in all source files.

### Step 4: Verify File Paths

For each extracted file path:

1. Check if it exists relative to the project root using Glob
2. If not found, try common prefixes: `backend/`, `ios/`, `app/`, `src/`, `frontend/`
3. If still not found, search for the filename anywhere in the project using Glob with `**/{filename}`

Mark each path as:
- **EXISTS** — found at the referenced location
- **MOVED** — file exists but at a different path (note the new path)
- **MISSING** — file not found anywhere in the project

### Step 5: Verify Symbols

For each extracted function, class, or struct name:

1. Grep the project root for the definition pattern:
   - Python: `def {name}(`, `class {name}`
   - Swift: `struct {name}`, `class {name}`, `func {name}(`, `enum {name}`
   - TypeScript/JS: `function {name}(`, `class {name}`, `const {name}`, `export.*{name}`
2. Search across all file types if the language is unclear

Mark each symbol as:
- **FOUND** — definition found in codebase
- **MISSING** — no definition found

### Step 6: Verify API Endpoints

For each extracted endpoint:

1. Grep for route decorator patterns containing the path:
   - FastAPI/Flask: `@router.(get|post|put|delete|patch)\(.*{path}`, `@app.(get|post|put|delete|patch)\(.*{path}`
   - Express: `router.(get|post|put|delete|patch)\(.*{path}`
   - General: grep for the path string itself in route files
2. Also check for the path in OpenAPI/swagger specs if they exist

Mark each endpoint as:
- **FOUND** — route definition found
- **MISSING** — no matching route found

### Step 7: Verify Code Patterns

For each extracted code pattern:

1. Identify the key symbols referenced (model names, function calls, imports)
2. Verify those symbols still exist using Step 5's approach
3. Check if the pattern's import paths are still valid

Mark each pattern as:
- **VALID** — all referenced symbols exist
- **PARTIALLY_VALID** — some symbols exist, some don't (list which are missing)
- **INVALID** — key symbols are missing

### Step 8: Check Orphaned Conventions

Scan memory files for convention-style claims that may no longer apply:

- Tool/framework references ("Always use X", "We use Y for Z") — verify the tool/framework is still in the project's dependencies
- Naming conventions tied to specific patterns — verify examples still exist
- Architecture rules ("All routes go in X directory") — verify the directory structure

Flag any conventions where the supporting evidence has disappeared.

### Step 9: Compute Staleness Score

For each memory file, compute a staleness percentage:

```
staleness = (missing_claims + invalid_claims) / total_verifiable_claims * 100
```

Where:
- `missing_claims` = claims marked MISSING
- `invalid_claims` = claims marked INVALID
- Moved claims count as 0.5 (they're partially stale)
- PARTIALLY_VALID counts as 0.5

Assign a grade:
| Score | Grade | Color |
|-------|-------|-------|
| 0-10% | Fresh | Green `#16a34a` |
| 11-30% | Aging | Yellow `#ca8a04` |
| 31-60% | Stale | Orange `#ea580c` |
| 61%+ | Rotten | Red `#dc2626` |

Files with 0 verifiable claims get grade "N/A" (gray).

Also compute an **overall score** as the weighted average across all files (weighted by claim count).

### Step 10: Generate Suggested Actions

Group suggestions by priority:

**HIGH Priority** (missing files, missing functions — memory is actively wrong):
- "Remove reference to `{path}` — file no longer exists"
- "Update `{function_name}` — function has been removed or renamed"
- "Remove endpoint `{path}` — route no longer defined"

**MEDIUM Priority** (moved/renamed — memory is outdated but not wrong):
- "Update path `{old_path}` → `{new_path}`"
- "Verify if `{symbol}` was renamed — similar symbol `{similar}` found"

**LOW Priority** (convention drift — memory may be subtly wrong):
- "Review convention about `{convention}` — supporting examples have changed"
- "Check if `{tool}` is still the preferred approach"

Limit to top 10 actions total, prioritized by impact.

### Step 11: Save HTML Report

1. Read the style template at `~/.claude/skills/memory-audit/style.html`
2. Generate a self-contained HTML report using the template structure
3. Fill in all sections with computed data
4. Save to `~/.claude/memory-audits/YYYY-MM-DD.html` using today's date
5. If the file already exists, append `-2` (then `-3`, etc.)
6. Open the report in the browser: `open ~/.claude/memory-audits/{filename}`

**Report sections:**

1. **Header**: "Memory Audit" title, subtitle with file count, claim count, date
2. **Overall Score**: Large staleness grade with percentage, color-coded
3. **Per-File Breakdown**: `.audit-file` cards for each memory file, sorted worst-first:
   - File name and project
   - Staleness badge (Fresh/Aging/Stale/Rotten)
   - Claim counts by category
   - Individual claim results with status badges (EXISTS/FOUND/MISSING/MOVED)
4. **Suggested Actions**: Grouped by priority (HIGH/MEDIUM/LOW), each with the specific fix
5. **Summary Stats**: Total claims, verification breakdown, per-category accuracy
6. **Footer**: "Generated by /memory-audit" with date and "Run again in 2 weeks"

### Step 12: Print Terminal Summary

Print a concise terminal summary (the HTML is the detailed output):

```
Memory Audit Complete
━━━━━━━━━━━━━━━━━━━━

Overall: {grade} ({staleness}% stale)

  {file1}  {grade1}  ({x}/{y} claims verified)
  {file2}  {grade2}  ({x}/{y} claims verified)
  ...

Top Actions:
  1. {highest priority action}
  2. {second action}
  3. {third action}

Report: ~/.claude/memory-audits/YYYY-MM-DD.html
Next audit: 2 weeks
```

Do NOT repeat the full report in the terminal.

## Guidelines

- **Read-only**: NEVER modify any memory files. Only suggest changes.
- **Session-state excluded**: Always skip `session-state.md` — it's ephemeral by design.
- **Graceful failures**: If a project root can't be resolved, skip it and note the failure. If grep/glob fails, mark the claim as UNVERIFIABLE rather than crashing.
- **Deduplication**: Same claim across files gets verified once, reported in all files.
- **Performance**: Use parallel tool calls wherever possible — verify multiple files simultaneously, grep for multiple symbols at once.
- **Project filter**: When argument is provided, only audit memory files in matching project directories. Partial, case-insensitive matching.
- **Relative paths**: All file path claims should be verified relative to the resolved project root, not from `~` or `/`.
- **Report reuse**: The HTML template at `style.html` provides CSS classes — use them for visual consistency with `/insights` reports.

## Gotchas

_No known gotchas yet. Add lessons here as they emerge from real usage._
