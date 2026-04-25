---
name: design-md
description: Author, validate, and apply DESIGN.md — Google's format for describing a visual identity (colors, typography, spacing, components) to coding agents. Use whenever a project would benefit from a single source-of-truth design system file, when bootstrapping UI for a new app, when asked to "set up a design system" / "make this look like X", before generating multi-page UI from scratch, or when the user asks to lint, diff, or export a DESIGN.md. The CLI is installed globally as `design.md`.
user_invocable: true
argument: Optional. A path to an existing DESIGN.md, a subcommand (lint|diff|export|spec|init), or a free-form ask like "create a DESIGN.md for a brutalist news site".
---

# DESIGN.md Skill

DESIGN.md is a single-file format for describing a visual identity to coding agents — YAML front matter for machine-readable tokens, markdown prose for the *why*. The CLI `design.md` (installed globally via `@google/design.md`) lints, diffs, and exports these files.

## Pre-made DESIGN.md files (getdesign.md / awesome-design-md)

[**getdesign.md**](https://getdesign.md) hosts 60+ ready-made DESIGN.md files modeled on real brands. The companion index — [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) — is mirrored offline in `reference/awesome-design-md/` (this skill's directory). Each subfolder under `reference/awesome-design-md/design-md/<brand>/` has the canonical URL.

**Before authoring from scratch**, check whether the user's reference aesthetic ("make it look like Stripe", "Apple-style", "Linear-style") already has a downloadable file. Workflow:

1. Browse `reference/awesome-design-md/README.md` (or check `reference/awesome-design-md/design-md/` for the brand directories) to find a match.
2. Fetch the actual content from `https://getdesign.md/<brand>/design-md` using WebFetch (the site is JS-rendered — ask WebFetch to extract the YAML front matter and full markdown body verbatim).
3. Save as `DESIGN.md` at the project root.
4. Run `design.md lint DESIGN.md` and fix anything broken (the gallery files generally lint clean, but resolve any errors before claiming done).
5. Customize the prose / tweak tokens for the actual project — keep attribution in the prose ("inspired by <brand>").

Available brands cover AI/LLM platforms (Claude, Cohere, ElevenLabs, Mistral, OpenCode, Replicate, RunwayML, xAI, …), dev tools (Cursor, Vercel, Warp, Raycast, Linear, Expo), backend/devops (Supabase, MongoDB, Sentry, ClickHouse, HashiCorp), productivity (Notion, Cal.com, Intercom, Resend, Zapier), design tools (Figma, Framer, Webflow, Miro, Airtable), fintech (Stripe, Coinbase, Revolut, Wise), and more — see the offline mirror for the complete list.

## When to use this skill

- User asks to create / bootstrap a design system, style guide, or "DESIGN.md".
- User wants UI generated from a consistent visual identity (avoids per-page drift).
- User asks to validate, diff, or export an existing DESIGN.md.
- About to generate multi-page or multi-component UI from scratch — propose creating a DESIGN.md first so all components reference shared tokens.
- User says "make it look like {brand/aesthetic}" — capture the aesthetic in a DESIGN.md so it persists.

Skip when: the project already has a working design system (Tailwind config, tokens.json, Figma export) — don't duplicate it. Offer to *import* into DESIGN.md only if the user asks.

## CLI quick reference

```bash
design.md lint DESIGN.md                    # validate structure, refs, contrast
design.md diff DESIGN.md DESIGN-v2.md       # detect token regressions between versions
design.md export --format tailwind DESIGN.md > tailwind.theme.json
design.md export --format dtcg DESIGN.md > tokens.json
design.md spec                              # full spec as markdown (inject into prompts)
design.md spec --rules-only --format json   # just the linter rules
```

All commands accept `-` for stdin. `lint` exits `1` on errors, `0` otherwise. `diff` exits `1` on regressions.

## Authoring workflow

1. **Pull the spec into context first.** Run `design.md spec` and read it before writing tokens — the spec is the source of truth for section order, token types, and component property names.
2. **Place the file at the repo root** as `DESIGN.md` (uppercase, like README.md) unless the user specifies otherwise.
3. **Front matter first, prose second.** Tokens are normative; prose explains *why*.
4. **Section order matters.** Sections are optional but those present must appear in: Overview → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts. Out-of-order = lint warning.
5. **Use token references** (`{colors.primary}`) inside `components` rather than re-stating hex values. Broken refs are lint *errors*.
6. **Lint before claiming done.** Run `design.md lint DESIGN.md` and fix all errors. Address warnings unless the user accepts them (e.g., intentional low-contrast on decorative elements).
7. **Wire into the build** if applicable: export to Tailwind theme or DTCG tokens.json so generated components actually consume the tokens.

## Skeleton

```markdown
---
version: alpha
name: <brand name>
description: <one sentence aesthetic summary>
colors:
  primary: "#..."
  secondary: "#..."
  tertiary: "#..."
  neutral: "#..."
  on-primary: "#..."     # text/icon color when on primary bg
typography:
  h1:    { fontFamily: ..., fontSize: 3rem,    fontWeight: 700, lineHeight: 1.1 }
  body-md: { fontFamily: ..., fontSize: 1rem,  fontWeight: 400, lineHeight: 1.5 }
  label-caps: { fontFamily: ..., fontSize: 0.75rem, letterSpacing: 0.08em }
rounded:
  sm: 4px
  md: 8px
  lg: 16px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-tertiary}"
    rounded: "{rounded.sm}"
    padding: 12px
  button-primary-hover:
    backgroundColor: "{colors.tertiary-container}"
---

## Overview
<2–4 sentences: the *feel* — what mood, what reference points, what to avoid>

## Colors
- **Primary (#...):** what it's for
- ...

## Typography
- **h1:** when to use, character of the typeface
- ...

## Components
- **button-primary:** primary CTA, sole driver of interaction
- ...

## Do's and Don'ts
- ✅ Do ...
- ❌ Don't ...
```

Valid component properties: `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`. Variants (hover/active/pressed) go in separate component entries with related key names (`button-primary-hover`).

## Common lint findings and fixes

| Rule | Severity | Fix |
|:-----|:---------|:----|
| `broken-ref` | error | Token reference doesn't resolve — check the path matches a defined token exactly |
| `missing-primary` | warning | Add a `primary` color or accept agent auto-generation |
| `contrast-ratio` | warning | Component bg/text pair < WCAG AA 4.5:1 — pick a higher-contrast pair |
| `orphaned-tokens` | warning | Color defined but no component uses it — either reference it or remove it |
| `missing-typography` | warning | Add at least body + h1 typography tokens |
| `section-order` | warning | Reorder `##` headings to canonical order |

## Companion: impeccable

The [`impeccable`](https://impeccable.style) skill (also installed globally) covers the *application* side: scanning code for UI anti-patterns, polishing existing interfaces, and applying a design system to actual components. Rough split:

- **design-md (this skill)** — author / validate / export the *spec* (DESIGN.md tokens + prose).
- **impeccable** — read DESIGN.md (and PRODUCT.md) and *apply* it: shape, craft, polish, audit, detect anti-patterns. CLI: `impeccable detect <dir>` for CI-style anti-pattern scans.

Use them together: run this skill to produce or refresh `DESIGN.md`, then invoke impeccable to generate / refine UI that consumes those tokens.

## Tips

- For "make it look like X" requests, study the reference (screenshot, URL, brand) and capture *why* in the prose, not just hex values. The prose is what keeps future generations on-brand.
- When asked to update an existing DESIGN.md, run `design.md diff` after editing to surface regressions before committing.
- For Tailwind projects, `design.md export --format tailwind` produces a theme config you can drop into `tailwind.config.js`.
- The `design.md spec` output is designed for prompt injection — when generating UI components from a DESIGN.md, include the spec output in the prompt so the model knows the schema.
