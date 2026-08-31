---
description: Cut a spec into vertical tickets with named seams. Max 25 per effort.
argument-hint: "[effort slug, or empty for the effort with a spec and no tickets]"
---
Run the `cut-slices` skill against the spec for: $ARGUMENTS

Default when no argument: the effort under `docs/issues/` that has a `spec.md`
and no `NN-*.md` tickets yet; ask if several qualify.

Write tickets to `docs/issues/<effort>/NN-<slug>.md`, one file per ticket,
numbered from the next free number in the folder (01 for a fresh effort), in
dependency order. They sit beside `shape.md` and `spec.md`, in the effort
folder itself — there is no second `issues/` level.

Then run `cold-read` over the finished ticket set and answer in writing:
if every ticket is implemented exactly as written and nothing more, does the
feature run end to end?
