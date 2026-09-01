---
name: shape-idea
description: Interrogates an idea at product altitude before any spec exists. Use when starting a new feature or effort, when an idea is still fuzzy, when the user says 'shape this', 'grill me', 'stress-test this idea', when a waiting stub shape is picked up, or before writing any spec. Asks only what the user alone can answer, parks every technical unknown as agent work so the interview never drifts into implementation questions, and mints a stub shape for any sub-problem that turns out to be its own effort.
user-invocable: false
---

# Shape the idea

Ask at **product altitude**: the world outside the code — who, when, what
counts as working, what happens when it does not.

The user is the only source for that. Everything below it — which library,
which shape, which column, which order — the agent settles by reading,
prototyping, or trying. Asking the user is the expensive path, so it is spent
only where their judgement is the answer.

## Before the first question

A **stub shape** is a sub-problem an earlier interview split off, parked as
`docs/issues/<its-slug>/shape.md` — "A sub-problem is not a bucket" below
defines it and owns the rationale for the two greps quoted here. Run both
before the first question.

`grep -rn --include=shape.md '^\*\*Discovered while shaping:\*\*' docs/issues/`
walks every split end ever written, shaped or not. Read each line back
against the `shape.md` of the effort it names: each end must name the other,
and a missing shape end takes the `— split off: docs/issues/<its-slug>/`
bullet form. The repair lands in this edit — into the stub's own file when
the named effort already carries a `## Close,` block, because nothing reads
a closed effort's shape again. No output means no split was ever recorded; a
grep error means the folder is missing or unreadable — go look, never read
it as empty.

`grep -rn --include=shape.md '^\*\*Status:\*\* unshaped' docs/issues/` says
which of those ends still wait. If the idea being shaped matches a waiting
stub, that stub's folder is the effort, and its `**Why it exists:**` and
`**What is known:**` lines are the interview's opening input — beliefs to
state, not questions to re-ask. The finished `shape.md` replaces the stub in
the same folder and keeps every `**Discovered while shaping:**` line
verbatim — the first grep above is what still finds them after retirement —
so the replacement leaves the Status grep without cutting an end. If the
idea matches no stub, name the waiting ones in a single line and move on —
a stub nobody restates is how a discovery rots.

## The three buckets

Every question that arises in this phase goes into exactly one:

| Bucket | Who answers | How |
|---|---|---|
| **Product** | the user | ask now |
| **Fact** | the agent | read the source, the docs, the config |
| **Craft** | the agent | research, a prototype, or the walking skeleton |

A number with consequences the user owns is **Product**, not Craft, even when it
looks technical. "What weight does a cached read carry?" and "how long do we
keep this?" set what the product does and what it costs. The guardrail below is
about how something is built, never about what it is worth.

The third bucket is the one usually missing, and its absence is why interviews
drift downward: an implementation choice is not a look-uppable fact, so with
only two buckets it falls to the user by default. It belongs to **Craft**.
Park it and keep asking at altitude.

## What to ask

**Who and when.** Who uses this, in what situation, and what were they doing
one minute earlier? What do they do with the result one minute later?

**Working.** How will you know this worked? Name the observation you would
make, not the metric.

**The worst wrong answer.** What is the most damaging thing this can
confidently get wrong, and who eats it?

**Today.** What do people do instead right now, and what is wrong with it?

**The edges that decide.** Put two concrete situations from the boundary of the
feature to the user and ask what should happen in each. "A customer has two
accounts on the same email — what does the report show?" Concrete beats
abstract: an edge case answers a design question the abstract version cannot.

**Not this.** Name three things someone could reasonably expect this to do that
it will not do. Get each confirmed.

**Real volume.** How many, how often, how big, how old? This decides whether
the idea is one effort or three, which is the only sizing question the user can
answer.

## How to ask

**One at a time, and follow the vague word.** Ask one question per message.
When an answer carries "usually",
"should probably", "some kind of", "and stuff" — quote that word back. It is
the next question, and it is always better than the one you had queued.

**State beliefs, don't queue questions.** When you have a belief, write it down
as a statement and ask for a correction. A wrong statement gets corrected
faster than an open question gets answered.

**Let the agent answer craft questions in the answer itself.** If you would
have asked "should this be async?", write "the walking skeleton will show us"
into Open Questions and move on.

Guardrail, because this one failure is worth naming once: a question about a
library, a schema, a field name, a file location, or the internal structure of
the code is **Craft**. It is parked, never asked. If the answer changes what the
product does or what it costs, it was Product all along.

## A sub-problem is not a bucket

Sometimes the interview surfaces work, not a question: a problem that is real,
that the user confirms matters, and that this feature will not solve. That is
not Product, Fact or Craft — it is a different effort trying to be born in the
wrong interview.

