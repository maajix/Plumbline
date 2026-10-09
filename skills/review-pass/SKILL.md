---
name: review-pass
description: Reviews a ticket's work along four axes, labels every finding blocker/required/nit, and hands each to hold-the-line for its verdict. Use after building a ticket, before merging a branch, when reviewing a diff or a PR, or when the user asks to review changes since a point. Bounded to three cycles so a review cannot turn into a ticket factory.
user-invocable: false
---

# Review pass

A review is a **cold read** of a finished thing: whole artifact, top to bottom,
findings at the end, repairs on request. Read `cold-read` for the mode. This
skill adds what to look for and what happens to each finding. Skills named in
this flow are this plugin's — invoke `plumbline:<name>`, not a same-named
standalone skill.

On a bare PR or diff with no ticket file behind it, the four axes and the
cold-read mode hold unchanged; the findings report to the requester replaces
the ticket file as the address, and `hold-the-line`'s verdicts wait until a
ticket set exists to receive them.

Ticket text and code comments are **leads, not evidence** (`cold-read`); a
ticket that calls itself `resolved` is a claim. The ticket under review
normally reads `claimed`:
`build-slice` leaves it that way on purpose, and this skill is what turns it
`resolved` at the end.

## Fix the point first

Read `${CLAUDE_PLUGIN_ROOT}/references/ticket-lifecycle.md`. It owns stable
IDs, legacy commit lookup, pinned Base/Head, interrupted cycles and the audit
mode. With no ticket named, select the newest build by qualified ID; legacy
subjects require the path-scoped check described there.
For a bare PR use the requester's comparison point and freeze its head too.
For a ticket cycle, before starting readers write Base, Head and Readers: pending.
An audit records its Head and audit heading instead; a bare PR writes no ticket.
Resume an unfinished attempt instead of opening another cycle.

## The four axes, read in parallel, reported apart

Run each as its own reader, as a separate subagent that cannot see the others,
and keep the reports apart: one reader wearing four hats produces one report
four times. Do not merge or rerank across axes — merging is the judgement the
separation exists to prevent.

When two axes land on the same finding, keep both entries and say they
converged. Convergence is signal about the finding's weight, not duplication to
clean up.

**What every reader gets.** Each axis reader is its own subagent, handed: the
pinned Base and Head and `git diff <base> <head>` (audit: current source plus
original build context), the ticket file's path, the repo as its working
directory, its own axis paragraph below verbatim, and the
instruction *"cold read; report `<file::symbol>: <label>: <problem>. <fix>.`
lines only; edit nothing"*. Plus one extra input per axis:

| axis | also gets |
|---|---|
| Seam | the ticket's `## Seam check` report, and `plumbline:seam-check` |
| Ticket | the ticket file and effort spec, including referenced constraints and Load |
| Bar | `${CLAUDE_PLUGIN_ROOT}/references/standing-bar.md` and the ticket's `## Bar` block |
| Craft | the repo's documented standard, by path |

**Seam.** Cold-read the `## Seam check, <date>` report that `build-slice` §5
appended to the ticket, against current source: does anything read what this
wrote; does anything write what it reads. Re-run `seam-check` only if the
report is missing or the diff has touched the seam's producer or consumer
since it was written — a criterion repair that changed tests and bookkeeping
is not the seam moving. A repair that changed production behavior must refresh
its proof per the lifecycle. A re-run ordered here reads the recorded far ends against
current source; it never replays and never touches `REPLAYS` (`seam-check`).
This axis goes first because it is the axis the measurement behind this flow
found the defects in.

**Ticket.** Against the ticket file: what did it ask for that is missing or
partial; what is in the diff that it did not ask for; what looks implemented
but is implemented wrong. Quote the criterion for each finding.

