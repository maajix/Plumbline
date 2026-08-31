---
description: Turn a shape into a spec organised by paths that run, not components.
argument-hint: "[effort slug, or empty for the effort with a shape and no spec]"
---
Run the `write-spec` skill for: $ARGUMENTS

Default when no argument: the effort under `docs/issues/` that has a
`shape.md` and no `spec.md`; ask if several qualify.

Input is `docs/issues/<effort>/shape.md`. Write `docs/issues/<effort>/spec.md`.
Then run `cold-read` over the result.
