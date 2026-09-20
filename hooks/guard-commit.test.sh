#!/usr/bin/env bash
# The one executable check for guard-commit.py: a temp repo per case, one
# docs/issues/ state, one assert on the exit code. No framework.
set -u

GUARD="$(cd "$(dirname "$0")" && pwd)/guard-commit.py"
PASS=0
FAIL=0

new_repo() {
  REPO="$(mktemp -d)"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name tester
  git -C "$REPO" config commit.gpgsign false
  git -C "$REPO" config core.hooksPath /dev/null
  mkdir -p "$REPO/docs/issues/demo"
  printf 'readme\n' > "$REPO/README.md"
}

commit_all() { git -C "$REPO" add -A && git -C "$REPO" commit -qm "$1"; }

GUARD_ERR="$(mktemp)"

guard() {
  # Stage as a separate operation, unless testing a deliberately partial index.
  if [ "${KEEP_INDEX:-0}" = 0 ]; then git -C "$REPO" add -A 2>/dev/null || true; fi
  local cmd="${1:-git commit -m x}"
  python3 -c 'import json,sys; print(json.dumps({"cwd": sys.argv[1], "tool_name": "Bash", "tool_input": {"command": sys.argv[2]}}))' \
    "$REPO" "$cmd" | python3 "$GUARD" >/dev/null 2>"$GUARD_ERR"
  echo $?
}

expect() { # expect <want> <got> <name>
  if [ "$1" = "$2" ]; then
    PASS=$((PASS + 1)); printf 'ok   %s\n' "$3"
  else
    FAIL=$((FAIL + 1)); printf 'FAIL %s (want %s, got %s)\n' "$3" "$1" "$2"
  fi
}

done_ticket() { # done_ticket <path>
  cat > "$1" <<'EOF'
# 01 — the path runs

**Status:** claimed

**PRODUCES:** new: an observation
**CONSUMED BY:** cli.py::main, reading observation.status
**CONSUMES:** nothing

**Touches:** cli.py

- [x] **The path runs.** it does
- [x] **Checked by something that would go red.** test_seam_status

## Seam check, 2026-01-01

WROTE  observation.status  READ BY  cli.py::main, reading observation.status

- [seam] clean — nothing raised

## Resolution, 2026-01-01

The queue prints one line.

**Red:** AssertionError: 'queued' not found in ''
**Mutated:** observation.status -> AssertionError: 'queued' not found
**Forward references left standing:** none

## Bar, 2026-01-01

`grep -c '^- \[ \]' 01-path.md` printed `0`
EOF
}

# 1 — sentinel present, staged inside the same command, index empty at hook time
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **something** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard 'git add -A && git commit -m "BUILD: x (ticket 01)"')" \
  "combined staging and commit is refused"

# 2 — unborn HEAD does not crash and still checks
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **something** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard)" "A: unborn HEAD, pending verdict blocks"

# 3 — unborn HEAD, finished skeleton ticket
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
expect 0 "$(guard)" "unborn HEAD, finished ticket passes"

# 4 — review commit: unticked repair criteria and existing bar evidence
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
python3 - "$REPO/docs/issues/demo/01-path.md" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("- [x] **Checked by something that would go red.** test_seam_status",
              "- [x] **Checked by something that would go red.** test_seam_status\n"
              "- [ ] **The empty list prints nothing.** added by review")
s = s.replace("`grep -c '^- \\[ \\]' 01-path.md` printed `0`",
              "`grep -c '^- \\[ \\]' 01-path.md` printed `0`\n\n"
              "Re-run after the NOW repair: `grep -c '^## Resolution' 01-path.md` printed `1`")
s += """
## Review findings, 2026-01-02 — cycle 1

- [craft] **a comment misleads** — nit — NOW. clarified comment
- [ticket] **the empty list is unasserted** — required — CRITERION on ticket 01. added

Review cycle 1 of 3 — undecided: none
"""
open(p, "w").write(s)
EOF
expect 0 "$(guard 'git commit -m "REVIEW: cycle 1 (ticket 01)"')" \
  "B: review commit with CRITERION and a NOW paste passes"

# 5 — REOPEN in a review commit on a ticket that died after §6
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
cat >> "$REPO/docs/issues/demo/01-path.md" <<'EOF'

## Handoff, 2026-01-01

**Red:** AssertionError: 'queued' not found in ''
**Green:** nothing yet
**Half-edited:** cli.py
**Next action:** run the seam test
EOF
commit_all "BUILD: the queue prints one line (ticket 01)"
cat >> "$REPO/docs/issues/demo/01-path.md" <<'EOF'

