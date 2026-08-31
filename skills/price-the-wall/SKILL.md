---
name: price-the-wall
description: Prices a constraint before anyone designs around it. Use when a wall appears mid-task - a limitation, an error that says something cannot be done, or a capability note claiming it - and while writing a doc, spec, playbook or corpus another agent will execute.
---

# Price the wall

A limitation you discover is a **finding**, not a premise. The default failure
is to document the wall, design around it, and ship an artifact that describes
what it cannot do. Run this the moment a wall appears, before it enters any
card, note or plan.

For the prose mechanics of agent-facing documents use `writing-for-agents` if it
is installed; it is not part of this plugin. This skill asks whether the content
is *true and executable*, not how it is shaped.

## The four lines

Every line names its evidence. A line reading "unknown" means the investigation
is still running, and that is the stop condition.

```
WALL    — the enforcing file:line, read in source THIS session.
PRICE   — the files, the migration and the tests that removing it costs,
          and which of those already exist.
PURPOSE — what the deliverable is for, named; and whether the workaround
          still serves it.
RULE    — the repo's ordering rule that decides this, or "none".
```

- **WALL.** A wall is a claim about an **interface** — this prevents that — so
  read **both ends**: what the sender emits and what the receiver enforces. One
  end read is a guess with a line number on it. A `file:line` is right here and
  nowhere else in this flow: the wall is read in this session, not cited across
  tickets. `cut-slices` cites symbols because its citations must survive later
  edits; a wall line is evidence for today.
- **PRICE.** First ask whether it is **already built**: grep the name the fix
  would have, not the name of the thing that is broken. The column, hook or
  capability it needs is often already there, which routinely makes the
  root-cause fix *smaller* than the workaround.
- **RULE.** *Schema before callers*, *the store before its reader*. Apply it at
  the wall, not in the retro.

Before writing "already built" or "one line", walk the **exposure chain** (see
`cold-read`): a capability that exists is not a capability that is reachable.
Name the hops in the artifact — a step that names one hop is a step that will be
implemented at one hop.

Then the decision goes **to the operator, with the price**, and the priced wall
goes to `hold-the-line` as a finding with a severity. A ticket is one of its six
verdicts, not the default: a wall that blocks the current ticket is **TICKET**
by that skill's first test, a wall the operator declines is **DECLINE** in
writing, and a wall this session goes through is **NOW**. A wall written into a
capability note is the decision to keep it, made silently.

## When the artifact is executed by an agent

Playbooks, runbooks, tool contracts, spec corpora — read literally, with no
missing capability improvised.

- Every step names **the verb that performs it** and **the writer that records
  the result**. A step with neither is prose.
- A step the running system can **grade** is a procedure. One it cannot grade is
  a lead, labelled as one — after you have priced making it gradable.
- Check the two surfaces match: what the agent may **send**, and what the system
  may **replay or verify**. They diverge quietly, and a technique that is
  performable but unprovable is the classic gap.
- Count before shipping: **"N of M steps cannot be graded."** That number
  decides whether the artifact ships or the capability lands first.

**The plan you are writing is one of these.** A spec handed to a fresh session
is executed literally, so write it to the bar `cold-read` will hold it to:

- Every number carries the command that produced it, run over the **whole
  corpus**. A number read off row zero is a sample wearing a total's clothes.
- Every `file:line` was opened this session, not only the one on the WALL line.
- A rule over N cases is checked against the **distribution** of those N.
- A validator you specify is run against the artifact the system **really
  emits**, as a positive corpus.

Then **cold-read** it before calling it ready.
