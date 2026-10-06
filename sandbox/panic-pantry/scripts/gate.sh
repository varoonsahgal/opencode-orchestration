#!/usr/bin/env bash
# Run the Module 3 acceptance gate on one returned artifact.
#   bash scripts/gate.sh builder        (importer.py, after Implementer returns)
#   bash scripts/gate.sh breaker        (test_promo_import.py, after Breaker returns)
#   bash scripts/gate.sh integration    (the staged product diff + the whole suite)
# It checks scope against the card's TOUCH line and runs the card's DONE check
# itself, then appends one line to the gate log in workshop/integration-notes.md.
# It never edits tracked files. Exit code: 0 = PASS, 1 = FAIL, 2 = bad usage.
cd "$(dirname "$0")/.." || exit 2
PYTHONDONTWRITEBYTECODE=1 exec python3 - "$@" <<'PY'
import datetime, os, re, shutil, subprocess, sys, tempfile

IMPORTER = "src/panic_pantry/importer.py"
BREAKER_TESTS = "tests/test_promo_import.py"
NOTES = "workshop/integration-notes.md"
TIMEOUT = 120
CARDS = {
    "builder": {"card": "workshop/cards/builder.md", "owner": "Implementer", "touch": IMPORTER,
                "done": "python3 -m unittest tests.test_importer_contract -v"},
    "breaker": {"card": "workshop/cards/breaker.md", "owner": "Breaker", "touch": BREAKER_TESTS,
                "done": "python3 -m unittest tests.test_promo_import -v"},
}
HARNESS = ("workshop/", ".opencode/")
FROZEN = re.compile(r"^(tests/test_importer_contract\.py$|fixtures/|scripts/|tickets/|data/promotions\.json\.seed$|AGENTS\.md$)")
LOG_HEADER = ("## Gate log\n\n"
              "Written by `bash scripts/gate.sh`. One line per gate run; a FAIL then a later PASS is one repair cycle.\n\n"
              "| Time | Gate | Verdict | Evidence |\n|---|---|---|---|\n")


