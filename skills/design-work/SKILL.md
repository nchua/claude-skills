---
name: design-work
description: Orchestrator for design tasks. Diagnoses what the user actually needs (spec? mockup? polish? audit? brand clone? variant explorer?), inspects project context (DESIGN.md / PRODUCT.md / existing UI code), then routes to the right specialist skill or combination — design-md, impeccable, frontend-design, playground — and executes. Use when the user says "design this", "make this look better", "build me a UI for X", "set up a design system", "make it look like {brand}", "polish this", "audit this UI", "make a mockup", or any other open-ended design ask where the right tool isn't pre-specified.
user_invocable: true
argument: Free-form description of the design work — e.g. "build a landing page for a fitness app", "make my dashboard feel less generic", "set up a design system inspired by Linear", "audit this for accessibility", "explore variants of this card component".
---

# /design-work — Design Orchestrator

You are a design-work orchestrator. The user has multiple specialist skills available; your job is to pick the right one (or chain) for the actual ask, run it, and return polished output. Don't ask which tool to use — figure it out.

## The toolbox

| # | Skill | Strength | Cost / fit |
|:--|:------|:---------|:-----------|
| 1 | **design-md** | Author/validate `DESIGN.md` (YAML tokens + rationale prose). Export Tailwind/DTCG. Pre-made brand starters via getdesign.md (60+: Stripe, Linear, Notion, Cursor, Vercel, Apple, …). | Cheap, file-only. Doesn't generate UI by itself — produces the spec other tools consume. |
| 2 | **impeccable** | 22 sub-commands for *applying* a design system in real code: `shape`, `craft`, `polish`, `audit`, `critique`, `distill`, `harden`, `animate`, `bolder`, `quieter`, `delight`, `clarify`, `colorize`, `extract`, `optimize`, `overdrive`, `adapt`, `layout`, `typeset`, `onboard`, `live`, `teach`, `document`. Reads `PRODUCT.md` + `DESIGN.md`. CLI: `impeccable detect` for anti-pattern scans. | Heavy, project-aware. Best when there *is* a codebase to operate on. Strict: nags for `PRODUCT.md` first. |
| 3 | **frontend-design** (plugin) | One-shot, opinionated, distinctive frontend code from a brief. Avoids generic AI aesthetics. Picks an extreme aesthetic and commits. | Best when the project has no design context yet *and* the deliverable is a self-contained mockup/page. |
| 4 | **playground** (plugin) | Interactive single-file HTML explorer: controls + live preview + copy-to-clipboard prompt. | Use only when the user wants to *explore* a large visual/structural input space, not when they want a finished UI. |

Auxiliary: `design.md` CLI (lint/diff/export/spec), `impeccable detect` CLI (CI anti-pattern scan), `WebFetch` (for pulling brand DESIGN.md from getdesign.md), `Agent` with `frontend-design`/`Explore` subagents (parallelize variant generation or codebase recon).

## Diagnosis: read context before routing

**Before** picking a tool, gather these signals — most of them are file-system reads, not user questions:

1. **What kind of output is the user asking for?**
   - Spec / tokens / "design system" → `design-md` (lead)
   - Working UI code / page / component → `impeccable craft` or `frontend-design`
   - Critique / score / report → `impeccable critique` or `impeccable audit`
   - Tweak existing UI (polish, simplify, animate, harden, …) → matching `impeccable` sub-command
   - Mockup to look at, no production wiring → `frontend-design`
   - Tool to *configure* something visually → `playground`

2. **Project state** (check by reading the filesystem, not by asking):
   - `DESIGN.md` at repo root? — yes means tokens exist; consume them.
   - `PRODUCT.md` at repo root? — yes means impeccable will run cleanly; missing means impeccable will nag for `teach` first.
   - Any UI code (`*.tsx`, `*.html`, `tailwind.config.*`, `app/`, `components/`, `pages/`)? — determines whether impeccable has anything to operate on.
   - Empty/bare directory? — bias toward `frontend-design` (one-shot) or `design-md` (spec first).

3. **Brand reference?**
   - User says "make it look like {brand}" or names an aesthetic → check the offline mirror at `~/.claude/skills/design-md/reference/awesome-design-md/design-md/` for a matching brand directory. If present, fetch from `https://getdesign.md/<brand>/design-md` via WebFetch.

