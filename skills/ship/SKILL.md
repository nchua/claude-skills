---
name: ship
description: Quality gate before committing — chains /evaluate + /simplify + lint to catch issues before they ship. Run after implementing features or plans.
---

# Ship — Pre-Commit Quality Gate

Run this after implementing a feature, plan, or significant change. Chains evaluation, simplification, and linting into a single pass.

## Process

### Step 1: Evaluate
Run `/evaluate` to get an independent QA assessment of uncommitted changes. This grades the work against conventions, plan completeness, and cross-file consistency.

- If the verdict is **FAIL** or has critical defects: fix them before proceeding to Step 2.
- If the verdict is **PASS** or **PASS WITH WARNINGS**: proceed.

### Step 2: Simplify
Run `/simplify` to refine the changed code for clarity, consistency, and maintainability.

- Focus on files flagged by the evaluator where possible.
- Preserve all functionality — simplify only.

### Step 3: Lint Check
Run a final lint pass on all changed Python files:
```bash
# Get changed .py files
CHANGED=$(git diff --name-only HEAD -- '*.py' 2>/dev/null; git diff --name-only --cached -- '*.py' 2>/dev/null)
if [ -n "$CHANGED" ]; then
  ruff check $CHANGED
fi
```

### Step 4: Report
Summarize the results to the user:
- Evaluator verdict + score
- Number of issues found and fixed by simplify
- Any remaining lint warnings
- Whether the changes are ready to commit

## When to Run Automatically

This skill mechanizes the behavior from `feedback_post_plan_review.md`. Run it automatically (without asking) when:
- 4+ files were created or modified in one execution pass
- Multiple agents wrote code in parallel (council execution, /feature with subagents)
- A plan was executed that spans multiple layers (backend + frontend, models + schemas + API)

Skip when:
- 1-3 files changed by a single agent (low cross-file risk)
- Simple edits: bug fixes, config changes, single-feature additions
- Non-code changes: docs, mockups, plans
