---
name: structured-debugging
description: Four-hypothesis falsification protocol with fact ledger. Use when the cause is unknown - diagnosing a bug or error, a flaky test, missing/delayed/duplicated data, or a performance regression.
---

# Structured debugging

Before investigating, write **four** distinct, testable hypotheses, ordered by likelihood ÷ test cost. Each: one-sentence mechanism + discriminating prediction ("Then …") that differs from the other hypotheses + the cheapest observation that would falsify it. Reserve one slot for "the measurement/repro itself is wrong" (broken instrumentation, non-equivalent runs, stale data):

```
Working hypotheses, in order:
1. The "missing" rows are mostly still in the ingest backlog. Then `SELECT count(*)` on both the queue and the target table keeps rising during measurement.
2. The two runs are not functionally equivalent (different input set, filters, config, tool versions). Then the difference remains after both have fully drained.
3. ...
4. ...
```

Then:
- Preserve logs, metrics, IDs, queue state, versions, config **before** changing anything.
- Test hypotheses against primary evidence: logs, traces, metrics, DB state, queue state, source. Prefer the test that could **disprove** the current leading hypothesis.
- Keep a **fact ledger** separating **observed facts** / **inferences** / **unknowns**; every fact cites its source (log line, query, command) so it can be re-derived.
- Re-rank hypotheses (todo list) as evidence lands. Evidence kills a hypothesis → strike it, never bend it. All four dead → write four new ones from the fact ledger.
- For missing/delayed/duplicated data, trace representative IDs through the full pipeline: one broken, one healthy, one boundary; find the divergence point.
- Experiments change one variable at a time; revert failed probes before the next.
- Diagnosis complete only when the mechanism explains **all** observations — including the cases that still work. No fix before that. Fix verified = the identical measurement that showed the symptom now shows it gone.
- Diagnose ≠ fix: when asked to diagnose, deliver cause + evidence; implement only on request.

## In this flow

`build-slice` §4 invokes this skill when a ticket hits an unknown cause. The
diagnosis is a finding like any other: give it a severity (`blocker`,
`required`, `nit`) and take it through `hold-the-line` for its verdict — the
fix is not applied by reflex, even with the mechanism proven.
