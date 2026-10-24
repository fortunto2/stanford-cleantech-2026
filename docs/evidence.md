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

To do with a DOL API key: §5141.1 and §3395 citations and complaints 2022–2026 from OSHA enforcement
data (inspection, violation, related_activity tables; Cal/OSHA is a state plan and is included).
