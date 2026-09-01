---
name: cut-slices
description: Cuts a spec into tickets that each leave something running end-to-end. Use when turning a spec into tickets, breaking a feature down, planning an effort, sizing work for an agent session, or when an existing ticket plan needs checking for seam coverage. Every ticket names both ends of its seam, so integration defects cannot pile up until the first real run.
user-invocable: false
---

# Cut slices, not components

A ticket that finishes leaves something **running**, not something *built*.

This exists because of a measurement. In one effort, tickets 1-60 were
component-shaped. Of tickets 111-165, **64 % were seam defects**:
`a-queued-job-is-read-by-nothing`,
`the-result-store-is-connected-at-neither-end`,
`fifty-templates-and-not-one-has-ever-been-selected`.

Every one of those components was built correctly. Each ticket named one end of
an interface, nobody ran both ends together, and the defects all arrived on the
first real run — 35 seam defects across 55 tickets.

The agent did not make gross mistakes. **The ticket contained half a seam.**

## Rule 1 — The first ticket built is a walking skeleton

The skeleton makes the thinnest possible end-to-end path run for real.
Hardcode everything that is not the path. One input at the front, one
observable result at the back, through every layer the real feature crosses.
In a fresh effort it is ticket `01`; in a successor effort it takes the next
free number ("Numbers are addresses", below) — the exemptions and duties in
this flow attach to *the skeleton*, not to the number.

State it as a sentence before cutting anything else:

> A hostname in a text file goes in at the front, and a line in the operator's
> `queue` output comes out at the back.

If that sentence cannot be written, the effort is not understood well enough to
cut. Go back to the spec.

A walking skeleton is not a prototype and not a spike. It is production code
that does one trivial thing correctly through the whole stack, and it stays.

**On existing code** the path may already run. There the skeleton is the
thinnest change that makes the effort's new behaviour observable at the far
end *through the existing path* — often one hardcoded value surfacing where
the operator will later read the real one — and its `Why` block carries the
measurement showing today's behaviour.

**Rule 1 outranks Rule 4.** The skeleton crosses as many files and seams as the
path needs, and the size ceiling does not apply to it. Nothing else in an effort
gets that exemption. Shaping the architecture to fit a ticket-size rule is the
rule steering the design, which is backwards.

Two things follow from that exemption.

**The skeleton is the effort's likeliest handoff.** It is the one ticket the
size ceiling was never applied to, and it is the first one built, so it is the
one most likely to outlast the session that claims it. That is not a reason to
shrink it — it is a reason to expect the handoff. `build-slice` says what to
leave in the ticket when a session ends first.

**The skeleton leaves behind the effort's verify command.** It is the first
ticket that meets the real toolchain — it has to, to run through every layer for
real — so it is the ticket that learns the one command that runs this effort's
tests from a clean checkout. Write that command into the spec's
`## Verify command` section, and pick a form that **prints the name of each
test it ran** (`pytest -v`, not `-q`): the standing bar reads a named test in
that output, and a quiet runner defeats the line. Every later ticket's bar
then has something to execute where it otherwise only asserts.

That command is not a second seam, not a fourth production file, and not a
criterion of its own: Rules 3, 3b and 4 are untouched by it. It is one line of
spec recording what the skeleton already ran. No plugin ships it, because only
this effort knows its toolchain.

## Rule 2 — Every ticket names its seam

Three lines. They are not prose; each takes one of a fixed set of values.

```
PRODUCES     <kind>: <what crosses>
CONSUMED BY  <one of the five forms below>
CONSUMES     <what it reads, and who wrote it>
```

A ticket that produces more than one value carries one `PRODUCES` /
`CONSUMED BY` pair **per value**. The common case is the skeleton: it shows
the operator something (`operator, via <cmd>`) *and* leaves a structure a
later ticket reads (`ticket NN`) — that is two pairs, not a choice between
them. A slice that ends at a person always carries its `operator, via <cmd>`
pair; that last hop is what the feature exists for.

