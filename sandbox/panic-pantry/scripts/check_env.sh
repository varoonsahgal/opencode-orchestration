#!/usr/bin/env bash
# Verify the classroom environment for the Panic Pantry sandbox.
# Prints tool versions and runs the offline test suite. Exits nonzero on failure.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0

if python3 --version; then :; else
  echo "[check_env] FAIL: python3 not found"
  fail=1
fi

if git --version; then :; else
  echo "[check_env] FAIL: git not found"
  fail=1
fi

if command -v opencode >/dev/null 2>&1; then
  opencode --version
else
  echo "[check_env] opencode: not found (required for the class exercises)"
fi

if [ ! -f data/promotions.json ]; then
  echo "[check_env] data/promotions.json missing — running scripts/reset.sh"
  bash scripts/reset.sh >/dev/null
fi

echo "[check_env] running test suite..."
if python3 -m unittest discover -s tests; then
  echo "[check_env] tests: PASS"
else
  echo "[check_env] FAIL: test suite did not pass"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "[check_env] OK"
fi
exit "$fail"
