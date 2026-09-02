#!/usr/bin/env python3
"""Plumbline commit guard.

Blocks a `git commit` whose `docs/issues/` state contradicts four rules of the
flow that need nothing but greps over that folder:

  A  a changed ticket file still carries a `— verdict pending` entry
  B  a build commit adds `## Bar,` while the ticket is unfinished
  C  `**Status:** resolved` appears outside a review commit
  D  a spec is closed while a ticket in its folder is neither
     `resolved` nor `declined`

Every other rule in the flow needs the target repo's toolchain and stays with
the skills. B's three counts use the standing bar's own greps, so a ticket that
clears the bar cannot be blocked here.

The guard compares the **working tree** against HEAD, not the index:
`git add -A && git commit` stages inside the same Bash call, so at hook time
`--cached` would be empty. Fenced blocks are stripped before anything is read,
because this flow pastes command output and template examples into tickets.

Exit 2 blocks the command and shows stderr to Claude. Any internal error exits
0 with a note: a bug in this hook must never block a commit.
"""

import json
import os
import re
import shlex
import subprocess
import sys

# `NN-<slug>.md`, `14a-<slug>.md`; never `2026-01-02-notes.md`
TICKET_NAME = r"\d\d[a-z]?(?:[-_. ][^/]*)?\.md"
TICKET = re.compile(r"^docs/issues/[^/]+/" + TICKET_NAME + r"$")
SPEC = re.compile(r"^docs/issues/[^/]+/spec\.md$")
NAME_ONLY = re.compile(r"^" + TICKET_NAME + r"$")
SENTINEL = "— verdict pending"
STATUS = re.compile(r"^\*\*Status:\*\*[ \t]*(.*?)[ \t]*$", re.M)
FENCE = re.compile(r"(?ms)^ {0,3}(?:```|~~~).*?^ {0,3}(?:```|~~~)[^\n]*$")
CLOSED_STATUS = ("resolved", "declined")
GIT_VALUE_OPTS = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path",
    "--super-prefix", "--config-env",
}
IN_PROGRESS = ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD",
               "BISECT_LOG", "rebase-merge", "rebase-apply")


def git(cwd, *args):
    return subprocess.run(
        ("git", "-c", "core.quotePath=false") + args,
        cwd=cwd,
        capture_output=True,
        text=True,
        timeout=8,
    )


def is_git_commit(command):
    """True only for a real `git commit`, not for a command mentioning one."""
    for segment in re.split(r"&&|\|\||[;|\n]", command):
        try:
            tokens = shlex.split(segment)
        except ValueError:
            continue
        if not tokens or os.path.basename(tokens[0]) != "git":
            continue
        i = 1
        while i < len(tokens):
            token = tokens[i]
            if token in GIT_VALUE_OPTS:
                i += 2
            elif token.startswith("-"):
                i += 1
            else:
                if token == "commit":
                    return True
                break
    return False


def strip_fences(text):
    return FENCE.sub("", text)


def changed_paths(cwd, base):
    """path -> (status letter, pathspecs to diff), for everything under docs/issues/."""
    out = {}
    r = git(cwd, "diff", base, "--name-status", "--", "docs/issues")
    for line in r.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        status, path = parts[0][0], parts[-1]
        if status in ("R", "C"):
            # a move carries its old content: diff both ends, judge as modified
            out[path] = ("M", [path, parts[1]])
        else:
            out[path] = (status, [path])
    r = git(cwd, "ls-files", "--others", "--exclude-standard", "docs/issues")
    for path in r.stdout.splitlines():
        if path.strip():
            out[path.strip()] = ("A", [path.strip()])
    return out


def read(cwd, path):
    full = os.path.join(cwd, path)
    if not os.path.isfile(full):
        return ""
    with open(full, encoding="utf-8", errors="replace") as fh:
        return strip_fences(fh.read())


def added_lines(cwd, base, specs, status, body):
    if status == "A":
        return body.splitlines()
    args = ["diff", base, "--"] + [":(literal)" + s for s in specs]
    r = git(cwd, *args)
    added = "\n".join(
        line[1:]
        for line in r.stdout.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )
    return strip_fences(added).splitlines()


def count(pattern, body):
    return len(re.findall(pattern, body, re.M))


def status_value(body):
    found = STATUS.search(body)
    if not found:
        return "missing"
    return found.group(1).strip() or "empty"