This axis also re-reads the seam fields against source. `seam-check` greps the
code; only this axis opens the citation the ticket itself claims. Check the `CONSUMES` head the same
way — a redeemed one (`…, written by 02`) opens the cited writer; one still
reading `ticket NN` is checked like the forward form below. Check each
`CONSUMED BY` by its form: for `<module::symbol>, reading <literal>`, open the
symbol and find the literal — a symbol citation you cannot confirm in source
is a `blocker`, and "indirectly via the reason text" is the form that
passes every other gate. For `operator, via <cmd>`, run the command and read
the output. For `ticket NN`, confirm NN exists and is not `resolved` or
`declined`. For `<name>, out of repo`, confirm the named contract check exists.
If the `## Seam check` report records skipped grep hits (brownfield), open a
sample of them.

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
correctness first, then structure, then everything else. If there is one
structural problem and ten naming nits, the structural problem leads and the
nits follow it. Ordering is not filtering: record every finding the readers
report, because one dropped here is a decline nobody wrote down.
`hold-the-line` decides what is not worth doing, and its `nit` row already
allows DECLINE.

Label each: `blocker`, `required`, `nit`. One line each:

```
<file::symbol>: <label>: <problem>. <the fix>.
```

The label is not decoration: `hold-the-line`'s severity table decides the
verdict from it. Assign it knowing that.

## Every finding gets a verdict

**Write the findings into the ticket when the four readers report** — before
the verdicts, not after. An unverdicted finding is indistinguishable from an
open one; a finding that exists only in this session's context is
**invisible**, and that context can end.

The entries go under `## Review findings, <date> — cycle N`, in the format
`hold-the-line` owns: axis tag in brackets, severity, then `— verdict pending`
until `hold-the-line` answers, and the verdict replaces that marker in the
same edit that records it. The open pending entries **are** the state of the
cycle: a session that finds them knows exactly which findings were raised and
which still owe an answer, without re-running anything. A cycle with no
pending entries left and Readers complete is a cycle whose verdicts are all in.

Writing them early does not merge them. The axis tag keeps the four readers'
entries apart in the ticket — the separation the readers were run under
survives into the file or it was never real.

Set `**Readers:** complete` only after all four reports are recorded.
Early means *after all four have reported*, never while one is still reading:
the Ticket axis has this file open, and `cold-read` discards its line-numbered
findings if the file moves under it.

Hand the findings to `hold-the-line` with their labels. Every finding comes
back with exactly one of its six verdicts, written into the ticket that
produced it. `hold-the-line` owns that set; do not shorten it from memory
here.

## Closing the cycle

Follow the shared lifecycle's state table and repair ordering. Once all four
readers and verdicts are recorded, commit the review findings and any affected
ticket files. NOW and CRITERION repairs to executable behavior are built in a
separate commit and receive the next review; no executable repair rides an
approval commit. Only a clean reviewed snapshot becomes resolved.
A split stays declined and a decision stays blocked.

## Three cycles, and the bound does not move

One pass of all four axes is one cycle. Resumption keeps its number.
At cycle three, any remaining executable repair blocks for a decision; keep
its criterion and explain what is unverified. Never silently reset the counter,
run a fourth cycle or make an unreviewed repair to close the ticket.
A genuine later REOPEN of resolved work starts a new review per the lifecycle.

## The tell that a review is theatre

Across two or more cycles where findings were raised, every verdict came back
DECLINE or ALREADY OWNED. That is validation wearing a review's clothes. Stop
and say so.

## Approving

Approve when the change improves the codebase **against the behaviour the
ticket promised**, not against the previous commit — measured, a change that
plainly improved the code also silently sent every customer lookup to a public
resolver.

Approve even when it is not how you would have written it. Perfect code does not exist and blocking on
taste turns the review into another source of tickets.

## The next step

When the cycle closes clean, end your final message by naming it: start a
**fresh session** and run `/plumbline:build` for the next frontier ticket — or
`/plumbline:close` when no ticket is left `open` or `claimed`. A ticket set
`blocked — needs decision` has no next command; it has a question, and the
message ends with that question instead.