## Review findings, 2026-01-03 — cycle 1

- [seam] **the status never reaches the far end** — blocker — REOPEN ticket 01. goes back

Review cycle 1 of 3 — undecided: none
EOF
expect 0 "$(guard 'git commit -m "REVIEW: cycle 1 (ticket 01)"')" \
  "B: REOPEN on a ticket with Resolution and Handoff passes"

# 6 — close: a moved resolved ticket arrives as a new file in the successor
new_repo
mkdir -p "$REPO/docs/issues/next"
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
sed 's/^\*\*Status:\*\* claimed/**Status:** resolved/' \
  "$REPO/docs/issues/demo/01-path.md" > "$REPO/docs/issues/next/01-path.md"
printf '# next — spec\n\n## Verify command\n\npytest -v\n' \
  > "$REPO/docs/issues/next/spec.md"
expect 0 "$(guard 'git commit -m "CLOSE: demo, one ticket moved"')" \
  "C: a moved resolved ticket in a new folder passes"

# 7 — close with a ticket still open in the folder
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '# 02 — later\n\n**Status:** open\n\n- [ ] **it runs**\n' \
  > "$REPO/docs/issues/demo/02-later.md"
printf '# demo — spec\n' > "$REPO/docs/issues/demo/spec.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
printf '\n## Close, 2026-01-04\n\nAll four walks answered.\n' \
  >> "$REPO/docs/issues/demo/spec.md"
expect 2 "$(guard 'git commit -m "CLOSE: demo"')" \
  "D: close with an open ticket in the folder blocks"

# 8 — a refused close leaves the effort open
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '# 02 — later\n\n**Status:** open\n\n- [ ] **it runs**\n' \
  > "$REPO/docs/issues/demo/02-later.md"
printf '# demo — spec\n' > "$REPO/docs/issues/demo/spec.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
printf '\n## Close refused, 2026-01-04\n\nWalk 3: ticket 02 is open.\n' \
  >> "$REPO/docs/issues/demo/spec.md"
expect 0 "$(guard 'git commit -m "CLOSE: refused"')" \
  "D: Close refused passes"

# 9 — the sentinel on the continuation line of a two-line entry
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
cat >> "$REPO/docs/issues/demo/01-path.md" <<'EOF'

## Seam check, 2026-01-05

- [seam] **cli.py::main: WROTE observation.target, read by NOBODY. the console
  should read it.** — required — verdict pending
EOF
expect 2 "$(guard)" "A: sentinel on a continuation line blocks"

# 10 — not a commit at all
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **x** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
expect 0 "$(guard 'git status --short')" "no git commit in the command: exit 0"

# 11 — nothing under docs/issues changed
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
printf 'more\n' >> "$REPO/README.md"
expect 0 "$(guard)" "nothing under docs/issues changed: exit 0"

# 12 — a build commit that adds the bar with a criterion still unticked
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
sed -i 's/^- \[x\] \*\*The path runs\.\*\* it does/- [ ] **The path runs.** not yet/' \
  "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard 'git commit -m "BUILD: x (ticket 01)"')" \
  "B: Bar added with an unticked criterion blocks"

# 13 — resolved written outside a review commit
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
sed -i 's/^\*\*Status:\*\* claimed/**Status:** resolved/' \
  "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard 'git commit -m "BUILD: x (ticket 01)"')" \
  "C: resolved outside a review commit blocks"

# 14 — the message names the file, the rule and the skill section
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **x** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
guard > /dev/null
if grep -q '01-path.md' "$GUARD_ERR" && grep -q 'hold-the-line' "$GUARD_ERR"; then
  expect 1 1 "the block message names the file and the skill section"
else
  expect 1 0 "the block message names the file and the skill section"
fi
if grep -q 'skipped (' "$GUARD_ERR"; then
  expect 1 0 "the guard did not fail open on a real state"
else
  expect 1 1 "the guard did not fail open on a real state"
fi

# 15 — a commit made from a subdirectory of the repo
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **x** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
REPO_ROOT="$REPO"
REPO="$REPO/docs/issues/demo"
expect 2 "$(guard)" "the check runs from a subdirectory of the repo"
REPO="$REPO_ROOT"

# 16 — a cwd that is not a git repo at all
REPO="$(mktemp -d)"
expect 2 "$(guard)" "an expected Git failure blocks"

