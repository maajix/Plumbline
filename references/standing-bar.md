# The standing bar

The same bar every change clears, every time. Acceptance criteria vary per
ticket and answer *did we build the right thing*. This answers *is it finished*.

Single source of truth. Skills point here rather than restating it.

The bar is cleared in `build-slice` §7, before the ticket goes to review; the
ticket still reads `**Status:** claimed` here, because `resolved` is written
by `review-pass` when the review cycle closes.

## Per ticket, checked by machine

Each line carries the command that decides it, or the command whose hits a
stated rule then decides. Write the `## Bar, <date>` heading first — the
block-count line below reads its own heading — then run each command and
paste it with what it printed under that heading at the bottom of the
ticket. Quote the decisive lines verbatim — the count a grep printed, the
named test line — and elide bulk with an explicit `… (N lines)` marker;
never characterize output instead of quoting it. Quoted hits under `## Bar`
are history by the redemption line's own rule, so quote them whole — a
bar output that lives only in this session's context is a walked checklist by
the next one. Read the number a grep prints, not its exit status: `grep -c`
exits non-zero whenever it prints `0`. Paste commands and their output only,
never this file's own checkbox lines: a pasted `- [ ]` trips the first line's
grep below, and a pasted `- [x]` inflates `hold-the-line`'s criteria count.

- [ ] Every acceptance criterion in the ticket file is ticked.
      `grep -c '^- \[ \]' <ticket>` prints `0`. (A Rule 3b deferral is
      written ticked — `- [x] … deferred to ticket NN` — because the
      redemption grep below guards it; an unticked deferral would fail this
      line on every legitimate deferral.)
- [ ] The seam test passes. Run the effort's verify command — the one the
      walking skeleton's session wrote into the spec under `## Verify command`
      (`cut-slices` Rule 1) — and read this ticket's test by name in its
      output. Green overall is not the check; the named test is. On a
      `PRODUCES: nothing` ticket the named test is the behaviour test
      `cut-slices` Rule 3 puts in the same criterion slot.
- [ ] Any forward reference *this* ticket redeemed has been rewritten into a
      real citation in the ticket that made it.
      Run `grep -rn 'ticket <NN>' docs/issues/<effort>/` with `<NN>` this
      ticket's own number and read each hit that contains `CONSUMED BY`,
      `CONSUMES` or `deferred to`. A hit in a ticket's seam-field head — the
      unindented `**CONSUMED BY:**` or `**CONSUMES:**` line or a criterion's
      `deferred to` — is an
      unredeemed debt and fails the line. A hit inside any dated `##` block
      (`## Bar`, `## Seam check`, `## Review findings`, `## Build findings`,
      `## Resolution`, `## Close`) is history: pastes, findings and
      redemption records quote these tokens legally, including this very
      line's own paste. Any reference this ticket wrote or leaves standing
      is listed in its own `## Resolution`, **by number only** — quoting the
      token forms there would plant new hits.
- [ ] Existing tests still pass, and no test was skipped, deleted, or weakened.
      The same verify command, read whole, plus `git diff` for added `.skip`,
      deleted test files and removed assertions.
- [ ] The diff contains only what this ticket asked for. Run
      `git status --short --untracked-files=all` (it sees untracked and
      staged files where `git diff --stat` does not, and the flag stops it
      collapsing an untracked directory into one line) and compare the file
      list against the ticket's `Touches` line as corrected in `build-slice`
      §1. Files under `docs/issues/<effort>/` edited by this flow's own
      rules — the ticket file, `live-inputs.md`, tickets whose debts §5
      redeemed, and on the skeleton the effort's planning artifacts (the
      plan rides the skeleton's commit, and §3 writes the verify command
      into `spec.md`) — are expected, and so are the ticket's test files:
      `Touches` lists production files only, but the seam test and any
      criterion tests are this ticket's work;
      any other unexplained file is a finding, including build artifacts.
- [ ] The ticket file carries a `## Resolution` block, a `## Bar` block, and no
      `## Handoff` block. `grep -c '^## Resolution' <ticket>` prints at least
      `1` (a reopened ticket carries one dated block per resolve; the last is
      current), `grep -c '^## Bar' <ticket>` prints at least `1`, and
      `grep -c '^## Handoff' <ticket>` prints `0`.

