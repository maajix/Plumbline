---
description: Seam check. Read the ticket's seam report; re-run the pass only if it is missing or stale.
argument-hint: "[ticket number, or empty for the last built ticket]"
---
Check the seams for: $ARGUMENTS

Default when no argument: the most recently built ticket — the newest commit
whose subject ends `(ticket NN)` and does not begin `REVIEW:`.

The full pass already ran once, as `build-slice` §5, and left its report in
the ticket under `## Seam check, <date>`. So this command **reads**:

- Open that report. Check its `WROTE`/`READ` records against current source —
  do the cited symbols still read the cited literals.
- Re-run the `seam-check` skill only if the report is missing, or the diff
  has touched the seam's producer or consumer since it was written — changed
  tests or bookkeeping are not the seam moving.
- Never replay `live-inputs.md` blocks and never increment `REPLAYS` here —
  one increment per ticket, and it belongs to `build-slice` §5's run.

Report findings into the ticket's `## Seam check` section in `hold-the-line`'s
entry format. Do not repair during the pass.
