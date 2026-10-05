---
name: prototype
description: Builds a throwaway prototype that answers one design question, keeps the answer and parks the code on its own branch. Use when a shape's open question is tagged PROTOTYPE, when write-spec has to answer one, or when the user wants to feel out a state model or logic, or see what a UI could look like, before it is built for real.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides
the shape, and the answer is the only part that ships.

Adapted from Matt Pocock's `prototype` skill
([mattpocock/skills](https://github.com/mattpocock/skills) @ `3216582`).

## The question, before any code

One sentence: what is being decided, and which answer would change the plan. In
this flow it is a line from the shape's `## Open questions, for the agent` that
ends `— PROTOTYPE`, quoted verbatim. A prototype that answers a neighbouring
question is pure waste, and nobody notices, because it still runs.

## Pick a branch

Identify which question is being answered from that sentence and the surrounding
code; ask only if neither decides it:

- **"Does this logic / state model hold?"** → [LOGIC.md](LOGIC.md). One
  shareable HTML file over a pure, liftable module, with free-play buttons and
  tabbed walkthroughs that push it through the cases that are hard to reason
  about on paper.
- **"What should this look like?"** → [UI.md](UI.md). Several radically
  different variations on one route, switchable via a URL search param and a
  floating bottom bar.

The two branches produce very different artifacts, so getting this wrong wastes
the whole prototype. If the question is genuinely ambiguous and the user isn't
reachable, default to whichever branch better matches the surrounding code (a
backend module → logic; a page or component → UI) and state the assumption at
the top of the prototype.

## Who judges

`shape-idea` already decided who answers what, and a prototype does not move
the line:

- **Logic: the agent, first.** Run every walkthrough yourself and read the
  state after each step (LOGIC.md §4). The answer is what the state did.
  Hand the file to the user only for a situation they alone can decide — put
  it to them as a concrete edge, "a refund after the invoice closed: allowed?",
  never as "does this reducer look right?".
- **UI: the user.** What the product looks like is their judgement. The agent's
  job is variants different enough for that judgement to mean something.

## Rules that apply to both

1. **Throwaway from day one, on its own git branch.** Before the first line,
   cut `prototype/<effort>-<slug>` from the current HEAD (`prototype/<slug>`
   outside an effort). On it, place the code next to the module or page it
   prototypes for, named so a casual reader sees it is a prototype; a throwaway
   route obeys the project's routing convention, never a new top-level
   structure.
2. **Trivial to run.** A UI prototype starts from one command in the project's
   task runner: `pnpm <name>`, `python <path>`, `bun <path>`. A logic demo is a
   single HTML file the user double-clicks.
3. **No persistence by default.** State lives in memory. Persistence is the
   thing a prototype would be *checking*, not something it depends on. If the
   question explicitly involves a database, hit a scratch DB or a local file
   with a clear "PROTOTYPE, wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes it
   runnable, no abstractions. The standing bar does not apply: a prototype is
   not a ticket, carries no seam, and merges nothing.
5. **Surface the state.** After every action (logic) or on every variant switch
   (UI), render the full relevant state so the change is visible.
6. **Capture it when done.**
   - Commit on the prototype branch, staging the prototype's files **by path**
     — never `git add -A`, or whatever the session was writing elsewhere rides
     along. The message states the question and the verdict.
   - Switch back to the branch you came from. **Nothing on the prototype branch
     merges**: the tickets build the decision properly, and may read the
     prototype from the branch (`git show <branch>:<path>`). Leave the branch;
     it is the primary source. Push it only when the operator says so.
   - Record the answer where its reader is. In an effort that is the spec's
     **Open questions, answered**, one line:
     `- <question> — PROTOTYPE: <verdict, and why>. Source: prototype/<effort>-<slug> @ <short sha>`.
     Outside an effort, the commit message and your final message carry it.

A prototype still waiting for its judge is an open question: the spec is not
done, and it is not "the walking skeleton will show" either — the skeleton
builds one design, it does not choose between several.

## In this flow

- **Gate 2, `write-spec`**, is the caller: its **Open questions, answered**
  section is where a `PROTOTYPE` question from the shape gets run and recorded.
- **Not the walking skeleton.** `cut-slices` says it in reverse: the skeleton is
  production code that stays; a prototype is thrown away. Never a ticket either
  — an open question carries no seam (`shape-idea`).
- **A surprise is a finding about the idea** — "wait, that shouldn't be
  possible". Before tickets exist, work it into the spec directly (the edge it
  settled goes under **Decided at the edges**), as `cold-read` findings are at
  gates 2 and 3. Once tickets exist, it goes to `hold-the-line` with a severity
  like any other finding.
