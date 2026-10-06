# Agent rules for Panic Pantry

## Commands
- Tests (canonical): `python3 -m unittest discover -s tests -v` — run from the repo root.
- Standard library only. There is no pytest and nothing to install.
- Reset sandbox state: `bash scripts/reset.sh`
- Environment check: `bash scripts/check_env.sh`
- Acceptance gate (Module 3, run by the human): `bash scripts/gate.sh builder|breaker|integration`

## Style
- Python 3 stdlib only; do not add dependencies.
- Keep modules small (each file under ~120 lines).
- Promo codes are uppercase; money is integer cents.
- Tests must be deterministic and offline: no network, no wall clock, no randomness.

## Boundaries
- Promotion policy is enforced in `src/panic_pantry/promotions.py` — new entry
  points must go through `PromotionService.create_promotion`. Never write
  `data/promotions.json` directly and never reimplement approval logic.
- `data/promotions.json` is generated; change `data/promotions.json.seed` instead.
- Feature work is ticketed in `tickets/`. Read the ticket before coding.
- Do not edit `tests/test_importer_contract.py`, `fixtures/`, or `scripts/`.

## Where things live
- Models: `src/panic_pantry/models.py` · Service: `src/panic_pantry/promotions.py`
- Catalog/checkout: `src/panic_pantry/store.py` · Tests: `tests/`
