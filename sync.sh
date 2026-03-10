#!/usr/bin/env bash
# Sync skills from ~/.claude/skills source to this repo and push
set -euo pipefail

SKILLS_DIR="$HOME/development/.claude/skills"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS=(agent-memory job-search multi-agent-orchestration seo x-craft remotion-best-practices)

echo "Syncing from $SKILLS_DIR..."

for skill in "${SKILLS[@]}"; do
  src="$SKILLS_DIR/$skill"
  if [ -d "$src" ]; then
    rsync -a --delete "$src/" "$REPO_DIR/$skill/"
    echo "  ✓ $skill"
  else
    echo "  ✗ $skill (not found in source, skipping)"
  fi
done

cp "$SKILLS_DIR/README.md" "$REPO_DIR/README.md"

cd "$REPO_DIR"
git add -A

if git diff --cached --quiet; then
  echo "Nothing changed."
else
  git commit -m "Sync skills $(date '+%Y-%m-%d')"
  git push
  echo "Pushed."
fi