## Per ticket, checked by reading

No command decides these, and saying so is the point. A line that claims to be
checked and is not is worse than a line that admits it is judgement.

- [ ] **Judgement.** The seam test was watched failing before the code existed,
      and was broken once on purpose. The `Red:` and `Mutated:` lines in
      `## Resolution` carry the two assertion messages; a resolution without
      them is this line failing. One shared exception (`review-pass`'s
      criterion branch): a repair test born green records
      `Red: none — born green` and the `Mutated:` line is the sole proof. Only the session that watched them knows the
      messages are real — a passing test at the end looks identical either way.
- [ ] **Judgement.** The `## Seam check` report shows no unexplained `NOBODY`.
      A far end recorded as `ticket NN`, `operator, via <cmd>`,
      `<name>, out of repo`, or `the <constraint> at <where>` satisfies this;
      a bare `NOBODY` does not. That is an agent pass over source, not a
      command.
- [ ] **Judgement.** The live run reached **this ticket's case**, not merely a
      green exit. Every block in `docs/issues/<effort>/live-inputs.md` whose
      `STATUS` begins with `live` was replayed and the far end was read — or
      the ticket that owns the far end is named and the run is recorded as
      owed. Where the spec's `Load` section names a figure for this path, the
      run reached it or the ticket says why not.
- [ ] **Judgement.** `cut-slices` Rule 3b: the real thing behind any injected
      double is checked too, or the deferral names its ticket
      (`deferred to ticket NN`). Whether a recorded response still resembles
      the live system is a reading, not a run.

## A bar line with neither is decoration

Every per-ticket line above sits under one of those two headings: it carries a
command, or it is marked **Judgement** and says what it rests on. A line with
neither is decoration — it gets ticked, the tick means nothing, and the bar
reads one line higher than it stands. When a line is added here, put it under
the heading it can actually earn, and if it can earn neither, it does not
belong on the bar.

## Per effort

The first four are `close-effort`'s four walks — each names its own command or
its own reading there; this list is the index, not the check. The fifth has
its command here.

- [ ] Every ticket is `resolved`, `declined` in writing, or has been moved into
      the successor effort's folder and named in this effort's `## Close` block.
      A moved ticket keeps its status; the folder it sits in says which effort
      owns it.
- [ ] Every `CONSUMED BY: ticket NN` forward reference in the effort (on disk
      `**CONSUMED BY:** ticket NN`) has been
      redeemed into a real citation, deleted together with the value nothing
      reads, or moved to the successor effort with both of its ends. A reference
      whose two ends land in two different efforts is the defect this flow exists
      to prevent, arriving on schedule.
- [ ] No exit criterion in the spec is unowned.
- [ ] The feature runs end to end, demonstrated once, not argued.
- [ ] Every review finding carries a verdict.
      `grep -rn '— verdict pending' docs/issues/<effort>/` shows no entry
      line (`- [axis] **…** — verdict pending`) — the em-dash marker is the
      entry sentinel; cycle lines say `undecided` precisely so they cannot
      match it, and a hit that only quotes the marker inside a pasted
      command or a close record is history.

## The bar moves up silently and down loudly

Loosening the bar is a change that must be visible in review. Five moves to
watch for in `git diff`, all cheap to spot:

1. **A threshold moved.** A budget lowered, a severity dropped, a check pulled
   out of the fast stage.
2. **A test got easier.** `.skip` added, a test file deleted, assertions
   removed from a test that stayed.
3. **A checker got silenced.** New `@ts-ignore`, `eslint-disable`, `# type:
   ignore`, `nosemgrep`, `istanbul ignore`.
4. **Work is unfinished.** A stub that throws, an empty `catch` that turns a
   failure into silence, a `TODO` standing where the code should be.
5. **An exception appeared.** A new carve-out nobody discussed.

Each of these is a **finding**, and findings go to `hold-the-line` for a
verdict. None of them is a reason to fail the build on its own — a silenced
checker with a written reason beside it is a decision, not a defect.
