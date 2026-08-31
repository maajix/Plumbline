---
name: cold-read
description: Cold-reads an artifact before calling it ready. Use before handing a plan, spec, ticket set, playbook or migration to another session, after patching review findings, and as the reading mode for every review pass in this flow.
---

# Cold read

Authoring and reviewing in one pass does not work. Editing section by section is
exactly what makes a contradiction between two sections invisible: you see the
paragraph you are changing, never the one three pages up that now disagrees with
it.

A **cold read** is one pass over the finished artifact, whole, top to bottom, as
if you had never seen it — no memory of what a paragraph was *meant* to say,
only what it says.

For whether a constraint is real use `price-the-wall`. For prose mechanics use
`writing-for-agents` if it is installed; it is not part of this plugin. This
skill asks one question: **is the finished thing internally consistent and true
right now.**

## This is a read, not a repair

State the mode before starting, and hold it: a cold read **reports**. Patching
mid-pass is how the pass ends early — attention moves to the fix and the rest of
the document goes unread. Finish the read, deliver the findings, repair on
request.

Other agents' summaries, ticket text and code comments are **leads, not
evidence**. Current source, current artifacts and commands that run are evidence.

## Fresh snapshot

Read the whole artifact **before** checking anything; a reader who verifies as it
goes never reaches the section that contradicts section two. Then read the
current source of every place it names, and note the artifact's identity
(timestamp, size, line count).

If the artifact changes during the pass: **discard every line-numbered finding**,
re-read it whole, and start again. Stale line numbers in a report are worse than
no report — they send the next reader to the wrong place.

## Turn each claim into an invariant

The core move. A claim is prose; an invariant is a command with an expected
answer. Write the **evidence**, the **counter-check** that would falsify it, and
the **acceptance** you would run.

| Claim | Invariant |
|---|---|
| "the tool is available" / "X exists, so this is free" | walk the exposure chain below and find the hop that is not wired |
| "missing and empty are different" | the distinction survives **every** caller and every transport boundary, not the one the report named |
| "the gate catches 31 cases" | run the gate's predicate over the whole corpus and count 31 |
| "the validator accepts our output" | everything the emitter currently produces is the validator's positive corpus, and none of it is rejected |
| "all fields are preserved" | union of keys over **all** records — the first record is a sample, not a schema |

A claim with no counter-check has not been checked.

## The exposure chain

A capability that exists is not a capability that is reachable. A fix lands at
one hop; it is *done* at all of them.

- Authority: **constant → contract → group → role membership → what the server
  serves → handler → dispatch → backend function → state change → response.**
- Data: **producer → transport → persistence → reader → gate.**

Check the fix at every hop, and at **every caller** of the shared function, not
the one the report named. The classic miss is a membership list at a hop nobody
opened, still naming the old group.

## Six hunts

Each names what settles it. A hunt with no command run is a hunt not done.

1. **Unmeasured number** — a count, a field list, "N distinct", "all X are Y".
   Settle over the whole corpus, never a sample.
2. **Unopened citation** — a `file:line`, or a cited standard, offered as
   evidence. Open it and ask whether it supports *this* claim or merely sits near
   the subject. A correct line number under a wrong inference reads as proof, and
   a rule enforced hard that the standard calls optional is a defect in the same
   direction as a missing rule.
3. **Half a round trip** — a claim about an interface checked on one side.
   Auto-added headers, defaulted lengths and framing added by a client library
   live on the side nobody read.
4. **One hop wired** — see the exposure chain. Patched artifacts fail here most.
5. **Sections that disagree** — a decision taken in one place and restated in
   another. Grep the artifact for its own key numbers and names, and compare the
   hits to each other.
6. **Blanket rule over a distribution** — one fix asserted for N cases. Measure
   the spread first; "replace every A with B" is wrong the moment some need C.

## Reporting

One line per finding: what is wrong, the evidence that settles it, which hunt it
is. Rank by whether it would produce wrong work if executed.

Say plainly which hunts you ran and which you could not, and why. A cold read
that reports nothing because it checked nothing is worse than none — it certifies.

**Done** when every claim a reader would act on has been settled by a command or
a read in this pass, and the report carries both counts: **"M claims found, N
unsettled."** M is the guard on the read itself — five claims found in a
forty-page plan is an under-enumeration, visible in the number. Ready is a state
those two numbers decide, not a feeling at the end of a long edit.

## In this flow

Findings from a cold read are findings like any other: each gets a severity
(`blocker`, `required`, `nit`) and goes to `hold-the-line` for exactly one
verdict. The read reports; it does not open tickets. Before tickets exist —
the spec and plan reads at gates 2 and 3 — there is nothing for a verdict to
land on: those findings are worked into the artifact directly, after the full
pass, and `hold-the-line` begins once a ticket can carry a verdict.
