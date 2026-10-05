# Panic Pantry

Panic Pantry is a tiny late-night snack shop written in pure Python 3
(standard library only — nothing to install). The team is heads-down
preparing the **Midnight Crunch Drop**: a midnight product launch where
marketing hands out promo codes to the after-hours snack rush.

## Run the tests

```bash
python3 -m unittest discover -s tests -v
```

All tests are offline and deterministic. There is no pytest and no pip step.

## Reset the sandbox

```bash
bash scripts/reset.sh      # restore seed data, remove generated files
bash scripts/check_env.sh  # verify python3/git and a green test suite
```

## Layout

| Path | What it is |
|---|---|
| `src/panic_pantry/` | the shop: models, promotion service, catalog/checkout |
| `tests/` | unittest suites (run from the repo root) |
| `fixtures/` | CSV fixtures used by tests and exercises |
| `data/` | `promotions.json` runtime store, created from `promotions.json.seed` |
| `tickets/` | queued feature work — start with `tickets/TICKET-001.md` |
| `workshop/` | learner planning artifacts live here |
| `AGENTS.md` | rules for coding agents working in this repo |
