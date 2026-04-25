# claude-skills

Personal Claude Code skills, versioned for use across machines and mobile.

## Layout

- `skills/` — unzipped skill sources (clone target for Claude Code on desktop)
- `dist/` — prebuilt `.zip` files (upload these to claude.ai for mobile / web app)
- `build.sh` — regenerate `dist/` from `skills/`

## Install on a new Mac

Clone the repo, then symlink each skill into `~/.claude/skills/` so `git pull` auto-updates every machine:

```bash
git clone git@github.com:nchua/claude-skills.git ~/claude-skills
mkdir -p ~/.claude/skills
for d in ~/claude-skills/skills/*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

Verify with `ls -la ~/.claude/skills/` — each entry should be a symlink into `~/claude-skills/skills/`.

## Use on mobile / claude.ai

1. Open this repo on your phone (github.com/nchua/claude-skills)
2. Navigate to `dist/`, tap the zip you want, tap **Download raw file**
3. In claude.ai → Settings → Capabilities → Skills → Upload

## Adding or updating a skill

1. Edit files under `skills/<name>/`
2. Commit and push

```bash
git add -A
git commit -m "update <skill-name>"
git push
```

A GitHub Action ([`.github/workflows/build-dist.yml`](.github/workflows/build-dist.yml)) auto-rebuilds `dist/*.zip` on every push that touches `skills/` or `build.sh` and commits the refreshed zips back to `main` with `[skip ci]`. You can also rebuild locally with `./build.sh` if you want to verify before pushing, or trigger the workflow manually from the Actions tab.

On other machines: `git pull` — symlinks pick up changes automatically, no re-install needed.

## Current skills

### Workflow
- **council** — multi-agent planning from idea dumps
- **evaluate** — independent QA grader for uncommitted changes
- **feature** — structured per-layer feature implementation
- **handoff** — save session state for resumption
- **idea-dump** — restructure messy stream-of-consciousness asks into a clean prompt + auto plan-mode
- **insights** — periodic Claude Code workflow audit + recommendations
- **memory-audit** — verify memory file references still match the codebase
- **pipeline** — chains council → execute → evaluate → ship
- **review** — pre-merge review + checks + merge to main
- **ship** — quality gate (evaluate + simplify + lint) before commit

### Design
- **design-md** — author/validate `DESIGN.md` (Google Stitch format); pre-made brand starters (Stripe/Linear/Notion/…) mirrored offline from [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md). CLI: `npm i -g @google/design.md`.
- **impeccable** — 22 sub-commands for designing/refining UI in real code (shape, craft, polish, audit, critique, distill, harden, animate, …) plus an anti-pattern detector. Apache 2.0, from [pbakaus/impeccable](https://github.com/pbakaus/impeccable). CLI: `npm i -g impeccable`.
- **design-work** — orchestrator: diagnoses any open-ended design ask, reads project context, and routes to the right combination of `design-md` / `impeccable` / `frontend-design` / `playground`. Use this as the front door for design work.

### Knowledge / persona
- **holocron-research** — deep web research → spaced-repetition cards (paired with the [holocron](https://github.com/nchua/holocron) backend)
- **holocron-refresh** — pull from Gmail/Notion/web → POST cards to Holocron
- **jarvis-persona** — JARVIS voice / mannerisms

## Mobile usage tips

For the **design-work** orchestrator on mobile claude.ai: it routes to other skills, so upload `design-work.zip`, `design-md.zip`, and `impeccable.zip` together. The CLI parts (`design.md lint`, `impeccable detect`) won't run on mobile — the skill content still works as instruction text for generating DESIGN.md or routing recommendations.