### PRODUCES has a kind, and the kind is the point

| kind | means |
|---|---|
| `new` | a value, row, file or event that did not exist before |
| `changed` | an existing value whose **number, unit, type or shape** moves |
| `contract` | no new value; an existing producer's behaviour or errors change |
| `nothing` | this ticket writes nothing that anything else reads |

`changed` and `contract` are the two that get missed. A ticket that rewrites a
policy so a column holds a different number produces no new column and is the
most dangerous kind of seam change there is — it is `seam-check`'s own unit
drift, arriving through a field that looks unchanged. A ticket that stops an
existing call from raising has changed a contract without adding a value.

### CONSUMED BY takes one of five forms

| form | when | what it obliges |
|---|---|---|
| `<module::symbol>, reading <literal>` | code on the path reads it | that code exists **when this ticket lands** |
| `ticket NN` | a later ticket will read it | NN is unfinished in this effort; see Rule 5 |
| `operator, via <cmd>` | a human reads it | the ticket asserts on that output |
| `<name>, out of repo` | another codebase reads it | name the contract and how it is checked |
| `nothing` | `PRODUCES` is `nothing` | no seam test is owed; Rule 3 asks for a behaviour test instead |

`seam-check` records one extra far-end form — `the <constraint> at <where>`
— discovered at check time; it is a finding of the pass, never a cut-time
citation, which is why this table does not carry it.

**Cite the symbol, not the line.** `cli.py::cmd_queue`, not `cli.py:43`. This
skill says below that numbers are addresses nothing catches when they go stale,
and a line number is exactly that: in testing, the skeleton's citations were
eight lines wrong the moment the next ticket inserted a guard above them. A
symbol name survives an edit; a line number does not.

**Name the literal the reader reads.** The symbol alone stops discriminating
after the first ticket: once one reader exists, every following ticket names
the same one, and the field says nothing the title did not. The literal is the
greppable token `PRODUCES` introduced — the column, the key, the field, the
event string:

```
01  cli.py::cmd_queue, reading observation.status
02  cli.py::cmd_queue, reading observation.target
03  cli.py::cmd_queue, reading observation.confidence
```

Same reader, three different lines. `seam-check` starts its grep from that
literal instead of guessing one, and a later ticket that changes what the same
reader consumes has to write a visibly different line.

**The citation must be true at the moment this ticket lands**, not eventually.
"Indirectly via the reason text" and similar phrasings are how a plausible
sentence passes a check it should fail. If the consumer only exists after
another ticket, the honest form is `ticket NN`, not a file path.

The human form is not a loophole. **Every vertical slice ends at a person** —
that last hop is what the feature exists for, and it is the one hop a file
citation cannot express. It earns the same proof as any other seam: the ticket
asserts on what the operator actually sees.

## Rule 3 — The proof test crosses the seam

Every ticket carries one criterion of this exact shape:

```
- [ ] **Checked by something that would go red.** <a test that runs the
      producer and the consumer together and asserts the value survives
      the crossing>
```

A test that asserts a function returns the right shape does not satisfy this.
The test must fail if the two sides use different names, different tables,
different units, or different types.

A `PRODUCES: nothing` ticket — a deletion, an internal refactor — has no seam
to cross. It carries a red-first test for the behaviour it changes in the same
criterion slot, and the standing bar reads that test's name instead of a seam
test's.

A ticket carrying two pairs (Rule 2) owes each value an assertion at its far
end. One test may carry both assertions; a value no assertion looks at is half
a seam wearing a green test.

**Prove the test discriminates.** Change the reader's literal — the status
string, the column name, the key — and watch the test go red. A seam test you
have not tried to break is a claim, not a check. `build-slice` §2 schedules
this at build time, and the ticket's `## Resolution` records what was mutated
and what went red — a discrimination check nobody wrote down was not run.

Write it so it stays sensitive across ticket boundaries. In testing, a later
ticket changed a policy from integer to float; the ticket's own test passed
because `50.0 == 50`, and the **previous** ticket's seam test caught it, because
it asserted the number appeared in the sentence the operator reads. That is the
rule earning its keep, and it only works if the assertion looks at the far end.

