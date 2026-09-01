---
name: hold-the-line
description: "Decides what happens to a discovered problem: fixed now, added as an acceptance criterion, sent back to the ticket that shipped it, recognised as already owned, cut as a new ticket, or declined in writing. Use whenever a review, test run, debug session or implementation turns up work that was not planned, and before opening any unplanned ticket. This is the gate that stops a backlog growing once per completed ticket."
user-invocable: false
---

# Hold the line

Every review defers something. If every deferral mints a ticket, the backlog
grows once per completed ticket and the effort never visibly shrinks — even when
the work is nearly done.

Observed both ways. One effort with this rule written down: 14 tickets done, net
growth about +3. One effort without it: tickets 76-80 filed by implementation
reviews, 81-83 by live validation, 87-88 by one final review, 89-92 by the
questions those raised. It reached 165. Two efforts do not isolate one rule as
the cause, but the direction of the difference is what this skill bets on.

**A finding is not automatically a ticket.** It is also not automatically
deferred, which is the mistake the first version of this skill made.

And without an effort's ticket files — a bare PR or diff review outside this
flow — there is nothing to write a verdict into: report the findings with
their severities and stop. The six verdicts begin where tickets exist.

## Severity decides first

A finding arrives with a severity from `review-pass`, `seam-check`, or
`build-slice` §4: `blocker`, `required`, `nit`. Severity is an input here, not
decoration.

| severity | means | verdict |
|---|---|---|
| `blocker` | shipped code is wrong, unsafe, or loses data | **NOW** or **REOPEN**; **ALREADY OWNED** when a not-yet-`resolved` ticket already carries exactly this work; **TICKET** only when the code is outside this effort's tickets and the unowned test passes |
| `required` | must be right before the effort closes | any of the six |
| `nit` | costs less to fix than to record | **NOW** or **DECLINE** |

A blocker never becomes a deferred criterion. In testing, this skill sent a
measured guaranteed crash and an unused variable to the same verdict, and the
crash stayed merged and green. That is the failure this table exists to stop.

## The six verdicts

Every finding gets exactly one, written into the ticket that produced it. A
finding left as prose with no verdict does not close a ticket — an unverdicted
finding is indistinguishable from an open one, so the next review rediscovers it
and it reads as new work.

### 1. NOW — fixed in this pass

The fix costs less than recording it, or the severity is `blocker` on code in
the ticket you are standing in. Do it, and note it in one line. Any NOW repair
that changes production code gets its own failing test first, whatever the
severity — a review repair without a red test is the mid-session failure
CRITERION warns about, one verdict to the left — **and** re-runs the
standing bar's machine lines, appending the paste dated to the ticket's
`## Bar` block: the repair rides the review commit, which the next cycle
pins as its fixed point, so no later diff ever re-reads it — the red test
and this paste are all the checking it will ever get. Only a repair that
touches no production code — a comment, a doc line — skips both.

This is the verdict for trivia. Without it, a thirty-second cleanup becomes a
criterion on an unrelated ticket, which is bookkeeping that costs more than the
work.

### 2. CRITERION — the default for planned work

The work becomes an acceptance criterion on a ticket in this effort that is not
yet `resolved` or `declined`. **The ticket you are currently building or
reviewing counts** — it is the most common home, and `claimed` is not a reason
to look elsewhere. (`build-slice` keeps a ticket `claimed` through its review
precisely so this verdict stays available for it.) One exception: when the
ticket's cycle line reads `cycle 3 of 3`, the ticket under review is no longer
a legal home — `review-pass` names the alternatives, because cycle-3 work here
would demand a forbidden fourth cycle.

Write it into that ticket in this edit, before implementing anything.

- **On another ticket** — parked. That ticket does it later.
- **On the ticket you are standing in** — work for *this* session. Do it now,
  and **give it its own failing test first**. A criterion added mid-session is
  the one most likely to be built without a red test, because the red-first
  habit attaches to the ticket's headline seam. When the criterion adds an
  assertion over behaviour that is already correct, the test is born green —
  then `build-slice` §2's discrimination check carries the proof alone: break
  the literal, watch red, restore, record the `Mutated:` line.

### 3. REOPEN — the ticket that shipped it takes it back