# 17 — a command that only mentions a commit, with a blocking state on disk
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n- [seam] **x** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
expect 0 "$(guard 'echo "next step: git commit -m fix"')" \
  "a mentioned commit is not a commit"
expect 0 "$(guard 'git commit-graph write')" "git commit-graph is not git commit"
expect 0 "$(guard 'git log --format="%h %s" | grep -E "\(ticket 01\)$"')" \
  "a git command that is not commit"
expect 2 "$(guard 'git -C . commit -m "BUILD: x (ticket 01)"')" \
  "git -C <path> commit is a commit"

# 18 — a merge in progress: the other side's lines are not this session's work
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
printf '\n- [seam] **x** — required — verdict pending\n' \
  >> "$REPO/docs/issues/demo/01-path.md"
git -C "$REPO" rev-parse HEAD > "$REPO/.git/MERGE_HEAD"
expect 0 "$(guard)" "a merge in progress is left alone"
rm -f "$REPO/.git/MERGE_HEAD"
expect 2 "$(guard)" "the same state blocks once the merge is gone"

# 19 — fenced blocks are quoted output, not live state
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
cat >> "$REPO/docs/issues/demo/01-path.md" <<'EOF'

## Review findings, 2026-01-02 — cycle 1

- [bar] **the bar paste is quoted below** — nit — NOW. quoted

What the earlier session pasted, for the record:

```markdown
## Bar, 2026-01-01

- [ ] **an example criterion** — from the template
- [seam] **an example finding** — required — verdict pending
```

Review cycle 1 of 3 — undecided: none
EOF
expect 0 "$(guard 'git commit -m "REVIEW: cycle 1 (ticket 01)"')" \
  "a fenced paste of a bar, a criterion and the sentinel passes"

# 20 — a renamed ticket carries its old content
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
git -C "$REPO" mv docs/issues/demo/01-path.md docs/issues/demo/01a-path.md
printf '\n- [ ] **the second half** — split out\n' \
  >> "$REPO/docs/issues/demo/01a-path.md"
expect 0 "$(guard 'git commit -m "REVIEW: split 01 into 01a, 01b (ticket 01)"')" \
  "a renamed ticket is judged as modified, not re-added"

# 21 — a close walk reads the status value, not the whole line
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
sed -i 's/^\*\*Status:\*\* claimed$/**Status:** resolved (moved to 02 in the next effort)/' \
  "$REPO/docs/issues/demo/01-path.md"
printf '# demo\n\n**Status:** open\n' > "$REPO/docs/issues/demo/spec.md"
commit_all "SLICE: the demo effort (ticket 01)"
printf '\n## Close, 2026-01-03\n\nEvery ticket resolved.\n' \
  >> "$REPO/docs/issues/demo/spec.md"
expect 0 "$(guard)" "D: a resolved status with a trailing note passes"
sed -i 's/^\*\*Status:\*\* resolved (moved.*$/**Status:**/' \
  "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard)" "D: an empty status value blocks"

# 22 — a date-named note in the effort folder is not a ticket
new_repo
printf '# notes\n\n- [seam] **x** — required — verdict pending\n' \
  > "$REPO/docs/issues/demo/2026-01-02-notes.md"
expect 0 "$(guard)" "a date-named file is not a ticket"
mkdir -p "$REPO/docs/issues/demo/02-sub.md"
printf 'x\n' > "$REPO/docs/issues/demo/02-sub.md/inner.txt"
expect 0 "$(guard)" "a directory named like a ticket does not crash the guard"

# 23 — glob metacharacters in a ticket name
new_repo
done_ticket "$REPO/docs/issues/demo/03-a[b].md"
sed -i 's/^## Bar, 2026-01-01$/## Notes/' "$REPO/docs/issues/demo/03-a[b].md"
commit_all "BUILD: the bracket ticket (ticket 03)"
printf '\n- [ ] **added by review** — pending work\n\n## Bar, 2026-01-04\n\n`grep -c` printed `1`\n' \
  >> "$REPO/docs/issues/demo/03-a[b].md"
expect 2 "$(guard)" "B: a ticket name with glob characters is read literally"

# 24 — the index, not the working tree, is the commit's content.
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
git -C "$REPO" add -A
printf '\n- [seam] **unstaged** — required — verdict pending\n' >> "$REPO/docs/issues/demo/01-path.md"
KEEP_INDEX=1
expect 0 "$(guard)" "clean staged ticket, pending unstaged: allow"
git -C "$REPO" add -A
sed -i '/unstaged/d' "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard)" "pending staged ticket, clean unstaged: block"
KEEP_INDEX=0

