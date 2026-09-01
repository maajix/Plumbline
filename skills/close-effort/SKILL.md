---
name: close-effort
description: Closes an effort by settling every debt it opened. Use when an effort's tickets look done, when deciding whether to split an effort that has grown, or when the user asks whether a feature is finished. Walks the forward references, the exit criteria and the ticket statuses so an effort can end rather than drift.
user-invocable: false
---

# Close the effort

Nothing else in this flow owns the effort as a whole. Each ticket closes itself,
and an effort that no step ever ends is how one reaches 165 tickets.

An effort closes when every debt it opened is settled. Debts, not tickets — the
count going to zero is not the same as the work being finished.

## The four walks

Each produces a written answer in the spec, under `## Close, <date>`. An
unanswered walk means the effort is not closed.

A walk that **refuses** — a ticket not yet `resolved` or `declined` that
cannot move, an unredeemable reference — is also written down: `## Close refused, <date>`, naming the
walk and what blocked it. The comma in `## Close,` is what `/close`'s
detection greps for, so a refusal record does not make the effort read as
closed. Either record ends in a commit: subject `CLOSE: <what closed, or
why refused>`, holding the close block, any moved tickets and the successor
spec — and carrying no `(ticket NN)` suffix, which belongs to build commits.
An uncommitted close is swept into the next diff and read as its work.

### 1. Forward references

Run `grep -rn 'ticket [0-9]' docs/issues/<effort>/` and read every
`CONSUMED BY`, `CONSUMES` and `deferred to` hit — the pattern matches through the
template's bold markers, where a literal `CONSUMED BY: ticket` never would.
Only hits in a ticket's seam-field head are debts; hits inside dated `##`
blocks (`## Bar` pastes, findings entries, resolution records) are history
and stay as they are. Most debt lines should already be gone: `build-slice` §5 redeems each one in the
session that lands NN. What is left is what nobody paid.

Each remaining line takes exactly one of three endings, and the ending is
written down:

- **Redeemed.** NN landed; rewrite the line into the real citation, symbol and
  literal, and grep the literal inside that symbol to prove it.
- **Deleted.** Nothing will read the value. Delete the value and the code that
  writes it, in this edit.
- **Moved, both ends together.** The producing ticket *and* NN both go to the
  successor effort. Moving only one end is the defect this whole flow exists to
  prevent, arriving exactly on schedule.

An unread forward reference never becomes a note in the next effort's spec. A
note is not an end.

### 2. Exit criteria

Every `E<n>` in the spec. Each is either met, or moved out into a named
successor effort in the same edit.

Check it from the tickets: each names the criterion it serves. A criterion no
ticket names is work nobody did. And check the set is complete against the
shape: `grep -c '^- .*— must hold before close$' docs/issues/<effort>/shape.md`
prints the number of tagged In scope bullets, and each has its `E<n>` — met
here or moved out, never lost between shape and spec. A successor effort
built in synthesis mode has no `shape.md` and no count: its criteria came in
with the moved tickets, keeping their `E<n>` numbers, and the numbers are
the check.

### 3. Ticket statuses

Every ticket is `resolved` or `declined`. Anything `open`, `claimed`, or
`blocked — needs decision` either gets finished now or moves into the successor
effort's folder, keeping its number and its status.

Also run `grep -rn '— verdict pending' docs/issues/<effort>/` (the em-dash
entry marker; cycle lines say `undecided` and cannot match) and read each
hit: an entry line — `- [axis] **…** — verdict pending` — is a review whose
verdicts never came in, on a ticket that therefore never legally became
`resolved`; a hit that merely quotes the marker inside a pasted command or a
close record is history. There must be no entry-line hit.

Numbers are unique inside an effort, not across efforts, so a moved ticket does
not get renumbered. The successor's walking skeleton takes the next free number
in that folder. It is the first ticket **built** there, not the lowest number.

### 4. The whole path, once

Run the feature end to end, the way an operator would, using every block in
`docs/issues/<effort>/live-inputs.md` whose `STATUS` begins with `live` —
the `live, <reason>` blocks included; their reason exempts them from
promotion, not from this walk. Read the far end.