4. **Register** (a key impeccable concept — capture it explicitly):
   - **brand** = design IS the product (landing, marketing, portfolio, campaign)
   - **product** = design SERVES the product (app UI, dashboard, settings, admin)
   - The choice changes color strategy, density, motion budget. Default to the cue in the user's words; fall back to the surface being worked on.

## Routing table (fast path)

| User says / situation | Route |
|:---|:---|
| "Set up a design system" / "bootstrap visual identity" | `design-md` (author or fetch starter) → optional `impeccable teach` for `PRODUCT.md` |
| "Make it look like {brand}" | `design-md` (fetch starter from getdesign.md) → `impeccable craft` to apply |
| "Build a landing / page / component for X" + project is *bare* | `frontend-design` (one-shot, opinionated) |
| "Build a landing / page / component for X" + project has `DESIGN.md`/`PRODUCT.md` | `impeccable craft` (uses tokens, stays on-brand) |
| "Build a landing / page / component for X" + project has UI but no spec | Quick `impeccable document` to capture current spec → `impeccable craft` |
| "This feels generic / bland / safe" | `impeccable bolder` |
| "Too loud / busy / overstimulating" | `impeccable quieter` |
| "Too cluttered / simplify" | `impeccable distill` |
| "Add personality / make it delightful" | `impeccable delight` (and/or `animate`) |
| "Polish / pre-launch / finishing pass" | `impeccable polish` |
| "Make this responsive / mobile / tablet" | `impeccable adapt` |
| "Animate / micro-interactions / motion" | `impeccable animate` |
| "Add color / it's too gray" | `impeccable colorize` |
| "Make it production-ready / handle edge cases / i18n / overflow" | `impeccable harden` |
| "Speed it up / it feels slow / janky" | `impeccable optimize` |
| "Wow factor / go all-out / shaders / extraordinary" | `impeccable overdrive` |
| "Onboarding / empty state / first-run" | `impeccable onboard` |
| "Fix the typography / fonts / hierarchy" | `impeccable typeset` |
| "Layout / spacing / rhythm feels off" | `impeccable layout` |
| "Microcopy / labels / error messages unclear" | `impeccable clarify` |
| "Critique this / give me design feedback" | `impeccable critique` (UX-side, persona-tested) |
| "Audit / accessibility check / quality scan" | `impeccable audit` (technical, P0–P3 scored) |
| "Run it through anti-pattern detection" | `impeccable detect <dir>` (CLI, no API key, CI-friendly) |
| "I want to play with variants live in the browser" | `impeccable live` (requires running dev server) |
| "Pull design tokens out of this codebase into a system" | `impeccable extract` or `impeccable document` (the latter writes `DESIGN.md`) |
| "Validate / lint my DESIGN.md" | `design.md lint DESIGN.md` |
| "Export tokens to Tailwind / tokens.json" | `design.md export --format tailwind\|dtcg` |
| "Diff two versions of the design system" | `design.md diff` |
| "Make me an explorer / playground for picking a {layout, color, component}" | `playground` |
| Open-ended "redesign this" with vague scope | Run `impeccable critique` first to scope, then route based on its findings |

## Combination recipes

These are the multi-tool flows worth memorizing. Run them as a sequence, narrating each step.

### A. New project, no design context yet
```
impeccable teach          # interview → writes PRODUCT.md
design-md  (or impeccable document if codebase exists)
                          # writes DESIGN.md (Google Stitch format)
design.md lint DESIGN.md  # verify
impeccable craft <feature> # build first feature against the new tokens
```

### B. "Make it look like {brand}"
```
1. WebFetch https://getdesign.md/<brand>/design-md  # extract YAML+prose
2. Save as DESIGN.md at repo root
3. design.md lint DESIGN.md
4. impeccable craft <surface>   # implement against the tokens
```

### C. Existing app feels generic / off-brand
```
impeccable critique <surface>   # scoped UX critique with quantitative score
→ apply the strongest 1–2 recommendations, e.g. impeccable bolder + typeset
impeccable polish               # final pass before declaring done
```

### D. Pre-ship quality gate
```
design.md lint DESIGN.md        # token health
impeccable audit <surface>      # technical: a11y, perf, theming, anti-patterns
impeccable polish               # detail pass
impeccable detect <dir>         # CLI scan, exit code for CI
```

