# Writable learner files by exercise

Learner planning artifacts live in this `workshop/` directory. This manifest
lists what learners (and their agents) may create or edit per exercise.

| Exercise | Checkpoint | May create/edit | Must not touch |
|---|---|---|---|
| 0 — Vague ticket / baseline | tag `starter`, worktree `single-agent` | `src/panic_pantry/importer.py` only (`tests/test_promo_import.py` is reserved for the Ex3 Breaker) | everything else |
| 1 — Split the job | tag `starter` | `workshop/plan.md`, `workshop/cards/builder.md`, `workshop/cards/breaker.md` | all of `src/`, `tests/` |
| 2 — Build the crew | tag `starter` | `.opencode/agents/implementer.md`, `reviewer.md`, `lead.md`; `.opencode/commands/review-ticket.md` (optional Level up) | all of `src/`, `tests/` (the lock checks must leave `store.py` unchanged) |
| 3 — Orchestrated run | tag `starter`, worktree `orchestrated` | `src/panic_pantry/importer.py` (implementer, running the builder card), `tests/test_promo_import.py` (Breaker), `workshop/integration-notes.md` (primary); plus the `.opencode/agents/*.md` and `workshop/cards/*.md` you copy in | each other's files above |
| 4 — Model routing | tag `starter` | `workshop/model-comparison.md`, scratch branch files | shared fixtures and tests |
| Capstone | end of Ex. 3 | files from Ex. 3 plus `workshop/release-note.md` | fixtures, scripts |

Always read-only for every exercise: `tests/test_importer_contract.py`,
`fixtures/`, `data/promotions.json.seed`, `tickets/`, `scripts/`, `AGENTS.md`.
Reset between attempts with `bash scripts/reset.sh`.
