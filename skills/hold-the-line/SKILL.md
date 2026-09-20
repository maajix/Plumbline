---
name: hold-the-line
description: "Decides what happens to a discovered problem: fixed now, added as an acceptance criterion, sent back to the ticket that shipped it, recognised as already owned, cut as a new ticket, or declined in writing. Use whenever a review, test run, debug session or implementation turns up work that was not planned, and before opening any unplanned ticket. This is the gate that stops a backlog growing once per completed ticket."
user-invocable: false
---

# Hold the line

Every review defers something. If every deferral mints a ticket, the backlog
grows once per completed ticket and the effort never visibly shrinks — even when
the work is nearly done.

Observed both ways: an effort carrying this rule held at net +3 tickets, one
without it reached 165 (`${CLAUDE_PLUGIN_ROOT}/docs/DIAGNOSIS.md`).

**A finding is not automatically a ticket.** It is also not automatically
deferred, which is the mistake the first version of this skill made.

And without an effort's ticket files — a bare PR or diff review outside this
flow — there is nothing to write a verdict into: report the findings with
their severities and stop. The six verdicts begin where tickets exist.

Read `${CLAUDE_PLUGIN_ROOT}/references/ticket-lifecycle.md` for IDs,
resumption and repair ordering; it owns when a verdict is committed and built.

## When invoked as `/verdict`

With no argument the findings are every entry still marked `— verdict pending`
in the current effort, which `close-effort`'s "Which effort" picks. Run
`grep -rn '— verdict pending' docs/issues/<effort>/`. Only entry lines are open
findings; a hit that quotes the marker inside a paste is history.

## Severity decides first

A finding arrives with a severity from `review-pass`, `seam-check`, or
`build-slice` §4: `blocker`, `required`, `nit`. Severity is an input here, not
decoration.

| severity | means | verdict |
|---|---|---|
| `blocker` | shipped code is wrong, unsafe, or loses data | **NOW** or **REOPEN**; **ALREADY OWNED** when a not-yet-`resolved` ticket already carries exactly this work; **TICKET** only when the code is outside this effort's tickets and the unowned test passes |
| `required` | must be right before the effort closes | any of the six |
| `nit` | costs less to fix than to record | **NOW** or **DECLINE** |

A blocker never becomes a deferred criterion — an early version of this skill
sent a guaranteed crash and an unused variable to the same verdict, and the
crash stayed merged and green.

## The six verdicts

Every finding gets exactly one, written into the ticket that produced it. A
finding left as prose with no verdict does not close a ticket — an unverdicted
finding is indistinguishable from an open one, so the next review rediscovers it
and it reads as new work.

### 1. NOW — repair before unrelated work

For a cheap fix or a blocker in the current ticket. During build, write the
criterion, repair it red-first, then include it in the normal build and review.
During review, record executable repairs as unticked criteria, commit the
verdict first, then build and review the repair per the shared lifecycle.
Tests and configuration are executable work too. Pure prose/comment repairs
may be completed in the review commit itself. Record which case applies;
a NOW verdict is a priority decision, not evidence the repair has already passed.

### 2. CRITERION — the default for planned work

The work becomes an unticked criterion on a ticket in this effort that is not
resolved or declined. The current claimed ticket is normally the best home.
Write the criterion before implementing it. On another ticket it is parked;
on the current ticket it follows the shared lifecycle: build-time findings are
fixed before review, review-time findings are committed before the repair build.
Born-green tests use build-slice §2's production mutation proof.
At cycle three, a current-ticket executable repair blocks for a decision;
record it there without starting a fourth cycle.

### 3. REOPEN — the ticket that shipped it takes it back

The finding is about work in a `resolved` ticket — or in a `claimed` ticket
whose session ended and left a `## Handoff` — and it is `blocker` or a straight
miss of what that ticket promised.

Set that ticket back to `claimed` (a handed-off ticket already is), add the
criterion there, and say why in a new dated `## Resolution` block when it
re-resolves. Parking a shipped defect on a future ticket is how it disappears.
Only reopening resolved work starts a fresh cycle count; resuming a claimed
ticket with a Handoff preserves its count. The old count stays in
the file as history, and the new review appends its findings blocks below the
old ones — on a same-day reopen, suffix the new heading with ` — reopened` so
no two headings collide.

### 4. ALREADY OWNED — a ticket covers it, unfinished or landed

Name the ticket number and stop. Add nothing. A `claimed` or
`blocked — needs decision` ticket owns its work as much as an `open` one
does. And a `resolved` ticket whose landed work already satisfies the
finding is ownership in its strongest form — name the ticket and the
commit; DECLINE would be a lie here, because the work *was* done.

This is not a criterion and it is not a decline — without it the honest move
would be a criterion recording that nothing was added.

### 5. TICKET — only on one of two tests

- **It blocks.** A ticket that is not yet `resolved` cannot finish until this is
  done. Add the new ticket's number to the **blocked** ticket's `Blocked by`
  line, in the same edit — the edge sits on the ticket that waits, so the
  frontier rule holds it back until the new ticket lands.
