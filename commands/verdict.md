---
description: Give a finding its verdict - NOW, CRITERION, REOPEN, ALREADY OWNED, TICKET or DECLINE.
argument-hint: "[findings or ticket, or empty for all pending entries]"
---
Run the `hold-the-line` skill on the findings in: $ARGUMENTS

Default when no argument: every entry still marked `— verdict pending` in the
current effort's tickets — the effort under `docs/issues/` whose `spec.md`
has no `## Close,` block (comma included: a `## Close refused,` record
leaves the effort open); if several qualify, list them and ask (`grep -rn '— verdict pending' docs/issues/<effort>/` — the em-dash entry
marker; cycle lines say `undecided` and cannot match).

Only entry lines (`- [axis] **…** — verdict pending`) are open findings; a
hit that merely quotes the marker in a paste is history.

Every finding gets exactly one verdict, written into the ticket that produced
it, replacing its `— verdict pending` marker in the same edit.
