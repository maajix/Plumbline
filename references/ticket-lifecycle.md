# Ticket identity and lifecycle

Read this before build, review, verdict, prove, split or close. This is the
single owner of identity, commit ordering and resumption; the standing bar owns
the quality checks. The workflow remains single-session.

## Identity and history

Every ticket has `**ID:** <origin-effort>/<NN>`, for example `billing/01`.
The origin slug is kebab-case; NN is the two-digit number with an optional
split letter. The ID never changes when the file moves. Split children get
their parent's origin plus their own number: `billing/14a`, `billing/14b`.
Numbers must be unique in their current folder and IDs unique in the repo.

Commands accept an ID, a ticket path, or a number within one unambiguous effort.
With several possible efforts, ask using their qualified IDs. Never select a
ticket from another effort just because its number matches.

Build and review subjects end with `(ticket <ID>)`. Find builds with
`git log --format='%H %s' | grep -E '\(ticket <ID>\)$' | grep -v ' REVIEW:'`,
substituting the ID literally; `--reverse` on git log gives the oldest build.
A review commit is `REVIEW: <result> (ticket <ID>)`; a close has no ticket suffix.
Find the default last-built ticket with the same suffix pattern using
`[a-z0-9]+(-[a-z0-9]+)*/[0-9][0-9][a-z]?` for the ID.

**Legacy tickets.** Upgrade only the ticket being used. Recover its origin from
the file's history (`git log --follow -- <ticket-path>`), then add its ID.
For old `(ticket NN)` subjects, inspect that path's history and verify which
build/review each candidate belongs to; `--follow` may include a copied file's
source history, so verify the actual paths changed by each candidate.
Record verified old commit hashes in
the ticket's `## History` block, including the first build and latest completed
review. If the origin or a commit is ambiguous, ask for the specific choice;
never fall back to a repo-wide number-only match. Existing IDs and qualified
commits take precedence. Do not rewrite historical commits or bulk-migrate files.

## State and resumption

Use the most recent review attempt; old blocks are history. A matching review
commit is the one that recorded that attempt's findings block, not merely any
older REVIEW subject with the same ticket ID. Inspect the ticket diff in the
candidate commit to confirm this.

| Current state | Next action |
|---|---|
| `declined` or `blocked — needs decision` | Preserve it; no automatic resolve or cycle reset. |
| Review block has `Readers: pending` | Finish/re-run readers for that same cycle and frozen snapshot. |
| Review findings have `verdict pending` | Complete verdicts; do not start a build or another cycle. |
| Readers complete and verdicts recorded, but no matching review commit | Commit that attempt first, even if it added unticked repair criteria. |
| `claimed` with unticked criteria, Handoff, or missing Resolution/Bar | Build or resume; work remains. |
| Built but uncommitted | Clear the bar against current work, then make the build commit. |
| Built and committed, review not closed | Review the built snapshot. |
| Clean closing review | Set `resolved` in that review commit only. |

An open ticket becomes claimed when build starts. REOPEN on resolved work adds
an unticked repair criterion and sets claimed; its new review has a fresh cycle
count. Resuming an interrupted review or repair does not reset the count.

## Review, repair, review

Before readers start, freeze full commit hashes as `**Base:**` and `**Head:**`
under the cycle heading, plus `**Readers:** pending`. Cycle 1's base is the
parent of the first build; later cycles use the previous completed review
commit. After REOPEN use the parent of its first repair build. If that build
is a root commit, use `git hash-object -t tree /dev/null` as base.
Read `git diff <base> <head>`; never let HEAD move underneath a review.
An empty ordinary build diff needs investigation; it is not a clean review.

After all four readers finish, write all findings (or each axis's clean line)
and change Readers to complete. Then give verdicts and commit the review.
Any executable repair discovered **during review**, whether NOW or CRITERION,
is first an unticked criterion. NOW means repair this ticket before unrelated
work, not permission to skip review. Findings and criteria ride the review
commit; code, tests and configuration repairs ride a subsequent build commit.
The next review cycle sees that repair. Until then the ticket stays claimed.
During a build, NOW/current-ticket
CRITERION work is done before the normal build commit and review.

Only prose and comment-only repairs may ride a review commit directly.
Executable repairs run red/green/mutation, update Resolution, and clear the
standing bar. If production behavior or a seam moved, refresh its seam proof
and replay affected live cases; count each ticket's replay only once. Test-only
repairs need not repeat an unchanged live run. The effort's tests and named
far-end assertions must still pass.

Resolve only with every axis complete, all findings verdicted, all criteria
ticked, no Handoff, and no executable change made after the reviewed head.
A recorded split stays declined. A blocked decision stays blocked.
If cycle three still requires executable repair, keep the criterion, set
`blocked — needs decision`, commit the findings, and explain the remaining work.
No fourth cycle, hidden repair loop or automatic reset. A user decision that
needs a new work unit must explicitly split/replan it before building again.

**Audit.** An audit of resolved work reads the current implementation against
the ticket and spec. Freeze the current Head, locate the original build range
for context, and inspect current producers, consumers and tests even when no
commit followed resolution. A diff since resolution is supplemental, never the
audit's only artifact. Audits consume no cycle and do not themselves resolve
tickets; executable findings take REOPEN or another appropriate verdict, then
the normal build/review path. Commit the audit findings separately.

## Every commit: stage, then commit

Finish edits and run checks, stage the intended files in one Bash call, inspect
`git diff --cached`, then commit in a separate Bash call. Use a simple
`git [-C <repo>] commit -m <message>` or `-F <message-file>`; RTK wrappers and a
plain `env` prefix are supported. Message files must already exist.
Do not use commit `-a`, `--only`, `--include`, `--amend`, file arguments,
alternate Git environments, substitutions or chained commands. Literal dollar
signs and backticks in messages also require `-F`, since the guard rejects them
conservatively in shell text. The hook checks
one staged tree; unrelated unstaged work is not part of that commit.

The hook is a check for this invocation contract, not enforcement over shell
scripts, aliases, external commits, concurrent index writers, or native Git
hooks that modify the index. Internal unexpected errors remain fail-open with
a diagnostic; expected command/Git failures block and must be corrected.
