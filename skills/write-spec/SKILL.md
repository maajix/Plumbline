---
name: write-spec
description: Turns a shape into a spec organised around paths that run, not components that exist. Use after shape-idea, when writing a spec or PRD, when an existing spec needs checking before tickets are cut from it, or whenever the user asks for a spec. A component-shaped spec is what produces component-shaped tickets, so this runs before cut-slices.
user-invocable: false
---

# Write the spec

A spec is read once by a human and then repeatedly by whoever cuts the tickets.
Its **shape decides the tickets' shape**. A spec organised by component yields
component tickets, however loudly the ticket skill says "cut vertically".

So organise it by **path**: a thing goes in one end and something observable
comes out the other.

Input is `shape.md`. Do not re-interview — synthesise what is already there,
and read the current source of anything the feature touches. One exception:
a successor effort's spec takes the closing effort's spec plus the moved
tickets as its input instead — `close-effort` says when.

A `shape.md` carrying `**Status:** unshaped` is a stub shape, not spec
input — it never had an interview. Run `shape-idea` on it first.

## Lead with the paths

The first and longest section is a numbered list of paths. Each is one
sentence, in the present tense, naming the whole crossing:

```
1. An operator uploads a domain list, and each domain appears in the queue
   with a status.
2. The scanner takes a queued domain, resolves it, and writes one observation
   the console can list.
3. An observation the operator dismisses stops appearing in the list and stays
   in the record.
```

A path names what enters, what leaves, and who sees it. If a line cannot name
its far end, it is a component, not a path — rewrite it or cut it.

Ordinary user stories tempt the opposite. *"As an operator I want a scanner
service"* is a component wearing a story's clothes. Write what crosses.

## Then the parts, each pointing at its paths

Only after the paths, name the parts the system needs. Every part carries the
path numbers it serves.

```
- Domain queue — serves paths 1, 2
- Resolver — serves path 2
- Observation store — serves paths 2, 3
- Console list view — serves paths 2, 3
```

A part serving no path is a part nobody asked for. Delete it or find its path.
A path with no parts is not yet understood.

This table is what makes the seams visible: two parts on one path share a seam,
and that seam is the thing a ticket will have to prove.

## The rest, and it is short

**Not this.** Carried over from the shape, plus anything the spec ruled out
while being written. Each line says why; a `split off:` line carries the
folder path in place of the why.

**Decided at the edges.** The concrete situations and their answers, from the
shape. Add any the spec had to settle.

**Open questions, answered.** The shape parked these as agent work. Answer them
here — read the source, run a prototype — and record the answer. They do not
become tickets: a research question produces nothing anything reads, so it can
carry no seam. What survives into the tickets is the answer, not the question.

Anything still open when the spec is done is a question the walking skeleton
will settle. Say which.

**Exit criteria.** Numbered `E1`, `E2`, … so a ticket can name the one it
serves. What must be true before this effort closes. Every criterion belongs to
this effort or names the effort that owns it — an unowned criterion makes the
effort permanently unclosable, because every ticket can be done and it still
reads as unfinished.

Every In scope bullet in the shape ending `— must hold before close` becomes
an `E<n>` here, quoting the bullet's words so the pairing is greppable, and
the link is counted, not trusted:
`grep -c '^- .*— must hold before close$' docs/issues/<effort>/shape.md`
prints the number of tagged In scope bullets, and each one has an `E<n>`
quoting it. That tag is the shape's only way to name an exit criterion
before a spec exists — a line the shape wrote that this section did not read
would be the same defect the Load section below exists for. A successor spec
written in synthesis mode has no `shape.md` and no count: the moved `E<n>`
numbers are the whole check there.

Numbering matters: `cut-slices` gives each ticket a `Serves exit criterion`
field, and an exit criterion no ticket names is work nobody is doing.

**Verify command.** A section with its own heading — `## Verify command` — so
the bar can find it without guessing. Left blank here and filled in by the
session that builds the walking skeleton, because that session is the first to
meet the real toolchain (`cut-slices` Rule 1). One line: the command that runs
this effort's tests from a clean checkout, in a form that **prints the name of
each test it ran** (`pytest -v`, not `-q`) — the standing bar reads a named
test in that output on every ticket, so a spec without it hands every later
ticket a bar line it can only assert.

**Load.** The volumes and rates from the shape, carried forward as numbers with
units: how many, how often, how big, how old. Then name, for each, what in the
system has to survive it.

This section exists because the shape's own answer got lost. In testing,
`shape.md` recorded "peak ~20 run-reports per second", nothing downstream ever
read it again, and the code shipped a single shared database connection that
failed 20 out of 20 times at exactly that load. In this flow's own words:
`shape.md` wrote a number, read by nobody.

So this section has a named reader: `cut-slices` makes a ticket on a path with
a Load figure quote that figure in its `## Why` block, and the standing bar's
live-run line asks whether the run faced it. A Load section nothing downstream
reads would be the same defect, moved one file to the right.

## Two rules about content

**No file paths, no code.** They go stale between writing and building, and a
stale path in a spec is read as fact. Name types and behaviours; let the
builder find the file.

The verify command is the first of two exceptions, and it is exempt for the
same reason the rule exists: a stale path is read as fact, while a stale
command fails the moment someone runs it. It earns its place by being run, not by being read.

`docs/issues/` addresses carried from the shape's `split off:` bullets are
the second: they are the flow's own bookkeeping, and `close-effort`'s
split-off ledger runs `ls` over every one — a stale address is rewritten
there or handed to `hold-the-line` as a finding, never left standing.

**Say what is true now.** Where the spec describes existing behaviour, read the
current source and say what it actually does. A spec that describes the code as
the author remembers it is the most expensive kind of wrong.

## Before handing it over

Run `cold-read` over the finished spec. Then answer, in writing:

> Can every path in section one be cut into tickets that each leave something
> running?

A path that cannot is a path that is too big. Split it in the spec, where it is
one line of work, rather than in the tickets, where it is ten.
