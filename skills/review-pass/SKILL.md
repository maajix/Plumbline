---
name: review-pass
description: Reviews a ticket's work along four axes, labels every finding blocker/required/nit, and hands each to hold-the-line for its verdict. Use after building a ticket, before merging a branch, when reviewing a diff or a PR, or when the user asks to review changes since a point. Bounded to three cycles so a review cannot turn into a ticket factory.
---

# Review pass

A review is a **cold read** of a finished thing: whole artifact, top to bottom,
findings at the end, repairs on request. Read `cold-read` for the mode. This
skill adds what to look for and what happens to each finding.

On a bare PR or diff with no ticket file behind it, the four axes and the
cold-read mode hold unchanged; the findings report to the requester replaces
the ticket file as the address, and `hold-the-line`'s verdicts wait until a
ticket set exists to receive them.

Ticket text and code comments are **leads**. Current source, current artifacts
and commands that run are evidence. A ticket that calls itself `resolved` is
a claim, not a proof. The ticket under review normally reads `claimed`:
`build-slice` leaves it that way on purpose, and this skill is what turns it
`resolved` at the end.

## Fix the point first

Pin the comparison before anything else: `git diff <fixed-point>...HEAD`.
Cycle 1 pins the parent of the ticket's **first** build commit
(`git log --reverse --oneline --grep 'ticket <NN>'`, oldest hit whose
subject ends `(ticket NN)` and does not begin `REVIEW:`, which review
commits own — "first", so a criterion repair later in history cannot shrink
the diff to itself); cycle 2 and 3 pin the previous cycle's review
commit — every cycle leaves one, whichever way it closes; a re-review after
REOPEN pins the parent of the reopen repair's build commit — the tickets that
landed in between were reviewed by their own cycles, and their work is not
this review's diff. Confirm the ref
resolves and the diff is non-empty. A bad ref should fail here, not inside
four parallel readers. One bad ref has a known meaning: no build commit for
this ticket at all says the build session died between §7 and §8 — hand back
to `build-slice` to run §8, and review after.

A re-read outside the ticket's cycles — an audit of `resolved` work — is
none of the above: it pins the commit that resolved the ticket, appends
under `## Review findings, <date> — audit`, consumes no cycle, and touches
no `Status`. Its block closes with `Audit — undecided: none` in place of a
cycle line, and it commits on its own, immediately:
`REVIEW: audit — <what it settled> (ticket NN)`. Its findings take verdicts like any other, and an audit whose
verdicts all come back DECLINE or ALREADY OWNED is the theatre tell below,
single pass or not.

If HEAD is the repo's first commit, there is no earlier ref: the fixed point is
the empty tree: `git diff $(git hash-object -t tree /dev/null) HEAD`. That
is the walking skeleton's normal case on greenfield.

## The four axes, read in parallel, reported apart

Run each as its own reader, as a separate subagent that cannot see the others,
and keep the reports apart. Four readers that cannot see each other produce four
genuinely different reports; one reader wearing four hats produces one report
four times. Do not merge or rerank across axes — merging is the judgement the
separation exists to prevent.

When two axes land on the same finding, keep both entries and say they
converged. Convergence is signal about the finding's weight, not duplication to
clean up.

**Seam.** Cold-read the `## Seam check, <date>` report that `build-slice` §5
appended to the ticket, against current source: does anything read what this
wrote; does anything write what it reads. Re-run `seam-check` only if the
report is missing or the diff has touched the seam's producer or consumer
since it was written — a criterion repair that changed tests and bookkeeping
is not the seam moving, and closing's rule that the repair leaves the report
standing wins. A re-run
ordered here walks the greps and reads the recorded far ends only; live
replays and the `REPLAYS` counts belong to `build-slice` §5's run alone —
reading the recorded far ends against current source is this axis's
counter-check. This axis goes first because it is the one that produced 64 % of
the late tickets in the effort this workflow was built from.

**Ticket.** Against the ticket file: what did it ask for that is missing or
partial; what is in the diff that it did not ask for; what looks implemented
but is implemented wrong. Quote the criterion for each finding.

This axis also re-reads the seam fields against source. `seam-check` greps the
code; only this axis opens the citation the ticket itself claims. Check the `CONSUMES` head the same
way — a redeemed one (`…, written by 02`) opens the cited writer; one still
reading `ticket NN` is checked like the forward form below. Check each
`CONSUMED BY` by its form: for `<module::symbol>, reading <literal>`, open the
symbol and find the literal — a symbol citation you cannot confirm in source
is a `blocker`. For `operator, via <cmd>`, run the command and read the
output. For `ticket NN`, confirm NN exists and is not `resolved` or
`declined`. For `<name>, out of repo`, confirm the named contract check
exists. If the `## Seam check` report records skipped grep hits (brownfield),
open a sample of them. In testing, a citation reading "indirectly via the
reason text" passed every other gate.

**Bar.** Against `${CLAUDE_PLUGIN_ROOT}/references/standing-bar.md`, including
the five ways a bar gets quietly lowered. Tightening is silent; loosening is
loud. The ticket's `## Bar` block carries what the machine lines printed;
re-run any grep you doubt.

**Craft.** Naming, duplication, dead code, complexity that does not earn its
keep, a refactor that relocated complexity instead of reducing it. The repo's
own documented standard always wins over any general rule.

## Sizing, so the review can be honest

```
~100 changed lines   reviewable in one sitting
~300 changed lines   fine if it is one logical change
~1000 changed lines  too large; the review will be shallow, split it
```

