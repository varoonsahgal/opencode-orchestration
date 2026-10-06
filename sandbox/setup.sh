#!/usr/bin/env bash
# Set up the Panic Pantry teaching sandbox for the matched comparison:
# - make sandbox/panic-pantry its own git repo (nested repo is intentional)
# - commit the starter state and tag it "starter"
# - create two matched worktrees: worktrees/single-agent and worktrees/orchestrated
# Run it once, from anywhere: bash sandbox/setup.sh
# Re-running recreates the worktrees from the starter tag, which discards any
# learner work inside them, so a re-run needs --force.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANTRY="$SCRIPT_DIR/panic-pantry"
WORKTREES="$SCRIPT_DIR/worktrees"

if [ -d "$WORKTREES" ] && [ "${1:-}" != "--force" ]; then
  echo "[setup] already set up: $WORKTREES exists."
  echo "[setup] Re-running WIPES both worktrees (your Module 0 and Module 3 work)."
  echo "[setup] If that's really what you want: bash sandbox/setup.sh --force"
  exit 1
fi

cd "$PANTRY"

if [ ! -d .git ]; then
  git init -b main
  echo "[setup] initialized git repo in $PANTRY"
fi

# Local identity so commits work on a fresh classroom VM.
git config user.name >/dev/null 2>&1 || git config user.name "Panic Pantry Learner"
git config user.email >/dev/null 2>&1 || git config user.email "learner@panic-pantry.local"

bash scripts/reset.sh >/dev/null
echo "[setup] sandbox reset to starter state"

# Commit the sandbox and its templates, never learner work left in this checkout
# (plans, cards, agent files, notes from a dry run). A template is staged the
# first time, and again later only if it still matches the course repo's own
# committed copy (a course update, not a learner's edits).
git add -A -- . ':(exclude)workshop' ':(exclude).opencode'
COURSE="$SCRIPT_DIR/.."
for t in workshop/WRITABLE_FILES.md workshop/scorecard.md workshop/model-comparison.md workshop/prompts; do
  if ! git ls-files --error-unmatch -- "$t" >/dev/null 2>&1; then
    git add -- "$t"
  elif git -C "$COURSE" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
       git -C "$COURSE" diff --quiet HEAD -- "sandbox/panic-pantry/$t" 2>/dev/null; then
    git add -- "$t"
  fi
done
if ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  git commit -m "starter"
  echo "[setup] created starter commit"
elif ! git diff --cached --quiet; then
  git commit -m "starter"
  echo "[setup] committed starter updates"
else
  echo "[setup] starter commit already up to date"
fi
git tag -f starter >/dev/null
echo "[setup] tag 'starter' -> $(git rev-parse --short HEAD)"

mkdir -p "$WORKTREES"
for name in single-agent orchestrated; do
  path="$WORKTREES/$name"
  git worktree remove --force "$path" >/dev/null 2>&1 || true
  rm -rf "$path"
  git worktree prune
  git branch -D "$name" >/dev/null 2>&1 || true
  git worktree add -b "$name" "$path" starter >/dev/null
  (cd "$path" && bash scripts/reset.sh >/dev/null)
  echo "[setup] worktree '$name' -> $path (branch $name @ $(git -C "$path" rev-parse --short HEAD))"
done

echo "[setup] worktrees:"
git worktree list
echo "[setup] done"
