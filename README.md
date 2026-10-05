# Orchestration Fundamentals for Agentic Development (OpenCode)

The student repo for the four-hour course. You'll split, delegate, run, review and integrate a real feature with a crew of OpenCode agents, in a tiny offline Python shop called **Panic Pantry**.

## Start here

```bash
git clone https://github.com/varoonsahgal/opencode-orchestration.git
cd opencode-orchestration
bash sandbox/setup.sh                              # once, before Module 0
bash sandbox/panic-pantry/scripts/check_env.sh     # ends with [check_env] OK
```

Then open [Module 0](student/module-0-baseline.md). Its first section, **Before you start**, walks through these commands and what you should see. Your class VM already has OpenCode, Git and Python installed.

## What's in here

| Path | What it is |
|---|---|
| [student/](student/README.md) | The course: an overview, Modules 0–5, and appendices. Read it rendered (GitHub, or VS Code's Markdown preview: Ctrl/Cmd+Shift+V) |
| [sandbox/panic-pantry/](sandbox/panic-pantry/README.md) | The shop's code, tests and ticket. This is where you and your agents work |
| [sandbox/setup.sh](sandbox/setup.sh) | Makes the sandbox its own Git repo and creates the two worktrees the exercises use |

`sandbox/worktrees/` doesn't exist until you run `setup.sh`.