A diff this size is a symptom: the ticket was cut too wide. Say so, and hand it
to `cut-slices`. The walking skeleton is the exception — it crosses every
layer by design, so judge it by whether one path runs, not by its size.

## Lead with leverage

Order findings by what they cost, not by what is easy to spot. Seam and
correctness first, then structure, then everything else. A few high-conviction
findings beat a long list — if there is one structural problem and ten naming
nits, the structural problem **is** the review.

Label each: `blocker`, `required`, `nit`. One line each:

```
<file::symbol>: <label>: <problem>. <the fix>.
```

The label is not decoration. `hold-the-line` reads it: a `blocker` cannot become
a deferred criterion, and a `nit` is fixed now or declined. Assign the label
knowing that.

## Every finding gets a verdict

**Write the findings into the ticket when the four readers report** — before
the verdicts, not after. Same argument as below, one step sharper: an
unverdicted finding is indistinguishable from an open one, but a finding that
exists only in this session's context is not indistinguishable, it is
**invisible**. Four subagents that cannot see each other report into one
context, and that context can end.

The entries go under `## Review findings, <date> — cycle N`, in the format
`hold-the-line` owns: axis tag in brackets, severity, then `— verdict pending`
until `hold-the-line` answers, and the verdict replaces that marker in the
same edit that records it. The open pending entries **are** the state of the
cycle: a session that finds them knows exactly which findings were raised and
which still owe an answer, without re-running anything. A cycle with no
pending entries left is a cycle whose verdicts are all in.

Writing them early does not merge them. The axis tag keeps the four readers'
entries apart in the ticket — the separation the readers were run under
survives into the file or it was never real.

Early means *after all four have reported*, never while one is still reading.
`build-slice` forbids editing a ticket a cold read has open, for the reason that
rule gives: a reader discards line-numbered findings when the artifact moves
under it, and the Ticket axis reads this file.

Hand the findings to `hold-the-line` with their labels. Every finding comes
back with exactly one of its six verdicts, written into the ticket that
produced it. `hold-the-line` owns that set; do not shorten it from memory here,
because a `blocker` reduced to a deferred criterion is the bar going down
quietly.

## Closing the cycle

A session arriving at a ticket whose newest findings block is fully
verdicted but has no matching `REVIEW: … (ticket NN)` commit finishes
exactly that — the last review died between its verdicts and its commit; run
this section, do not open a new cycle.

When no `— verdict pending` entry remains, commit the cycle **either way**:
one review commit holding the ticket file, any NOW repairs, and every other
ticket file a verdict in this cycle edited (CRITERION, REOPEN, TICKET all
write elsewhere) — `REVIEW: <what the review settled> (ticket NN)`. An
uncommitted review is swept into the next commit's diff and read as its work,
and this commit is the fixed point the next cycle pins.

- If no criterion was added to this ticket, set `**Status:** resolved` in that
  same commit — this is the one edit that writes that value.
- If a criterion **was** added to this ticket, the commit carries the findings
  and verdicts, the ticket stays `claimed`, and it goes back to `build-slice`
  (red test first, as always — and when the criterion adds a missing assertion
  over behaviour that is already correct, the test is born green: then the
  discrimination check is the proof — break the asserted literal, watch red,
  restore, record it on the repair's `Mutated:` line). The repair runs
  `build-slice` §2–§3 and §7 — a dated addition to `## Resolution` and a fresh
  `## Bar, <date>` paste — but not §5: the seam report stands and `REPLAYS`
  moves once per ticket. The repair lands as its own `(ticket NN)` build
  commit, and the re-review of that work is the next cycle.

A ticket reopened later by a REOPEN verdict starts a fresh cycle count when it
returns here; the old count stays in the file as history.

## Three cycles, and the bound does not move

A cycle is one pass of all four axes, plus the verdicts and repairs that follow
it. The re-review is the start of the next cycle, not the end of this one.

The cycle line at the bottom of the findings block —
`Review cycle 2 of 3 — undecided: seam 1, craft 2`, closing as
`— undecided: none` once every verdict is in —
is what survives the session boundary. A bound nobody writes down cannot
survive one, and a count without its axes tells the next session how many
cycles are left and nothing about what is unfinished inside this one. A fresh
session can re-run an axis; what it cannot do is work out which axis produced
a pending finding it never saw raised.

Stop when the next cycle returns only findings already considered, **or** after
three cycles, **or** when the user says ship it.

If cycle three still surfaces substantive findings, that is information about
the artifact, not a reason to run a fourth. Remaining `required` findings take
CRITERION on a *different* unfinished ticket, or TICKET — never another
criterion here. If nothing can hold them, set the ticket
`blocked — needs decision`, record why in the findings block, and hand it to
the user. Never a fourth cycle.

If three cycles feel obviously insufficient because the change is large: the
change is too large. Split it and review the parts. **Do not lift the bound.**

## The tell that a review is theatre

Across two or more cycles where findings were raised, every verdict came back
DECLINE or ALREADY OWNED. That is validation wearing a review's clothes. Stop
and say so.

## Approving

Approve when the change improves the codebase **against the behaviour the
ticket promised**, not against the previous commit. In testing a change that
plainly improved the code also silently sent every customer lookup to a public
resolver — better than before, and wrong.

Approve even when it is not how you would have written it. Perfect code does not exist and blocking on
taste turns the review into another source of tickets.
