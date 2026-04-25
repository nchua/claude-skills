---
name: insights
description: Use for a periodic workflow review — audits your Claude Code workflow, archives a timestamped snapshot, and recommends improvements.
user_invocable: true
---

# Workflow Review

Audit the user's Claude Code configuration, usage patterns, and workflow maturity. Archive a timestamped report and compare against the previous review.

## Process

### Step 1: Gather Current State

Read ALL of these data sources in parallel using the Read tool. Do not skip any.

| Source | Path | What to Extract |
|--------|------|-----------------|
| Settings | `~/.claude/settings.json` | `hooks` object (trigger types, matchers, commands), `enabledPlugins` object |
| Permissions | `~/.claude/settings.local.json` | `permissions.allow` array — count entries and group by prefix (Bash, Read, etc.) |
| Stats | `~/.claude/stats-cache.json` | `dailyActivity`, `dailyModelTokens`, `modelUsage`, `totalSessions`, `totalMessages`, `hourCounts`, `longestSession` |
| Skills | Glob `~/.claude/skills/*/SKILL.md` | For each: read the frontmatter fields (name, description, user_invocable) |
| Global CLAUDE.md | `~/.claude/CLAUDE.md` | Line count + list of `##` section headings |
| Project CLAUDE.md | `{cwd}/CLAUDE.md` (if exists) | Line count + list of `##` section headings |
| Memory | Glob `~/.claude/projects/*/memory/*` | File names + line counts per file. Note if empty. |
| Previous Review | Glob `~/.claude/reviews/*.html` and `~/.claude/reviews/*.md` | Identify the most recent file (by filename date) |

### Step 2: Load Previous Review

If a previous review exists in `~/.claude/reviews/`:
- Read the most recent file (sorted by filename)
- Parse these sections for comparison: **Hooks**, **Plugins**, **Skills**, **Permissions**, **CLAUDE.md**, **Memory**, **Session Activity**

If no previous review exists, note "First review — establishing baseline."

### Step 3: Compare

For each category, produce a one-line change summary:
- **Added**: new hooks, plugins, skills, permissions, CLAUDE.md sections, memory files
- **Removed**: items present in the previous review but absent now
- **Modified**: line count changes in CLAUDE.md, permission count changes, etc.
- **Unchanged**: note if a category hasn't changed

If this is the first review, skip this step.

### Step 4: Analyze Usage Profile

Write a 2-3 sentence narrative characterizing how the user uses Claude Code, based on:
- **Session cadence**: How many active days out of the period? Daily user vs sporadic?
- **Session intensity**: Average messages per active day — light (<100), moderate (100-500), heavy (500-1500), power user (1500+)
- **Model strategy**: Single model or multi-model? Which models and in what proportion?
- **Automation level**: How many hooks, plugins, and skills? Manual vs automated workflow?
- **Time pattern**: When do they work? Night owl, morning person, all-day?

This narrative goes in the "How You Use Claude Code" section of the report.

### Step 5: Identify Big Wins

Based on the gathered data, identify 2-3 things the user is doing well. Look for:
- **Strong automation**: Multiple hooks covering different triggers (PostToolUse, PreToolUse, PermissionRequest)
- **Rich documentation**: Large, well-sectioned CLAUDE.md files with lessons learned
- **Diverse tooling**: Multiple plugins enabled, multiple skills created
- **Active memory use**: Memory files capturing patterns and decisions
- **Multi-model usage**: Strategic use of different models for different tasks
- **High session volume**: Consistent, daily usage showing deep adoption
- **Permission discipline**: Well-curated permissions list (not too few, not too many)

Write each win as a title + 1-2 sentence description of what they're doing and why it's effective.

### Step 6: Identify Friction Points

Based on config gaps and usage patterns, identify 1-3 areas where the workflow could improve. Look for:
- **Missing automation**: No hooks, no post-edit checks, no notifications
- **Documentation gaps**: Thin CLAUDE.md, no memory files, no project-specific instructions
- **Session patterns**: Very long sessions (suggests context may be getting stale), very concentrated hours (may be missing quick-task opportunities)
- **Model rigidity**: Only using one model when cost/speed tradeoffs could help
- **Permission sprawl**: Large unorganized permission lists
- **Skill gaps**: Few or no reusable skills for repetitive workflows

Write each friction point as a title + 1-2 sentence description of what's happening and what the impact is.

### Step 7: Generate Recommendations

Run each heuristic check below. For every check that triggers, include the recommendation in the report with its title and action steps.