def check(cwd, base, path, status, specs):
    """Return the problems this one file carries."""
    if status == "D":
        return []
    body = read(cwd, path)
    if not body:
        return []
    added = added_lines(cwd, base, specs, status, body)
    problems = []

    if TICKET.match(path):
        # A — every finding carries a verdict before the commit
        for line in body.splitlines():
            if line.rstrip().endswith(SENTINEL):
                problems.append(
                    f"{path}: a finding still reads `{SENTINEL}`. Every finding "
                    "gets exactly one verdict before this commit "
                    '(hold-the-line, "The six verdicts").'
                )
                break

        # B — a build commit's ticket has cleared the bar
        adds_bar = any(l.startswith("## Bar,") for l in added)
        adds_review = any(l.startswith("## Review findings,") for l in added)
        if adds_bar and not adds_review:
            if count(r"^## Resolution", body) < 1:
                problems.append(
                    f"{path}: `## Bar,` added with no `## Resolution` block "
                    "(standing-bar, per-ticket line 6; build-slice §6)."
                )
            if count(r"^## Handoff", body):
                problems.append(
                    f"{path}: `## Bar,` added while a `## Handoff` block "
                    "stands (standing-bar, per-ticket line 6; build-slice §6)."
                )
            if count(r"^- \[ \]", body):
                problems.append(
                    f"{path}: `## Bar,` added with an unticked `- [ ]` "
                    "criterion (standing-bar, per-ticket line 1)."
                )

        # C — `resolved` is written by the review, in the review's commit
        if status == "M":
            adds_resolved = any(
                re.match(r"^\*\*Status:\*\*[ \t]*resolved\b", l) for l in added
            )
            if adds_resolved and not adds_review:
                problems.append(
                    f"{path}: `**Status:** resolved` added outside a review "
                    "commit. Only a closing review cycle writes that value "
                    '(review-pass, "Closing the cycle").'
                )

    if SPEC.match(path) and any(l.startswith("## Close,") for l in added):
        folder = os.path.dirname(path)
        for name in sorted(os.listdir(os.path.join(cwd, folder))):
            if not NAME_ONLY.match(name):
                continue
            value = status_value(read(cwd, os.path.join(folder, name)))
            first = value.split()[0].strip("*_`.,").lower() if value else ""
            if first not in CLOSED_STATUS:
                problems.append(
                    f"{folder}/{name}: `**Status:** {value}` while `## Close,` "
                    "is added to the spec. Every ticket is `resolved`, "
                    "`declined`, or moved out first (close-effort, walk 3)."
                )
    return problems


def main():
    payload = json.load(sys.stdin)
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not isinstance(command, str) or not is_git_commit(command):
        return 0

    # git prints paths relative to the repo root, so run everything from there:
    # a commit made from a subdirectory would otherwise check
    # `<subdir>/docs/issues` and read every path against the wrong prefix.
    started_in = payload.get("cwd") or os.getcwd()
    root = git(started_in, "rev-parse", "--show-toplevel")
    if root.returncode != 0 or not root.stdout.strip():
        return 0
    cwd = root.stdout.strip()

    # A merge, rebase, cherry-pick or revert commit carries the other side's
    # work as "added" lines. Nothing here can judge it, so stay out of the way.
    git_dir = git(cwd, "rev-parse", "--absolute-git-dir").stdout.strip()
    if git_dir and any(os.path.exists(os.path.join(git_dir, p)) for p in IN_PROGRESS):
        return 0

    base = "HEAD"
    if git(cwd, "rev-parse", "--verify", "HEAD").returncode != 0:
        base = git(cwd, "hash-object", "-t", "tree", "/dev/null").stdout.strip()
        if not base:
            return 0

    problems = []
    for path, (status, specs) in sorted(changed_paths(cwd, base).items()):
        try:
            problems += check(cwd, base, path, status, specs)
        except Exception as exc:  # one unreadable file must not void the rest
            print(f"plumbline guard-commit: {path} skipped ({exc})",
                  file=sys.stderr)
    if not problems:
        return 0
    for line in problems:
        print(line, file=sys.stderr)
    print(
        "Commit blocked by plumbline's commit guard. Fix the lines above, or "
        "commit outside this session.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # fail open: a hook bug must not block a commit
        print(f"plumbline guard-commit: skipped ({exc})", file=sys.stderr)
        sys.exit(0)