- **It is unowned.** It needs a decision nobody in this effort owns — a
  different system, a different team, a product call.

The new ticket is cut per `cut-slices` — template, seam lines, the lot; a
verdict is not a licence for a headline-only ticket.

Neither test passes? It is a criterion. Not a small ticket, not a quick ticket.
A criterion.

### 6. DECLINE — write it down

The work will not be done. Record it with the reason, or as an ADR if it is a
standing decision. A decline that is not written becomes the next review's
finding.

## Watch the criteria, not just the tickets

Counting tickets alone hides the problem: measured, a ticket count held at 8
while one ticket went from 3 criteria to 8 and its work tripled.

So after a review, count both:

- **Tickets minted.** More than three from one ticket's review means that ticket
  was cut wrong. Re-cut with `cut-slices`.
- **Criteria added to any single ticket.** A ticket carrying more than six
  criteria (`grep -c '^- \[[ x]\]' <ticket>` — the checkbox forms only, so
  findings entries like `- [seam]` do not inflate the count), or criteria
  spanning more than one seam, has stopped satisfying `cut-slices` Rule 4. Split it. Rule 4 has no
  enforcement point after cutting, so this is it.

**The split procedure.** Keep the original file, set declined, and record
`split into 14a, 14b`. Children retain the origin slug in their stable IDs.
Move each criterion, test ownership and any Handoff Red line to its owner.
Rewrite every active `CONSUMED BY`, `CONSUMES`, `deferred to ticket NN`
(including ticked deferrals) and `Blocked by` reference in the effort.
Match complete numbers: 14 is not 14a. Assign value/test references to their
owning child; a dependency needing both children names both. Preserve history
under dated blocks. Verify no active reference still targets the declined
parent; resolving the review never overwrites that declined status.
Use the same four reference forms when moving tickets at close.

## The ceiling is real

`cut-slices` sets the effort ceiling. When a genuinely blocking finding would
push the effort past it, that is the signal to **close this effort and open the
next one**, not to grow.

Closing is `close-effort`'s job, and its first walk settles every forward
reference in one of `cut-slices` Rule 5's three endings. An effort that cannot
close is a program.

## Exit criteria need owners

If the spec lists an exit criterion this effort has decided not to do, move it
into an explicit "moved out" block naming the effort that owns it now, in the
same edit that makes the decision. Never leave it in the list.

An unowned exit criterion makes the effort permanently unclosable. Every ticket
can be done and it still reads as unfinished.

Each ticket names the exit criterion it serves, in its `Serves exit criterion`
field, so this is checkable rather than remembered.

## Status vocabulary

The values are the ones `cut-slices`'s ticket template lists, and no skill in
this flow adds a sixth. Anything not `resolved` or `declined` can receive a
criterion. A stub shape's `**Status:** unshaped` is a `shape.md` value, never a
ticket's.

Say the value, not "open", when you mean the whole unfinished set. A REOPEN
verdict writes `claimed`, and a reader who takes "open" literally will not find
that ticket again.

## Recording format

One format, owned here; `review-pass`, `seam-check` and `build-slice` §4 all
write it. At the bottom of the ticket that produced the findings, one dated
block per review cycle (or per build session, under `## Build findings,
<date>`; `seam-check` appends its entries under its own `## Seam check`
report):

```markdown
## Review findings, <date> — cycle N

**Base:** <full commit hash or empty-tree hash>
**Head:** <full reviewed commit hash>
**Readers:** complete <pending until all four axes report>

- [seam] **<finding>** — <severity> — verdict pending
- [craft] clean — nothing raised
- [ticket] **<finding>** — <severity> — NOW. <comment fixed, or criterion recorded for immediate repair>
- [bar] **<finding>** — <severity> — CRITERION on ticket NN. <what was added>
- [craft] **<finding>** — <severity> — REOPEN ticket NN. <why it goes back>
- [seam] **<finding>** — <severity> — ALREADY OWNED by ticket NN.
- [ticket] **<finding>** — <severity> — TICKET NN. Blocks MM. / Unowned: <who decides>
- [craft] **<finding>** — <severity> — DECLINED. <reason>

Review cycle N of 3 — undecided: seam 1, craft 2
```

Once every verdict is in, the cycle line's tail reads `undecided: none`.
`<date>` is `YYYY-MM-DD`, as in every heading of this flow (`cut-slices`
template).

The axis tag in brackets is the reader that raised it (`build` for
`build-slice` §4 discoveries), the severity survives into the entry, and the
verdict replaces `verdict pending` in the same edit that decides it. An axis
that found nothing writes the one-line `clean — nothing raised` form — no
severity, no verdict, no place in any count; it is evidence the axis ran,
not a finding. A block keeps the date of the session's first write to it —
a run that crosses midnight does not fork the heading. The cycle
line is the block's last line — one place, not two — and it deliberately says
`undecided`, never "verdict pending": the phrase `— verdict pending` is the
sentinel three greps hunt for, and a cycle line that contained it would read
as an unverdicted finding forever.