The test is a third end of the seam. When a later ticket widens a producer, an
earlier ticket's seam test is the thing that goes red — that is the design
working, not a brittle test to be relaxed.

## Rule 3b — Name what tests the real thing

A seam test reaches the seam by replacing the outside world with a double: an
injected resolver, a fake clock, a stub client. That double is where the seam
test stops and where correctness bugs live.

This is not hypothetical. In testing, a scanner passed four green seam tests, a
clean seam check, a walked standing bar and a live run — and reported **zero
findings on a list full of real ones**, because the adapter behind the injected
port asked the wrong DNS question. Every gate in this flow was green.

So any ticket that injects a double carries a second criterion:

```
- [ ] **The real thing is checked too.** <what exercises the adapter,
      the parser, the client or the query that the double stands in for,
      and against what — a run against the real dependency with an input
      known to produce this case, or failing that a recorded real response
      or a fixture captured from the live system, with a note on what the
      fixture cannot show>
```

If nothing can check it yet, write the deferral in the debt form Rule 5 walks —
and write it **ticked**:
`- [x] **The real thing is checked too.** deferred to ticket NN`. The tick is
honest because the redemption grep guards the debt, not the checkbox; an
unticked deferral would fail the standing bar's first line on every
legitimate deferral. The session that lands NN redeems it like any forward
reference, and the close walks it. An
unchecked double is the failure mode this flow is otherwise blind to, so it is
named, not assumed.

**Why this exists:** the measurement behind this skill says component tests miss
wiring. It does not say wiring tests catch correctness. Both are needed, and
only one of them is fashionable.

## Rule 4 — One agent session, one seam

A ticket is right-sized when one session takes it from red test to green test to
review. Nothing measures a session, so this is a sizing instinct, not a gate.
The gate is the ceiling below, and `hold-the-line`'s criteria count after it.

Because nothing measures it, a session that runs out mid-ticket is not a signal
that the cut was wrong. **Hand off, do not re-plan.** `build-slice` writes the
handoff and the next session picks the ticket up where it stands; re-cutting in
flight throws away the red test that is already running. Re-cutting has one
place, and it is `hold-the-line`'s criteria count after the review, not a
judgement made by whichever session happened to run short.

Ceiling: **one seam, three production files, one migration.** Two seams means
two tickets. The walking skeleton is exempt (Rule 1).

**One seam means one value's journey** from its producer to its far end,
however many hops it crosses. A ticket that introduces a new component between
two existing ones — a queue between scanner and store — carries that value in
and out of the new component as *one* seam: count the value, not the hops.
Count it against Rule 2's pairs the same way: a second `CONSUMED BY` pair on
the **same value** — the operator hop beside a `ticket NN` hop — is still one
seam; a pair carrying a **different value** is a second seam and this rule
says two tickets. The skeleton's two pairs ride its Rule 1 exemption. A
forward reference is for a consumer that does not exist yet, never a licence
to split a consumer that could be built in the same ticket.

Three is a number, not a feeling. A fourth file means either the ticket carries
two seams, or the architecture wants a shape the ticket is fighting — say which,
in the ticket, rather than moving code to satisfy a count.

Do not cut smaller than one seam. Half a seam is the failure this skill exists
to prevent.

## Rule 5 — A forward reference is a debt with an address

`CONSUMED BY: ticket NN` is allowed, and the walking skeleton depends on it:
its code consumers land later by definition — its human far end
(`operator, via <cmd>`) is the one it has on day one.

It carries three obligations:

- NN is a real ticket in this effort, and its status is not `resolved` or
  `declined`.
- **The session that lands NN redeems the line.** After NN's seam test is
  green, that same session rewrites the earlier ticket's `CONSUMED BY` from
  `ticket NN` into the real citation, symbol and literal. The debt is paid by
  the ticket that pays it, not by a walk months later.
