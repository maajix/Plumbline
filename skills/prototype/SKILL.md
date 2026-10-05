---
name: prototype
description: Builds a throwaway prototype that answers one design question, keeps the answer and parks the code on its own branch. Use when a shape's open question is tagged PROTOTYPE, when write-spec has to answer one, or when the user wants to feel out a state model or logic, or see what a UI could look like, before it is built for real.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides
the shape, and the answer is the only part that reaches the main branch as is.

Adapted from Matt Pocock's `prototype` skill
([mattpocock/skills](https://github.com/mattpocock/skills) @ `3216582`).

## The question, before any code

One sentence: what is being decided, and which answer would change the plan. In
this flow it is a line from the shape's `## Open questions, for the agent` that
ends `— PROTOTYPE`, quoted verbatim. A prototype that answers a neighbouring
question is pure waste, and nobody notices, because it still runs.

## Pick a branch

- **"Does this logic / state model hold?"** → [LOGIC.md](LOGIC.md). One
  shareable HTML file over a pure, liftable module, with free-play buttons and
  tabbed walkthroughs that push it through the cases that are hard to reason
  about on paper.
- **"What should this look like?"** → [UI.md](UI.md). Several radically
  different variations on one route, switchable via a URL search param and a
  floating bottom bar. **Outside an effort only** — see "Who judges".

Inside an effort the branch is always logic. Outside one, identify it from the
question and the surrounding code; ask only if neither decides it. If the user
isn't reachable, default to whichever branch better matches the surrounding
code (a backend module → logic; a page or component → UI) and state the
assumption at the top of the prototype.

## Who judges

- **Inside an effort, the agent.** A `PROTOTYPE` question is Craft
  (`shape-idea`), so the user never sees it as a question. Drive every scenario
  yourself (LOGIC.md §4); the answer is what the state did. A scenario that
  lands on a situation whose answer changes what the product does was Product
  all along (`shape-idea`'s guardrail): put that one situation to the operator
  as a concrete edge — "a refund after the invoice closed: allowed?", never
  "does this reducer look right?" — and record the answer under the spec's
  **Decided at the edges**. A `PROTOTYPE` question about how something *looks*
  was mis-parked the same way (`shape-idea`'s guardrail names it): no prototype
  runs inside the effort. Put it to the operator as one question — they may
  answer it by running this skill standalone — and record their answer under
  **Decided at the edges** too.
- **Outside an effort, the user.** Called directly, both branches are open: the
  user picks among UI variants, and gets a logic demo after the agent's own run.

## Rules that apply to both

1. **Throwaway from day one, in its own worktree.** Before the first line,
   give it branch `prototype/<effort>-<slug>` in a worktree beside the repo,
   `<slug>` being the question's kebab-case name (`prototype/<slug>` outside an
   effort): `git worktree add -b <branch> ../<repo>-<branch-with-dashes>`, or
   with `--orphan` added when the repo has no commit yet. The session's own
   working tree is never switched, so the shape and spec files still
   uncommitted at gate 2 stay exactly where they are. In the worktree, place
   the code next to the code it prototypes for, or where that code would live,
   named so a casual reader sees it is a prototype; a throwaway route obeys the
   project's routing convention, never a new top-level structure.
2. **Trivial to run.** A UI prototype starts with one command — a task-runner
   script (`pnpm <name>`) or a direct `bun <path>`, `python <path>` — once the
   worktree has its dependencies installed. A logic demo is a single HTML file
   the user double-clicks.
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
   - Commit in the worktree, staging **by path** every file the prototype
     added or edited — a manifest it touched (`package.json` for a new script)
     included, `git add -A` never. Commit the way
     `${CLAUDE_PLUGIN_ROOT}/references/ticket-lifecycle.md` "Every commit"
     says; a message quoting the question with backticks or `$` needs `-F`. The
     message states the question and the verdict.
   - Once the judge has seen it, remove the worktree
     (`git worktree remove <path>`, which refuses while uncommitted files
     remain — commit them or delete them there). The branch keeps everything.
   - **Nothing on the prototype branch merges.** Tickets build the decision
     properly and may read the prototype from the branch
     (`git show <branch>:<path>`). Leave the branch; it is the primary source.
   - Record the answer where its reader is. Inside an effort that is the spec's
     **Open questions, answered**, one line, the question without its
     `— PROTOTYPE` tag:
     `- <question> — PROTOTYPE: <verdict, and why>. Source: prototype/<effort>-<slug> @ <short sha>, <main file>`.
     `cut-slices` quotes that line into the `## Why` of every ticket that
     builds on it, which is how the builder finds the prototype. Outside an
     effort, the commit message and your final message carry it.
   - Until the branch is pushed, that `Source:` resolves only in this clone.
     Pushing is the operator's call; ask before the spec leaves this clone.

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
