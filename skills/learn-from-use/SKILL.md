---
name: learn-from-use
description: "Turns what a session taught into a change to a skill or agent, after the user says yes. Use when the user corrects how a skill behaved ('that's not how it should work', 'next time do X', 'why did you do Y'), states a standing preference while a skill runs, repeats a procedure no skill covers, or says a learned skill or agent is no longer needed. Proposes exactly one change, asks, applies on yes, and records a no so the same proposal is never raised twice."
argument-hint: "[what was learned, or empty to take it from the session]"
---

# Learn from use

A skill is a procedure written before it ever ran. The session is where it
meets the user, and the user's corrections live in the chat — gone with the
context, so the skill runs the same way next time and earns the same
correction. This skill moves the correction into the file the next session
reads.

It can do three things: patch a skill or agent that exists, create one that is
missing, or remove one it created earlier. **It never writes without a yes**,
in any permission mode. The question in §5 is the gate, not a courtesy.

## 1. Is it a lesson

Three triggers, each a sentence the user said or a thing that happened:

- **A correction.** The user said the skill did it wrong and how it should be:
  "that's not how it should work", "next time do X", "why did you do Y".
- **A standing preference.** Stated while a skill was running and phrased as
  general: "always", "we never", "in this project we".
- **A working path found the hard way.** A skill step hit a dead end and the
  session found what works, with more than a few tool calls.

The test for all three: **would the same correction hold the next time that
skill runs, on a different task?** If not, it is an instruction for this task
and no file changes.

Not a lesson for this skill:

- a preference about the user in general — language, tone, commit format.
  That belongs in `CLAUDE.md` or memory; say so in one line and stop.
- a bug in the code being worked on.
- a correction the user has already declined (§2).

**A new skill or agent** is a lesson when no skill was active, the session
worked out a multi-step procedure that ran to a working end, and the user
signalled recurrence — "we do this every time", a third ask for the same
thing. Never write a skill from a procedure that did not actually run.

**A removal** is a lesson only for a file this skill created — it carries
`origin: learned` in its frontmatter — and only when the user says it is
wrong or unneeded, or its content was just folded into another skill.
Anything without that marker is proposed as an edit, never deleted.

## 2. Check the declined ledger

`~/.claude/learned/declined.md` holds every proposal the user turned down,
one line each:

```markdown
- build-slice: run the seam test before the unit tests
- new skill release-notes: draft notes from the merged PR titles
```

Read it before drafting. If a line names this target with this proposal, the
user has decided: say nothing, write nothing. The one exception is the user
asking for exactly that change now, in their own words — then remove the line
in the same edit that applies the change, and continue.

## 3. Find the file

Which skill owns the behaviour: the one whose instruction produced it. Grep
the skill for the step. If no step produced it and the behaviour came from the
model's defaults, the lesson still goes to the skill the user was using, as a
new rule in the step where it would have mattered.

Where it is editable:

| Listed as | Loaded from | Edit |
|---|---|---|
| `name`, project skill | `.claude/skills/<name>/SKILL.md` in the repo | in place |
| `name`, user skill | `~/.claude/skills/<name>/SKILL.md` | in place, through the symlink if it is one |
| `plugin:name` | the install cache under `~/.claude/plugins/cache/`, replaced on every plugin update | the plugin's source checkout |

For a plugin skill, find the checkout:

```bash
find ~ -maxdepth 5 -path '*/.claude-plugin/plugin.json' -not -path '*/.claude/plugins/*' 2>/dev/null \
  | xargs grep -l '"name": "<plugin>"'
```

None found: ask for the path inside the §5 question. The change lands in the
checkout and reaches the running plugin only after a version bump and the
plugin update its README describes — say so in the report.

A new skill or agent never goes into a plugin; a plugin is a published thing
and a learned file belongs to the user. A procedure tied to one repo goes to
`.claude/skills/<name>/SKILL.md` or `.claude/agents/<name>.md`; a general one
to the same paths under `~/.claude/`.

## 4. Draft the change

**Lessons, not logs.** A rule plus one clause of why, in the step where it
applies — never an appended "Notes" or "Learnings" section, and never a date,
a quoted chat line or the story of how it was found. Delete whatever the new
rule contradicts in the same edit. Match the file's voice. If the trigger
changed, the `description` changes with it, because that line is what makes
the skill fire.

A correction that contradicts a rule the skill already carries is a decision,
not a patch: the question shows both rules and asks which one stands.

**A new skill** gets the frontmatter `name`, `description` in the words the
user used when they asked for it, and `origin: learned`; the body is the
steps as they ran, the pitfalls the session hit, and the check that showed it
worked. **A new agent** adds the tools it needs and copies the frontmatter
keys of an existing agent file in that directory; with none to copy, `name`
and `description` suffice.

## 5. Ask

One question before any write. It shows the target file and the change in
words: for a patch, the lines as they are and as they would be; for a new
file, its name, its description and its step list; for a removal, the path.
Three answers: **yes**, **no**, **change it**. Use `AskUserQuestion` where it
exists; otherwise ask in plain text and wait.

Nothing has been written at this point. A session that ends here has lost the
proposal and nothing else.

## 6. Apply, or record the no

**Yes.** Make the targeted edit — `Edit`, not a rewrite — or write the new
file, or `rm -r` the learned one. Then read the whole changed file once, top
to bottom, the way `cold-read` reads: a rule added in one section can
contradict a sentence three sections up, and the pass that added it is the
pass that does not see it. Fix what disagrees in the same pass. Then follow
the new rule for the rest of this session; the loaded copy is stale.

**No.** Append one line to the ledger, in the format §2 shows. Nothing else
changes, and the proposal is not raised again.

**Change it.** Redraft from the user's words and ask once more. A second
"change it" means the lesson is not understood: record nothing, say so.

## 7. Report

One line: what changed, in which file. A plugin skill adds the activation
steps; a no says the ledger carries it. The edit stays uncommitted in its
working tree — the user commits with their own conventions.
