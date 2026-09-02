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
  mkdir -p "$REPO/docs/issues/demo"
  printf 'readme\n' > "$REPO/README.md"
}

commit_all() { git -C "$REPO" add -A && git -C "$REPO" commit -qm "$1"; }

GUARD_ERR="$(mktemp)"

guard() {
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
  "A: pending verdict blocks, worktree only"

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

# 4 — review commit: CRITERION on the same ticket, NOW paste under the old Bar
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

- [craft] **a name misleads** — nit — NOW. renamed
- [ticket] **the empty list is unasserted** — required — CRITERION on ticket 01. added

Review cycle 1 of 3 — undecided: none
"""
open(p, "w").write(s)
EOF
expect 0 "$(guard 'git commit -am "REVIEW: cycle 1 (ticket 01)"')" \
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
expect 0 "$(guard 'git commit -am "REVIEW: cycle 1 (ticket 01)"')" \
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
expect 0 "$(guard 'git commit -am "CLOSE: demo, one ticket moved"')" \
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
expect 2 "$(guard 'git commit -am "CLOSE: demo"')" \
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
expect 0 "$(guard 'git commit -am "CLOSE: refused"')" \
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
expect 2 "$(guard 'git commit -am "BUILD: x (ticket 01)"')" \
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
expect 0 "$(guard)" "a cwd outside any repo: exit 0"

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
expect 0 "$(guard 'git commit -am "REVIEW: cycle 1 (ticket 01)"')" \
  "a fenced paste of a bar, a criterion and the sentinel passes"

# 20 — a renamed ticket carries its old content
new_repo
done_ticket "$REPO/docs/issues/demo/01-path.md"
commit_all "BUILD: the queue prints one line (ticket 01)"
git -C "$REPO" mv docs/issues/demo/01-path.md docs/issues/demo/01a-path.md
printf '\n- [ ] **the second half** — split out\n' \
  >> "$REPO/docs/issues/demo/01a-path.md"
expect 0 "$(guard 'git commit -am "REVIEW: split 01 into 01a, 01b (ticket 01)"')" \
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

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
