# Trial fixtures

Real payloads captured from the ClinicalTrials.gov API v2, formatted through
`ClinicalTrialClient.get_study` so they match exactly what `TrialScorer` and
`EligibilityChecker` receive at runtime.

They exist because scoring weights and thresholds cannot be tuned safely without
a way to measure whether a change helped. Hand-written hashes would only ever
prove the scorer agrees with my assumptions about the data.

## What each one covers

| Fixture | Covers |
|---------|--------|
| `nct05444699.json` | Sub-year minimum age, 6 Months to 24 Months. RECRUITING, two locations |
| `nct07102836.json` | Neonatal range in days, 0 Days to 28 Days. RECRUITING, two conditions |
| `nct00524693.json` | Week-based minimum, 4 Weeks to 2 Years. COMPLETED, **no locations** |
| `nct00798616.json` | WITHDRAWN status. The disqualifier case |
| `nct02657837.json` | Four conditions, UNKNOWN status, 30 Months minimum |
| `nct03774082.json` | 28 Days minimum, COMPLETED, twenty-one locations |

Five of the six use a non-year age unit. That is deliberate: reading the number
and ignoring the unit was a real bug, and these are the payloads that catch it.

## Refreshing them

Each file records `captured_at` and its source URL. ClinicalTrials.gov changes
study records over time, and a study that was RECRUITING at capture will not stay
that way, so **the specs must not assert on live-changing values** like status
unless the fixture is the thing under test.

To recapture:

```ruby
# bin/rails runner
study = ClinicalTrialClient.get_study("NCT05444699")
```

then rewrite the file keeping the `_fixture` block, updating `captured_at`.

If a schema change breaks parsing, the specs should fail loudly here rather than
letting scores quietly degrade in production.
