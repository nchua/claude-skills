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
2. Run `./build.sh` to refresh `dist/`
3. Commit and push

```bash
./build.sh
git add -A
git commit -m "update <skill-name>"
git push
```

On other machines: `git pull` — symlinks pick up changes automatically, no re-install needed.

## Current skills

- **council** — multi-agent planning from idea dumps
- **evaluate** — independent QA grader for uncommitted changes
- **feature** — structured per-layer feature implementation
- **handoff** — save session state for resumption
- **pipeline** — chains council → execute → evaluate → ship
- **ship** — quality gate (evaluate + simplify + lint) before commit
