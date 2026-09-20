---
name: close-effort
description: Closes an effort by settling every debt it opened. Use when an effort's tickets look done, when deciding whether to split an effort that has grown, or when the user asks whether a feature is finished. Walks the forward references, the exit criteria and the ticket statuses so an effort can end rather than drift.
user-invocable: false
---

# Close the effort

Nothing else in this flow owns the effort as a whole, and an effort no step ever
ends is how one reaches 165 tickets.

An effort closes when every debt it opened is settled. Debts, not tickets — the
count going to zero is not the same as the work being finished.

## Which effort

With no effort named, it is the one under `docs/issues/` whose `spec.md` has no
`## Close,` block — the comma matters: `## Close refused,` records a refusal and
leaves the effort open. If several qualify, list them and ask which.

Read `${CLAUDE_PLUGIN_ROOT}/references/ticket-lifecycle.md` for identity,
status preservation and separate staging/commit calls.

## The four walks

Each produces a written answer in the spec, under `## Close, <date>`. An
unanswered walk means the effort is not closed.

A walk that **refuses** — a ticket not yet `resolved` or `declined` that
cannot move, an unredeemable reference — is also written down: `## Close refused, <date>`, naming the
walk and what blocked it. The comma in `## Close,` is what `/close`'s
detection greps for, so a refusal record does not make the effort read as
closed. Do not append `## Close,` until every walk has passed; use a refusal block
while work remains. Either record ends in a commit: subject `CLOSE: <what closed, or
why refused>`, holding the close block, any moved tickets and the successor
spec — and carrying no `(ticket <ID>)` suffix, which belongs to build commits.
An uncommitted close is swept into the next diff and read as its work.

### 1. Forward references

Run `grep -rn 'ticket [0-9]' docs/issues/<effort>/` and read every
`CONSUMED BY`, `CONSUMES` and `deferred to` hit. **Only hits in a seam-field
head are debts**; hits inside dated `##` blocks are history and stay as they
are. Most debt lines should already be gone — `build-slice` §5 redeems each one
in the session that lands NN. What is left is what nobody paid.

Each remaining line takes exactly one of three endings, and the ending is
written down:

- **Redeemed.** NN landed; rewrite the line into the real citation, symbol and
  literal, and grep the literal inside that symbol to prove it.
- **Deleted.** Nothing will read the value. Route the deletion through
  hold-the-line, build and review first. Until that repair lands, record a
  refused close; the close commit itself never deletes production code.
- **Moved, both ends together.** The producing ticket *and* NN both go to the
  successor effort. Moving only one end is the defect this whole flow exists to
  prevent, arriving exactly on schedule.

An unread forward reference never becomes a note in the next effort's spec. A
note is not an end.

### 2. Exit criteria

Every `E<n>` in the spec. Each is either met, or moved out into a named
successor effort in the same edit.

Check it from the tickets: each names the criterion it serves. A criterion no
ticket names is work nobody did. Then check the set against the shape's tag
(`shape-idea` defines it):
`grep -c '^- .*— must hold before close$' docs/issues/<effort>/shape.md`
prints the number of tagged In scope bullets, and each has its `E<n>` — met
here or moved out. A successor effort built in synthesis mode has no
`shape.md` and no count: the moved `E<n>` numbers are the check.

### 3. Ticket statuses

Every ticket is `resolved` or `declined`. Anything `open`, `claimed`, or
`blocked — needs decision` is finished through build/review or moved into the
successor, preserving its ID, number, status and review history. Do not move an
uncommitted executable repair as part of a close commit: finish/review that work
first or refuse close and leave its Handoff in place.

Also run `grep -rn '— verdict pending' docs/issues/<effort>/` and read each
hit. An entry line — `- [axis] **…** — verdict pending` — is a review whose
verdicts never came in, on a ticket that therefore never legally became
`resolved`; a hit quoting the marker inside a paste is history, and a cycle
line says `undecided` and cannot match. There must be no entry-line hit.

Before moving, walk all active `Blocked by`, `CONSUMED BY`, `CONSUMES` and
`deferred to` references (ticked deferrals included). Move both ends of every
unpaid seam debt and every unfinished dependency together, repeating until
there are no dangling references. Preserve historical blocks.
For a Blocked by dependency that stays behind and is resolved or declined,
verify that status, remove that local dependency, and record its stable ID and
outcome in the successor handover. A fulfilled seam uses its real source
citation. Check IDs and local numbers for collisions before any move; ask for a
different successor folder if needed, never overwrite or renumber.

### 4. The whole path, once

Run the feature end to end, the way an operator would, using every block in
`docs/issues/<effort>/live-inputs.md` whose `STATUS` begins with `live` —
the `live, <reason>` blocks included; their reason exempts them from
promotion, not from this walk. Read the far end.

Not the test suite — the feature.

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
it with the reason a decision, not a shrug. If promotion needs a new test,
route it through build and review and refuse close until it lands. A closed
effort keeps no replay obligations; only checked records ride the close commit.

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
`grep -rl '^\*\*Discovered while shaping:\*\* <effort>,' docs/issues/` — the
trailing comma keeps `export` from also matching `export-audit` — and check
each hit's `**Status:**` line: the still-`unshaped` hits are stubs this
effort minted that nobody picked up. Name them in the close block — not
settled and not blocking, just visible at the one moment someone decides
what happens next.

## When to close early

An effort at the ticket ceiling closes whether or not it feels finished.

Move unfinished tickets into a new effort folder and write its spec in the
same close operation. write-spec uses the old spec and moved tickets; moved
exit criteria retain their E numbers. Existing files are never overwritten.

The successor normally inherits the existing end-to-end path. Run that path
and its verify command, then record `## Handover` in the successor spec:
the path, command, decisive output, source effort and IDs of moved tickets.
Copy the verified command into its `## Verify command`. If both pass for the
successor's path, no new skeleton is required and the ordinary frontier applies.

If the successor needs a different path, record `needs skeleton` in Handover;
`/slice <successor>` adds the minimal skeleton and makes every unfinished
inherited ticket depend on it. Already claimed work waits too; selection only
considers tickets whose dependencies are satisfied. A failed check on a path
that should already work is a finding, not permission to certify the handover.

Walk 1 still runs, and it is what makes an early close safe: a producer left
behind while its reader moves on is how the debt survives the close that was
supposed to settle it.

The same applies when the shape of the work has changed enough that the spec no
longer describes it. Close, and write the spec that does.

## Paths are addresses too

The closed effort's folder stays where it is. A folder path is an address like a
ticket number (`cut-slices` "Numbers are addresses"): moving it breaks the same
uncompiled pointers, at the one moment the effort that would have caught them
stops existing.

The `## Close, <date>` block is the status. No archive folder, no index, no
summary file — the four walks already wrote everything a reader needs.

If a repo does archive its closed efforts, then an archive move has two ends
like every other move in this skill. Grep the whole repo for the old folder path
first, rewrite every hit in the same edit, and record the count in the close
block. A move that leaves one pointer behind is the defect this flow exists to
prevent, arriving just after the last gate that could have caught it.

## The next step

End your final message by naming it: the flow ends here. The next feature
starts in a **fresh session** with `/plumbline:shape <idea>` — and if the close
walks passed waiting stub shapes (`**Status:** unshaped`), list them as
candidates. For a successor, instead name `/plumbline:build <ID>` for its inherited
frontier, or `/plumbline:slice <successor>` if Handover says needs skeleton.
A refused close names its debts and the build/review step that settles them.
