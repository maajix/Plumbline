#!/usr/bin/env python3
"""Check Plumbline's four commit invariants against one staged tree.

This is a guard for the documented Claude commit workflow, not a shell security
boundary. Stage in a separate call, then use a simple git/rtk commit command.
Expected command/Git errors block; unexpected internal errors remain fail-open.
"""

import difflib
import json
import os
import re
import shlex
import subprocess
import sys

TICKET_NAME = r"\d\d[a-z]?(?:[-_. ][^/]*)?\.md"
TICKET = re.compile(r"^docs/issues/[^/]+/" + TICKET_NAME + r"$")
SPEC = re.compile(r"^docs/issues/[^/]+/spec\.md$")
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
SEPARATORS = set(";&|\n")
COMMIT_FLAGS = {"--allow-empty", "--allow-empty-message", "--no-verify",
                "--no-gpg-sign", "--signoff", "-s", "--quiet", "-q", "--verbose", "-v"}
COMMIT_VALUES = {"-m", "--message", "-F", "--file", "--author", "--date"}
HELP = ("Stage in a separate Bash call, then run git [-C <repo>] commit -m <message> "
        "or -F <file> (rtk git / rtk proxy git and plain env are supported). "
        "Do not combine commands, use substitutions, alternate Git environments, "
        "file arguments, or options that change the staged snapshot.")


class GuardError(Exception):
    """An expected failure that must not be mistaken for a clean check."""