# 25 — supported wrappers and messages all reach the same check.
for command in 'git commit -m x' 'rtk git commit -m x' 'rtk proxy git commit -m x' \
               'env git commit -m x' 'env rtk git commit -m x'; do
  expect 0 "$(guard "$command")" "supported command on clean state: $command"
done
expect 0 "$(guard $'git commit -m "BUILD: title\n\nDetails"')" "multiline quoted message"
expect 0 "$(guard 'git commit -m "quoted && separator; not a command"')" "quoted shell punctuation"
expect 0 "$(guard 'git commit -m "&&"')" "operator as quoted message"
expect 0 "$(guard 'git commit -F /tmp/message.txt')" "message file"
expect 0 "$(guard $'\n\ngit commit -m x\n\n')" "blank lines around a simple commit"
printf '\n- [seam] **pending** — required — verdict pending\n' >> "$REPO/docs/issues/demo/01-path.md"
expect 2 "$(guard 'rtk git commit -m x')" "RTK does not bypass a pending finding"
expect 2 "$(guard $'git commit -m "BUILD: title\n\nDetails"')" "multiline message does not bypass a finding"
expect 2 "$(guard $'\n\ngit commit -m x\n\n')" "blank lines do not bypass a finding"

# 26 — git -C must select the actual repository, including repeated relative -C.
TARGET="$REPO"
git -C "$TARGET" add -A
new_repo
commit_all "INIT: clean caller"
expect 2 "$(guard "git -C '$TARGET' commit -m x")" "different target repo is checked"
expect 2 "$(guard "git -C '$TARGET/docs' -C issues commit -m x")" "relative repeated -C"
expect 2 "$(guard "rtk git -C '$TARGET' commit -m x")" "RTK target repo is checked"
expect 0 "$(guard 'echo "git commit -m x"')" "quoted mention is not a commit"

# 27 — unsupported forms fail with a concrete replacement, not fail-open.
for command in 'git add -A && git commit -m x' 'git commit -am x' \
               'git commit --only README.md -m x' 'git commit --include README.md -m x' \
               'git commit README.md -m x' 'git commit --amend -m x' \
               'git commit -m x && git status' 'cd .; git commit -m x' \
               'GIT_INDEX_FILE=/tmp/index git commit -m x' \
               'env -u GIT_DIR git commit -m x' 'git --work-tree=/tmp commit -m x' \
               'git -c core.hooksPath=/tmp commit -m x' \
               'git commit -m "$(date)"'; do
  expect 2 "$(guard "$command")" "unsupported form: $command"
done
expect 2 "$(guard $'git add -A\ngit commit -m x')" "newline command chaining is refused"
expect 2 "$(guard $'git add -A\n\ngit commit -m x')" "blank-line command chaining is refused"
expect 2 "$(guard $'git add -A;\ngit commit -m x')" "mixed separators are refused"
if grep -q 'Stage in a separate Bash call' "$GUARD_ERR"; then
  expect 1 1 "unsupported command explains how to retry"
else
  expect 1 0 "unsupported command explains how to retry"
fi

# 28 — a close must see staged statuses and staged moves, never disk state.
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '# demo\n' > "$REPO/docs/issues/demo/spec.md"
commit_all "BUILD: initial (ticket demo/01)"
printf '\n## Close, 2026-09-18\n' >> "$REPO/docs/issues/demo/spec.md"
git -C "$REPO" add -A
sed -i 's/Status:\*\* claimed/Status:** resolved/' "$REPO/docs/issues/demo/01-path.md"
KEEP_INDEX=1
expect 2 "$(guard)" "close sees claimed in index despite resolved on disk"
mkdir -p "$REPO/docs/issues/next"
git -C "$REPO" mv docs/issues/demo/01-path.md docs/issues/next/01-path.md
expect 0 "$(guard)" "staged move removes ticket from closing folder"
KEEP_INDEX=0

# 29 — only editing the inside of an existing code fence is not live state.
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
printf '\n\x60\x60\x60markdown\nexample\n\x60\x60\x60\n' >> "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: fixture (ticket demo/01)"
sed -i 's/^example$/**Status:** resolved\n## Bar, example\n- [ ] example/' "$REPO/docs/issues/demo/01-path.md"
expect 0 "$(guard)" "existing fence context is retained while diffing"

