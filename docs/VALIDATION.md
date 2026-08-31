# VALIDATION — adversarial review of plumbline

> **Status note, 2026-08-30 — read this first.** Everything below is pinned to
> `cd251dc`. B1, B2 and B3 were fixed in `0b8b0db` (the index marks them so),
> and two later waves — the `0b8b0db` doc pass and the 0.3.0 wave that worked
> an independent multi-agent review's findings — closed most SHOULD-FIX items
> too, S8 and S9 among them. Line numbers and quotes throughout are as of
> `cd251dc` and no longer match the tree. Read every finding as "true at
> `cd251dc`" until you have checked it yourself. Section 6's core verdict —
> the flow itself has never been executed as a chain — held through 0.3.0 and
> **fell on 2026-08-30**: two real runs (a full chain and a session-boundary
> stress run, final Nachträge below) executed the 0.3.0/0.3.1 text in a toy
> repo. What remains true: each fix wave, 0.3.1's included, is itself not
> re-run after being written — the runs test the text they ran, not the
> patches they caused. The finding index below keeps its `cd251dc` per-row
> state deliberately — this file is an audit record, not a live tracker;
> every S/Q/N row still marked open is closed in the current tree, per the
> Nachträge.

Pinned to commit `cd251dc` (clean tree, 2026-08-29 18:56 +0200). This matters
more than usual: **the repo received three commits while this validation was
running** (`5db15be`, `cd251dc`, plus late edits folded into `5db15be`), and
both chain-test reports (kept outside the repo) grew ~145 lines
each mid-pass. Findings against superseded text were discarded and re-derived
against the final state, per the flow's own cold-read rule. Two consequences
are themselves findings:

- **Every patch wave is execution-untested.** Both chain tests ran against the
  pre-`22afbed` skills. Nothing at HEAD — not the eight original patches, not
  the second wave (six verdicts, Rule 3b, close-effort, symbol citations), not
  the doc fixes — has ever been run by an agent. (Section 6.)
- The author patched an artifact while it was under a declared external review.
  `build-slice` now teaches "Finish your edits to the ticket file before any
  cold read opens on it" (skills/build-slice/SKILL.md:126). The plugin's own
  release process violated its own rule during this pass. [opinion]

---

## 1. Did the patches actually land?

### 1a. Rule 1 vs Rule 4 — LANDED, unambiguous everywhere

`skills/cut-slices/SKILL.md:39-42`:

> **Rule 1 outranks Rule 4.** The skeleton crosses as many files and seams as
> the path needs, and the size ceiling does not apply to it. Nothing else in an
> effort gets that exemption.

and cut-slices/SKILL.md:159-160:

> Ceiling: **one seam, three production files, one migration.** Two seams means
> two tickets. Ticket 01 is exempt (Rule 1).

The precedence is stated in both directions inside the only file that states a
per-ticket size rule at all; README and WORKFLOW list only the effort-level
caps, so there is no second home for the ambiguity. Bonus: "about three files"
became "three production files" plus "Three is a number, not a feeling"
(cut-slices:162), closing both test reports' fuzziness finding.