Not the test suite — the feature. Every measured failure behind this flow was
green when it shipped.

The blocks marked `promoted to <test>` are carried by the suite, so they are not
replayed here — and this walk does not replace the suite any more than the suite
replaces this walk. Run both, and say in the close block how many blocks ran
here and how many the suite carries. A block this walk could not run gets
`STATUS live, not run at close: <reason>` — that value is this walk's, and it
is distinct from a promotion exemption the same way `retired` is distinct from
both. A `live` block that neither ran nor took that status is a walk that was
not finished.

A block still `live` when the effort closes has no future replayer — nothing
after the close runs live replays, and this walk's replays count toward
promotion and increment `REPLAYS` like `build-slice` §5's. So each one takes
exactly one ending, in writing: **promote** it now (a promotion exemption
`live, <reason>` is priced against future hand-replays, and with no
successor there are none — the exemption expires with the effort), **move**
it to the successor effort with the ticket that owns its path, or **retire**
it with the reason a decision, not a shrug. A closed effort keeps no replay
obligations.

## The split-off ledger

Not a fifth walk and not blocking on its own — but it writes into the close
block like the walks do. Enumerate this effort's split ends with
`grep -rn 'split off:' docs/issues/<effort>/` — shape and spec both — and
run `ls` on each `docs/issues/` address, recording every address with its
result. A missing folder is a stale address read as fact by every session
since the spec carried it: rewrite the bullet to where the effort actually
lives, in this edit, or hand it to `hold-the-line` as a finding — those are
the two endings, and a shrug is neither.

Then run
`grep -rln '^\*\*Discovered while shaping:\*\* <effort>,' docs/issues/` — the
trailing comma keeps `export` from also matching `export-audit` — and check
each hit's `**Status:**` line: the still-`unshaped` hits are stubs this
effort minted that nobody picked up. Name them in the close block — not
settled and not blocking, just visible at the one moment someone decides
what happens next.

## When to close early

An effort at the ticket ceiling closes whether or not it feels finished.

Closing early is not failure. Move the unfinished tickets into a new effort
folder with its own spec and its own walking skeleton, and finish this one at
what is done. The successor's `spec.md` is written in the same edit, by
`write-spec` in synthesis mode: its input is this effort's spec plus the moved
tickets, not a new interview, and its exit criteria are the ones moved out
here, **keeping their `E<n>` numbers** — the moved tickets' `Serves exit
criterion` fields point at those numbers, and numbers are addresses here as
everywhere in this flow. An effort that cannot close is a program, and a
program has no end that anyone can see.

Walk 1 still runs, and it is the walk that makes an early close safe. Every
forward reference is redeemed, deleted, or moved **with both of its ends**. A
producer left behind in the closed effort while its reader moves on is how the
debt survives the close that was supposed to settle it.

The same applies when the shape of the work has changed enough that the spec no
longer describes it. Close, and write the spec that does.

## Paths are addresses too

The closed effort's folder stays where it is. `cut-slices` forbids renumbering
for exactly one reason: in-code comments and other tickets point at the number,
the pointers are not compiled, and nothing catches a stale one. A folder path is
the same kind of address. Moving it breaks the same pointers just as quietly,
and it does so at the one moment the effort that would have caught them stops
existing.

The `## Close, <date>` block is the status. No archive folder, no index, no
summary file — the four walks already wrote everything a reader needs, into the
file that reader opens anyway.

If a repo does archive its closed efforts, then an archive move has two ends
like every other move in this skill. Grep the whole repo for the old folder path
first, rewrite every hit in the same edit, and record the count in the close
block. A move that leaves one pointer behind is the defect this flow exists to
prevent, arriving just after the last gate that could have caught it.

## The next step

End your final message by naming it: the flow ends here. The next feature
starts in a **fresh session** with `/plumbline:shape <idea>` — and if the close
walks passed waiting stub shapes (`**Status:** unshaped`), list them as
candidates. A refused close ends with the debts that refused it, not with a
command.
