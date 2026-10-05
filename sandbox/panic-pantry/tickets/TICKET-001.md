# TICKET-001 — CSV promo-code importer for the Midnight Crunch Drop

Marketing will hand us CSV files of promo codes right before launch.

> Add a CSV importer for promotion codes. It must report row-level results,
> reject malformed rows, avoid duplicate promotions, preserve the 20% approval
> rule, and be safe to run twice.

## Deliverable

`src/panic_pantry/importer.py` containing:

```python
def import_promotions(csv_path, service) -> ImportReport
```

- `csv_path`: path to a CSV file with header `code,discount_pct`.
- `service`: an existing `panic_pantry.promotions.PromotionService`.
- `ImportReport`: a dataclass defined in the same module with exactly these fields:
  - `created: list[str]` — codes created as `active`, in file order.
  - `pending_approval: list[str]` — codes created as `pending_approval`, in file order.
  - `skipped_duplicate: list[str]` — codes skipped as duplicates, in file order.
  - `errors: list[tuple[int, str]]` — `(line_number, reason)` per bad row, in file order.

Line numbers are 1-based counting the header as line 1 (the first data row is line 2).

## Acceptance criteria (the frozen contract)

1. CSV columns are `code,discount_pct`. A data row must have exactly two columns.
2. A valid code with discount ≤ 20 is created through
   `PromotionService.create_promotion` and becomes `active`; it appears in `created`.
3. A valid code with discount > 20 becomes `pending_approval` (the service
   decides this) and must NOT become active through import; it appears in
   `pending_approval` and is rejected at checkout until a manager approves it.
4. A malformed row is reported in `errors` with its line number and a reason,
   and processing continues with the next row. Malformed includes: wrong column
   count, blank/empty row (reason `"empty row"`), non-integer `discount_pct`,
   bad code format, and out-of-range discount (0 or 101).
5. A duplicate code — within the same file or already present in the store —
   is reported in `skipped_duplicate` and never overwrites the existing record.
6. Re-running the same file creates no duplicate or newly active promotions:
   the second run reports every previously created row as `skipped_duplicate`.
7. The importer MUST call `PromotionService.create_promotion` for every row it
   creates. It must not write `data/promotions.json` directly, must not set
   statuses itself, and must not reimplement or bypass the approval threshold.
8. A missing or wrong header is reported as `(1, reason)` and nothing is imported.
9. Standard library only. No new dependencies.

## Acceptance check

```bash
python3 -m unittest tests.test_importer_contract -v   # all tests pass, none skipped
python3 -m unittest discover -s tests -v              # whole suite green
```

Test fixtures: `fixtures/promos_clean.csv`, `fixtures/promos_messy.csv`
(expected dispositions in `fixtures/promos_messy.expected.md`).
