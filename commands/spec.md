---
description: Turn a shape into a spec organised by paths that run, not components.
argument-hint: "[effort slug, or empty for the effort with a shape and no spec]"
---
Run the `write-spec` skill for: $ARGUMENTS

Default when no argument: the effort under `docs/issues/` that has a
`shape.md` and no `spec.md` — excluding stub shapes; ask if several qualify.
Argument or default, the input qualifies only if
`grep -c '^\*\*Status:\*\* unshaped' docs/issues/<effort>/shape.md` prints
`0` — a stub shape never had an interview and is not spec input. No number
printed is not a `0`: a missing `shape.md` is the synthesis-mode successor
case, whose input `write-spec` names.

Input is `docs/issues/<effort>/shape.md`. Write `docs/issues/<effort>/spec.md`.
Then run `cold-read` over the result.
