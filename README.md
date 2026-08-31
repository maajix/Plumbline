# plumbline

**A plumb line is the oldest tool that proves something is truly vertical.**
This plugin is the same thing for agent-built features: it proves a slice runs
end to end instead of taking "cut vertically" on trust.

Eight gates, eleven skills, one rule that stops the backlog from growing once
per finished ticket. MIT.

```
idea ──▶ shape ──▶ spec ──▶ slice ──▶ build ──▶ prove ──▶ review ──▶ verdict ──▶ close
```

## The problem

Coding agents do not usually fail by writing bad code. They fail by building
correct components that were never made to meet.

Measured on a real, non-public codebase: 292 commits, **165 tickets in a single
effort**. Classifying every ticket titled like *"X is read by nothing"*,
*"nothing registers Y"*, *"Z has no caller"*:

| Ticket range | Wiring defects | Total | Share |
|---|---|---|---|
| 1–60 | 1 | 60 | 1.7 % |
| 61–110 | 4 | 50 | 8.0 % |
| 111–165 | 35 | 55 | **63.6 %** |

The agent made no gross mistakes. Every component was built exactly as its
ticket described. The tickets each named **one end of a seam**, so nobody was
ever forced to run producer and consumer together — until the first real run,
and then 35 defects arrived at once.

The second failure mode is the mirror image: every review finding becomes a new
ticket, because no rule says it shouldn't. A cross-check against a second
codebase that *did* have such a rule: three efforts, 24 / 7 / 1 tickets, no
explosion.

Full measurement with evidence: [`docs/DIAGNOSIS.md`](docs/DIAGNOSIS.md).

## What it does

Two mechanics carry the whole plugin:

**1. A ticket cannot be written without both ends of its seam.** `PRODUCES`,
`CONSUMED BY`, `CONSUMES`. An empty field is a visible error, and `seam-check`
greps the literal the ticket named. "Slice vertically" as a sentence already
exists elsewhere — it doesn't work, because nothing checks it.

**2. Every finding gets exactly one verdict.** Six options: fix now, add as an
acceptance criterion, send back to the ticket that shipped it, already owned by
an open ticket, cut a new ticket, or decline in writing. Severity decides: a
`blocker` never becomes a deferred criterion, and a new ticket is only allowed
when the work blocks something or needs a decision nobody in the effort owns.

## Install

```bash
# once
/plugin marketplace add maajix/Plumbline
/plugin install plumbline@plumbline
```

Local checkout instead:

```bash
claude plugin marketplace add /path/to/plumbline   # this folder
claude plugin install plumbline@plumbline
```

After editing the plugin, bump `version` in `.claude-plugin/plugin.json`, then:

```bash
claude plugin marketplace update plumbline
claude plugin update plumbline@plumbline
```

Without a version bump the plugin cache keeps the old copy.

No install needed to read it: every skill is a plain Markdown file under
`skills/`.

## The flow

| # | Command | Skill | Produces |
|---|---|---|---|
| 1 | `/shape` | `shape-idea` | `interview.md`, `shape.md` |
| 2 | `/spec` | `write-spec` | `spec.md` + cold read |
| 3 | `/slice` | `cut-slices` | `NN-*.md` tickets + cold read |
| 4 | `/build` | `build-slice` | code + seam test — one session per ticket |
| 5 | `/prove` | `seam-check` | seam report inside the ticket |
| 6 | `/review-pass` | `review-pass` | findings, with severity |
| 7 | `/verdict` | `hold-the-line` | one of six verdicts |
| 8 | `/close` | `close-effort` | the effort ends instead of drifting |

Every command is also reachable namespaced: `/plumbline:build`,
`/plumbline:review-pass`. The review command is deliberately called
`/review-pass`, because `/review` is already a built-in Claude Code command and
a plugin does not shadow it.