Write it into `interview.md` the moment it appears, with the user's words that
raised it — the running record is what survives a session that dies
mid-interview. Mint it when the interview ends, whichever way it ends — the
three-round too-big split included. Not as a ticket: tickets belong to
efforts, and this one has no spec to cut from. It becomes a **stub shape**
at `docs/issues/<its-slug>/shape.md`, where `<its-slug>` is the kebab-case
name of the problem — the same convention as `<effort>`, the shaping
effort's own slug. It holds only what this interview actually established:

```markdown
# <Problem> — stub shape

**Status:** unshaped — needs its own shape-idea interview
**Discovered while shaping:** <discovering effort>, <date>
**Why it exists:** <the user's words, from interview.md>
**What is known:** <bullets — confirmed facts only, no guesses>
```

If `docs/issues/<its-slug>/` already exists — a live effort or a stub an
earlier interview minted — write nothing over it: point this shape's
`— split off: docs/issues/<its-slug>/` bullet at the existing folder and
append a second `**Discovered while shaping:** <discovering effort>, <date>`
line to its `shape.md` — the key the pickup read walks first, so the second
discoverer's end is read even on a live folder the Status grep never
returns. A blind mint over a live folder is an overwrite arriving exactly
where nothing would review it.

The originating `shape.md` names it under "Not this, deliberately" as
`- <bullet> — split off: docs/issues/<its-slug>/`, so the split has two
ends: the stub says where it came from, the shape says where it went. Find
every waiting stub with
`grep -rn --include=shape.md '^\*\*Status:\*\* unshaped' docs/issues/` — the
line anchor drops inline quotes of the value, `--include=shape.md` drops the
fenced template pastes that land in tickets and findings blocks, and no
`-s`: a grep error is "looked in the wrong place or was refused", never
"there are no stubs".

Do not shape it now — one interview, one idea; the stub's own interview
happens when someone picks it up. And do not skip the stub because the
problem feels small: `hold-the-line`'s verdicts begin where tickets exist,
so nothing downstream catches what shaping dropped. If the sub-problem must
be done before *this* feature counts as finished, it is not a stub — it is
an In scope bullet ending `— must hold before close`. `write-spec` turns
every bullet carrying that tag into an exit criterion, and `close-effort`
forces each one to be met or moved to a named successor, never skipped.

## When to stop

> Done when you can fill every section of the output file **using the user's
> own words**, and you can predict how they would answer the next three
> questions you would ask.

That test is checkable, and it is put to the user, not filed: write the three
questions and your predicted answers into `interview.md`, then state the
predictions to the user as beliefs (per "State beliefs, don't queue
questions") in the message that ends the last round. Confirmed predictions end
the interview; a corrected one means the shape was not done — work the
correction in before stopping. A prediction you were unwilling to write down
was not a prediction. It is not "every branch visited" and not "nothing
left assumed" — those bounds have no floor, so they drive the interview down
into implementation.

**Three rounds.** A round is one pass over the headings in "What to ask",
asked one question at a time, and it ends when you state your current beliefs
back and the user confirms or corrects them. Number each round in
`interview.md`. If the shape is not clear after three, the effort is too big.
Say so and shape one part of it instead — the parts not shaped are
sub-problems now, and each takes a stub shape like any other.

**Parked unknowns do not block done.** A parked question is a finished
question.

## Output

Two files under `docs/issues/<effort>/`, where `<effort>` is the feature's slug.
This folder is the effort, and every later gate writes into it under that same
name. A sub-problem recorded in `interview.md` adds its stub shape under its
own slug, minted in the same session that writes `shape.md`: a newly minted
sub-problem adds one file; one whose folder already existed adds only the
appended line.

`interview.md` is the raw exchange, by round: the questions asked, the answers
given, the vague words chased, and the three predicted answers that ended it.
It is the evidence for every quote in the shape; without it the user's own
words are reconstructed from memory a session later.

`shape.md` is the summary below, and it is what everything downstream reads.

```markdown
# <Feature> — shape

**For whom, when:** <one paragraph>
**Working looks like:** <the observation, not the metric>
**Worst wrong answer:** <one sentence, user-confirmed>
**Discovered while shaping:** <discovering effort>, <date> <only if this
shape replaced a stub or a later interview split into this folder — carried
verbatim, one line per discoverer>

## In scope
- <bullet>
- <bullet> — must hold before close <only if a sub-problem gates this
  effort's close>

## Not this, deliberately
- <bullet> — <why>
- <bullet> — split off: docs/issues/<its-slug>/

## Decided at the edges
- <situation> -> <what happens>

## Open questions, for the agent
- <unknown> — RESEARCH | PROTOTYPE | SKELETON WILL SHOW
```

**Under 600 words.** Longer means the effort is too big — split it before
specifying. The number is there so it can be checked; "one page" cannot.

The Open Questions are agent work and the user never sees them again as
questions. They are answered **before or inside** the walking skeleton, never as
tickets of their own: a research question produces no value anything reads, so
it satisfies neither `cut-slices` Rule 2 nor Rule 3. Answer it, record the answer
in the spec, and let the first ticket built stay the walking skeleton.
