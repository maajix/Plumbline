---
description: Implement exactly one ticket, seam-first, and leave the ticket file honest.
argument-hint: "[ticket number, or empty for the frontier]"
---
Run the `build-slice` skill on ticket: $ARGUMENTS

If no ticket is named, `build-slice` §0 picks the frontier: every `claimed`
ticket before every `open` one — REOPEN and an ended session are the same
case, work already started — then the lowest number whose every `Blocked by`
entry is `resolved` or `declined`. `14a` and `14b` sort after `14`, before
`15`.

If the chosen ticket carries a `## Handoff` block, read it before anything
else — before the ticket body, before the source. It names the failure the
last session was looking at, which is the one thing re-reading the source
cannot recover. It is a lead, not evidence: `build-slice` §1 still runs in
full, and `build-slice` deletes the block when it writes `## Resolution`.
