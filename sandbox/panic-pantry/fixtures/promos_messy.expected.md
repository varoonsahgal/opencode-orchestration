# Expected disposition of fixtures/promos_messy.csv

Line numbers are 1-based; line 1 is the header. Assumes the store was just
reset from `data/promotions.json.seed` (which already contains `WELCOME10`).

| Line | Row | Expected result | Reason |
|---|---|---|---|
| 1 | `code,discount_pct` | header | not a data row |
| 2 | `CRUNCH10,10` | created, active | valid code, discount ≤ 20 |
| 3 | `MIDNIGHT20,20` | created, active | boundary: exactly 20 does not need approval |
| 4 | `HALFOFF,50` | created, pending_approval | discount > 20 requires manager approval |
| 5 | `VIP25,25` | created, pending_approval | discount > 20 requires manager approval |
| 6 | `FREE-ALL,100` | created, pending_approval | discount > 20; must never activate via import |
| 7 | `CRUNCH10,15` | skipped_duplicate | duplicate of line 2 within this file; keeps 10% |
| 8 | `WELCOME10,10` | skipped_duplicate | already exists in seeded data; never overwritten |
| 9 | `SNACKS` | error (line 9) | missing discount_pct column |
| 10 | `OOPS,ten` | error (line 10) | discount_pct is not an integer |
| 11 | `lowercase-code,10` | error (line 11) | code fails format `^[A-Z0-9-]{3,20}$` |
| 12 | (blank line) | error (line 12) | empty row |
| 13 | `ZERO,0` | error (line 13) | discount out of range (must be 1-100) |
| 14 | `TOOMUCH,101` | error (line 14) | discount out of range (must be 1-100) |

Net effect of one import on a freshly reset store: 2 new active promotions,
3 new pending_approval promotions, 2 duplicates skipped, 6 row errors.
Running the import a second time creates nothing new: lines 2-8 all report
as skipped_duplicate and lines 9-14 report the same errors.