The finding is about work in a `resolved` ticket — or in a `claimed` ticket
whose session ended and left a `## Handoff` — and it is `blocker` or a straight
miss of what that ticket promised.

Set that ticket back to `claimed` (a handed-off ticket already is), add the
criterion there, and say why in a new dated `## Resolution` block when it
re-resolves. Parking a shipped defect on a future ticket is how it disappears.
A reopened ticket's review starts a fresh cycle count; the old count stays in
the file as history, and the new review appends its findings blocks below the
old ones — on a same-day reopen, suffix the new heading with ` — reopened` so
no two headings collide.

### 4. ALREADY OWNED — a ticket covers it, unfinished or landed

Name the ticket number and stop. Add nothing. A `claimed` or
`blocked — needs decision` ticket owns its work as much as an `open` one
does. And a `resolved` ticket whose landed work already satisfies the
finding is ownership in its strongest form — name the ticket and the
commit; DECLINE would be a lie here, because the work *was* done.

This is not a criterion and it is not a decline. Without it, the honest move is
to write a criterion and note that nothing was added, which is a lie shaped like
compliance.

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

Counting tickets alone hides the problem. In testing the ticket count held at 8
exactly as designed, while one ticket went from 3 criteria to 8 — spanning a
wire parser, a network default, a CLI refactor and two new tests. The count was
honest and the work had tripled.

So after a review, count both:

- **Tickets minted.** More than three from one ticket's review means that ticket
  was cut wrong. Re-cut with `cut-slices`.
- **Criteria added to any single ticket.** A ticket carrying more than six
  criteria (`grep -c '^- \[[ x]\]' <ticket>` — the checkbox forms only, so
  findings entries like `- [seam]` do not inflate the count), or criteria
  spanning more than one seam, has stopped satisfying `cut-slices` Rule 4. Split it. Rule 4 has no
  enforcement point after cutting, so this is it.

Splitting mid-effort follows `cut-slices` "Numbers are addresses": the split
ticket file stays in place with `**Status:** declined` and the reason
`split into 14a, 14b`, and the splitting session rewrites every
`CONSUMED BY: ticket 14` line (on disk `**CONSUMED BY:** ticket 14` — find
them with `grep -rn 'ticket 14' docs/issues/<effort>/`) **and** every
`Blocked by` entry naming `14` to the half that owns it, in the same edit,
redeeming nothing. A `claimed` ticket with a `## Handoff` is split only after its `Red:`
line has moved into the half that owns that test.

## The ceiling is real

`cut-slices` sets the effort ceiling. When a genuinely blocking finding would
push the effort past it, that is the signal to **close this effort and open the
next one**, not to grow.

Closing is `close-effort`'s job, and its first walk is what makes the close
honest: every forward reference is redeemed, deleted, or moved with both of its
ends. An effort that cannot close is a program.

## Exit criteria need owners

If the spec lists an exit criterion this effort has decided not to do, move it
into an explicit "moved out" block naming the effort that owns it now, in the
same edit that makes the decision. Never leave it in the list.

An unowned exit criterion makes the effort permanently unclosable. Every ticket
can be done and it still reads as unfinished.

Each ticket names the exit criterion it serves, in its `Serves exit criterion`
field, so this is checkable rather than remembered.

## Status vocabulary

Five values, the same in every skill of this flow: `open`, `claimed`,
`resolved`, `blocked — needs decision`, `declined`. Anything not `resolved` or
`declined` can receive a criterion. A stub shape's `**Status:** unshaped` is
a `shape.md` value, never a ticket's — the five above stay the whole ticket
vocabulary.

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

- [seam] **<finding>** — <severity> — verdict pending
- [craft] clean — nothing raised
- [ticket] **<finding>** — <severity> — NOW. <what was fixed>
- [bar] **<finding>** — <severity> — CRITERION on ticket NN. <what was added>
- [craft] **<finding>** — <severity> — REOPEN ticket NN. <why it goes back>
- [seam] **<finding>** — <severity> — ALREADY OWNED by ticket NN.
- [ticket] **<finding>** — <severity> — TICKET NN. Blocks MM. / Unowned: <who decides>
- [craft] **<finding>** — <severity> — DECLINED. <reason>

Review cycle N of 3 — undecided: seam 1, craft 2
```

Once every verdict is in, the cycle line's tail reads `undecided: none`.

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
