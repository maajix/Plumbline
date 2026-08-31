---
name: build-slice
description: Implements exactly one ticket in one session and leaves the ticket file honest about what happened. Use when implementing a ticket, working an effort's frontier, resuming a claimed ticket that carries a Handoff block ('continue ticket NN', 'pick up where it stopped'), or when the user says 'build ticket NN' or 'implement this'. Covers the moment the ticket turns out to be wrong mid-flight, which is where unplanned tickets normally get created.
---

# Build one slice

One session, one ticket. The ticket file is the state — it is written at the
start, during, and at the end, not remembered.

This skill exists because the usual instruction is six lines long and never
says what to do when the ticket turns out wrong. That silence is where backlogs
explode: the agent finds a problem, has no rule, and opens a ticket by default.

## 0. Pick the frontier, when no ticket is named

This flow is single-session: one agent works an effort at a time, so ticket
state lives in the files, never in a lock. **Every `claimed` ticket comes
before every `open` one.** A ticket is `claimed` because a session took it and
the review cycle has not closed — the build is half done, or REOPEN sent it
back, or it is built and awaiting review. All are work already started, and
work already started comes before work not started.

The ticket file says which of those it is. Before claiming, read its tail, in
this order:

- `— verdict pending` entries under a `## Review findings` heading — a
  review died mid-cycle. Close the cycle (`hold-the-line`, then
  `review-pass`'s closing rules); do not build. Pending entries under
  `## Seam check` or `## Build findings` are a *build* session's unfinished
  verdicts — this skill's case, settled in its own §4/§5 flow.
- An unticked `- [ ]` criterion, a `## Handoff` block, or no `## Resolution` /
  `## Bar` yet — build work, this skill's case: continue below. The unticked
  criterion is the tell that separates "awaiting rebuild" from "awaiting
  review" — it is what a REOPEN and a review's CRITERION verdict both leave
  behind, and neither of those goes to review before it is built.
- Otherwise — `## Resolution` and `## Bar` present, every criterion ticked, no
  handoff, no pending entries — built, awaiting review. One check first:
  confirm the build commit exists (`git log --oneline --grep 'ticket <NN>'`);
  a working tree still holding the work uncommitted means the session died
  between §7 and §8, so run §8 before anything else. Then hand the ticket to
  `review-pass`; there is nothing here to build.

Within the `claimed` set, and then within the `open` set, take the
lowest-numbered ticket whose every `Blocked by` entry is `resolved` or
`declined`. Sort `14a` and `14b` after `14` and before `15`.

If the chosen ticket carries a `## Handoff` block, read it before anything
else — see "The session is allowed to end first" below.

## 1. Claim it, out loud

Before any code:

- Read the ticket file whole.
- Read the current source of **every** file its `Touches` line names, plus the
  file behind its `CONSUMED BY` symbol — for the code form; the operator,
  out-of-repo and `ticket NN` forms have no file to open, the command output,
  contract or ticket stands in. The ticket text is a lead, not
  evidence — it may describe code that has since changed. Correct the
  `Touches` line now if the source disagrees with it.
- Set `**Status:** claimed` in the file and save. The five legal values across
  this flow are `open`, `claimed`, `resolved`, `blocked — needs decision`,
  `declined`.

If the ticket names no `PRODUCES` / `CONSUMED BY` / `CONSUMES` lines, it was
cut before `cut-slices` existed. Fill them in now, from source, before
building, with the kind (`new`, `changed`, `contract`, `nothing`) and the
literal the reader reads. A ticket whose consumer you cannot name is a ticket
you cannot finish.

## 2. Red at the seam, first

Write the failing test **before** the code, and write it at the seam the ticket
names — the one that runs producer and consumer together. On a
`PRODUCES: nothing` ticket the red-first test guards the behaviour the ticket
changes instead of a seam; everything else in this section applies to it
unchanged.

Run it. See it fail, and **read the failure**. It must be an assertion about
the value crossing the seam. Copy that first failing assertion message —
`## Resolution` has a `Red:` line waiting for it.

`ImportError: cannot import name 'cli'` is the default red of every greenfield
first ticket and proves nothing about the seam. Write enough scaffolding for the
test to reach its assertion, then watch *that* fail.

**Prove the test discriminates** (`cut-slices` Rule 3): once the test is green
in step 3, change the reader's literal — the status string, the column name,
the key; on a `PRODUCES: nothing` ticket, the behaviour test's expected
literal — and watch it go red again, then change it back. Copy that assertion
message too; `## Resolution` has a `Mutated:` line for it. A seam test you have
not tried to break is a claim, not a check.

If the seam does not exist yet to test at, **that is the finding.** Give it a
severity and take it through step 4's discovery rule — do not invent a seam to
satisfy this one.

## 3. Build the minimum that goes green

Only enough code to pass the test. No speculative flexibility, no
configurability nobody asked for, no error handling for cases nothing has
measured.

Tick each acceptance criterion in the ticket file **as it becomes true**, not
in a batch at the end. A batch at the end is written from memory.

On a walking skeleton every criterion becomes true in the same instant — the
first green run of the one path — so ticking them together is correct there and
nowhere else. That first green run also just taught the skeleton session the
effort's verify command: write it into the spec under `## Verify command` now
(`cut-slices` Rule 1), in a form that prints each test's name. §7's bar reads
it from there, on this ticket and every one after.

## 4. Three things that stop you, and what each one means

Each of the first two names a skill this plugin ships.

**A wall — "this cannot be done."** Run `price-the-wall` before designing
around it. Fill `WALL`, `PRICE`, `PURPOSE`, `RULE`. Building around an unpriced
wall produces code that documents its own limits, and that becomes next week's
ticket.

**An unknown cause — "why is it doing that?"** Run `structured-debugging`.
Four hypotheses, one of them "my measurement is wrong". An agent that guesses
mid-ticket ships the repair that becomes the next ticket.

**A discovery — "this other thing is broken."** Give it a severity —
`blocker`, `required` or `nit` — then run `hold-the-line` and take whichever of
its six verdicts comes back. Do not shorten that set from memory; the severity
decides, and a `blocker` is never allowed to become a deferred criterion. Do
not open a ticket by reflex, and do not fix it silently either. Silent fixes
make the diff unreviewable.

Record discoveries and their verdicts under `## Build findings, <date>` at the
bottom of the ticket, in `hold-the-line`'s entry format with `build` in the
axis slot. That heading is deliberately not `## Review findings` — a later
session must be able to tell what a review raised from what a build ran into.

## 5. Prove the seam before you call it done

Run `seam-check` on everything this ticket wrote and read. It appends its
`WROTE`/`READ` record and findings to the ticket under `## Seam check, <date>`;
the review's Seam axis reads that section instead of re-running the pass.

If the ticket injected a double, its second criterion applies: name what checks
the real adapter, parser, client or query the double stands in for. A green seam
test over an unchecked double is how a correctly wired system ships the wrong
answer.

An unexplained `NOBODY` means the ticket is not done, regardless of green
tests — green unit tests are exactly what the seam defect hides behind.

A far end the ticket already named as `ticket NN`, `operator, via <cmd>`,
`<name>, out of repo`, or `the <constraint> at <where>` is not `NOBODY`.
Record it and carry it to the effort's close.

**Redeem the debts this ticket pays.** Run
`grep -rn 'ticket <NN>' docs/issues/<effort>/` with `<NN>` this ticket's own
number. Each **`CONSUMED BY`** or **`deferred to`** hit was a promise that
this ticket would land that value or that check — the pattern is deliberately
wide so it matches through the template's bold markers, and it also catches
history that is *not* a debt: `CONSUMES … written by ticket NN` citations,
verdict entries, `## Bar` pastes. A debt lives only in a ticket's seam-field head — the unindented
`**CONSUMED BY:**` line, a `**CONSUMES:**` line still reading `ticket <NN>`,
or a criterion's `deferred to`; anything quoting the tokens inside a dated
`##` block is history. A `CONSUMES: ticket <NN>` head is the same debt seen
from the reader's side — rewrite it in the same edit. **A redeemed head drops
the `ticket <NN>` token**, and each head kind has its rewrite: a
`CONSUMED BY` head becomes `<module::symbol>, reading <literal>`; a
`CONSUMES` head becomes `<what it reads>, written by 02` with the bare
number; a `deferred to` criterion names the test that now checks the real
thing. The greps hunt the token, and a head still carrying it reads as an
unredeemed debt at every later bar and close. Rewrite only the promises into
the real citation — symbol and literal, or the named test; when the promised
consumer reads the value through an intermediary, cite the symbol that
actually touches the literal and name the chain in one clause — and leave
the history alone. A forward reference is redeemed by the session that lands the ticket,
never by a walk at close.

Then run the path once for real and read the far end. **Use the smallest input
that reaches the case this ticket is about**, and replay every block in
`docs/issues/<effort>/live-inputs.md` whose `STATUS` begins with `live`, so a
far-end regression cannot hide behind fresh test data. `seam-check` owns that
file's format, the replay-count rule, and the rule that promotes a replayed
block into a test. This run is the one that increments `REPLAYS`.

**An earlier seam test goes red.** On a `PRODUCES: changed` ticket this is the
design working: the old test asserted the value the operator saw, and the value
moved. Update that assertion to the new expected value, in this commit, and say
in the resolution which test you changed and why. The same holds for a `live`
block whose far end this ticket legitimately moved: rewrite its `FAR END` in
this commit and set `STATUS live, far end moved by <NN>`. That is the one case
where editing an existing assertion is not lowering the bar — every other case
is lowering-move 2. Deleting the old test, or loosening it instead of updating
it, is lowering the bar in both cases.

## 6. Write the resolution

Append to the ticket file:

```markdown
## Resolution, <date>

<what now runs, in one paragraph, naming the seam and the test that guards it.>

**Red:** <the first failing assertion message from §2, verbatim>
**Mutated:** <the literal changed in §2's discrimination check> -> <the
assertion that went red>
**Forward references left standing:** <by ticket number only, e.g.
"02 -> 03", covering lines this ticket wrote and cut-time lines it leaves
unredeemed, or "none". Numbers, never quoted token forms — the redemption
grep hunts the tokens>

<if anything in the ticket turned out wrong, say which criterion and why.>
```

On a reopened ticket, append a second dated `## Resolution` block; the last
dated block is the current one and the earlier ones are the history REOPEN
asked for.

**Leave `**Status:** claimed` standing.** The ticket becomes `resolved` only
when the review cycle closes — `review-pass` owns that edit. A ticket marked
`resolved` before anyone else has read it is a self-graded ticket.

**Delete the `## Handoff` block in the same edit that writes `## Resolution`.**
A handoff that outlives the session it described is a pointer to a failure
nobody is still looking at — the same defect class `close-effort` treats under
"Paths are addresses too", and nothing compiles a ticket file to catch it.

If the ticket's `Touches` line still reads `to be discovered` — the
greenfield skeleton's legal starting value — rewrite it now with the files
actually touched: §7's diff comparison needs the real list on its left-hand
side.

A ticket that closes without a resolution paragraph is a ticket the next
session has to re-derive from the diff.

## 7. Clear the standing bar

Before the ticket goes to review, take
`${CLAUDE_PLUGIN_ROOT}/references/standing-bar.md` in two steps: **run the
commands its machine-checked lines carry, then walk what no command can
check.** A line with a command beside it is not walked, it is run — paste the
command and what it printed under `## Bar, <date>` at the bottom of the
ticket. It is the same bar every time, and it is the single place it is
written. A finding this bar run itself raises goes under `## Build findings`
(§4's heading and format) and through `hold-the-line` like any other.

## 8. Commit, then hand to review

One build commit per ticket where possible. Subject uses the repo's uppercase
type prefix — on a repo too young to have one, pick any short uppercase
prefix except `REVIEW:`, which review commits own — states what now works,
not what was edited, and ends with `(ticket NN)`, which is how
`/review-pass` finds its default target.

Then hand to `review-pass`. Do not review your own work in the same pass —
authoring and reviewing in one pass does not work, which is the whole reason
`cold-read` exists. Alone in a session, that hand-off is a subagent per axis;
`review-pass` says how. The review's verdicts are what close the ticket:
`review-pass` sets `**Status:** resolved` when its cycle ends clean, and makes
the review commit.

**Finish your edits to the ticket file before any cold read opens on it.** A
cold read discards line-numbered findings when the artifact changes under it,
and this skill and `hold-the-line` both write into the same file.

## The ticket is allowed to be wrong

If the ticket asks for something that is now clearly the wrong thing to build:
**stop and say so.** Do not build it anyway, and do not silently build
something else.

Write the disagreement into the ticket, name the evidence, and set
`**Status:** blocked — needs decision`. That is a correct outcome for a
session. A ticket built against evidence is a defect with a checkmark on it.

The state has an exit: when the user decides, the deciding session writes the
decision under `## Decision, <date>` in the ticket and sets the status back to
`open` (or `declined`, if that is the decision). A blocked ticket with no
decision block is waiting; one with a decision block and a stale status is a
finding.

## The session is allowed to end first

`cut-slices` Rule 4 says out loud that nothing measures a session. So a ticket
that outlasts one is not the exception — it is the case no rule covers.

The walking skeleton is the likeliest one. Rule 1 exempts it from the size
ceiling, which makes the largest ticket of every effort the one the size rule
was never applied to, and it is the first one built.

When the session ends before the ticket does, append the handoff to the ticket
file **before** you stop, and leave `**Status:** claimed` standing. The block
lives in the working tree, so it survives a process death, not a workspace
loss — this flow accepts that, the same way it accepts losing the
uncommitted code. The ticket
is claimed — by the ticket, not by a session. There is no sixth status for
"claimed by nobody right now", and inventing one would make the frontier rule
in §0 skip the work that is furthest along.

```markdown
## Handoff, <date>

**Red:** <the failing test and its error message, verbatim>
**Green:** <criteria already ticked, and what each one proves>
**Half-edited:** <changed and not compiling, or changed and untested>
**Next action:** <one sentence: the next command or the next edit>
```

Four lines, and deliberately not a summary. §1 makes the next session re-read
the ticket whole and the current source of every file it names, so a summary of
the reasoning buys that session nothing it is not already getting. What it
cannot re-derive from source is which failure this session was looking at and
what had already been decided — that is all four lines carry. **A handoff that
summarises the reasoning is the compaction it exists to replace.**

Resuming is the mirror image: read the `## Handoff` block first, before the
ticket body and before the source, then do §1 in full anyway. The handoff's
`Red:` line may be carried into `## Resolution` marked `inherited from the
handoff` — the resuming session did not watch it, and saying so is cheaper
than pretending; the `Mutated:` check is re-run fresh, since the green state
still exists to break. That inheritance is for a death *after* green: when
the session died mid-§2 the red is still live, so run it and watch it
yourself — nothing to inherit. The block is a
lead like any other ticket text — it says where to look, not what is true.
`Next action` is checked against source before it is run.

This block belongs to §1 through §7 only. It is written in §1–§7 and deleted in
§6 — or, when the session dies *after* §6 wrote the resolution, by the
resuming session **before** it runs §7: delete the block first, then run the
bar, which is what makes the bar's `## Handoff` grep end at `0`. The deletion
loses nothing — a post-§6 handoff's facts sit in `## Resolution` already —
and a bar that then fails sends the ticket back to build, not back to the
deleted block. Both happen before §8 hands the ticket to `review-pass`, so
the block never edits a ticket a cold read has open: §8's rule holds
unchanged. A session that ends
*during* the review leaves no handoff; it leaves the `verdict pending` entries
`review-pass` writes, which are that phase's version of the same idea.