def git(*args):
    try:
        p = subprocess.run(["git", *args], capture_output=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return p.stdout.decode("utf-8", "replace") if p.returncode == 0 else None


def card_line(path, key):
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None
    m = re.search(rf"^\s*{key}:\s*(.+)$", text, re.M)
    return m.group(1).strip() if m else None


def touch_files(name):
    """The files on the card's TOUCH line, or the default if the card can't be read."""
    spec = CARDS[name]
    line = card_line(spec["card"], "TOUCH")
    paths = re.findall(r"[\w./-]+\.\w+", line or "")
    paths = [p for p in paths if "/" in p]
    if paths:
        return paths, f"{spec['card']} TOUCH: {line}"
    return [spec["touch"]], f"({spec['card']} has no readable TOUCH line; using {spec['touch']})"


def done_command(name):
    spec = CARDS[name]
    line = card_line(spec["card"], "DONE") or ""
    cmd = re.split(r"\s*(?:→|->)\s*", line, maxsplit=1)[0].strip()
    if cmd.startswith("python3 -m unittest"):
        return cmd.split(), line
    return spec["done"].split(), f"(no runnable DONE command on {spec['card']}; using: {spec['done']})"


def changed_product_files():
    """Changed or new files since the starter tag, harness files left out."""
    base = "starter" if git("rev-parse", "-q", "--verify", "refs/tags/starter^{commit}") else "HEAD"
    files = set()
    parts = (git("diff", "--name-only", "--no-renames", "--relative", "-z", base, "--", ".") or "").split("\0")
    files.update(p for p in parts if p)
    others = (git("ls-files", "--others", "--exclude-standard", "-z", "--", ".") or "").split("\0")
    files.update(p for p in others if p)
    return sorted(f for f in files if not f.startswith(HARNESS))


def run_tests(cmd, cwd="."):
    """(ran, failed, skipped, last line, loaded) from unittest's own summary."""
    args = cmd[1:] if cmd[:1] == ["python3"] else cmd
    if args[:2] == ["-m", "unittest"] and "-b" not in args:
        args = args[:2] + (["discover", "-b"] + args[3:] if args[2:3] == ["discover"] else ["-b"] + args[2:])
    try:
        p = subprocess.run([sys.executable, *args], cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return None
    out = p.stdout + p.stderr
    ran = re.findall(r"^Ran (\d+) tests? in", out, re.M)
    status = re.findall(r"^(OK|FAILED)\b(.*)$", out, re.M)
    if not ran or not status:
        return {"loaded": False, "line": "the tests did not run"}
    counts = {k: int(v) for k, v in re.findall(r"(failures|errors|skipped|expected failures)=(\d+)", status[-1][1])}
    word, rest = status[-1]
    return {"loaded": "_FailedTest" not in out,
            "ran": int(ran[-1]), "failed": counts.get("failures", 0) + counts.get("errors", 0),
            "skipped": counts.get("skipped", 0), "line": f"Ran {ran[-1]}: {(word + rest).strip()}"}


class Gate:
    def __init__(self, name):
        self.name, self.checks = name, []

    def check(self, label, ok, detail):
        self.checks.append((label, ok, detail))
        print(f"  {'PASS' if ok else 'FAIL'}  {label:<10} {detail}")

    def note(self, text):
        print(f"              {text}")

    @property
    def passed(self):
        return all(ok for _, ok, _ in self.checks)


def scope(gate, name, changed):
    """Every changed product file belongs to exactly one card; this card's file is among them."""
    mine, where = touch_files(name)
    other = [f for n in CARDS if n != name for f in touch_files(n)[0]]
    print(f"  card       {where}")
    if not any(f in changed for f in mine):
        gate.check("returned", False, f"{', '.join(mine)} is unchanged: nothing has come back yet")
        return
    gate.check("returned", True, f"{', '.join(f for f in mine if f in changed)} changed")
    strays = [f for f in changed if f not in mine and f not in other]
    frozen = [f for f in strays if FROZEN.match(f)]
    if frozen:
        gate.check("scope", False, f"FROZEN FILE CHANGED: {', '.join(frozen)}")
    elif strays:
        gate.check("scope", False, f"outside every card's TOUCH line: {', '.join(strays)}")
    else:
        others = [f for f in changed if f in other]
        gate.check("scope", True, "no file outside the cards' TOUCH lines"
                   + (f" ({', '.join(others)} belongs to the other card)" if others else ""))
    gate.note(f"git can't see who wrote a file: confirm in the child session that {CARDS[name]['owner']} made the edit.")


def builder_evidence(gate):
    cmd, line = done_command("builder")
    print(f"  card       DONE: {line}")
    r = run_tests(cmd)
    if r is None:
        gate.check("evidence", False, f"TIMEOUT after {TIMEOUT}s: look for an infinite loop")
    elif not r["loaded"]:
        gate.check("evidence", False, f"{r['line']}: the contract tests can't load")
    elif r["skipped"] == r["ran"]:
        gate.check("evidence", False, f"{r['line']}: every test skipped, so import_promotions didn't import")
    else:
        gate.check("evidence", r["failed"] == 0 and r["skipped"] == 0,
                   f"{r['line']} (DONE needs OK with none skipped)")


def breaker_evidence(gate):
    cmd, line = done_command("breaker")
    print(f"  card       DONE: {line}")
    # The card's DONE is about a checkout with no importer, so check it in a copy without one.
    tmp = tempfile.mkdtemp(prefix="gate-")
    try:
        for d in ("src", "tests", "fixtures", "data", "tickets"):
            if os.path.isdir(d):
                shutil.copytree(d, os.path.join(tmp, d), ignore=shutil.ignore_patterns("__pycache__"))
        for f in (IMPORTER, "data/promotions.json"):
            if os.path.exists(os.path.join(tmp, f)):
                os.remove(os.path.join(tmp, f))
        r = run_tests(cmd, cwd=tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    if r is None:
        gate.check("evidence", False, f"TIMEOUT after {TIMEOUT}s without importer.py")
    elif not r["loaded"] or r["ran"] == 0:
        gate.check("evidence", False, f"without importer.py: {r['line']}: the tests don't load (or there are none)")
    else:
        gate.check("evidence", r["failed"] == 0 and r["skipped"] == r["ran"],
                   f"without importer.py: {r['line']} (DONE needs OK, every test skipped)")
    if os.path.isfile(IMPORTER):
        r = run_tests(cmd)
        if r and r["loaded"]:
            gate.note(f"against the real importer: {r['line']}")
            if r["failed"]:
                gate.note("A failing Breaker test is a finding, not a Breaker failure. Decide its owner at the integration gate (B5).")


def integration(gate, changed):
    staged = sorted(p for p in (git("diff", "--cached", "--name-only", "--relative", "-z") or "").split("\0") if p)
    harness = [f for f in staged if f.startswith(HARNESS)]
    owned = {f: n for n in CARDS for f in touch_files(n)[0]}
    strays = [f for f in staged if f not in owned and f not in harness]
    unstaged = [f for f in changed if f in owned and f not in staged]
    if not staged:
        gate.check("staged", False, "nothing is staged: git add importer.py and test_promo_import.py first (B4)")
    elif harness:
        gate.check("staged", False, f"harness files are staged: {', '.join(harness)} (git restore --staged them)")
    elif strays:
        gate.check("ownership", False, f"staged files no card owns: {', '.join(strays)}")
    else:
        gate.check("ownership", True, "; ".join(f"{f} -> {CARDS[owned[f]]['owner']}" for f in staged))
    if unstaged:
        gate.note(f"changed but not staged: {', '.join(unstaged)}. Is that on purpose?")
    r = run_tests(["python3", "-m", "unittest", "discover", "-s", "tests"])
    if r is None:
        gate.check("evidence", False, f"whole suite: TIMEOUT after {TIMEOUT}s")
    elif not r["loaded"]:
        gate.check("evidence", False, f"whole suite: {r['line']}: some tests don't load")
    else:
        gate.check("evidence", r["failed"] == 0, f"whole suite: {r['line']}")
        if r["failed"]:
            gate.note("Who owns the failure? Test matches the ticket -> Implementer. Test contradicts it -> Breaker.")
            gate.note("Details: python3 -m unittest discover -s tests -v")


def log(gate):
    if not os.path.isdir("workshop"):
        return
    try:
        text = open(NOTES, encoding="utf-8").read() if os.path.exists(NOTES) else "# Orchestrated run notes\n"
    except OSError:
        return
    if "## Gate log" not in text:
        text = text.rstrip("\n") + "\n\n" + LOG_HEADER
    evidence = "; ".join(f"{label}: {detail}" for label, ok, detail in gate.checks if not ok) \
        or "; ".join(detail for label, _, detail in gate.checks if label == "evidence")
    row = f"| {datetime.datetime.now():%H:%M:%S} | {gate.name} | {'PASS' if gate.passed else 'FAIL'} | {evidence.replace('|', '/')} |\n"
    # Rows go at the end of the gate-log table, even if notes were written below it.
    head, _, tail = text.partition("## Gate log")
    lines = tail.splitlines(keepends=True)
    start = next((i for i, l in enumerate(lines) if l.startswith("|")), None)
    if start is None:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        lines.append("\n")
        start = len(lines)
        lines += LOG_HEADER.split("\n\n", 2)[2].splitlines(keepends=True)
    end = start
    while end < len(lines) and lines[end].startswith("|"):
        end += 1
    if end and not lines[end - 1].endswith("\n"):
        lines[end - 1] += "\n"
    lines.insert(end, row)
    with open(NOTES, "w", encoding="utf-8") as f:
        f.write(head + "## Gate log" + "".join(lines))
    print(f"\n  logged to {NOTES}")


def main():
    name = sys.argv[1].lower() if len(sys.argv) > 1 else ""
    if name not in ("builder", "breaker", "integration"):
        print("usage: bash scripts/gate.sh builder | breaker | integration")
        return 2
    if git("rev-parse", "--is-inside-work-tree") is None:
        print("gate.sh needs a git checkout: run it inside sandbox/worktrees/orchestrated")
        return 2
    gate = Gate(name)
    print(f"Gate: {name}   ({os.getcwd()}, branch {(git('branch', '--show-current') or '?').strip()})\n")
    changed = changed_product_files()
    if name == "integration":
        integration(gate, changed)
    else:
        scope(gate, name, changed)
        if gate.passed:
            (builder_evidence if name == "builder" else breaker_evidence)(gate)
    if gate.passed:
        verdict = "PASS: accept it."
    elif gate.checks and gate.checks[0][0] == "returned" and not gate.checks[0][1]:
        verdict = "FAIL: not returned yet. Nothing to accept."
    else:
        verdict = "FAIL: not accepted. Send a narrow repair to the artifact's owner (B5)."
    print(f"\n  {verdict}")
    if "not returned" not in verdict:
        log(gate)
    return 0 if gate.passed else 1


try:
    sys.exit(main())
except Exception as exc:  # a gate must never crash the room
    print(f"\ngate.sh hit an unexpected problem: {exc!r}. Run the DONE check by hand instead.")
    sys.exit(1)
PY
