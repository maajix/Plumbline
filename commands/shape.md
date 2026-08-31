---
description: Shape a new feature at the product level, or pick up a waiting stub shape. Product questions only, never implementation.
argument-hint: "[the idea, in a sentence]"
---
Run the `shape-idea` skill on: $ARGUMENTS

Before interviewing, run
`grep -rn --include=shape.md '^\*\*Status:\*\* unshaped' docs/issues/` and
name any waiting stub shapes; one matching the idea is the interview's
input, per the skill. No output means no stubs; a grep error means look,
never "none".

Write the results to `docs/issues/<effort>/`: `interview.md` with the
questions, answers and numbered rounds, and `shape.md` with the shape — plus
any stub shape as `docs/issues/<its-slug>/shape.md`, per the skill.
