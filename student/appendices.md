# Appendices

## Appendix A — Objective coverage map

Every objective and topic from [COURSE_OUTLINE.md](../COURSE_OUTLINE.md):

| Outline objective / topic area | Where covered |
|---|---|
| Break complex features into agent-ready units; boundaries; task size | ML1 (bad-split Predict: split by file) ([module 1](module-1-decomposition.md)) |
| Write task specifications and acceptance criteria | ML1 (the 6-line card), Ex1 Steps 3–5, including the Stranger Test in Step 5 ([module 1](module-1-decomposition.md)) |
| Identify dependencies, sequencing, safe parallel work, needed context | ML1 (Fig. 1), Ex1 (plan's Order line; critical-path Level up), ML3, Ex3 ([module 1](module-1-decomposition.md), [module 3](module-3-parallel-run.md)) |
| Prompting → orchestrating; too-large/ambiguous/coupled tasks | Opening, Ex0 ([module 0](module-0-baseline.md)) |
| Primary agent vs subagents; child sessions; fresh context | ML2, Ex2 ([module 2](module-2-agent-crew.md)) |
| Delegating (Task tool) vs invoking directly (@-mention); letting primary pick subagents | ML2, Ex2, Ex3 ([module 2](module-2-agent-crew.md), [module 3](module-3-parallel-run.md)) |
| Foreground vs background delegated work | ML3 — explained + recorded instructor demo (experimental in pinned V1; not exercised live) ([module 3](module-3-parallel-run.md)) |
| Navigating parent/child sessions | ML2, Ex2 step 5 ([module 2](module-2-agent-crew.md)) |
| When delegation adds value vs keeping work local | Ex1 Step 1 (keep or delegate), capstone step 2 ([module 1](module-1-decomposition.md), [module 5](module-5-capstone.md)) |
| Creating custom agents; instructions; roles; reusable designs | Ex2 (implementer, reviewer, lead; `/review-ticket` command Level up) ([module 2](module-2-agent-crew.md)) |
| Tool/permission control; read-only reviewer; controlled write access; preventing dangerous actions; controlling delegation targets | ML2, Ex2: `edit: deny` reviewer, path-locked implementer, `bash` allowlists, locks proved with `opencode debug agent` (Step 3); `permission.task` allowlist on the lead (Step 6); trifecta Level up. Ex3 lets the primary route a card ([module 2](module-2-agent-crew.md), [module 3](module-3-parallel-run.md)) |
| Model capability vs complexity/risk; reasoning-quality/latency/cost; variants and effort levels; escalation; avoiding expensive-model waste | ML4, Ex4 ([module 4](module-4-model-routing.md)) |
| Selecting models in OpenCode; per-agent models | ML4 (`/models`, per-agent `model`), Ex4 ([module 4](module-4-model-routing.md)) |
| Parallel orchestration; shared context; file ownership; conflict prevention; branches/worktrees; deliverable tracking | ML3, Ex3 ([module 3](module-3-parallel-run.md)) |
| Review, validate, integrate multi-agent results | ML5, Ex3 integration, capstone ([module 3](module-3-parallel-run.md), [module 5](module-5-capstone.md)) |
| Skills (on-demand know-how the agent pulls in) and hooks (plugin code on every tool call) | ML3 concept section, Ex3 Step 6 (crew-guard hook), Step 9 (live tool log), Step 13 (Reviewer pulls in a skill unprompted); Level ups: lock the skill shelf, write your own hook ([module 3](module-3-parallel-run.md)) |

## Appendix B — Command crib sheet

```bash
python3 -m unittest discover -s tests -v          # canonical test gate (repo root)
python3 -m unittest tests.test_importer_contract -v
bash scripts/reset.sh                             # restore seed data, remove importer
bash scripts/check_env.sh                         # environment + suite check
bash sandbox/setup.sh                             # (course root) one-time setup; a re-run needs --force and WIPES the worktrees
opencode models                                   # list model IDs (CLI)
opencode stats                                    # token/cost data
opencode debug agent reviewer --tool write --params '{"filePath":"src/panic_pantry/store.py","content":"# hi"}'
                                                  # run one tool with an agent's permissions, no model (Module 2)
# TUI: /models picker · Tab = Build/Plan · @agent = invoke subagent
# <Leader>+Down = first child session · Left/Right = cycle children · Up = parent (default keybinds — remappable)
# <Leader> = ctrl+x by default (press, release, then the next key)
# /new or <Leader>+n = fresh session · /models or <Leader>+m = model picker · /sessions or <Leader>+l = session list
# ctrl+t = cycle model variants (effort) · ctrl+p = command palette · esc = interrupt · /connect = add a provider
git switch -c scratch/ex4                         # throwaway branch; delete later with git branch -D
opencode debug skill                              # list every skill agents can see (project, global, ~/.claude/skills)
tail -f workshop/tool-log.md                      # live view of every tool call (written by the crew-guard hook, Module 3)
# Skills: .opencode/skills/<name>/SKILL.md (name + description frontmatter) · restart OpenCode to pick up changes
# Hooks:  .opencode/plugins/*.js|ts, auto-loaded at startup · `opencode debug agent` does NOT run hooks
```

**Agent file skeleton** (`.opencode/agents/<name>.md`; the file name is the agent name):

```markdown
---
description: <what it does and what it never does — primaries route on this>
mode: subagent                 # omit and it defaults to "all"
permission:
  edit: deny                   # allow | ask | deny
  bash:
    "*": deny                  # catch-all FIRST (last matching rule wins), and QUOTE it
    "git diff*": allow
---
<system prompt: objective, checklist, return format>
```

Path lock: `edit: {"*": deny, "src/panic_pantry/importer.py": allow}` (paths count from the git repo root). Delegation allowlist (primary agents): `task: {"*": deny, "reviewer": allow}`. `hidden: true` only hides an agent from the `@` menu; it isn't a security control.

## Appendix C — Sources

**OpenCode** (the class targets 1.18.33): [agents](https://opencode.ai/docs/agents) · [permissions](https://opencode.ai/docs/permissions) · [commands](https://opencode.ai/docs/commands) · [models](https://opencode.ai/docs/models) · [Zen](https://opencode.ai/docs/zen) · [CLI](https://opencode.ai/docs/cli) · [rules](https://opencode.ai/docs/rules)

**Stories and studies used in the modules**

- METR, *Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity* (Jul 2025): https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ and the Feb 2026 design update: https://metr.org/blog/2026-02-24-uplift-update/ (Module 0)
- Anthropic, *How We Built Our Multi-Agent Research System* (Jun 2025): https://www.anthropic.com/engineering/multi-agent-research-system (Modules 0 and 1)
- Mars Climate Orbiter (1999): https://en.wikipedia.org/wiki/Mars_Climate_Orbiter (Module 1)
- METR, *Recent Frontier Models Are Reward Hacking* (Jun 2025): https://metr.org/blog/2025-06-05-recent-reward-hacking/ (Module 1)
- Panickssery, Bowman & Feng, *LLM Evaluators Recognize and Favor Their Own Generations* (Apr 2024): https://arxiv.org/abs/2404.13076 (Module 2)
- The Register, Replit agent deletes a production database during a code freeze (Jul 2025): https://www.theregister.com/2025/07/21/replit_saastr_vibe_coding_incident/ (Module 2)
- Chroma, *Context Rot* (2025): https://www.trychroma.com/research/context-rot (Module 2)
- Anthropic, *Effective Context Engineering for AI Agents* (Sep 2025): https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents (Module 2)
- Simon Willison, *The lethal trifecta for AI agents* (Jun 2025): https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ (Module 2 Level up)
- OpenAI, *Harness Engineering* (Feb 2026): https://openai.com/index/harness-engineering/. A **harness** is everything around the model that shapes what it does: rules files, tools, permissions, tests. The post recommends keeping `AGENTS.md` a short table of contents and enforcing the real rules mechanically with tests, which is how this sandbox is built.

Model catalogs, free-model availability and these pages change. Recheck anything dated before you rely on it after class.

## Appendix D — Image credits

| Image | Source | License |
|---|---|---|
| [images/kitchen-pass.jpg](images/kitchen-pass.jpg) | MarkBuckawicki, "Restaurant Kitchen expo station," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Restaurant_Kitchen_expo_station.jpg) (resized) | CC0 1.0 |
| [images/opencode-tui.png](images/opencode-tui.png) | [OpenCode project](https://github.com/sst/opencode) README screenshot (resized) | MIT License, © 2025 opencode |
| [images/critical-path.png](images/critical-path.png) | Illes, "5n PERT graph with critical path," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:5n_PERT_graph_with_critical_path.svg) (rasterized, cropped) | Public domain |
| [images/swiss-cheese-model.png](images/swiss-cheese-model.png) | Davidmack, "Swiss cheese model of accident causation," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Swiss_cheese_model_of_accident_causation.png) (resized) | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) |
| [images/key-ring.jpg](images/key-ring.jpg) | Tmorrisey, "Key ring full," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Key_ring_full.jpg) | Public domain |
| [images/control-tower.jpg](images/control-tower.jpg) | Harrison Keely, "The FAA air traffic control tower at Philadelphia International Airport," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:The_FAA_air_traffic_control_tower_at_Philadelphia_International_Airport.jpg) (resized) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| [images/preflight-checklist.jpg](images/preflight-checklist.jpg) | U.S. Air Force, "Preflight checklist," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Preflight_checklist_(14443492762).jpg) (resized) | Public domain |
| [images/flight-data-recorder.jpg](images/flight-data-recorder.jpg) | U.S. National Transportation Safety Board, "Fdr sidefront," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Fdr_sidefront.jpg) | Public domain |
| [images/railway-switch-lever.jpg](images/railway-switch-lever.jpg) | W.carter, "Railway switch lever on Grötö," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Railway_switch_lever_on_Gr%C3%B6t%C3%B6.jpg) (resized) | Public domain |
| [images/night-launch.jpg](images/night-launch.jpg) | NASA Marshall Space Flight Center / Terry White, "NASA's Evolved SLS Block 1B Crew Rocket - Night Launch," [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:NASA%E2%80%99s_Evolved_SLS_Block_1B_Crew_Rocket_-_Night_Launch_(B1B_Crew_Night_Launch).jpg) (resized) | Public domain |

