---
name: handoff
description: Saves current session state to memory so the next session can pick up where you left off. Run before ending a session or when context is getting large.
user_invocable: true
argument: Optional notes about what to capture or context to include
---

# Session Handoff

You are saving the current session's state so a future session can seamlessly continue the work.

## Process

### Step 1: Gather State

Collect the following information from the current conversation and working directory:

1. **What was accomplished** this session — summarize completed work from the conversation
2. **What's in progress** — incomplete tasks, partially implemented features, files being edited
3. **Blockers or open questions** — decisions that need user input, bugs not yet resolved
4. **Key files touched** — files that were modified or are central to the current work
5. **Git state** — run `git branch --show-current` and `git log --oneline -3` to capture branch and recent commits

### Step 2: Write Session State

Write the gathered information to the project's memory directory. Determine the correct memory path:

1. Check if a `memory/` directory exists in the current project's Claude data directory
2. If the project memory directory path is available from context, use it
3. Otherwise, write to a `session-state.md` file in the project root as a fallback

Use this format:

```markdown
# Session State — Last Updated: {YYYY-MM-DD HH:MM}

## Session Name: {short descriptive name for /rename}

## Completed This Session
- {bullet points of what was accomplished}

## In Progress
- [ ] {task description} ({file_path}:{line_number} if applicable)
- [ ] {task description}

## Blockers / Open Questions
- {question or blocker, or "None" if clear}

## Git State
- Branch: `{branch_name}`
- Recent commits:
  - `{hash}` — {message}
  - `{hash}` — {message}

## Key Files Touched
- {file_path}
- {file_path}

## Context for Next Session
{Any additional context that would help the next session understand where things stand —
e.g., "The API endpoint works but the iOS view hasn't been updated yet",
"Migration created but not applied to prod", etc.}
```

### Step 3: Rename Session

After writing the session state, automatically rename the session using the `## Session Name:` value from the state file. Include a `## Session Name: {descriptive-name}` line in the state file (after the title), then run:

```
/rename {descriptive-name}
```

Do NOT ask the user to rename — just do it.

### Step 4: Confirm

After writing the file and renaming, tell the user:
- Where the session state was saved
- The session name it was renamed to
- Remind them to use `claude -c` (continue last session) or `claude -r` (pick a session) when they return

## Guidelines

- Keep it concise — the goal is fast ramp-up, not a transcript
- Focus on **actionable** items, not a history of everything discussed
- Include file paths with line numbers where relevant
- If the user provides notes in the argument, incorporate them into the "Context for Next Session" section
- If there's nothing in progress (session is at a clean stopping point), say so clearly — that's useful info too

## Gotchas

_No known gotchas yet. Add lessons here as they emerge from real usage._
