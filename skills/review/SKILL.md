---
name: review
description: Use when reviewing code before merging — verifies changes, runs checks, and merges to main if approved.
user_invocable: true
argument: Optional branch name to review (defaults to current branch)
---

# Code Review & Merge

Review the current branch's changes against main, verify quality, and merge if approved.

## Process

### Step 1: Understand the Changes
- Identify all commits on this branch that aren't on main
- Read the changed files to understand what was modified and why
- Summarize the changes in 2-3 sentences

### Step 2: Verification Checklist
Before approving, verify each item:

- [ ] **Tests pass** — run the project's test suite (pytest, npm test, etc.)
- [ ] **No lint errors** — run the project's linter (ruff, eslint, etc.)
- [ ] **No hardcoded credentials** — check for API keys, passwords, tokens in changed files
- [ ] **No untracked files** — `git status` shows nothing that should be committed but isn't
- [ ] **Migrations are clean** — no multiple Alembic heads, no conflicting migrations
- [ ] **Types are correct** — type hints present on new functions (Python), no `any` escape hatches (TypeScript)
- [ ] **Edge cases handled** — null checks, empty states, error responses

### Step 3: Report
Present findings to the user:
- Summary of changes
- Checklist results (pass/fail for each item)
- Any issues found with suggested fixes
- Recommendation: approve, request changes, or discuss

### Step 4: Merge (if approved)
Only after all checks pass and the user approves:
- Merge the branch into main with `git merge --no-ff`
- Push the result

## Guidelines

- Never merge without running the test suite first
- Flag issues but don't silently fix them — the user should know what was wrong
- If tests fail, show the failure output and stop — don't merge with failing tests
- Review the diff holistically, not just line-by-line — look for architectural issues

## Gotchas

_No known gotchas yet. Add lessons here as they emerge from real usage._