def git(cwd, *args, optional=False):
    try:
        result = subprocess.run(
            ("git", "-c", "core.quotePath=false") + args,
            cwd=cwd, capture_output=True, text=True, timeout=8,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise GuardError(f"Git check failed: {exc}") from exc
    if result.returncode and not optional:
        raise GuardError(result.stderr.strip() or "Git check failed")
    return result


def commit_prefix(tokens, start):
    """Recognize only direct git commands and the documented wrappers."""
    i = start
    unsafe = False
    while i < len(tokens):
        name = os.path.basename(tokens[i])
        if re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", tokens[i]):
            unsafe = True
            i += 1
        elif name == "env":
            i += 1
            while i < len(tokens) and tokens[i].startswith("-"):
                option = tokens[i]
                unsafe = True
                i += 2 if option in ("-u", "--unset", "-C", "--chdir") else 1
        elif name == "rtk":
            i += 1
            if i < len(tokens) and tokens[i] == "proxy":
                i += 1
        else:
            break
    if i >= len(tokens) or os.path.basename(tokens[i]) != "git":
        return None
    i += 1
    directories = []
    while i < len(tokens) and tokens[i].startswith("-"):
        option = tokens[i]
        if option in GIT_VALUE_OPTS:
            if i + 1 >= len(tokens):
                return None
            if option == "-C":
                directories.append(tokens[i + 1])
            else:
                unsafe = True
            i += 2
        elif option.startswith("-C") and len(option) > 2:
            directories.append(option[2:])
            i += 1
        else:
            unsafe = True
            i += 1
    if i < len(tokens) and tokens[i] == "commit":
        return i + 1, directories, unsafe
    return None


def command_repo(command, cwd):
    # Keep quoted newlines intact; never split raw shell text with a regex.
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lexer.whitespace = " \t\r"
    lexer.commenters = ""
    try:
        tokens = list(lexer)
    except ValueError:
        # A malformed quoted command cannot execute as a normal shell command.
        return None
    while tokens and tokens[0] and not tokens[0].strip("\n"):
        tokens.pop(0)
    while tokens and tokens[-1] and not tokens[-1].strip("\n"):
        tokens.pop()
    # shlex groups adjacent punctuation, including mixed ';\n' separators.
    starts = [0] + [i + 1 for i, token in enumerate(tokens)
                    if token and set(token) <= SEPARATORS]
    for start in starts:
        found = commit_prefix(tokens, start)
        if found is None:
            continue
        i, directories, unsafe = found
        if start or unsafe or "`" in command or "$" in command:
            raise GuardError(HELP)
        # A small allow-list makes every accepted invocation commit the index.
        # ponytail: arbitrary shell scripts/aliases are outside this guard;
        # use a native Git hook if enforcement outside this workflow is needed.
        while i < len(tokens):
            option = tokens[i]
            if option in COMMIT_FLAGS:
                i += 1
            elif option in COMMIT_VALUES and i + 1 < len(tokens):
                i += 2
            elif any(option.startswith(flag + "=") for flag in COMMIT_VALUES if flag.startswith("--")):
                i += 1
            elif option.startswith(("-m", "-F")) and len(option) > 2:
                i += 1
            else:
                raise GuardError(HELP)
        for directory in directories:
            cwd = os.path.abspath(os.path.join(cwd, directory))
        return cwd
    return None


def strip_fences(text):
    return FENCE.sub("", text)


def tree_files(cwd, tree):
    """Read blobs under docs/issues/; directories and symlinks are not tickets."""
    result = {}
    listing = git(cwd, "ls-tree", "-r", "-z", tree, "--", "docs/issues").stdout
    for entry in listing.split("\0"):
        if not entry:
            continue
        metadata, path = entry.split("\t", 1)
        mode, kind, oid = metadata.split()
        if mode not in ("100644", "100755") or kind != "blob":
            continue
        if TICKET.match(path) or SPEC.match(path):
            result[path] = strip_fences(git(cwd, "cat-file", "blob", oid).stdout)
    return result


def changed_paths(cwd, base, tree):
    # NUL delimiters preserve spaces, tabs and glob characters in filenames.
    entries = git(cwd, "diff", "--name-status", "-z", "-M", base, tree,
                  "--", "docs/issues").stdout.split("\0")
    result = {}
    i = 0
    while i < len(entries) and entries[i]:
        status, path = entries[i], entries[i + 1]
        i += 2
        if status.startswith(("R", "C")):
            result[entries[i]] = path
            i += 1
        elif not status.startswith("D"):
            result[path] = path
    return result


def count(pattern, body):
    return len(re.findall(pattern, body, re.M))


def status_value(body):
    found = STATUS.search(body)
    return (found.group(1).strip() or "empty") if found else "missing"


def check(path, before, body, files):
    # Strip fences in both complete snapshots, not in an isolated diff hunk.
    added = [line[2:] for line in difflib.ndiff(before.splitlines(), body.splitlines())
             if line.startswith("+ ")]
    problems = []
    if TICKET.match(path):
        if any(line.rstrip().endswith(SENTINEL) for line in body.splitlines()):
            problems.append(f"{path}: pending finding ({SENTINEL}); give it a verdict (hold-the-line).")
        adds_bar = any(line.startswith("## Bar,") for line in added)
        adds_review = any(line.startswith("## Review findings,") for line in added)
        if adds_bar and not adds_review:
            if not count(r"^## Resolution", body):
                problems.append(f"{path}: Bar added without Resolution (standing-bar, line 6).")
            if count(r"^## Handoff", body):
                problems.append(f"{path}: Bar added with a Handoff (standing-bar, line 6).")
            if count(r"^- \[ \]", body):
                problems.append(f"{path}: Bar added with an unticked criterion (standing-bar, line 1).")
        if before and any(re.match(r"^\*\*Status:\*\*[ \t]*resolved\b", line) for line in added):
            if not adds_review:
                problems.append(f"{path}: resolved outside a closing review (review-pass).")
    if SPEC.match(path) and any(line.startswith("## Close,") for line in added):
        folder = os.path.dirname(path)
        for ticket, content in files.items():
            if TICKET.match(ticket) and os.path.dirname(ticket) == folder:
                value = status_value(content)
                first = value.split()[0].strip("*_`.,").lower()
                if first not in CLOSED_STATUS:
                    problems.append(f"{ticket}: Status {value} while closing (close-effort, walk 3).")
    return problems


def main():
    payload = json.load(sys.stdin)
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not isinstance(command, str):
        return 0
    cwd = command_repo(command, payload.get("cwd") or os.getcwd())
    if cwd is None:
        return 0
    # Alternate inherited Git contexts cannot be reconstructed from cwd alone.
    if any(os.environ.get(key) for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE",
                                           "GIT_COMMON_DIR", "GIT_CONFIG_COUNT")):
        raise GuardError(HELP)
    cwd = git(cwd, "rev-parse", "--show-toplevel").stdout.strip()
    git_dir = git(cwd, "rev-parse", "--absolute-git-dir").stdout.strip()
    if any(os.path.exists(os.path.join(git_dir, name)) for name in IN_PROGRESS):
        return 0
    head = git(cwd, "rev-parse", "--verify", "HEAD", optional=True)
    base = head.stdout.strip() if head.returncode == 0 else git(
        cwd, "hash-object", "-t", "tree", "/dev/null").stdout.strip()
    tree = git(cwd, "write-tree").stdout.strip()
    paths = changed_paths(cwd, base, tree)
    if not paths:
        return 0
    before, after = tree_files(cwd, base), tree_files(cwd, tree)
    problems = []
    for path, old_path in paths.items():
        if path in after:
            problems.extend(check(path, before.get(old_path, ""), after[path], after))
    if problems:
        print("\n".join(problems), file=sys.stderr)
        print("Commit blocked by plumbline. Fix and stage the listed files.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except GuardError as exc:
        print(f"plumbline guard-commit: {exc}", file=sys.stderr)
        sys.exit(2)
    except Exception as exc:
        print(f"plumbline guard-commit: skipped ({exc})", file=sys.stderr)
        sys.exit(0)
