---
name: seam-check
description: Proves that what a change wrote is actually read, and what it reads is actually written. Use after implementing a ticket, before opening a review, when a feature does nothing despite green tests, or when auditing an effort for dead wiring. Catches written-by-nothing and read-by-nothing defects before the first real run does.
user-invocable: false
---

# Seam check

One question, asked in source, not from memory:

> **Does anything read what this wrote, and does anything write what this reads?**

The defect has a signature: the code looks right, every unit test is green, and
the feature does nothing.

Run this before the review, on every ticket that touched an interface. In this
flow that run is `build-slice` §5, the only run that counts a live replay:
`/prove` and the review's Seam axis **read** the report this pass leaves
behind. A pass ordered because that report is missing or stale walks the greps
and reads the recorded far ends only — the live-replay section below belongs to
`build-slice` §5's run alone.

**Which ticket.** With none named, the most recently built one:
`git log --format='%h %s' | grep -E '\(ticket [0-9][0-9][a-z]?\)$' | grep -v ' REVIEW:'`,
newest hit. Then read that ticket's `## Seam check, <date>` report against
current source — do the cited symbols still read the cited literals — and
re-run the pass only if the report is missing, or the diff has touched the
seam's producer or consumer since it was written; changed tests or bookkeeping
are not the seam moving. Findings go under the ticket's `## Seam check`
heading, in the format below.

## The pass

For each thing the change writes — a column, an event, a file, a return value,
a config key, a queue message, an object attribute, a CLI flag. Treat that list
as a starting set, not a checklist — a kind missing from it is a kind nobody
grepped.

1. **Grep the literal name.** Not the concept. Table name, column name, event
   string, key. Start from the literal the ticket's `CONSUMED BY` line names
   after `reading` when there is one; then grep anything else the change
   wrote.
2. **Read the hit.** A hit inside a test, a migration, or the writing function
   itself does not count. **On the path** means: production code that runs when
   an operator uses the feature. The writing *module* may still contain a real
   reader — judge the function, not the file. On existing code with many hits,
   stop at the first on-path reader that matches the ticket's `CONSUMED BY`
   and record how many other hits were skipped; the review's Ticket axis
   samples those.
3. **Record the symbol**, not the line number (`cut-slices` Rule 2).

### A reader that is not code

Some values are consumed by the machine rather than by a function: a `PRIMARY
KEY`, a `UNIQUE` constraint, a foreign key, an index, a type annotation the
runtime enforces. Grep finds no reader and the value is doing real work.

A primary key reported as read by `NOBODY`, followed literally, reads as an
instruction to delete it. Record these as
`READ BY the <constraint/index/type> at <where>`, and prove it the same way as
any other seam: make it fire once and read the error.

Mirror it for each thing the change reads.

Both sides take `cut-slices` Rule 2's far-end forms, plus
`the <constraint> at <where>` and `NOBODY`. Two are one-sided: the constraint
form only ever reads, and `operator, by hand at <path>` only ever writes (a
human *reading* is `operator, via <cmd>`). The `reading <literal>` clause
belongs to the read-by side. Use the symbol form the ticket used and keep its
literal.

```
WROTE  <name>  READ BY     <module::symbol>, reading <literal> | ticket NN | operator, via <cmd> | <name>, out of repo | the <constraint> at <where> | NOBODY
READ   <name>  WRITTEN BY  <module::symbol> | ticket NN | operator, via <cmd> | operator, by hand at <path> | <name>, out of repo | NOBODY
```

The read side needs the same forms as the write side: with only
`<file:line> | NOBODY` available, a value written by another repository records
as `WRITTEN BY NOBODY` — a false defect against working code.

## What NOBODY means, and what it does not

**`NOBODY` with no explanation is a finding.** Not a style note, not a future
improvement — the feature does not work.

**A named forward reference is not `NOBODY`.** When the ticket says
`CONSUMED BY: ticket NN`, the debt has an address and the pass records it as
`ticket NN`, not as a defect — a walking skeleton's code consumers land later
by definition.

Two conditions keep that from being a loophole:

- NN is a real ticket in this effort whose status is not `resolved` or
  `declined`. Write the status you found into the report, so the check is
  reviewable rather than asserted.
- The reference is redeemed by the session that lands NN, and no reference
  outlives its effort. Carry it into the report until then.

At effort close, `close-effort`'s first walk gives every recorded `ticket NN`
one of `cut-slices` Rule 5's three endings. Carry each one into the report
until then.

## A seam with nothing to grep

`PRODUCES: contract` writes no value. An existing call stops raising, starts
returning a different error, or changes what it accepts. Grep has no literal to
look for, so the method above finds nothing and reports clean.

Check it the only way that works: **make the old behaviour happen and read what
the caller does.** Feed the input that used to raise. If every caller still
handles the new answer, the contract holds. If one of them catches an exception
that no longer arrives, that caller is dead code with a passing test suite.

Record it as `CONTRACT <what changed> HANDLED BY <module::symbol> | NOBODY`.

## Two ends grep cannot reach

**A human consumer.** `operator, via <cmd>` is a real far end and grep says
nothing about it. Verify it the only way available: run the command and read the
output. If the ticket asserts on that output, say which test.

**Another repository.** This is the seam most likely to break and the one the
method is blind to. Grep cannot cross a repo boundary, so say so plainly rather
than reporting a clean pass. Name the contract — the schema, the endpoint, the
message shape — and name what checks it: a shared fixture, a contract test, a
version pin, or nothing. **"Nothing" is the finding.**

## The three that hide

