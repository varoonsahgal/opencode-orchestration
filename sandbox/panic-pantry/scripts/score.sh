#!/usr/bin/env bash
# Print the measured rows of the Panic Pantry scorecard for THIS checkout.
#   bash scripts/score.sh        (works from any folder, in any worktree)
# It reports; it never edits tracked files, and it always exits 0.
# Model + variant and the intervention count can't be measured: fill those in yourself.
cd "$(dirname "$0")/.." || exit 0
PYTHONDONTWRITEBYTECODE=1 exec python3 - <<'PY'
import io, os, re, subprocess, sys, tokenize

CONTRACT = "tests/test_importer_contract.py"
IMPORTER = "src/panic_pantry/importer.py"
FROZEN = re.compile(r"^(tests/test_importer_contract\.py$|fixtures/|scripts/|tickets/|data/promotions\.json\.seed$|AGENTS\.md$)")
TIMEOUT = 120
PAD = " " * 23


def row(label, text):
    print(f"{label:<22} {text}".rstrip())


def git(*args):
    try:
        p = subprocess.run(["git", *args], capture_output=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return p.stdout.decode("utf-8", "replace") if p.returncode == 0 else None


def run_tests(args):
    """Run unittest with -b so prints and logging inside tests can't garble the result."""
    try:
        cmd = [sys.executable, "-m", "unittest"]
        cmd += ["discover", "-b", *args[1:]] if args[:1] == ["discover"] else ["-b", *args]
        p = subprocess.run(cmd,
                           capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return None
    return p.stdout + p.stderr


def summary(out):
    """(ran, passed, skipped, last line) from unittest's own summary, or None if the tests didn't load."""
    ran = re.findall(r"^Ran (\d+) tests? in", out, re.M)
    status = re.findall(r"^(OK|FAILED)\b(.*)$", out, re.M)
    if not ran or not status or "_FailedTest" in out:
        return None
    n = int(ran[-1])
    word, rest = status[-1]
    counts = {k: int(v) for k, v in re.findall(r"(failures|errors|skipped|expected failures)=(\d+)", rest)}
    return n, n - sum(counts.values()), counts.get("skipped", 0), (word + rest).strip()


def load_error(out):
    where = re.findall(r'File "([^"]+)", line (\d+)', out)
    err = re.findall(r"^(\w*(?:Error|Exception)\b.*)$", out, re.M)
    place = ""
    if where:
        path, line = where[-1]
        if os.path.isabs(path):
            path = os.path.relpath(path)
        place = f" in {path} line {line}"
    return f"{err[-1] if err else 'the tests did not load'}{place}"


def code_only(src):
    """The source with comments removed and string contents blanked (quotes kept)."""
    chars = list(src)
    starts, pos = [], 0
    for line in src.splitlines(keepends=True):
        starts.append(pos)
        pos += len(line)
    starts.append(pos)

    def off(rc):
        r, c = rc
        return starts[r - 1] + c if r - 1 < len(starts) else len(chars)

    def blank(a, b):
        for i in range(max(a, 0), min(b, len(chars))):
            if chars[i] != "\n":
                chars[i] = " "

    try:
        toks = list(tokenize.generate_tokens(io.StringIO(src).readline))
    except (tokenize.TokenError, SyntaxError):
        return re.sub(r"#[^\n]*", "", src)
    fmid = getattr(tokenize, "FSTRING_MIDDLE", None)
    for t in toks:
        a, b = off(t.start), off(t.end)
        if t.type == tokenize.COMMENT or (fmid is not None and t.type == fmid):
            blank(a, b)
        elif t.type == tokenize.STRING:
            s = t.string
            i = next((k for k, ch in enumerate(s) if ch in "'\""), 0)
            q = 3 if s[i:i + 3] in ('"""', "'''") else 1
            blank(a + i + q, b - q)
    return "".join(chars)


CMP = r"(?:<=|>=|==|!=|<|>)"
CODE_PATTERNS = [
    (r"APPROVAL_THRESHOLD_PCT", "uses the service's threshold constant"),
    (rf"{CMP}\s*2[01]\b|\b2[01]\s*{CMP}", "compares a number to 20 or 21"),
    (r"^\s*[A-Za-z_]\w*\s*=\s*2[01]\s*$", "stores 20 or 21 in a name"),
    (r"\.status\s*=(?!=)|\bstatus\s*=\s*[\"']", "sets a status"),
    (r"\bPromotion\s*\(", "builds a Promotion itself instead of calling create_promotion"),
    (r"\._promotions\b", "reaches into the service's private store"),
    (r"\.approve\s*\(", "approves a promotion"),
    (r"\bjson\.dump", "writes JSON itself"),
]


def policy_scan(path):
    src = open(path, encoding="utf-8", errors="replace").read()
    original = src.splitlines()
    code = code_only(src).splitlines()
    no_comments = re.sub(r"#[^\n]*", "", src).splitlines()
    hits = []
    for i, line in enumerate(code):
        cleaned = re.sub(rf"len\([^()]*\)\s*{CMP}\s*\d+|\d+\s*{CMP}\s*len\([^()]*\)", "", line)
        reasons = [why for pat, why in CODE_PATTERNS if re.search(pat, cleaned)]
        if i < len(no_comments) and "promotions.json" in no_comments[i]:
            reasons.append("names the store file")
        if reasons:
            hits.append(f"importer.py:{i + 1}: {original[i].strip()}   <- {', '.join(reasons)}")
    return hits


def changed_files():
    if git("rev-parse", "--is-inside-work-tree") is None:
        return "Files changed", ["(can't tell: this folder isn't a git checkout)"]
    if git("rev-parse", "-q", "--verify", "refs/tags/starter^{commit}"):
        base, label = "starter", "Files changed since starter"
    elif git("rev-parse", "-q", "--verify", "HEAD"):
        base, label = "HEAD", "Files changed since the last commit"
    else:
        return "Files changed", ["(can't tell: nothing is committed yet)"]
    entries = []
    parts = (git("diff", "--name-status", "--no-renames", "--relative", "-z", base, "--", ".") or "").split("\0")
    for k in range(0, len(parts) - 1, 2):
        entries.append((parts[k][:1], parts[k + 1]))
    others = git("ls-files", "--others", "--exclude-standard", "-z", "--", ".") or ""
    entries += [("?", p) for p in others.split("\0") if p]
    lines = []
    for code, path in sorted(entries, key=lambda e: e[1]):
        if path == IMPORTER:
            tag = "Builder's file"
        elif path == "tests/test_promo_import.py":
            tag = "reserved for the Ex4 Breaker: out of scope here" if BRANCH == "single-agent" else "Breaker's file"
        elif path.startswith(("workshop/", ".opencode/")):
            tag = "your notes and agent setup"
        elif FROZEN.match(path):
            tag = "FROZEN FILE CHANGED: nobody may edit this"
        else:
            tag = "NO CARD OWNS THIS FILE: boundary problem?"
        kind = {"A": "added", "M": "changed", "D": "deleted", "?": "new", "T": "changed"}.get(code, code)
        lines.append(f"{kind:<8} {path:<40} {tag}")
    return label, lines or ["(none)"]


BRANCH = (git("branch", "--show-current") or "").strip()


def main():
    branch = BRANCH
    if not branch and git("rev-parse", "--is-inside-work-tree") is not None:
        at = (git("describe", "--tags", "--exact-match") or git("rev-parse", "--short", "HEAD") or "?").strip()
        branch = f"(detached at {at})"
    print(f"Scorecard for: {os.getcwd()}")
    print(f"Branch:        {branch or '(not a git checkout)'}")
    print()

    try:
        total = len(re.findall(r"^\s+def test_", open(CONTRACT, encoding="utf-8").read(), re.M)) or 9
    except OSError:
        total = 9
    out = run_tests(["tests.test_importer_contract", "-v"])
    hung = out is None
    if hung:
        row("Contract tests", f"0/{total}   (TIMEOUT: a test ran over {TIMEOUT}s; look for an infinite loop)")
    else:
        s = summary(out)
        if s is None:
            row("Contract tests", f"0/{total}   (ERROR: the tests can't load: {load_error(out)})")
        elif s[2] == s[0] and s[1] == 0:
            row("Contract tests", f"0/{total}   (SKIPPED: the tests can't import import_promotions: "
                                  "file missing, misnamed, or a failed import inside it. Counts as 0)")
        else:
            row("Contract tests", f"{s[1]}/{total}   ({s[3]})")

    out = None if hung else run_tests(["discover", "-s", "tests"])
    if hung:
        row("Whole suite", "not run: the contract tests already timed out")
    elif out is None:
        row("Whole suite", f"TIMEOUT after {TIMEOUT}s")
    else:
        s = summary(out)
        row("Whole suite", f"ran {s[0]} tests: {s[3]}" if s else f"ERROR: {load_error(out)}")

    if os.path.isfile(IMPORTER):
        hits = policy_scan(IMPORTER)
        if hits:
            row("Policy source check", "CHECK BY EYE: these lines may decide approval themselves")
            for h in hits:
                print(PAD + h)
        else:
            row("Policy source check", "nothing flagged (a text scan: still read how it picks created vs. pending)")
    else:
        row("Policy source check", f"n/a ({IMPORTER} doesn't exist)")

    label, lines = changed_files()
    row(label, "")
    for line in lines:
        print(PAD + line)

    print()
    print("Fill in by hand: model + variant (status bar), interventions (your tally),")
    print("                 elapsed and rework minutes (your timer), tokens / cost (opencode stats).")
    print("Details: python3 -m unittest tests.test_importer_contract -v")


try:
    main()
except Exception as exc:  # a report must never crash the room
    print(f"\nscore.sh hit an unexpected problem: {exc!r}. Run the tests directly instead.")
sys.exit(0)
PY