| # | Check | Triggers When | Recommendation |
|---|-------|---------------|----------------|
| 1 | Empty memory | No files in any `memory/` directory | Start using project memory files to capture debugging patterns, architecture decisions, and lessons learned. Create `MEMORY.md` in your most active project's memory directory. |
| 2 | Thin global CLAUDE.md | `~/.claude/CLAUDE.md` has fewer than 20 lines | Your global CLAUDE.md is light. Add instructions that apply to ALL your projects: preferred languages, coding style rules, common tool preferences, testing expectations. |
| 3 | No project CLAUDE.md | `{cwd}/CLAUDE.md` does not exist | This project has no CLAUDE.md. Create one with project-specific architecture, key commands, and conventions so Claude Code understands your codebase from the start. |
| 4 | No hooks configured | `hooks` object in settings.json is empty or missing | Add hooks to automate repetitive checks. Start with a PostToolUse hook that lints files after Edit/Write operations. See Claude Code docs for hook examples. |
| 5 | No plugins enabled | `enabledPlugins` is empty or missing | Enable plugins to extend Claude Code's capabilities. Check available plugins with `/config` and enable ones relevant to your stack. |
| 6 | Single model usage | `modelUsage` only has one model key | You're only using one model. Consider using Haiku for quick tasks (file lookups, simple questions) and Opus for complex implementation to optimize cost and speed. |
| 7 | Few skills | Fewer than 3 user-invocable skills | Build more custom skills for workflows you repeat. Good candidates: deployment checklists, PR review templates, debugging runbooks. |
| 8 | Large permissions list | More than 50 entries in `permissions.allow` | Your permissions allowlist is large. Review it for entries you no longer need. A tighter allowlist is easier to audit and reduces accidental approvals. |
| 9 | No session activity in 7+ days | Last entry in `dailyActivity` is older than 7 days from today | Your last Claude Code session was over a week ago. Regular usage builds muscle memory and helps you discover new capabilities. |
| 10 | Peak hours concentrated | More than 60% of `hourCounts` sessions fall within a 4-hour window | Your sessions are concentrated in a narrow time window. This is fine if intentional, but consider whether you're missing opportunities to use Claude Code for quick tasks throughout the day. |

### Step 8: Suggest Features to Try

Based on the user's current setup, suggest 1-3 Claude Code features they aren't using yet. Only suggest features that are clearly relevant to their workflow. Pick from:

| Feature | Suggest When | What to Say |
|---------|-------------|-------------|
| **Headless Mode** | User runs long scripts or batch operations (many Bash permissions, backfill-related commands) | Run Claude non-interactively for batch tasks: `claude -p "your prompt" --allowedTools "Bash,Read,Edit"`. Great for backfills, data migrations, and documentation updates that don't need babysitting. |
| **Subagents (Task tool)** | User has complex multi-file workflows but no skills referencing subagents | Use `Task` tool to parallelize independent work — one agent researching, another implementing, a third testing. Especially useful for your review-then-implement pattern. |
| **Custom Keybindings** | User has many sessions (power user) but no `~/.claude/keybindings.json` | Customize keyboard shortcuts for actions you repeat: rebind submit key, add chord shortcuts for common workflows. Run `/keybindings-help` to set up. |
| **Plan Mode** | User has complex features but no skills referencing EnterPlanMode | Use `/plan` before implementing complex features. Pour energy into the plan so Claude can one-shot the implementation. Switch back to planning when issues arise. |
| **Git Worktrees** | User works on multiple features concurrently (multi-clauding, many branches) | Use git worktrees to run parallel Claude Code sessions on different branches without conflicts. Each worktree gets its own working directory. |
| **MCP Servers** | User has no MCP configuration | Connect external tools (databases, APIs, services) directly to Claude Code via MCP servers. Lets Claude query your DB, check deployments, or interact with external services without manual Bash commands. |

### Step 9: Suggest New Usage Patterns

Based on the user's existing workflow, suggest 1-2 new ways they could use Claude Code more effectively. Each suggestion should include a concrete, copyable prompt they can paste into Claude Code. Focus on patterns that build on what they already do.

### Step 10: On the Horizon

Write 1-2 forward-looking ideas about how the user's workflow could evolve as Claude Code capabilities improve. Base these on their current usage patterns — extrapolate what they already do into more autonomous or sophisticated workflows.

### Step 11: Fun Fact

Pick one memorable or surprising stat from the data and write a 1-2 sentence fun observation. Examples:
- Busiest single day and what happened
- Night owl / early bird observation from hourCounts
- Longest session duration
- Most-used model and what percentage it dominates
- Messages-per-session average

### Step 12: Ask for Reflection

Use `AskUserQuestion` with this question:

- **Question**: "Is there anything about your Claude Code workflow that frustrated you or felt inefficient recently?"
- **Header**: "Reflection"
- **Options**:
  - "Nothing comes to mind" — description: "Skip this section, no frustrations to report."
  - "Yes, let me describe it" — description: "I'll type what's been bugging me so we can add it to the recommendations."

If the user selects "Yes", incorporate their response into a "User-Identified Improvements" section with concrete suggestions for addressing their frustration.

If the user selects "Nothing comes to mind", include a brief note: "No user-identified issues this review."

