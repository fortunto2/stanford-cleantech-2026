# Evidence: the rule exists, the exposure is large, enforcement is near zero

## Exposure (computed here, `work/evidence_smoke_days.py`, public data, no keys)

California agricultural worker-days at PM2.5 AQI >= 151 in fire season (June–October):

| Year | County-days >= 151 | Ag worker-days |
|---|---:|---:|
| 2020 | 628 | 3,321,216 |
| 2021 | 298 | 1,230,571 |
| 2022 | 62 | 13,367 |
| 2023 | 40 | 297,375 |
| 2024 | 20 | 17,511 |
| 2025 | 13 | 8,449 |

EPA AirData daily AQI by county (defining parameter PM2.5) × BLS QCEW private NAICS 11 employment ×
5/7. A lower bound: the rule counts hours, a daily mean hides them; QCEW misses uncovered farm work.

## Enforcement (reported)

- **11 citations** under §5141.1 from July 2019 to 5 Oct 2021, 221 complaints (Cal/OSHA data via
  KVPR/CalMatters, Dec 2021). Against ~4.5M exposed worker-days in 2020–21: one citation per ~400,000.
- ~60% of 300+ San Joaquin Valley farmworkers: no N95 from the employer, or did not know what one was
  (CCEJN survey, 2021). Sonoma 2025: nearly a third bought their own PPE.
- Heat (§3395) is the opposite: the most-cited Cal/OSHA standard in agriculture every year AgSafe
  reports (e.g. 130 violations, $404K, 2017–18); the classic failure is no written plan in the field.

## What it means for the product

- Smoke is bursty (3.3M worker-days in 2020, 8K in 2025); heat is every summer and enforced. Sell the
  heat paperwork, carry smoke on the same sheet.
- Enforcement waits for complaints and workers fear retaliation: the worker report button (§5141.1
  requires employers to encourage reports) is the lever that creates the urgency enforcement does not.

## Enforcement (measured here, `work/evidence_citations.py`, DOL OSHA enforcement API)

Cal/OSHA violations by issuance year, deleted citations excluded (current penalties). Cal/OSHA is a state
plan, so its inspections are in the federal data; §3395/§3396/§5141.1 are California-only standards.

| Year | Heat §3395 | Penalties | Smoke §5141.1 | Ag worker-days in smoke |
|---|---:|---:|---:|---:|
| 2020 | 1,246 | $1,055,702 | 0 | 3,321,216 |
| 2021 | 946 | $919,977 | 16 (9 inspections, $11,690) | 1,230,571 |
| 2022 | 1,190 | $958,320 | 0 | 13,367 |
| 2023 | 1,205 | $1,066,126 | 0 | 297,375 |
| 2024 | 1,098 | $1,396,334 | 0 | 17,511 |
| 2025 | 1,118 | $1,410,945 | 1 ($250) | 8,449 |

July 2019 to 18 Sep 2026: heat 8,507 violations, $8.1M; smoke 19; indoor heat §3396 (in force 2024)
393. The state and industry split needs the inspection join, which the API keeps answering with 502;
re-run the script, violations are cached in `work/output/evidence/violations.json`.
