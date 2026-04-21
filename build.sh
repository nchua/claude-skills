#!/usr/bin/env bash
# Rebuild dist/*.zip from skills/*/ — run after editing any skill source.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf dist
mkdir -p dist

for skill_dir in skills/*/; do
  name=$(basename "$skill_dir")
  # -j would strip paths; we want the folder preserved so the zip extracts to <name>/SKILL.md
  (cd skills && zip -qr "../dist/${name}.zip" "$name")
  echo "built dist/${name}.zip"
done