- **No forward reference outlives its effort.** At close, every remaining
  `ticket NN` line takes one of three endings: redeemed, deleted together with
  the value nothing reads, or moved to the successor effort **with both ends
  together**. Splitting the two ends across two efforts is the defect this flow
  exists to prevent, arriving on schedule.

A forward reference with an address is a plan. One without is how 35 tickets
got filed at once.

## Rule 6 — An effort has a ticket ceiling

Hard ceiling: **25 tickets.** At 25, stop and split into a second effort with
its own spec and its own walking skeleton.

An effort of 165 tickets is not an effort. It is a program that was never
allowed to close, and no human can hold its state.

## Ticket template

```markdown
# NN — <what runs after this, as a sentence>

**What to build:** <two to four sentences. What exists after, and what is
broken today.>

**Blocked by:** <ticket numbers, or "nothing">

**PRODUCES:** <kind>: <what crosses>
**CONSUMED BY:** <module::symbol, reading <literal> | ticket NN | operator,
via <cmd> | <name>, out of repo | nothing>
<one PRODUCES/CONSUMED BY pair per produced value — the skeleton usually
carries two>
**CONSUMES:** <what it reads and who wrote it — `<module::symbol>`,
`ticket NN`, `operator, by hand at <path>`, or `<name>, out of repo` — or
"nothing">

**Touches:** <the production files this ticket expects to change, or
"to be discovered">

**Status:** open

**Serves exit criterion:** <the spec's exit criterion this closes, or "none">

- [ ] **<criterion, as a statement that is true when done>**
- [ ] **Checked by something that would go red.** <the seam test, or the
      behaviour test on a `PRODUCES: nothing` ticket>
- [ ] **The real thing is checked too.** <only if this ticket injects a double>

## Why

<On existing code: the evidence. A log line, a query result, a failing run.
Not an argument. If the spec's Load section names a figure for this path,
quote it here — it is the number the live run must face.>

<On greenfield, where there is nothing to measure yet: the sentence from the
spec this ticket serves, quoted, and what goes wrong for the operator if it is
built differently. Say which mode you are in.>
```

Angle-bracket text in this template is placeholder guidance: replace it or
delete it, never leave it standing in a cut ticket.

`Status` takes exactly these values, and every skill in this flow uses the same
set: `open`, `claimed`, `resolved`, `blocked — needs decision`, `declined`.
`Touches` is a lead, not a promise: `build-slice` §1 corrects it against
source, and the standing bar compares the actual diff against the corrected
line.

## Numbers are addresses

Never renumber. Split `14` into `14a`, `14b` — the old file stays in place
with `**Status:** declined` and the reason `split into 14a, 14b`, and the
splitting session rewrites every `CONSUMED BY: ticket 14` line **and** every
`Blocked by` entry naming `14` to the half that owns it, in the same edit
(`hold-the-line` carries the full split procedure). In-code
comments and other tickets point at numbers, the pointers are not compiled,
and nothing catches a stale one.

Numbers are unique inside one effort, not across efforts. A ticket moved into a
successor effort keeps its number, and the successor's walking skeleton takes
the next free number instead of `01`. The skeleton is the first ticket **built**
in an effort; it does not have to be the lowest number.

## Before you hand the plan over

Run `cold-read` on the finished set. Then answer in writing, in `spec.md`
under `## Plan check`:

> If every ticket is implemented exactly as written and nothing more, does the
> feature run end to end?

An answer needing "well, then we would also need to…" names a seam nobody owns.
Add it now, not after the first real run.

The plan is files, and files ride commits: the effort's planning artifacts —
spec, tickets, the folder — go in with the walking skeleton's build commit
(`build-slice` §8). Nothing in this flow commits them earlier, and the
standing bar's diff line expects them there.

The plan is cut before the skeleton runs, and the spec says the skeleton will
settle its open questions — so when the skeleton lands, re-read the remaining
tickets against what it showed. A re-cut at that point goes through
`hold-the-line`'s criteria count like any other; what it never does is happen
silently.
