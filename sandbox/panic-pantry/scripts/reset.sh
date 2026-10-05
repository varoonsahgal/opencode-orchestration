#!/usr/bin/env bash
# Reset the Panic Pantry sandbox to its starter state. Filesystem-only
# (no git commands) and safe to run repeatedly.
set -euo pipefail
cd "$(dirname "$0")/.."

cp data/promotions.json.seed data/promotions.json
echo "[reset] data/promotions.json restored from seed"

removed=0
for f in src/panic_pantry/importer.py src/panic_pantry/csv_parser.py src/csv_parser.py; do
  if [ -f "$f" ]; then
    rm -f "$f"
    echo "[reset] removed $f"
    removed=1
  fi
done
[ "$removed" -eq 0 ] && echo "[reset] no importer files to remove"

find . -type d -name __pycache__ -prune -exec rm -rf {} +
echo "[reset] cleared __pycache__ directories"
echo "[reset] done — run: python3 -m unittest discover -s tests -v"