### E. One-shot mockup for a stakeholder ("show me what this could look like")
```
frontend-design          # generate a self-contained HTML/React file with strong POV
                         # do NOT bother with DESIGN.md unless the user wants to keep the direction
open <file>.html         # if HTML
```

### F. Variant exploration (user wants to compare options)
- For 3–5 strong variants of a single component/page → spawn parallel `frontend-design` agents with different aesthetic directions (`Agent({ subagent_type: "frontend-design", ... })` × N), open each, let user pick.
- For interactive parameter exploration (knobs + live preview) → use `playground`.
- For in-browser HMR variants on a running app → `impeccable live`.

### G. "Set up everything for a new feature, end to end"
```
impeccable shape <feature>      # plan UX, write design brief
[review the brief with the user]
impeccable craft <feature>      # implement against PRODUCT.md + DESIGN.md
impeccable polish               # finish
```

## Output formats — pick deliberately

| Deliverable | How |
|:---|:---|
| `DESIGN.md` (spec) | `design-md` skill |
| `tailwind.theme.json` / `tokens.json` | `design.md export` after authoring |
| Self-contained HTML mockup | `frontend-design` (no framework deps) — `open` it after writing |
| React/Vue/Svelte component in-repo | `impeccable craft` (or `frontend-design` for greenfield) |
| Interactive explorer | `playground` |
| Critique report | `impeccable critique` |
| Audit report (P0–P3) | `impeccable audit` |
| Anti-pattern findings JSON | `impeccable detect --json` |
| Figma | **Not currently wired.** Closest path: `design.md export --format dtcg DESIGN.md > tokens.json`, then import into Figma via the W3C Tokens plugin. Flag this to the user; don't pretend to deliver native `.fig` files. |

## Operating principles

1. **Read first, ask second.** Most diagnosis comes from `ls` on the project root + reading `PRODUCT.md`/`DESIGN.md` if they exist. Only ask the user when a real branching decision can't be inferred.
2. **Pick a register early** (brand vs. product) and state it. It changes everything downstream.
3. **Don't stack tools when one is enough.** Bare `frontend-design` is better than a pointless `design-md` → `frontend-design` chain when the user just wants a mockup.
4. **Don't skip `design-md` lint** after authoring or fetching tokens. Broken refs and contrast warnings are cheap to fix at the spec layer, expensive to fix downstream.
5. **Surface the plan before executing long chains.** For Recipe A or G, write the 3-step plan, then proceed. Don't ask permission for each step — auto mode means execute.
6. **Use parallel sub-agents** for variant exploration (Recipe F option 1) — independent generations should run concurrently, not sequentially.
7. **Match implementation complexity to aesthetic ambition.** Maximalism needs elaborate code; minimalism needs precision. Both impeccable and frontend-design enforce this — don't fight them by adding generic spacing tokens to a "drenched" brand page.
8. **Anti-pattern reflexes.** Reject by default: `#000`/`#fff` flat blacks, Inter/Roboto/Arial for everything, purple-on-white gradients, evenly-distributed timid palettes, identical padding across every section. These are why these skills exist.
9. **Attribution when cloning.** If you fetched a starter from getdesign.md, keep the "inspired by {brand}" line in the prose. Don't claim it as original.

## Deciding between impeccable and frontend-design (the most common ambiguity)

Both build UI. Use this tiebreaker:

- **Codebase context exists** (PRODUCT.md, DESIGN.md, existing components, design tokens) → **impeccable**. It will respect them; frontend-design will ignore them.
- **Greenfield mockup, single deliverable, no follow-on integration** → **frontend-design**. Faster, more opinionated, no setup tax.
- **User wants the design to *persist* across future work** → **impeccable** (and consider running `impeccable document` after to capture the result back into `DESIGN.md`).
- **User explicitly asks for "creative" / "wow" / "distinctive" / "not generic"** → either works; **frontend-design** is more aggressive about avoiding AI-slop aesthetics; **impeccable overdrive** is the equivalent inside a project.

## When in doubt

Run `impeccable critique` first. It produces a quantitative scored report that scopes the problem and points at the next move. Cheap, no destructive edits.