# 30 — failed snapshot creation is an expected error, not a clean result.
new_repo
commit_all "INIT: fixture"
BLOB="$(git -C "$REPO" rev-parse HEAD:README.md)"
printf '100644 %s 1\tREADME.md\n100644 %s 2\tREADME.md\n100644 %s 3\tREADME.md\n' "$BLOB" "$BLOB" "$BLOB" |
  git -C "$REPO" update-index --index-info
KEEP_INDEX=1
expect 2 "$(guard)" "unmerged index blocks snapshot check"
KEEP_INDEX=0

# 31 — execute the lifecycle's history recipe with repeated ticket numbers.
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: first effort (ticket demo/01)"
FIRST_BUILD="$(git -C "$REPO" rev-parse HEAD)"
mkdir -p "$REPO/docs/issues/second"
done_ticket "$REPO/docs/issues/second/01-path.md"
commit_all "BUILD: second effort (ticket second/01)"
SECOND_BUILD="$(git -C "$REPO" rev-parse HEAD)"
FOUND="$(git -C "$REPO" log --reverse --format='%H %s' | grep -E '\(ticket second/01\)$' | grep -v ' REVIEW:' | cut -d ' ' -f 1)"
expect "$SECOND_BUILD" "$FOUND" "qualified first build excludes another effort's 01"
mkdir -p "$REPO/docs/issues/successor"
git -C "$REPO" mv docs/issues/second/01-path.md docs/issues/successor/01-path.md
commit_all "CLOSE: move to successor"
FOUND="$(git -C "$REPO" log --reverse --format='%H %s' | grep -E '\(ticket second/01\)$' | grep -v ' REVIEW:' | cut -d ' ' -f 1)"
expect "$SECOND_BUILD" "$FOUND" "ID history survives a move"

# 32 — identical legacy files can make --follow trace a copy as well as a move.
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: legacy first (ticket 01)"
mkdir -p "$REPO/docs/issues/second"
done_ticket "$REPO/docs/issues/second/01-path.md"
commit_all "BUILD: legacy second (ticket 01)"
LEGACY="$(git -C "$REPO" rev-parse HEAD)"
mkdir -p "$REPO/docs/issues/successor"
git -C "$REPO" mv docs/issues/second/01-path.md docs/issues/successor/01-path.md
commit_all "CLOSE: move legacy"
FOUND="$(git -C "$REPO" log --follow --format='%H %s' -- docs/issues/successor/01-path.md | grep -E '\(ticket 01\)$' | cut -d ' ' -f 1)"
expect 2 "$(printf '%s\n' "$FOUND" | wc -l | tr -d ' ')" \
  "legacy copy history is ambiguous: do not silently pick its oldest candidate"
expect docs/issues/second/01-path.md "$(git -C "$REPO" show --format= --name-only "$LEGACY")" \
  "verify the legacy candidate's actual path before recording its hash"

# 33 — verdict first, then repair, then the next review sees the repair.
printf '\n## Review findings, 2026-09-18 — cycle 1\n- [ticket] **repair** — required — NOW. Criterion recorded.\n- [ ] repair\n' >> "$REPO/docs/issues/successor/01-path.md"
commit_all "REVIEW: repair required (ticket second/01)"
REVIEW_BASE="$(git -C "$REPO" rev-parse HEAD)"
printf 'result = 2\n' > "$REPO/feature.py"
sed -i 's/^- \[ \] repair/- [x] repair/' "$REPO/docs/issues/successor/01-path.md"
commit_all "BUILD: repair (ticket second/01)"
REVIEW_HEAD="$(git -C "$REPO" rev-parse HEAD)"
FOUND="$(git -C "$REPO" diff "$REVIEW_BASE" "$REVIEW_HEAD" --name-only | grep -c '^feature.py$')"
expect 1 "$FOUND" "next pinned review includes executable NOW repair"
printf '\n## Review findings, 2026-09-18 — cycle 2\n- [ticket] clean — nothing raised\n' >> "$REPO/docs/issues/successor/01-path.md"
commit_all "REVIEW: resolved (ticket second/01)"
AUDIT_HEAD="$(git -C "$REPO" rev-parse HEAD)"
expect 'result = 2' "$(git -C "$REPO" show "$AUDIT_HEAD:feature.py")" \
  "audit reads current implementation even at the resolve commit"
expect '' "$(git -C "$REPO" diff "$AUDIT_HEAD" HEAD)" \
  "empty post-resolution diff is valid audit context"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
