---
description: Close an effort by settling its forward references, exit criteria and statuses.
argument-hint: "[effort slug, or empty for the one unclosed effort]"
---
Run the `close-effort` skill on: $ARGUMENTS

Default when no argument: the effort under `docs/issues/` whose `spec.md` has
no `## Close,` block (the comma matters: `## Close refused,` records a
refusal and leaves the effort open). If several qualify, list them and ask
which.
