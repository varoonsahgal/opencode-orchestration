---
name: promo-policy-review
description: Panic Pantry checklist for reviewing, auditing or accepting code that creates, imports or changes promotions or discounts (importer.py, test_promo_import.py, promotions.py). Use when reviewing the CSV promo importer or any promo/discount change.
---

# Promo policy review (Panic Pantry)

Start your report with this exact line, so the human can see this checklist was used:

`Checklist: promo-policy-review`

Then mark every item PASS, FAIL or UNSURE, with a file:line for each FAIL.

## 1. The 20% rule lives in the service, not the importer

- [ ] `importer.py` never compares a discount to 20 (or to `APPROVAL_THRESHOLD_PCT`).
- [ ] `importer.py` never sets `status`, `"active"` or `"pending_approval"` itself.
- [ ] Every created row goes through `PromotionService.create_promotion`.
- [ ] Nothing writes `data/promotions.json` directly.

## 2. The boundary cases are tested, not assumed

- [ ] A test proves exactly **20** ends up `active` (in `created`).
- [ ] A test proves **21** ends up `pending_approval`, never `active`.
- [ ] A test proves `FREE-ALL,100` cannot end up active.

## 3. Duplicates include what's already in the store

- [ ] `WELCOME10` (seeded in the store) is reported as `skipped_duplicate`, even if it appears only once in the CSV.
- [ ] Running the same file twice creates nothing new the second time.

## 4. Errors are honest

- [ ] Line numbers count the header as line 1 (first data row is line 2).
- [ ] A blank row's reason is exactly `"empty row"`.
- [ ] A bad header is reported as `(1, reason)` and nothing is imported.

## 5. Scope

- [ ] Only `src/panic_pantry/importer.py` and `tests/test_promo_import.py` changed in `src/` and `tests/`.
- [ ] No test was weakened, skipped or deleted to make the suite pass.

End with one line: `Verdict: SHIP`, `Verdict: FIX FIRST` or `Verdict: NEEDS HUMAN`.