### Step 13: Save Archive as HTML

1. Create the reviews directory: `mkdir -p ~/.claude/reviews/`
2. Generate the filename: `YYYY-MM-DD.html` using today's date
3. If a file with that name already exists, append `-2` (then `-3`, etc.)
4. Generate the full HTML report using the template below, filling in all data
5. Write the HTML to `~/.claude/reviews/{filename}` using the Write tool
6. Open the HTML file in the browser: `open ~/.claude/reviews/{filename}`

### Step 14: Present Summary in Terminal

Show a **brief** terminal summary (not the full report — that's in the HTML). Include:
- Workflow Maturity level and score
- 1-line "At a Glance" summary
- Number of recommendations triggered
- Path to the HTML file
- Reminder to run again in 1-2 weeks

Do NOT repeat the full report in the terminal. The HTML file is the primary output.

## Report Template (HTML)

Generate a self-contained HTML file. Read the style reference at `~/.claude/skills/insights/style.html` for the exact CSS and HTML structure. Fill in each section with the computed data.

**Section mapping** — the HTML uses these section IDs and card styles:

| Section | Card Style | Color |
|---------|-----------|-------|
| At a Glance | `.at-a-glance` | Amber gradient (`#fef3c7` → `#fde68a`) |
| Impressive Things | `.big-win` | Green (`#f0fdf4` border `#bbf7d0`) |
| Where Things Could Improve | `.friction-category` | Red (`#fef2f2` border `#fca5a5`) |
| Features to Try | `.feature-card` | Green (`#f0fdf4` border `#86efac`) |
| New Usage Patterns | `.pattern-card` | Blue (`#f0f9ff` border `#7dd3fc`) |
| On the Horizon | `.horizon-card` | Purple gradient (`#faf5ff` → `#f5f3ff`) |
| Fun Fact | `.fun-ending` | Amber gradient (same as At a Glance) |

**Data to include in each section:**

1. **Header**: Title "Claude Code Insights", subtitle with message count, session count, and date range
2. **Stats row**: Messages, Sessions, Active Days, Msgs/Day, Maturity Level
3. **Nav TOC**: Links to each section
4. **At a Glance**: What's working, What's hindering, Quick wins (with `→` links to relevant sections)
5. **How You Use Claude Code**: Narrative paragraph in `.narrative` card with `.key-insight` callout
6. **Current Setup**: Tables for Hooks, Plugins, Skills, Permissions, CLAUDE.md, Memory — use standard HTML tables with the table styling from style.html
7. **Session Activity**: Stats table, Model breakdown bar chart, Time of Day bar chart (Morning/Afternoon/Evening/Night), Peak hours
8. **Impressive Things**: 2-3 `.big-win` cards with title and description
9. **Where Things Could Improve**: 1-3 `.friction-category` cards with title and description
10. **What Changed**: Bullet list of per-category deltas (or "First review" / "No changes")
11. **Recommendations**: Numbered cards with title and action steps
12. **Features to Try**: `.feature-card` cards with title, one-liner, "Why for you" explanation, and copyable code example
13. **New Usage Patterns**: `.pattern-card` cards with title, summary, detail, and copyable prompt
14. **On the Horizon**: `.horizon-card` cards with title, what's possible, and getting-started tip
15. **Fun Fact**: `.fun-ending` card with headline and detail
16. **User-Identified Improvements**: If any, otherwise "No user-identified issues"

**Bar chart HTML pattern** (for model breakdown, time of day, etc.):
```html
<div class="bar-row">
  <div class="bar-label">Label</div>
  <div class="bar-track"><div class="bar-fill" style="width:{pct}%;background:{color}"></div></div>
  <div class="bar-value">123</div>
</div>
```

**Copyable code block pattern** (for features and patterns):
```html
<div class="feature-code">
  <code>{code content}</code>
  <button class="copy-btn" onclick="copyText(this)">Copy</button>
</div>
```

## Guidelines

- This skill is **read-only** — never modify any configuration files
- Read all data sources in parallel for speed
- Keep recommendation language concrete and actionable — no vague advice
- The archived file should be self-contained (readable without Claude Code)
- If a data source file doesn't exist, note it gracefully and continue
- Use the raw model IDs from stats (e.g., `claude-opus-4-5-20251101`) — don't try to prettify them
- For daily averages, divide by the number of **active days** (days with at least 1 session), not calendar days
- Big Wins and Friction sections should be specific to THIS user's data, not generic advice
- Feature suggestions should only include features they aren't already using
- Usage Patterns should build on what they already do, not suggest entirely new workflows
- The "At a Glance" summary should be the first thing the user sees — make it punchy and actionable
- On the Horizon ideas should extrapolate from their current patterns, not be generic Claude Code roadmap items

## Gotchas

_No known gotchas yet. Add lessons here as they emerge from real usage._