NIT [opinion]: review-pass/SKILL.md:54 ("~1000 changed lines too large ...
split it" and :57 "hand it to `cut-slices`") carries no skeleton exemption. A
fat ticket 01 diff gets told to split by a skill whose target says it cannot be
split. Unlikely in practice (skeletons are thin); one clause would close it.

### 1b. `CONSUMED BY: ticket NN` vs `NOBODY` — LANDED at ticket level; the contradiction moved to effort close

All four places now agree. Quoted:

cut-slices/SKILL.md:171-178 (Rule 5):

> `CONSUMED BY: ticket NN` is allowed, and the walking skeleton depends on it
> [...] - NN is a real, open ticket in this effort.
> - **The effort cannot close while any forward reference is unread.** At
>   close, every `ticket NN` line is walked and must have become a real citation.

seam-check/SKILL.md:57-61, 65-66:

> **A named forward reference is not `NOBODY`.** [...] A walking skeleton is by
> definition built before anything real calls it; a rule that forbade that
> would block ticket 01 of every effort.
> - NN must be an open ticket in this effort. Check it.
> - The effort cannot close while the reference is unread. Carry it forward.

build-slice/SKILL.md:85-89:

> An unexplained `NOBODY` means the ticket is not done, regardless of green
> tests [...] A far end the ticket already named as `ticket NN`, `operator,
> via <cmd>`, or `out of repo` is not `NOBODY`. Record it and carry it to the
> effort's close.

references/standing-bar.md:13-15:

> `seam-check` reports no unexplained `NOBODY`. A far end recorded as
> `ticket NN`, `operator`, or `out of repo` satisfies this; a bare `NOBODY`
> does not.

No file forbids what another permits at ticket level. Ticket 01 can close.
**But the permission is funded by an effort-close walk, and at effort close the
patched rules now contradict each other — see BLOCKING B2.**

---

## 2. New contradictions introduced by the patches

### BLOCKING

**B1 — review-pass and build-slice hand findings to a verdict set that no
longer exists as stated; review-pass contradicts itself four lines apart.**

hold-the-line was rebuilt around six verdicts with a severity gate,
hold-the-line/SKILL.md:25-33:

> | `blocker` | shipped code is wrong, unsafe, or loses data | **NOW** or **REOPEN** |
> [...] A blocker never becomes a deferred criterion.

review-pass/SKILL.md:73-74 knows this:

> The label is not decoration. `hold-the-line` reads it: a `blocker` cannot
> become a deferred criterion, and a `nit` is fixed now or declined.

and then review-pass/SKILL.md:79-80 says:

> Hand the findings to `hold-the-line`. Each comes back as **criterion**,
> **ticket**, or **decline**, written into the ticket that produced them.

A blocker finding can come back as none of those three. Same stale set in
build-slice/SKILL.md:72-73 ("Run `hold-the-line` and take its verdict:
criterion, ticket, or decline") and, incompletely, README.md:28
("jetzt | Kriterium | Ticket | Ablehnung" — four of six; REOPEN and ALREADY
OWNED missing) and the WORKFLOW gate table. An agent following review-pass or
build-slice literally will never use NOW, REOPEN, or ALREADY OWNED — the three
verdicts wave 2 was added to create, fixing test B's "verdict taxonomy does
not survive contact". The patch fixed the taxonomy in one file and left three
callers speaking the old one.

**B2 — Effort close: three files say an unread forward reference makes close
impossible; close-effort and hold-the-line command closing anyway.**

cut-slices/SKILL.md:177: "**The effort cannot close while any forward
reference is unread.**" seam-check/SKILL.md:66 repeats it.
standing-bar.md:29-31:

> Every `CONSUMED BY: ticket NN` forward reference in the effort has become a
> real citation. An unread forward reference is the defect this flow exists to
> prevent, arriving on schedule.

close-effort/SKILL.md:53-56:

> An effort at the ticket ceiling closes whether or not it feels finished.
> Closing early is not failure. Move the open tickets into a new effort folder
> with its own spec and its own walking skeleton [...]

and close-effort/SKILL.md:25-27 adds a third instruction neither Rule 5 nor
the bar acknowledges:

> An unread forward reference **is** the defect this whole flow exists to
> prevent [...] It does not get carried into the next effort as a note. It
> gets read, or the value that nothing reads gets deleted.

Take the concrete case both chain tests produced: skeleton wrote a value,
`CONSUMED BY: ticket 07`, ticket 07 still open when the ceiling (or the user)
forces close. cut-slices/standing-bar: the effort cannot close. close-effort
and hold-the-line/SKILL.md:115-117 ("that is the signal to **close this effort
and open the next one**"): it must close, and 07 moves out. close-effort's own
delete branch then instructs deleting the skeleton's stored value that the
moved ticket 07 still plans to read. Every path violates at least one rule
stated as hard. The ticket-level contradiction from the chain tests did not
disappear; it was relocated to the one gate no test has ever run.

**B3 — cut-slices contradicts its own ticket template, twice, on the field the
whole plugin centers on.**

cut-slices/SKILL.md:77 (form table): `<file:module::symbol>`, and :82:

> **Cite the symbol, not the line.** `cli.py::cmd_queue`, not `cli.py:43`.
> [...] A symbol name survives an edit; a line number does not.

cut-slices/SKILL.md:203 (the template agents copy):

> **CONSUMED BY:** <file:line | ticket NN | operator, via <cmd> | <name>, out of repo>

The template mandates the exact pointer form the rule 120 lines earlier calls
a defect (and which test B measured going stale: "ticket 02 inserted 8 lines
above them"). Both chain tests followed the template over the prose. Second
clash in the same field: cut-slices:50 says `CONSUMED BY <one of the four
forms below>` and :73 titles the table "CONSUMED BY takes one of four forms",
while :69 mandates a fifth value the table and template do not contain:

> When `PRODUCES` is `nothing`, write `CONSUMED BY: nothing` and move on.

An agent cannot fill the field satisfying both the rule and the template.

### SHOULD-FIX

**S1 — "smallest input" was fixed in seam-check and left standing in two
mirrors.** seam-check/SKILL.md:108-109: "**Use the smallest input that reaches
the case this ticket is about** — not the smallest input." vs
build-slice/SKILL.md:91: "Then run the path once for real, smallest input, and
read the far end." and standing-bar.md:18: "The path ran once for real,
smallest input". The wave-2 patch (motivated by test A's QTYPE bug passing its
live run) contradicts the two files that operationalize the same run.

**S2 — seam-check contradicts itself on line numbers.** seam-check:31-32:
"**Record the symbol**, not the line number. Line numbers go stale" vs its own
record format at :48 (`READ BY <file:line> | ...`) and finding format at :128
(`<file:line>: WROTE <name> ...`).

**S3 — the patched CONSUMED BY forms were never mirrored to the WRITTEN BY
side.** seam-check:49: `READ <name> WRITTEN BY <file:line> | NOBODY`. No
`ticket NN`, `operator`, or `out of repo` form, although seam-check's own
cross-repo section (:78-82) exists and test B's actual pass produced
`READ RunReport.<four counts> WRITTEN BY NOBODY` for an out-of-repo writer.
The asymmetry re-creates the pre-patch bind on the read side.

**S4 — "open" is still used loosely after the five-value status patch.** The
vocabulary is consistent where declared (cut-slices:224-225, build-slice:22-24,
hold-the-line:137-139, close-effort:39). But cut-slices:78 and :176 ("NN is a
real, open ticket"), seam-check:65 ("NN must be an open ticket ... Check it."),
hold-the-line:83 ("Something already open cannot finish") and
commands/build.md:6-7 ("open, unclaimed") all use "open" where they mean "not
resolved or declined" — the exact `claimed`-vs-`open` confusion patch 7 fixed
inside hold-the-line's criterion rule and nowhere else. Sharpest consequence:
hold-the-line:70 (REOPEN) sets a ticket "back to `claimed`", and
commands/build.md's frontier picks only "open, unclaimed" tickets — **a
reopened ticket is invisible to `/build` forever.**

**S5 — the new severity gate has no input from two of its three feeders.**
hold-the-line:22-23: "A finding arrives with a severity from `review-pass`:
`blocker`, `required`, `nit`. Severity is an input here, not decoration." But
build-slice step 4 discoveries and seam-check findings (seam-check:131-133)
are also sent to hold-the-line and neither skill assigns severities. The
severity table cannot run for them and no rule says what to do. Half a seam,
shipped by the patch that was fixing half-seams.

**S6 — obligations recorded into artifacts that do not exist.**
standing-bar.md:16-17: forward references are "carried into the effort's close
checklist" — no skill creates a close checklist; close-effort writes
"## Close, <date>" into the spec and re-derives references by grepping.
seam-check:117: "Keep the inputs in a file the next ticket reuses" and
close-effort:45-46 ("with the inputs the live runs accumulated") both depend
on an input file with no name, location, or owner.

**S7 — PRODUCES kinds exist only in cut-slices.** seam-check's method (grep
"each thing the change writes") has no way to check a `contract` kind, which
by definition writes nothing greppable; build-slice:26-29's backfill
instruction predates kinds and does not mention them. The most dangerous kind
the patch introduced is invisible to the skill that proves seams.

**S8 — no rule converts a forward reference into a citation when it is
redeemed.** When ticket NN finally reads the value, nothing in build-slice
tells that session to update the earlier ticket's `CONSUMED BY: ticket NN`
line. cut-slices:178 demands that at close every line "must have become a real
citation" — as written, every one of those lines still literally reads
`ticket NN` at close, and walk 1 must re-derive the entire effort by hand.

**S9 — successor-effort mechanics are self-contradictory.**
close-effort:39-41: open tickets move "to the successor effort by number";
close-effort:55-56: the successor gets "its own walking skeleton"; cut-slices
Rule 1: "The first ticket of every effort" is that skeleton, and tickets are
numbered from 01 (commands/slice.md:7). A successor inheriting tickets 07 and
12 plus a mandatory new 01 has an undefined ordering, and "Never renumber"
(cut-slices:229) makes the collision permanent.

**S10 — doc summaries lag the severity rule.** README.md:45-47 and
docs/WORKFLOW.md ("Ein Finding wird ein Kriterium, kein Ticket. Neues Ticket
nur, wenn ...") still state the pre-severity rule with no NOW/REOPEN, i.e. a
blocker becomes a criterion — precisely what hold-the-line:31 now forbids.

### Answers to the direct questions

- Five-value status set: **consistent** in all four declaring files. One end
  state has no status: standing-bar:27's "moved out to a named successor
  effort" is recorded nowhere in the ticket file.
- References to forms/statuses that no longer exist: **yes** — the
  three-verdict set (B1), and the template's bare `file:line` (B3). No stale
  status values found.

---

## 3. Unreachable or unenforceable rules

Test applied: what happens if an agent ignores it? Improved by wave 2:
review-pass:91 now writes `Review cycle 2 of 3` into the ticket, hold-the-line
counts criteria per ticket, exit criteria are traceable end to end
(write-spec E-numbers -> template `Serves exit criterion` -> close-effort walk
2 -> standing-bar:32). Still decorative:

1. **build-slice:51-52 "Tick each acceptance criterion ... as it becomes
   true"** together with :118 "One commit per ticket where possible". Test A
   proved a batch tick and an honest tick produce byte-identical commits, so
   standing-bar:10-11 ("each was ticked when it became true") asks reviewers
   to verify the unverifiable. Ignoring it is undetectable. Unpatched through
   three waves. Drop one of the two rules or drop the bar line.
2. **cut-slices:156-157 "one session takes it from red test to green test to
   review without compacting context"** — no detection, no record of sessions
   or compaction; hold-the-line's criteria count (:108-111, explicitly "Rule 4
   has no enforcement point after cutting, so this is it") rescues the size
   half, not the session half.
3. **shape-idea:82-84 the predict-three-answers stop test and :90 "Three
   rounds"** — self-graded; `interview.md` now exists (:100) but nothing
   requires the three predictions or the round count to be written into it.
   An agent that says "yes, I could have predicted" cannot be caught. Both
   test reports flagged this; unpatched.
4. **standing-bar.md:21 "The diff contains only what this ticket asked for"**
   — the only bar line with no runnable check attached; test B ticked it and
   shipped 11 `.pyc` files. One clause ("run `git diff --stat` and compare
   against the files the ticket names") would arm it.
5. **cut-slices:88 "The citation must be true at the moment this ticket
   lands"** — nothing re-reads ticket seam lines against source: seam-check
   greps code, not ticket claims; review-pass's Ticket axis quotes criteria,
   not the seam fields. Enforcement is the author's honesty, which is how
   "indirectly via the reason text" passed in test B.
6. **seam-check:65 "Check it"** (NN is open) — no record of the check is
   demanded anywhere, so it cannot be reviewed.
7. [opinion] **Rule 6's 25-ticket ceiling** is enforceable but inert — both
   tests measured it doing zero work at 7-8 tickets. DIAGNOSIS.md honestly
   files it as an alarm, not a tool. Fine as is.

*(Note, 2026-08-30, after the session-boundary pass. `standing-bar.md`'s
"Per ticket" is now two blocks — **checked by machine**, each line carrying its
command inline, and **checked by reading**, each line marked `Judgement` — with
a closing rule that a line carrying neither is decoration. Against the seven
above: item 1's countable half is now `grep -c '^- \[ \]' <ticket>` = 0, and the
unverifiable "when it became true" half is off the bar rather than asked of
reviewers — the ordering rule stays in build-slice, where it is advice, not a
gate. Item 4 is closed; the `git diff --stat` clause landed. Item 5's redeem
half gains a command (`grep 'CONSUMED BY: ticket <NN>'` over the effort folder);
its "citation is true in source" half stays review-pass's Ticket axis, i.e.
judgement, and is now labelled as such. Item 2's session half is handled rather
than enforced: build-slice writes a `## Handoff` block, commands/build.md makes
every `claimed` ticket frontier ahead of every `open` one, and review-pass
writes findings into the ticket as `— verdict pending` before the verdicts.
That is a way to survive the boundary, not a measurement of it, and
docs/WORKFLOW.md says so explicitly. Items 3, 6 and 7 were untouched at `0b8b0db`; the 0.3.0 wave then moved the
discrimination check (item 3) into build-slice §2 with `Red:`/`Mutated:` lines
in the Resolution. This note
describes text: section 6's verdict is unchanged, and the eight skill, command
and reference files this pass edited enlarge the never-executed surface rather
than shrink it. The bar's new
commands in particular have been read, not run — the verify command they lean
on is written by the session that builds ticket 01, and no such session has
happened.)*

---

## 4. The known-unfixed weakness: the seam field stops discriminating

Confirmed still open. DIAGNOSIS.md:295-297 files it as "Ungeloest", and the
wave-2 change does not touch it: test A's degenerate citations
(`cli.py::cmd_queue` on tickets 01, 02, 03 and 05) were already
symbol-granular, so "Cite the symbol, not the line" changes nothing about
discrimination.

**It is fixable, cheaply: bind the citation to the value, not just the
reader.** Change the code form from `<file:module::symbol>` to

```
CONSUMED BY  <module::symbol>, reading <literal>
```

where `<literal>` is the greppable token PRODUCES introduced (column, key,
field, event string). Test A's degenerate set becomes discriminating again:

```
01  cli.py::cmd_queue, reading observation.status
02  cli.py::cmd_queue, reading observation.target
03  cli.py::cmd_queue, reading observation.confidence
05  cli.py::cmd_queue, reading verdict.hostname (anti-join)
```

Three things fall out for free: seam-check's step 1 ("grep the literal name")
gets its target handed to it instead of re-deriving it; close-effort walk 1
("a symbol that reads the value") becomes mechanically checkable (grep literal
inside symbol); and a later ticket that changes what the same reader consumes
is forced to write a visibly different line. Residual truth worth documenting
either way: since wave 2, the *test* is the discriminator — cut-slices:112-114
("Prove the test discriminates. Change the reader's literal ... and watch the
test go red") already forces a per-ticket, value-specific proof. If the field
is left as an address only, say so in Rule 2, so nobody expects the field to
catch what the mutation check catches.

---

## 5. Skill-authoring quality

Checked against the criteria given (body length, description, negation, no-op
instructions, reference depth, terminology):

- **Body under 500 lines:** pass, all eight (max cut-slices at 241).
- **Description under 1024 chars, third person, triggers early:** pass, all
  eight (285-385 chars, verb-first third person, "Use when" trigger lists).
  NIT: hold-the-line's description names four of its six verdicts (no ALREADY
  OWNED, no TICKET) — skills/hold-the-line/SKILL.md:3.
- **Negation-heavy steering:** no material violation. 3-9 negative imperatives
  per file, but nearly every one is paired with the replacement action ("Never
  renumber. Split `14` into `14a`, `14b`", "Report, do not repair. Findings
  first ... repairs on request"). [opinion]
- **No-op instructions:** build-slice:48-49 "No speculative flexibility, no
  configurability nobody asked for, no error handling for impossible cases"
  restates default agent behavior; also test B showed "impossible" reads wrong
  after you have measured the case ("'Impossible' needs to be 'unmeasured'"),
  which three waves have not picked up. NIT.
- **References one level deep:** pass on depth (standing-bar.md and
  borrowed-skills.md reference no further files). SHOULD-FIX on location: both
  live outside every skill directory and are addressed as
  `../../references/standing-bar.md` (build-slice:113, review-pass:42,
  cut-slices:235, write-spec:104, build-slice:61). Those paths resolve only
  against the skill file's own location, not the session's cwd in the target
  repo. Both chain tests worked because the agents read the plugin source tree
  directly; the installed-plugin path has never been exercised (see 6).
- **Consistent terminology:** three spellings of one form — `operator, via
  <command>` (cut-slices:79), `operator, via <cmd>` (cut-slices:203,
  build-slice:88), bare `operator` (seam-check:48, standing-bar:14). "open"
  used two ways (S4). Tickets live in folders named `issues/`
  (commands/slice.md:6). German docs and commands around English skills.
  commands/shape.md:6 still says "Write the result to
  `docs/issues/<feature-slug>/shape.md`" while shape-idea:98 now outputs two
  files (`interview.md`, `shape.md`). All NIT except the shape command, which
  an agent may follow over the skill.
- **Manifests:** marketplace.json:2 `$schema`
  `https://anthropic.com/claude-code/marketplace.schema.json` returns 404
  (verified live today, redirects to www.anthropic.com and dies); the commit
  claiming "manifests match the verified schema" (`5e2844b`) shipped a
  fabricated-looking URL. plugin.json's schemastore URL resolves (200).
  plugin.json version is still `0.1.0` across three behavior-changing
  commits. Both NIT.

---

## 6. The gap nobody has tested

**Everything at HEAD.** Both chain tests exercised the pre-`22afbed` text.
Since then: 8 committed patches, then wave 2 (PRODUCES kinds in anger, four
CONSUMED BY forms, six verdicts with severity, Rule 3b's double criterion,
symbol citations, `interview.md`, the Load section, E-numbering,
borrowed-skills substitutes, close-effort, `/review`, `/close`). Zero agent
runs. The two verdicts in section 1 are text-level only.

Most likely to break, concretely:

- **Effort close** (never run, and cannot run cleanly as written): B2's
  deadlock at the ceiling; S8's never-updated `ticket NN` lines forcing walk 1
  to re-derive the whole effort; the archive move
  (close-effort:65-67, into `docs/issues/.archive/<slug>/`) silently breaking
  every in-code comment and cross-ticket path that pointed at the old folder —
  the exact stale-pointer failure cut-slices:227-230 warns about for numbers.
  *(Closed after this pass: B2 in `0b8b0db`; the archive move is gone — the
  folder now stays in place and a path is treated as an address, like a number.
  S8 was closed in the same wave — `cut-slices` Rule 5 and `build-slice` §5
  carry the redeem rule; the grep pattern it leans on was corrected for the
  bold on-disk form in 0.3.0. The "never run" verdict stands.)*
- **Around ticket 15 of a real effort:** a later `PRODUCES changed:` ticket
  legitimately turns an earlier ticket's seam test red — cut-slices:122-124
  calls that "the design working", but fixing it requires editing the old
  assertion, which standing-bar:20 ("No test was skipped, deleted, or
  weakened") and lowering-move 2 flag as bar-lowering. hold-the-line owns the
  arbitration and no rule says the old test may be updated. Expect friction or
  quiet rule-breaking the first time a `changed` kind lands. Also: the first
  `14a`/`14b` split meets commands/build.md's "lowest-numbered" frontier sort,
  which is undefined over `14a`.
- **Second effort:** S9's numbering collision; ownership of moved-out exit
  criteria in a successor spec nobody has written; cross-effort
  `CONSUMED BY: ticket NN` lines whose NN now lives in another folder.
- Also never exercised: gate 1 against a real product owner (both tests
  self-interviewed); a non-greenfield repo (grep-based seam-check against
  legacy readers); two agents claiming concurrently (`Status: claimed` has no
  atomicity); the installed-plugin path (`claude plugin install`, command
  layer, `../../references/` resolution — see section 5).

---

## 7. Would I use it?

**Yes, for exactly one class of work, and only after B1-B3 are fixed and one
chain test has run at HEAD:** solo-agent, feature-shaped efforts that cross
three or more layers and end at an observable far end — greenfield or
brownfield services, CLIs, pipelines. There the evidence is real and beats
instinct: Rule 1 measurably changed decomposition in both tests ("Left to
habit I would have cut `01-set-up-the-sqlite-schema` ..."), and the seam test
caught the only genuine bug in either run across a ticket boundary that no
unit test would have seen. That is the defect class the 165-ticket diagnosis
measured, and the mechanics attack it directly rather than by exhortation.

Not for: cross-repo integration efforts (the worst defect in test B lived at
the repo boundary and was found by reading the spec, not by any seam rule —
the flow itself admits grep stops at the edge); research- or prototype-heavy
work (deliberately excluded from tickets now, correctly, but that means the
flow governs none of it); small fixes (the ceremony of kinds, forms, bar walks
and verdicts exceeds the work); and multi-agent teams (claiming, frontier
selection and review hand-off all assume one agent and one session at a time).

The honest caveat: the plugin is currently a fast-moving target whose newest
half is validated only by the static read above. Its own standing bar would
not let a ticket close in this state — "The seam test exists, was watched
failing, and now passes" has no equivalent here, because nothing has watched
the patched flow fail or pass. Run one full chain test at `cd251dc` before
trusting any of it.

---

## Finding index

| ID | Severity | One line |
|---|---|---|
| B1 | BLOCKING, fixed 0b8b0db | review-pass:79-80, build-slice:72-73 hand findings to a three-verdict set; hold-the-line has six and forbids blocker->criterion; review-pass:73-74 contradicts :79-80 |
| B2 | BLOCKING, fixed 0b8b0db | cut-slices:177, seam-check:66, standing-bar:29-31 forbid closing with unread forward refs; close-effort:25-27,53-56 and hold-the-line:115-117 command it |
| B3 | BLOCKING, fixed 0b8b0db | cut-slices template :203 mandates `file:line` its own rule :82 forbids; :69 mandates `CONSUMED BY: nothing` outside the "four forms" :50,:73 |
| S1 | SHOULD-FIX | seam-check:108-109 "not the smallest input" vs build-slice:91 and standing-bar:18 "smallest input" |
| S2 | SHOULD-FIX | seam-check:31 "record the symbol" vs its own `file:line` formats :48,:128 |
| S3 | SHOULD-FIX | WRITTEN BY side (seam-check:49) lacks `ticket NN`/`operator`/`out of repo` forms |
| S4 | SHOULD-FIX | "open" used loosely post-patch (cut-slices:78,:176; seam-check:65; hold-the-line:83; commands/build.md:7); REOPEN->`claimed` invisible to `/build` frontier |
| S5 | SHOULD-FIX | hold-the-line:22 requires severity; build-slice step 4 and seam-check findings carry none |
| S6 | SHOULD-FIX | "close checklist" (standing-bar:16-17) and the reusable live-input file (seam-check:117, close-effort:45-46) are artifacts no skill defines |
| S7 | SHOULD-FIX | PRODUCES kinds unknown to seam-check (no method for `contract`) and to build-slice's backfill step |
| S8 | SHOULD-FIX, closed by `0b8b0db`+0.3.0 | redeem rule now in cut-slices Rule 5 / build-slice §5; grep pattern fixed for the bold on-disk form |
| S9 | SHOULD-FIX, closed by 0.3.0 | skeleton decoupled from `01` at every call site; `/slice` numbers from the next free number |
| S10 | SHOULD-FIX | README:45-47 / WORKFLOW rule summaries omit the severity override (blocker never becomes criterion) |
| N1 | NIT | operator-form spelled three ways; commands/shape.md names one output file, shape-idea produces two; `issues/` folders hold "tickets"; German/English split |
| N2 | NIT | marketplace.json `$schema` 404s; plugin.json version unbumped at 0.1.0 |
| N3 | NIT | review-pass sizing table has no skeleton exemption [opinion]; build-slice:48-49 "impossible cases" should read "unmeasured"; hold-the-line description names 4 of 6 verdicts |
| Q3 | SHOULD-FIX | decorative rules: tick-as-true vs one-commit; session/compaction clause; predict-three-answers; bar's diff-scope line; citation-true-at-landing; "Check it" |

Sections with no findings: none claimed clean; the five-value status
vocabulary and the exit-criteria chain are the two patch areas that check out
end to end.

---

## Nachtrag, 2026-08-30 — die 0.3.0-Welle

Ein unabhängiges Multi-Agent-Review (sieben Leseachsen: chain-run, design,
consistency, executability, prose-for-agents, plugin-mechanics, docs-drift;
jedes Finding adversarial verifiziert) bestätigte 131 Befunde gegen den Stand
nach `0b8b0db`: 4 blocker, 66 required, 61 nit. Die Kernbefunde und ihre
Antworten in 0.3.0:

- **Der Lebenszyklus war gegen die Review verschoben.** `build-slice` §6
  setzte `resolved` vor der Review; `hold-the-line` verbot CRITERION auf
  `resolved` — beim letzten Ticket eines Efforts hatte ein `required`-Finding
  damit kein legales Verdikt, und jeder REOPEN erzeugte einen zweiten
  `## Resolution`-Block, an dem die Latte scheiterte. Antwort: das Ticket
  bleibt `claimed` durch Bau, Latte und Commit; `review-pass` schreibt
  `resolved`, wenn der Zyklus sauber schließt, und macht den Review-Commit.
- **Der zentrale Vorwärtsverweis-Grep war tot.** Auf der Platte heißt die
  Zeile `**CONSUMED BY:** ticket NN`; das Muster
  `'CONSUMED BY: ticket <NN>'` traf sie nie — die Latte druckte immer
  "nichts" und die Zeile galt als bestanden. Antwort: Muster, das durch die
  Fettmarker trifft, an allen drei Stellen (Latte, build-slice §5,
  close-effort Walk 1).
- **TICKET-Verdikt schrieb die `Blocked by`-Kante falsch herum** (Deadlock
  unter der Frontier-Regel). Antwort: die Kante sitzt auf dem wartenden
  Ticket.
- **Drei Aufrufe von `seam-check` je Ticket, ein REPLAYS-Zähler.** Antwort:
  genau ein Lauf (build-slice §5) zählt; `/prove` und die Naht-Achse lesen
  den Bericht unter `## Seam check` im Ticket.
- **Sechs relative `../../references/`-Pfade** funktionieren im installierten
  Plugin nicht verlässlich. Antwort: `${CLAUDE_PLUGIN_ROOT}/references/…`.
- **`/review` kollidiert mit dem eingebauten Befehl.** Antwort: der Befehl
  heißt `/review-pass`.
- Die drei geliehenen Skills (`cold-read`, `price-the-wall`,
  `structured-debugging`) sind jetzt gebündelt; `references/borrowed-skills.md`
  ist gelöscht, `coding-standards` aus den Docs entfernt (es rief nie etwas
  auf).

Der installierte Pfad (marketplace add + install) wurde in dieser Welle
erstmals real getestet; das Ergebnis steht im README unter "Stand".

## Nachtrag, 2026-08-30 — der erste echte Kettenlauf (0.3.1)

Nach der 0.3.0-Welle lief die Kette erstmals komplett real durch: Wegwerf-Repo,
Spielzeug-CLI (`watchlist`), Spec mit Exit-Kriterien und Load-Abschnitt, drei
Tickets nach Template, Ticket 01 und 02 vollständig durch build-slice §0–§8
(roter Test mit echter Assertion, Mutationsschritt, Nahtcheck mit
WROTE/READ-Protokoll, `live-inputs.md` mit REPLAYS-Inkrement und
`far end moved by 02`, alle Latten-Kommandos ausgeführt und gepastet,
Build-Commits mit `(ticket NN)`), je ein voller Review-Zyklus mit Verdikten
und Review-Commit bis `resolved`, und ein Close-Versuch, den die vier Walks
korrekt verweigerten, weil Ticket 03 offen stand.

Befund: kein Blocker; 15 von 18 Latten-Kommandos arbeiteten exakt wie
geschrieben, 3 nicht. Sechs Regel-Lücken, alle in 0.3.1 geschlossen:

- **Die Einlöse-Zeile der Latte kontaminierte sich selbst** — ihr eigener
  Paste und jedes Finding, das die Tokens zitiert, wurden zu Dauer-Treffern.
  Antwort: nur Treffer im Nahtfeld-Kopf eines Tickets sind Schulden; Treffer
  in datierten `##`-Blöcken sind Historie, an drei Stellen gleich formuliert
  (Latte, build-slice §5, close-effort Walk 1). Die Resolution listet
  hinterlassene Referenzen nur noch als Nummern.
- **Kein Commit-Zeitpunkt für Planungsartefakte.** Antwort: der Plan fährt im
  Skeleton-Commit mit; die Diff-Zeile der Latte erwartet ihn dort.
- **Ein verweigerter Close hatte weder Form noch Commit** und kollidierte mit
  der `/close`-Erkennung. Antwort: `## Close refused, <datum>` (das Komma in
  `## Close,` trennt die Erkennung), und jeder Close endet in einem
  `CLOSE:`-Commit ohne `(ticket NN)`-Suffix.
- Dazu: `--untracked-files=all` in der Diff-Zeile, Latten-Heading vor dem
  Lauf schreiben, Findings des Latten-Laufs unter `## Build findings`,
  Formen-Lücken (`CONSUMES`, handeditierte Eingabedatei), Platzhalter-Regel
  im Template, geschlossene Zykluszeile `undecided: none`.

Eine Abweichung im Lauf: die vier Review-Achsen las ein Agent sequenziell
statt als vier getrennte Subagenten.

Danach lief im selben Wegwerf-Repo ein zweiter, gezielter Lauf über die
Session-Grenzen — die Hälfte, die der erste Lauf ausließ: Session-Tod mitten
in §2 mit echtem Handoff und Resume durch eine frische Session, eine Review,
die mit offenen `— verdict pending`-Einträgen starb und von der nächsten
Session über §0 korrekt geschlossen wurde, ein CRITERION auf dem Ticket
selbst (Review-Commit als gültiger Fixpunkt für Zyklus 2, nachgemessen), ein
echtes REOPEN (der Lauf fand einen realen Defekt: der `__main__`-Guard des
Skeletons ließ spätere Testklassen still ungelaufen), und ein erfolgreicher
Close mit allen vier Walks. Ergebnis: kein Blocker; §0 routete alle drei
Grenzzustände korrekt; die drei Sentinel-Greps überlebten ihre eigenen
Pastes. Fünf Regel-Lücken — der Promotionsauslöser der Live-Blöcke
widersprach sich, ein `far end moved`-Block war für immer handzuspielen, der
REOPEN-Fixpunkt reviewte fremde Zwischenhistorie, „red test first" hatte
keinen Zweig für grün geborene Tests, der Umfang einer Criterion-Reparatur
war ungesagt — sind mitsamt den billigen Reibungspunkten in 0.3.1
eingearbeitet.

Als dritter Lauf ist inzwischen auch der vorgeschriebene Review-Modus selbst
ausgeführt worden: vier Achsen-Subagenten, die einander nicht sehen konnten,
lasen dasselbe Ticket parallel (elf Findings, getrennte Reports), und eine
koordinierende Session schrieb Findings, elf Verdikte und den Review-Commit
nach den Regeln der Skills. Der Modus trägt; seine Befunde — Zyklus-1-Pin
auf den **ersten** Build-Commit, Audit-Form für Re-Reads geschlossener
Arbeit, born-green-Ausnahme an der Latte, Paste-Zitierregel, ALREADY OWNED
für bereits gelandete Arbeit, Seam-Re-run-Auslöser — sind in 0.3.2
eingearbeitet.

Nicht gemessen bleiben: Brownfield und Nachfolge-Efforts über die
Ordnergrenze. Und wie bei jeder Welle zuvor gilt: die 0.3.1-Fixtexte selbst
sind nach ihrem Einarbeiten nicht erneut als Kette gelaufen — die Läufe
prüfen den Text, den sie ausführten, nicht die Patches, die sie auslösten.
