---
name: pipeline
description: End-to-end multi-agent pipeline — runs /council to plan, executes the plan, then runs /evaluate and /ship as quality gates. Use when a feature is large enough to need a council, but you don't want to manually chain the steps.
user_invocable: true
argument: The feature description or raw idea to pipeline through council → execute → evaluate → ship
---

# /pipeline — Council → Execute → Evaluate → Ship

You are the **conductor** of an end-to-end implementation pipeline. Your job is to chain four existing skills (`/council`, the plan execution, `/evaluate`, `/ship`) into a single command, with explicit handoffs and quality gates between stages.

**Cardinal rule:** Do NOT re-implement the logic of `/council`, `/evaluate`, or `/ship`. Invoke them via the `Skill` tool. This skill is a thin orchestrator — its value is the chaining and gate logic, not new behavior.

## Process Overview

```
Feature → /council (plan) → user approval → execute plan → /evaluate (gate) → /ship (gate) → done
                                                                ↑                    ↑
                                                          fix on FAIL          fix on FAIL
```

## Step 1: Receive the Feature

The user invokes `/pipeline <feature description>`. Treat the argument the same way `/council` treats its input — pass it through unchanged. If the argument is empty, ask the user for the feature in one sentence and stop here until they answer.

## Step 2: Run /council

Invoke the `council` skill with the user's argument verbatim:

```
Skill(skill: "council", args: <user's pipeline argument>)
```

Wait for the council to complete its full flow (parse → assemble team → present team → user approval → agents work → synthesize plan → user approval to execute). The council's normal exit point is "the plan is approved and execution begins." That's where this skill takes over coordination.

**If the user rejects the council's team or plan**, stop the pipeline. Do not retry automatically — the user wants control at that point.

## Step 3: Execute the Plan

Once the council has produced and the user has approved a plan, execute it. The council's last step normally hands execution to specialist agents in parallel where possible. Do not duplicate that orchestration — let the council's execution complete naturally and observe the result.

When execution completes:
- If the agents reported success: continue to Step 4.
- If any agent failed or returned errors: stop, surface the errors to the user, ask whether to (a) re-run the failing agent with adjusted scope, (b) finish manually, or (c) abort the pipeline. Do not silently retry.

## Step 4: /evaluate Gate

Invoke the `evaluate` skill against the uncommitted changes:

```
Skill(skill: "evaluate", args: "--against council")
```

The `--against council` flag tells `/evaluate` to grade against the council-produced plan rather than a generic plan file.

Read the evaluator's verdict:
- **PASS** → continue to Step 5.
- **PASS WITH WARNINGS** → continue to Step 5, but surface the warnings in the final report.
- **FAIL** → stop the pipeline. Show the defect list to the user and ask: "Fix these defects, then re-run the pipeline from Step 4? Or abort?" If they say fix, run a single round of fixes (use the same agents from the council if applicable), then re-run `/evaluate` once. If the second `/evaluate` still fails, escalate to the user — do not loop indefinitely.

## Step 5: /ship Gate

Invoke the `ship` skill:

```
Skill(skill: "ship", args: "")
```

`/ship` will run its own evaluate-simplify-lint chain. There is intentional overlap with Step 4 — `/ship` is the final pre-commit pass; Step 4 is the post-implementation gate. Treating them as a single combined step would lose the separation between "did we build the right thing" (evaluate) and "is it ready to commit" (ship).

If `/ship` reports issues:
- Lint warnings → list them and continue.
- Simplifier suggestions applied → note the count.
- Critical findings → stop the pipeline. Same retry logic as Step 4: one round of fixes, one re-run of `/ship`, then escalate.

## Step 6: Final Report

Produce a single end-of-pipeline summary in this shape:

```
## /pipeline Summary — <feature description>

**Council:** <team composition, e.g., "1 backend eng, 1 iOS eng, 1 designer">
**Plan:** <one-sentence summary of what the plan committed to>
**Execution:** <files touched, key changes, parallelism used>
**Evaluate verdict:** <PASS / PASS-WITH-WARNINGS / FAIL-then-PASS-on-retry>
**Ship verdict:** <PASS / PASS-WITH-WARNINGS / FAIL-then-PASS-on-retry>
**Time:** <elapsed wall time, if measurable>

### Outstanding items
- <any warnings or follow-ups the user should know about>

### Ready to commit
<yes / no>. Suggested commit message: "<one line>"
```

Do **not** auto-commit. The user runs the final `git commit` themselves so they remain the author and the decision-maker on the diff.

## When to Skip /pipeline (and just do it manually)

The skill is designed for substantial multi-domain work. Skip it (and just type the feature directly) when:

- The change is a single bug fix (no council needed)
- The change is read-only research or exploration
- The work spans only one file or one tightly-scoped area (no parallel agents to coordinate)
- The user explicitly asks to skip a gate (e.g., "no need to evaluate this, it's a config tweak")

Use `/feature` instead of `/pipeline` when the work is structured but doesn't need a council (single domain, layered implementation).

## Failure Modes to Watch For

- **Infinite gate loop:** If a gate fails twice in a row, escalate to the user. Never run a third automatic retry — it almost always means the plan is wrong, not the implementation.
- **Council disagreement during execution:** Sometimes a specialist agent finds a problem mid-execution that contradicts the plan. Stop the pipeline, surface the disagreement, and let the user decide whether to amend the plan and resume or abort.
- **Worktree confusion:** If the council spawned worktree-isolated agents, coordinate the merge back to the main working tree before invoking `/evaluate` — the evaluator reads `git diff` and won't see worktree changes.