A ticket only becomes `resolved` once its review cycle closes: `build-slice`
takes it to `claimed` through build, bar and commit, and `review-pass` writes
`resolved` once no finding still carries `— verdict pending` and no verdict has
placed a criterion on it. Details: [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

All artefacts of an effort live under `docs/issues/<effort>/`: `interview.md`,
`shape.md`, `spec.md`, `live-inputs.md`, and the tickets as `NN-<slug>.md`.

## The four rules

**1. The first ticket built runs.** The thinnest end-to-end path, real, staying
in the code. If you cannot state it as "X goes in the front, Y comes out the
back", you have not understood the effort yet. This rule beats rule 4.

**2. Every ticket names both ends of its seam.** Including the last hop, which
is usually a human: `operator, via <command>` is a legal form and owes the same
proof as any other seam. A forward reference (`CONSUMED BY: ticket NN`) is a
debt with an address, redeemed by the session that lands NN.

**3. Every finding gets exactly one verdict.** Severity decides, not
convenience. Without this rule the backlog grows once per finished ticket.

**4. Everything is capped.** Three question rounds when shaping, 25 tickets per
effort, three review cycles. A cap that gets hit is a signal to split — never a
reason to raise the cap.

## Skills

The eight gates:

| Skill | What it is for |
|---|---|
| `shape-idea` | Product questions before the spec. Technical unknowns are parked as agent work, never asked of the user. |
| `write-spec` | A spec organised by paths that run, not components that exist. |
| `cut-slices` | Spec to tickets that run. Walking skeleton, seam fields, caps. |
| `build-slice` | One ticket, one session. Also covers the ticket turning out wrong mid-flight. |
| `seam-check` | Proves what a change writes is actually read, and what it reads is actually written. |
| `review-pass` | Four axes, cold read, capped at three cycles. |
| `hold-the-line` | A verdict for every finding. Six options, severity decides. |
| `close-effort` | Ends an effort instead of letting it drift. |

Three base skills the flow calls are **bundled**, so the plugin runs without
prerequisites. They are useful standalone:

| Skill | Where the flow needs it |
|---|---|
| `cold-read` | Gates 2, 3, 5, 6. Full pass, then findings, then repair. |
| `price-the-wall` | Gate 4, the moment "that's not possible" shows up. |
| `structured-debugging` | Gate 4, only when the cause is unknown. |

Shared quality bar for all of them:
[`references/standing-bar.md`](references/standing-bar.md).

## When not to use it

Built for feature-sized efforts: several layers, an observable far end, enough
tickets that a backlog could explode at all. For a two-liner the ceremony costs
more than the work — there, `build-slice` §2/§5 (red test, seam proof) and
`hold-the-line` on their own are enough.

## Status

Run for real three times, not just designed. A full chain in a throwaway repo —
red test, mutation step, seam check, live replays, verdicts through to
`resolved`, and a close correctly refused because a ticket was still open. A
second run deliberately suffered the session boundary: death mid-build, handoff,
resume, a dying review, a real `REOPEN`. A third ran the prescribed review mode
properly — four parallel axis subagents that could not see each other. No
blockers in any run, and every rule gap they found is fixed. On top of that, an
independent multi-agent review across seven reading axes, adversarially
verified.

A seam test proves two ends talk. It never proves they tell the truth — which is
why `cut-slices` rule 3b makes the ticket name what checks the real thing.

Full report, residual risks and what is still unmeasured:
[`docs/VALIDATION.md`](docs/VALIDATION.md).

## Credits and prior art

This flow is built on two existing skill sets and would not exist without them.

**[mattpocock/skills](https://github.com/mattpocock/skills)** — Matt Pocock's
skill set is the foundation. The overall shape of the chain (idea → spec →
tickets → review) and the two-axis review come from there, as does the habit of
small, composable, hackable skills. The measurements in `docs/DIAGNOSIS.md` are
partly a critique of specific skills in that set, and that critique is only
possible because the set is public, readable and precise enough to argue with.

**[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** —
Addy Osmani's set contributes three mechanics the chain otherwise lacks: the
stop-the-line rule when something breaks, the hard cycle limit from
`doubt-driven-development`, and the enumeration of the ways a quality bar gets
quietly lowered, which `references/standing-bar.md` is a direct descendant of.

What is new here is the seam rules and the verdict rule, both of which come out
of the measurements in `docs/DIAGNOSIS.md` rather than from either set.

`cold-read`, `price-the-wall` and `structured-debugging` are standalone skills
by the same author, bundled here so the plugin runs without prerequisites.

## License

MIT — see [`LICENSE`](LICENSE).

`docs/DIAGNOSIS.md` and `docs/WORKFLOW.md` are written in German,
`docs/VALIDATION.md` is mixed. The skills, commands and this README are English.