**Name drift.** Producer writes `task_id`, consumer reads `taskId`. Both sides
compile. Grep both spellings.

**Unit and type drift.** Producer writes seconds, consumer reads milliseconds.
Or the value silently becomes a float and the column's declared type does not
stop it. Same name, same field, quietly wrong. Read the unit and the type at
both ends, in source, and check what the store actually accepted — a declared
`INTEGER` column will hold a float without complaining.

**Vocabulary drift.** Producer emits a value the consumer's allow-list does not
contain, and the rejection is logged rather than raised. Read the allow-list.
Measured: eighteen proposals, zero accepted, everything "working".

## Prove it once, live

A grep proves the reader exists. It does not prove the value arrives.

Run the path once for real and read the output at the far end. When the far end
belongs to a later ticket, name that ticket and say the live run is owed.

**Use the smallest input that reaches the case this ticket is about** — not the
smallest input. "Smallest" pushes you to the cases nobody doubted.

**Replay every block whose `STATUS` begins with `live`, then add this ticket's
new case.** The `live, <reason>` blocks are replayed too — the reason exempts
them from promotion, not from the replay, and they are exactly the ones with
no test guarding them. A far-end regression is invisible when each ticket picks
fresh inputs — measured: a ticket changed which resolver was used and its live
run passed because it used different hostnames than the previous ticket's. Keep
the inputs in
`docs/issues/<effort>/live-inputs.md` and start from that file rather than
from a fresh idea. The walking skeleton's session creates the file, with its
own block at `REPLAYS 0 ()`.

### The file has a form, and a ceiling

One block per ticket, this shape and no prose:

```
## NN
INPUT           <the input, verbatim>
FAR END         <what was observed at the far end>
STATUS          <one of the values below>
REPLAYS         <count, and the ticket numbers that replayed it>
```

| `STATUS` | means |
|---|---|
| `live` | replayed by hand on every following ticket's live run |
| `live, <reason>` | replayed by hand, and exempt from promotion for the reason given |
| `live, far end moved by <NN>` | still live; ticket NN legitimately moved the far end (`PRODUCES: changed`) and rewrote `FAR END` in its own commit |
| `live, not run at close: <reason>` | written only by `close-effort`, when walk 4 could not run this block |
| `promoted to <test>` | a named test asserts this now; not replayed by hand any more |
| `retired, <reason>` | the path this input exercised no longer exists; the reason names the ticket that removed it |

`REPLAYS` is the one field a later session cannot re-derive — it lives in no
diff and no test output — so the ticket that replays a block increments the
count in the same edit that reads the far end: `REPLAYS 2 (03, 05)`. **One
increment per ticket**: the count moves in `build-slice` §5's run — and once
more in `close-effort` walk 4, which replays as §5 does — nowhere else;
`/prove` and the review's Seam axis read the recorded far end without touching
it.

**A block whose last two replays matched its recorded far end gets promoted** —
`REPLAYS 2` or higher with the record current. A `far end moved by <NN>`
rewrite restarts that count at NN's own replay; once two replays match the
*rewritten* record, the block promotes like any other — no block is
hand-replayed forever. At that point it is doing exactly one job — detecting a
regression — and a test is the thing that detects regressions. The promotion
is executed *after* the pass, as a NOW verdict on the pass's own finding:
write the test — born green, so `build-slice` §2's proof applies, on the
recorded far-end literal — set the
block to `promoted to <test>`, name the test and its mutation in the
ticket's `## Resolution`, and stop replaying it by hand.

A replay that does **not** match the recorded far end is not a promotion and not
a bookkeeping problem. It is a finding, with a severity, like any other in this
skill: the far end moved and nothing said so. Reset nothing, report it. (The
legitimate moves — this ticket's own `PRODUCES: changed`, or a
`PRODUCES: new` value landing in a far end earlier blocks also read, the way
an appended stdout line moves every recorded summary — are recorded by that
ticket itself as `live, far end moved by <NN>`, per `build-slice` §5.)

That rule is the file's ceiling: without it ticket 20 replays nineteen blocks by
hand and the last ones get skimmed.

**Promotion adds a test. It never removes one.** Retiring a *block* is not
retiring a *test*: the standing bar's "no test was skipped, deleted, or
weakened" is untouched by either move here. A block marked
`promoted to <test>` stays in the file as the address of the test that replaced
it, and deleting that test is a bar-lowering move like any other.

What cannot be promoted stays live and puts the reason on the same line —
`live, needs a human at the far end`, `live, needs the real dependency`. A block
at `REPLAYS 2` or higher still marked with a bare `live` is a block nobody has
decided about, and that is a finding too.

## Reporting

Report, do not repair: findings first, whole pass finished, repairs on request.
`cold-read` owns the mode and says why patching mid-pass ends the pass early.

**The report has an address.** Append the `WROTE`/`READ` record and the
findings to the ticket under `## Seam check, <date>`. `build-slice` §5 leaves
it there and the review's Seam axis reads it there; a pass that reports only
into its session's context is a pass the next session cannot tell from no pass
at all.

Findings go under that heading in the entry format `hold-the-line` owns, with
`seam` in the axis slot, so the pending-verdict greps and the verdict step
see them like any review finding:

```
- [seam] **<module::symbol>: WROTE <name>, read by NOBODY. <what should read
  it>.** — <severity> — verdict pending
```

Give each finding a severity — `blocker`, `required` or `nit` — using the table
in `hold-the-line`. Without one, the verdict step has no input and defaults to
the softest answer.

## When a finding turns up

Do not open a ticket by reflex. Take `hold-the-line`'s verdict.
