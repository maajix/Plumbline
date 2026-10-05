# Logic prototype

A single, self-contained HTML file (a **shareable demo**) that lets anyone drive
a state model by clicking buttons. Use this when the question is about
**business logic, state transitions, or data shape**: the kind of thing that
looks reasonable on paper but only feels wrong once you push it through real
cases.

Because it's one file with nothing to install, it can be handed to a
non-developer (a designer, a PM, a domain expert) to feel the model for
themselves. So it speaks their language, not the code's.

## When this is the right shape

- "I'm not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API should look like before writing it."
- Anything where someone wants to **press buttons and watch state change**.

If the question is "what should this look like," this is the wrong branch. Use
[UI.md](UI.md).

## Process

### 1. State the question

The sentence from [SKILL.md](SKILL.md), at the top of the demo in a visible
intro, not just a comment, so it can be checked later by whoever opens the file.

### 2. Isolate the logic in a portable module

Put the logic that answers the question in its own `<script id="model">` block,
written as a small, pure module that could be lifted into the real codebase
later. The page around it is throwaway; this module isn't.

The right shape depends on the question:

- **A pure reducer**: `(state, action) => state`. Good when actions are discrete
  events and state is a single value.
- **A state machine**: explicit states and transitions. Good when "which actions
  are even legal right now" is part of the question.
- **A small set of pure functions** over a plain data type. Good when there's no
  implicit current state, just transformations.
- **A class or module with a clear method surface** when the logic genuinely
  owns ongoing internal state.

Pick whichever shape best fits the question, *not* whichever is easiest to wire
to a page. Keep it pure: no DOM, no `document`, no button handlers reaching
inside it. The page calls into it; nothing flows the other direction.

The **scenarios** live in the same block, as plain data: each one a name, a
plain-language description, and an ordered list of actions. The page renders
them as walkthroughs (§3); the agent runs them headless (§4). One list, two
readers, so they cannot drift apart.

### 3. Build the shareable HTML file

One file, plain HTML/CSS/JS: no framework, no bundler, no server, everything
inline so it opens by double-click and survives being emailed around.

Every label is in **domain language**, not code: buttons and state read like
the business, not the reducer. Explain in plain words what's happening.

Lay it out with a clean hierarchy, top to bottom:

1. **Title and one-line explanation** of what this demo lets you explore (the
   question from step 1).
2. **Current state**: the full relevant state, rendered as a readable panel
   (labelled fields, not a raw JSON dump), re-rendered after every click. Where
   it helps a non-developer follow, call out what just changed.
3. **Free-play buttons**: one button per action, always available, so anyone
   can poke at the model in any order.
4. **Guided walkthroughs**: one tab per scenario. Each tab holds the scenario's
   description (the situation it sets up and what to watch for) and underneath
   it, the ordered **buttons to press**. Each step is a real button: clicking it
   performs that action and moves to the next step. Starting a walkthrough
   resets to a known initial state so it runs the same way every time.

Choose scenarios that demonstrate the awkward cases: the happy path, a tricky
edge case, an attempt at something that should be illegal.

Keep it beautiful but restrained: clean typography, generous spacing, one accent
colour. No animations, nothing that competes with the state and the buttons.

### 4. Run it yourself first

The model block references no browser by rule, so it runs outside one: copy it
out and run it with the project's JS runtime (`node`, `bun`, `deno`), feeding it
each scenario and printing the state after every step. That printout is the
evidence the answer cites. It asserts nothing, so it is not a test suite — it
shows.

Read it for the moments that matter: a state that "shouldn't be possible", a
legal action that was refused, a result that differs from what the question
assumed. Those are the bugs in the *idea*, which is the whole point.

### 5. Hand over what needs a judge

If the printout settles the question, it is answered — no handover. If it lands
on a situation only the user can decide ([SKILL.md](SKILL.md), "Who judges"),
send them the file or open it, name the tab that shows the situation, and ask
the concrete edge. If they want new actions or a new scenario, add them to the
model block, re-run §4. Prototypes evolve.

### 6. Capture the answer and the prototype

Capture both the way [SKILL.md](SKILL.md) rule 6 describes. The validated
module stays on the prototype branch with its shell; the ticket that builds the
real thing lifts it from there and gives it the tests the prototype skipped.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
  The headless run in §4 prints; it does not assert.
- **Don't wire it to the real database.** Use in-memory state unless the
  question is specifically about persistence.
- **Don't generalise.** No "what if we wanted to support X later." The prototype
  answers one question.
- **Don't blur the logic and the page together.** If the model block references
  the DOM, `document`, or button handlers, it is no longer liftable, and §4
  cannot run it.
- **Don't reach for a framework, bundler, or server.** One file the recipient
  double-clicks; a React app or a dev server defeats "shareable".
- **Don't ship the HTML shell.** The page is optimised for being clicked
  through by hand. The model behind it is the bit worth keeping.
