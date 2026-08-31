---
description: Review pass. Four axes, cold read, findings with severity.
argument-hint: "[ticket number, or empty for the ticket in the last commit]"
---
Run the `review-pass` skill over: $ARGUMENTS

Default scope when no argument: the ticket named in the newest commit whose
subject ends `(ticket NN)` and does not begin `REVIEW:` — `build-slice` §8
ends every build subject that way, and `REVIEW:` marks a cycle already run. One pass covers
all four axes and counts as one cycle. Hand every finding to `hold-the-line`,
and close the cycle per `review-pass` (it writes `resolved`, not the build).
