# UI prototype

Generate **several radically different UI variations** on a single route,
switchable from a floating bottom bar. The user flips between variants in the
browser and picks one, or steals bits from each.

**Outside an effort only.** Inside one, a question about how something looks
is Product the shape missed, not a prototype's to answer ([SKILL.md](SKILL.md),
"Who judges").

If the question is about logic/state rather than what something looks like,
this is the wrong branch. Use [LOGIC.md](LOGIC.md).

## When this is the right shape

- "What should this page look like?"
- "I want to see a few options for this dashboard before committing."
- "Try a different layout for the settings screen."
- Any time the user would otherwise spend a day picking between three vague
  mockups in their head.

## Two sub-shapes: strongly prefer sub-shape A

A UI prototype is much easier to judge when it's **butting up against the rest
of the app**: real header, real sidebar, real data, real density. A throwaway
route on its own is a vacuum: every variant looks fine in isolation. Default to
sub-shape A whenever there's a plausible existing page to host the variants.

### Sub-shape A: adjustment to an existing page (preferred)

The route already exists. Variants are rendered **on the same route**, gated by
a `?variant=` URL search param. The existing data fetching, params, and auth all
stay. Only the rendering swaps.

If the prototype is for something that doesn't yet have a page but *would
naturally live inside one* (a new section of the dashboard, a new card on the
settings screen, a new step in an existing flow), it's still sub-shape A. Mount
the variants inside the host page.

### Sub-shape B: a new page (last resort)

Only when the thing being prototyped genuinely has no existing page to live
inside (an entirely new top-level surface, or a flow that can't be embedded
anywhere sensible).

Create a **throwaway route** following whatever routing convention the project
already uses. Name it so it's obviously a prototype (the word `prototype` in the
path or filename). Same `?variant=` pattern.

Before committing to sub-shape B, sanity-check: is there really no existing page
this could be embedded in? An empty route hides design problems that a populated
one would expose.

In both sub-shapes the floating bottom bar is identical.

## Process

### 1. State the question and pick N

Default to **3 variants**. More than 5 stops being radically different and
starts being noise, so cap there.

Write the plan in one line, under the question from [SKILL.md](SKILL.md), in a
top-of-file comment of the switcher:

> "Three variants of the settings page, switchable via `?variant=`, on the
> existing `/settings` route."

### 2. Generate radically different variants

Draft each variant. Hold each one to:

- The page's purpose and the data it has access to.
- The project's component library / styling system (TailwindCSS, shadcn, MUI,
  plain CSS, whatever).
- A clear exported component name, e.g. `VariantA`, `VariantB`, `VariantC`.

Variants must be **structurally different**: different layout, different
information hierarchy, different primary affordance, not just different colours.
Three slightly-tweaked card grids isn't a UI prototype, it's wallpaper. If two
drafts come out too similar, redo one with explicit "do not use a card grid"
guidance.

### 3. Wire them together

Create a single switcher component on the route:

```tsx
// pseudo-code, adapt to the project's framework
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

For sub-shape A: keep all the existing data fetching above the switcher; only
the rendered subtree changes per variant.

For sub-shape B: the throwaway route mounts the same switcher.

### 4. Build the floating switcher

A small fixed-position bar at the bottom-centre of the screen with three pieces:

- **Left arrow**: cycles to the previous variant (wraps around).
- **Variant label**: the current variant key and, if the variant exports a name,
  that name too, e.g. `B (Sidebar layout)`.
- **Right arrow**: cycles forward (wraps around).

Behaviour:

- Clicking an arrow updates the URL search param through the framework's router
  (`router.replace` on Next, `navigate` on React Router, etc.) so the variant is
  shareable and reload-stable.
- Keyboard: `←` and `→` also cycle. Don't intercept arrow keys when an
  `<input>`, `<textarea>`, or `[contenteditable]` is focused.
- Visually distinct from the page (high-contrast pill, subtle shadow) so it's
  obviously not part of the design being evaluated.
- Hidden in production builds: gate on `process.env.NODE_ENV !== 'production'`
  or the equivalent, so even a stray merge can't ship the bar to users.

Put the switcher in a single component next to the variants.

### 5. Run it, then hand it over

Start it with its one command and load every variant once yourself before the
user sees it: a variant that crashes or renders empty wastes the judge's time
and biases the pick. Then surface the URL and the `?variant=` keys. The
interesting feedback is usually **"I want the header from B with the sidebar
from C"**, which is the actual design they want.

### 6. Capture the answer

The answer is what the user picked and why — often a mix, so name the parts:
"B's header, C's sidebar, A's empty state". Capture it and the prototype the way
[SKILL.md](SKILL.md) rule 6 describes. The full set of variants and the switcher
stay on the prototype branch; whoever builds the page rewrites the winner
properly, reading it from there for reference.

## Anti-patterns

- **Variants that differ only in colour or copy.** That's a tweak, not a
  prototype. Real variants disagree about structure.
- **Sharing too much code between variants.** A shared `<Header>` is fine; a
  shared `<Layout>` defeats the point. Each variant should be free to throw out
  the layout.
- **Wiring variants to real mutations.** Read-only prototypes are fine. If a
  variant needs to mutate, point it at a stub: the question is "what should this
  look like", not "does the backend work".
- **Merging the winning variant.** It was written under prototype constraints
  (no tests, minimal error handling). Rewrite it when building it for real.