Images are stored locally so the handout works offline, like the rest of the course.

---

## Appendix E — Glossary

Look things up here; don't pre-read it. Each term links to the module that teaches it.

**Orchestration vocabulary**

| Term | Plain-English meaning | Taught in |
|---|---|---|
| **Orchestration** | Splitting a feature into checkable tasks, handing them to agents, and integrating what comes back — you as the release lead | [Module 1](module-1-decomposition.md) |
| **Contract** | The agreed interface and rules every task builds against: function signature, return shape, edge-case behavior, policy | [Module 1](module-1-decomposition.md) |
| **Freeze (a contract)** | Declare it final *before* work starts. Nobody changes it mid-run; if it must change, you stop, re-freeze, and re-brief everyone | [Module 1](module-1-decomposition.md) |
| **Task card** | Six lines (DO, READ, RULES, TOUCH, DONE, REPORT) that give one agent exactly one job. The card is the whole message you send it | [Module 1](module-1-decomposition.md) |
| **Builder / Breaker** | The two TICKET-001 jobs. The Builder writes the importer. The Breaker writes tests from the ticket (never from the Builder's code) that attack it, starting with every way `FREE-ALL` could go live | [Module 1](module-1-decomposition.md) |
| **Acceptance check** | An executable way to decide "done": the card's DONE line. "Looks good" isn't one | [Module 1](module-1-decomposition.md) |
| **Idempotent** | Safe to run twice: the second run changes nothing | [TICKET-001](../sandbox/panic-pantry/tickets/TICKET-001.md), criterion 6 |
| **Disposition** | The decided outcome for an item. For a CSV row: which `ImportReport` bucket it lands in. For a review finding: fix, accept with reason, or defer with an owner | [Module 4](module-4-model-routing.md), [Module 5](module-5-capstone.md) |
| **Intervention** | Any time you step into a run to steer it — a correction, clarification, or manual edit | [Module 0](module-0-baseline.md) |
| **Matched comparison** | Two runs with the same commit, ticket, tests, model, and timebox, so the only difference is the approach | [Module 3](module-3-parallel-run.md) |

**OpenCode vocabulary**

| Term | Plain-English meaning | Taught in |
|---|---|---|
| **Primary agent** | The agent you talk to directly in the main conversation. Built-ins: **Build** (full tools) and **Plan** (can't edit your files, but can still run shell commands). Tab switches between them | [Module 0](module-0-baseline.md) |
| **Subagent** | A helper agent the primary (or you) hands one task to. Built-ins in 1.18.33: **explore** (fast codebase search; read-only by its prompt only, since it may run shell commands) and **general** (multi-step tasks; can edit). You'll build your own | [Module 2](module-2-agent-crew.md) |
| **Session / child session** | A session is one conversation. A delegation creates a **child session** under it — a new conversation with fresh, empty context | [Module 2](module-2-agent-crew.md) |
| **Session tree** | A parent session plus the child sessions its delegations created. You walk it with the child-navigation keys | [Module 3](module-3-parallel-run.md) |
| **@-mention** | *You* choose the subagent: `@reviewer check the diff` | [Module 2](module-2-agent-crew.md) |
| **Task tool** | The tool the *primary agent* calls to delegate on its own. It chooses the subagent by reading each subagent's `description`; `permission.task` limits which ones it may pick. Subagents don't get it | [Module 2](module-2-agent-crew.md), [Module 3](module-3-parallel-run.md) |
| **Permission** (`allow` / `ask` / `deny`) | Configured authority per action: `allow` runs, `ask` pauses for your approval, `deny` blocks — whatever the prompt says | [Module 2](module-2-agent-crew.md) |
| **Frontmatter** | The YAML block between `---` fences at the top of an agent file — its settings. The body below is its system prompt | [Module 2](module-2-agent-crew.md) |
| **Provider / model ID** | A provider is a model service (Anthropic, OpenAI, OpenCode Zen, …). Models are named `provider_id/model_id` | [Module 4](module-4-model-routing.md) |
| **Variant (effort)** | A preset for the same model — e.g., a higher thinking budget or reasoning effort. `ctrl+t` cycles variants | [Module 4](module-4-model-routing.md) |
| **Leader key** | A prefix key for many shortcuts; `ctrl+x` by default. `<Leader>+Down` means press `ctrl+x`, release, then press ↓ | [Module 0](module-0-baseline.md) |
| **Foreground / background delegation** | Foreground: the primary waits for the child to finish. Background: the child runs while the primary keeps working (experimental in the V1 line; not used live today) | [Module 3](module-3-parallel-run.md) |
| **Skill** | A folder with a `SKILL.md` (name + description + instructions) in `.opencode/skills/`. Agents see only the name and description until they decide the task matches; then they **pull in** the full body with the `skill` tool. The `skill` permission limits who may load what | [Module 3](module-3-parallel-run.md) |
| **Plugin / hook** | A plugin is a JS/TS file OpenCode auto-loads from `.opencode/plugins/`. Its **hooks** are functions OpenCode calls at fixed points (e.g., before and after every tool call), so they run every time whether or not the model remembers. Throwing in `tool.execute.before` blocks the call | [Module 3](module-3-parallel-run.md) |

**Git words** (tag, branch, worktree, tracked, untracked): see [Appendix F](#appendix-f--git-in-90-seconds).

## Appendix F — Git in 90 seconds

- A **commit** is a saved snapshot of the whole project. A **tag** is a permanent name for one commit: `starter` always means "the shop before anyone touched it".
- A **branch** is a movable name for a line of work. It moves forward as you commit on it.
- A **worktree** is an extra folder attached to the same repository, with its own branch checked out. Editing a file in `worktrees/single-agent` can't change the same file in `worktrees/orchestrated`: they're different files on disk.
- Files Git knows about are **tracked**. New files you create (agent files, cards, notes) are **untracked** until committed, and untracked files exist *only* in the folder where you made them. That's why Module 3 has you copy your agents and cards across.

Why you care: the course ends with a comparison (one agent vs. a crew). Worktrees guarantee both runs start from the same commit and can't contaminate each other.

## Appendix G — Version note

OpenCode V2 exists and renames some vocabulary (`permissions`, `shell`, `subagent`). This class uses **V1 syntax only**, matching the pinned 1.18.33 binary. If a doc page or blog snippet looks different from these materials, check which major version it targets before trusting it.

---

Back to the [course index](README.md).
