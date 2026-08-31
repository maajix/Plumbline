# Warum der Flow kaputtgeht — Befund mit Belegen

Gemessen an Projekt A (292 Commits, 165 Tickets in *einem* Effort) und
gegengeprueft an Projekt B (3 Efforts: 24 / 7 / 1 Ticket, keine Explosion).

Beide sind nicht-oeffentliche Codebasen und hier anonymisiert. Zahlen,
Ticketnamen und Zitate sind unveraendert; nur die Projektnamen sind ersetzt.

## Befund 1 — Die Tickets sind NICHT zu grob

Gegenbeleg: Ticket 163 aus Projekt A ist vorbildlich. Es hat
`Blocked by`, vier abhakbare Akzeptanzkriterien, ein Kriterium
"Checked by something that would go red", einen `Why`-Abschnitt mit
Log-Auszug als Beweis, und einen `Resolution`-Abschnitt.

Das Ticketformat ist gut. Die Ursache liegt woanders.

## Befund 2 — Die Ursache ist horizontale Zerlegung

Verteilung der "Verdrahtungsdefekte" (Titel der Bauart
"X wird von nichts gelesen", "nichts registriert Y", "Z hat keinen Aufrufer"):

| Ticketbereich | Verdrahtungsdefekte | Gesamt | Anteil |
|---|---|---|---|
| 1-60    |  1 | 60 |  1,7 % |
| 61-110  |  4 | 50 |  8,0 % |
| 111-165 | 35 | 55 | **63,6 %** |

Tickets 1-60 sind geplante Bau-Tickets, Verbform:
`09-send-http-through-the-egress-proxy`, `27-let-the-scheduler-choose-and-dispatch`,
`36-create-candidate-record`.

Tickets 111-165 sind fast alle Nahtdefekte:
`126-the-result-store-is-connected-at-neither-end`,
`128-three-python-workers-with-no-caller`,
`142-a-queued-job-is-read-by-nothing`,
`152-a-test-is-authored-and-nothing-performs-it`,
`156-a-validated-record-opens-no-work`,
`164-fifty-templates-and-not-one-has-ever-been-selected`.

(Die Slugs sind umbenannt. Satzform, Verbform und Zaehlung sind unveraendert —
sie sind der Befund; die Substantive der privaten Codebasis sind es nicht.)

**Mechanik:** Der Spec beschreibt Komponenten. `to-tickets` schneidet entlang
Komponentengrenzen. Jeder Agent baut seine Komponente korrekt und in Isolation.
Niemand ist je gezwungen, Erzeuger und Verbraucher zusammen laufen zu lassen.
Die Naht wird erst beim ersten echten Durchlauf angefasst — und dann kippen
35 Defekte (in 55 Tickets) auf einmal herein.

Der Agent hat also **nicht** "grobe Fehler gemacht". Er hat genau das gebaut,
was im Ticket stand. Im Ticket stand nur die halbe Naht.

Beleg dafuer, dass das Projekt selbst das erkannt hat:
`130-check-the-wiring-the-way-the-auditor-checks-the-queue` — sie mussten
nachtraeglich einen Verdrahtungspruefer als Ticket erfinden.

## Befund 3 — Jede Review gebiert Tickets

Die Abdeckungsliste des Efforts protokolliert es woertlich: Tickets 76-80 von
Implementation-Reviews, 81-83 von Live-Validierung, 87 und 88 von der
Final-Review zu Ticket 64, 89 von einer Betreiberfrage, 90/91/92 daraus wieder.

Es gibt keine Regel, die eine Review-Erkenntnis daran hindert, ein Ticket zu
werden. Also wird jede eins.

## Befund 4 — Die Gegenregel existiert schon, nur nicht als Skill

Projekt B, `docs/issues/WORKING-AGREEMENTS.md` Regel 1:

> Wenn ein Ticket berechtigt Arbeit parkt, die es nicht tun soll, wird diese
> Arbeit ein Akzeptanzkriterium an einem bereits offenen Ticket im selben
> Effort. Ein neues Ticket entsteht nur, wenn die geparkte Arbeit etwas
> **blockiert**, oder wenn sie eine Entscheidung braucht, die niemand im
> Effort besitzt.

Diese Regel steht in einer Markdown-Datei, die kein Skill liest. Projekt B
(mit der Regel) explodiert nicht. Projekt A (ohne) hat 165 Tickets.

## Befund 5 — Grilling fragt technisch, weil es auf Implementierung zielt

Nutzerbefund, bestaetigt: Fragen der Art "sollen wir das so oder so
implementieren, was ist mit dieser Variable" gehoeren in Ticket und Prototyp,
nicht in die Ideenphase. Die Ideenphase muss Produktfragen stellen.

## Was daraus folgt

1. Schneide Tickets **vertikal** (ein Pfad, der laeuft), nicht horizontal
   (eine Komponente, die fertig ist).
2. Ticket 1 jedes Efforts ist ein **Walking Skeleton**: der duennste
   Ende-zu-Ende-Pfad, der echt durchlaeuft.
3. Jedes Ticket, das etwas erzeugt, benennt seinen Verbraucher und hat einen
   Test, der die **Naht** beweist, nicht nur die Komponente.
4. Review-Erkenntnisse werden Kriterien, nicht Tickets — ausser sie blockieren.
5. Grilling fragt nur Produktfragen. Technische Fragen sind verboten.
6. Ein Effort hat eine Ticket-Obergrenze. Darueber wird geteilt, nicht gewachsen.

---

# Nachtrag — was die Skill-Analyse ergab

## Befund 6 — `to-tickets` sagt bereits "vertikal". Es wirkt nicht.

Woertlich aus `to-tickets/SKILL.md`, Abschnitt `<vertical-slice-rules>`:

> - Each slice cuts a narrow but COMPLETE path through every layer (schema,
>   API, UI, tests) — vertical, NOT a horizontal slice of one layer
> - A completed slice is demoable or verifiable on its own
> - Each slice is sized to fit in a single fresh context window

Die Regel ist richtig und stand die ganze Zeit da. Projekt A hat trotzdem
60 horizontale Tickets bekommen.

**Warum die Regel wirkungslos ist:** Sie ist eine Absichtserklaerung ohne
Pruefung. Nichts im Ticketformat zwingt den Schneider, die Naht zu benennen.
Das Template hat genau vier Felder: Titel, `What to build`, `Blocked by`,
`Status`, plus Kriterien. Kein Feld fragt "wer liest das?".

Zusaetzlich: `to-spec` produziert *"a LONG, numbered list of user stories …
extremely extensive"* plus einen Abschnitt `Implementation Decisions`. Ein Spec
in dieser Form beschreibt Komponenten, und der Ticketschneider folgt der Form
des Specs, nicht der Regel im Skill.

Und die Granularitaet wird **vom Nutzer abgenommen**:

> Ask the user: Does the granularity feel right? … Iterate until the user
> approves the breakdown.

Bei 60 Tickets kann kein Mensch sehen, welche Naht fehlt. Die Abnahme ist echt,
die Pruefung ist es nicht.

**Konsequenz fuer uns:** "vertikal" als Satz reicht nicht. `cut-slices`
erzwingt es mechanisch ueber `PRODUCES` / `CONSUMED BY` / `CONSUMES`. Ein Feld,
das leer bleibt, ist ein sichtbarer Fehler. Ein Grundsatz, der nicht befolgt
wird, ist keiner.

## Befund 7 — `implement` ist sechs Zeilen lang und schreibt keinen Zustand

Der vollstaendige Skill-Koerper:

> Implement the work described by the user in the spec or tickets.
> Use /tdd where possible, at pre-agreed seams.
> Run typechecking regularly, single test files regularly, and the full test
> suite once at the end.
> Once done, use /code-review to review the work.
> Commit your work to the current branch.

Daraus folgt zweierlei, beides gemessen:

1. **Kein Ticket wird je abgehakt.** Kein Kriterium wird getickt, kein Status
   gesetzt, kein Issue geschlossen. Welches Ticket fertig ist, steht nur in der
   Git-Historie oder im Kopf.
2. **Es gibt keine Regel fuer "mitten im Ticket faellt etwas auf".** In
   `implement`, `to-tickets` und `to-spec` zusammen: null Treffer fuer
   `mid-ticket`, `if you discover`, `turns out`, `re-plan`.

Das ist die eigentliche Mechanik der Ticket-Explosion. Der Agent findet ein
Problem, es gibt keine Regel, also greift die Voreinstellung: ein Ticket
aufmachen. `hold-the-line` ist genau die fehlende Regel.

## Befund 8 — Grilling hat keine Flughoehe, und das ist messbar

Suche ueber die gesamte Skill-Datei nach `product`, `feature`, `user story`,
`requirement`, `outcome`, `business`, `high-level`, `low-level`,
`implementation`: **null Treffer.**

Der Skill sagt dem Agenten nirgends, auf welcher Ebene er fragen soll. Drei
Mechanismen ziehen ihn dann nach unten:

1. **Der Baum hat keinen Boden.** *"Map this as a design tree: every decision
   branches into the decisions that hang off it."* Die Blaetter eines
   Design-Baums **sind** Implementierungsentscheidungen.
2. **Das Abbruchkriterium erzwingt den Abstieg.** *"The session is done when the
   frontier is empty: every branch of the design tree visited, nothing left
   silently assumed."* Unter "nothing left silently assumed" ist jeder
   Variablenname ein unbesuchter Ast.
3. **Die Frage/Fakt-Teilung hat keinen dritten Eimer.** *"Finding facts is your
   job, never the user's. The decisions are the user's."* Eine
   Implementierungsentscheidung ist kein nachschlagbarer Fakt, also landet sie
   per Konstruktion beim Nutzer.

Der Wartende weiss davon. In
[`.out-of-scope/question-limits.md`](https://github.com/mattpocock/skills/blob/main/.out-of-scope/question-limits.md)
von `mattpocock/skills` steht zu Issue #44 *"Codex just asked me 200
questions"*:

> a model that asks redundant or low-value questions (a prompt-quality issue,
> not a quantity issue). The fix for the latter belongs in the skill prompt,
> not in a counter.

Dieser Fix ist nie geschrieben worden. Version 1.2.3 hat nur das Tempo
geaendert (Runden statt Einzelfragen), nicht die Flughoehe.

**Konsequenz fuer uns:** `shape-idea` braucht (a) eine ausdrueckliche
Verbotsliste, (b) ein Abbruchkriterium auf Produktebene, das *nicht* "Frontier
leer" heisst, und (c) einen dritten Eimer fuer technische Unbekannte:
Research-Auftrag oder Prototyp — als Agentenarbeit vor oder im Skeleton, nie
als eigenes Ticket und nie als Frage an den Nutzer (so steht es jetzt in
`shape-idea`).

## Befund 9 — Achtung, zwei Kopien der Skills auf der Platte

| Kopie | Pfad | Version |
|---|---|---|
| geladen | `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/1.2.3/` | 1.2.3 |
| veraltet | `~/.claude/plugins/marketplaces/mattpocock/` | 1.2.0 |

`grilling` und `writing-for-agents` unterscheiden sich stark. Massgeblich ist
die Cache-Kopie.

---

# Nachtrag 2 — was die zwei Kettenlaeufe ergaben

Zwei Agenten haben die volle Kette auf zwei verschiedenen Aufgaben gefahren
(DNS-Dangling-Scanner, Token-Budget-Governor), je sieben bis acht Tickets
geschnitten, je zwei echt gebaut, getestet und reviewt.

## Was nachweislich funktioniert hat

**Der Walking Skeleton ist die staerkste Regel.** Bericht A woertlich: die Regel
"forced the store and its reader into one ticket. Left to habit I would have cut
`01-set-up-the-sqlite-schema`, `02-write-the-resolver`, `03-add-the-queue-command`
— three tickets, three green suites, and no proof that `scan` and `queue` agree
on the string `dangling` until the first real run."

Das ist exakt der Projekt-A-Fehler, verhindert bevor er entsteht.

**Der Nahttest faengt Fehler ueber Ticketgrenzen hinweg.** In Lauf B aenderte
Ticket 02 die Budget-Politik von Ganzzahl auf Gleitkomma. Der **eigene** Test von
Ticket 02 blieb gruen, weil `50.0 == 50` in Python wahr ist. Rot wurde der
Nahttest von Ticket 01, weil er prueft, ob die Zahl im Satz auftaucht, den der
Operator liest.

Der Fehler dahinter war echt: die Spalte ist `INTEGER NOT NULL` deklariert,
SQLite speichert per Typaffinitaet trotzdem `REAL` hinein, und aus einer
Budgetzahl wurde `0.30000000000000004`. Ein Unit-Test auf `charge()` haette das
nie gesehen.

**`hold-the-line` hat ein Ticket verhindert.** Der Fund wurde Kriterium an
Ticket 02, nicht Ticket 08. Beide Tests des Skills wurden durchgegangen und
beide verneint.

**Die Latte hat eine Versuchung erwischt.** Bericht B: der billigste Weg, das
rote Testergebnis loszuwerden, waere gewesen, die Zusicherung typunabhaengig zu
machen — "a one-line edit that looks like fixing a brittle assertion and is
actually `standing-bar` lowering move 2, 'a test got easier'." Wurde als
ausdrueckliche Ablehnung protokolliert.

## Was kaputt war, und jetzt behoben ist

Beide Laeufe fanden unabhaengig dieselben zwei Kernfehler.

**1. Regel 1 und Regel 4 widersprachen sich.** Der Skeleton kreuzt vier Dateien,
die Groessenregel erlaubt drei. Keine Regel sagte, welche gewinnt. Beide Agenten
haben geraten, und beide haben die Architektur nach der Regel gebogen statt
umgekehrt. Bericht B: "That is the rule changing the architecture, not the plan."
Behoben: Regel 1 schlaegt Regel 4, ausdruecklich.

**2. Vorwaertsverweis und `NOBODY` widersprachen sich direkt.** `cut-slices`
erlaubte `CONSUMED BY: ticket NN`; `seam-check`, `build-slice` und die Latte
verboten denselben Zustand. Bericht B: "Rule 2 grants permission for a state that
three other places forbid. And it is not an edge case: a walking skeleton is by
definition one end of a system built before anything real calls it, so ticket 01
of *every* effort lands here."

Behoben, und zwar so, dass die Erlaubnis nicht zum Schlupfloch wird: ein
Vorwaertsverweis ist eine **Schuld mit Adresse**. Das Ziel-Ticket ist weder
`resolved` noch `declined`, die Session, die NN landet, loest den Verweis ein
(`build-slice` §5), und beim Close nimmt jeder Rest genau eines von drei
Enden: eingeloest, mitsamt dem ungelesenen Wert geloescht, oder mit beiden
Enden zusammen in den Nachfolge-Effort verschoben.

**3. Jeder vertikale Schnitt endet bei einem Menschen.** Bericht A: "the last hop
of a slice is the one hop `PRODUCES`/`CONSUMED BY` cannot describe, and it is the
hop the feature exists for." Behoben: `operator, via <befehl>` ist eine legale
Form, und sie schuldet denselben Beweis wie jede andere Naht.

**4. Die gefaehrlichste Nahtaenderung hatte kein Feld.** Ticket 02 in Lauf B
aenderte keine Spalte, keinen Typ, kein Ereignis — nur die Zahl darin. Behoben:
`PRODUCES` traegt jetzt eine Art: `new`, `changed`, `contract`, `nothing`.

**5. Eine Zitierung durfte in der Zukunft wahr sein.** Bericht B hat sich selbst
beim Schummeln erwischt: "indirectly via the reason text" bestand die Pruefung,
obwohl der zweite Verbraucher zum Zeitpunkt des Tickets nicht existierte.
Behoben: die Zitierung muss wahr sein, **wenn dieses Ticket landet**.

**6. Naehte ueber Repo-Grenzen waren unsichtbar.** Bericht B nennt das "the
biggest gap in the plugin" — grep kann die Grenze nicht kreuzen, also meldete der
Check faelschlich sauber. Behoben: eigene Form, und "nichts prueft den Vertrag"
ist ausdruecklich ein Fund.

**7. Zwei Skills benutzten verschiedene Statuswoerter.** `build-slice` erfand
`claimed`; `hold-the-line` kannte nur "already open" — womit das Ticket, an dem
man gerade arbeitet, kein Kriterium aufnehmen durfte. Behoben: fuenf Werte,
ueberall dieselben, und das laufende Ticket zaehlt ausdruecklich.

**8. Ein mitten in der Session ergaenztes Kriterium bekam keinen roten Test.**
Bericht B hat genau diesen Fehler selbst gemacht und protokolliert. Behoben:
`hold-the-line` verlangt ihn jetzt beim Namen.

## Der wichtigste Fund — alle Naehte gruen, und trotzdem kaputt

Lauf A hat einen Scanner gebaut. Der Scanner lief. Jede Naht war belegt, jedes
Ticket geschlossen, jedes Kriterium erfuellt. Der Bericht des Agenten ueber
seinen eigenen Code:

> The plugin did not catch a single one of the five real defects in the code it
> shipped. … A scanner reporting zero findings on a list full of real ones,
> with every seam test green. This is the mirror image of the defect the plugin
> was built to fix.

Der Mechanismus ist genau umgekehrt zum Projekt-A-Muster, und deshalb zaehlt er.
Projekt A baute Teile, die einzeln stimmten und zusammen nichts ergaben. Der
Nahttest faengt das. Lauf A baute eine Kette, die durchlief und dabei die
falsche Sache mass: der Test fuetterte eine Attrappe (ein Stellvertreter-Objekt,
das nur das Antwortformat nachbildet). Die Naht war damit bewiesen. Der Inhalt
war es nie.

Der Fehler war meiner. Ich hatte den Nahttest zur einzigen Pflichtform gemacht.
Damit war "die Naht traegt" die ganze Definition von fertig, und alles, was die
Naht nicht beruehrt, fiel durch.

Behoben mit Regel 3b in `cut-slices`: das Ticket muss benennen, was **die echte
Sache** prueft, und ob der Test gegen eine Attrappe oder gegen das Original
laeuft. Eine Naht, die nur gegen eine Attrappe gruen ist, ist ein halber Beweis
und muss sich so nennen.

Das bleibt die duennste Stelle des Plugins. Ein Nahttest beweist, dass zwei
Enden reden. Er beweist nie, dass sie die Wahrheit sagen.

## Was gemessen, aber nicht behoben ist

**Die 25er-Obergrenze war wirkungslos.** Beide Efforts brauchten sieben bis acht
Tickets. Bericht A: "a 25-ticket ceiling is a guard against the 165-ticket
pathology, not a working constraint. It does no work on a normal feature." Die
Grenze bleibt als Alarm, nicht als Werkzeug.

**Das Nahtfeld verliert nach Ticket 01 an Trennschaerfe.** Sobald ein Leser
existiert, nennt jedes folgende Ticket denselben. Bericht A: es fand auf den
Tickets 02, 03 und 05 nichts, was der Titel nicht schon sagte. Geloest in
0.2.0: `cut-slices` Regel 2 verlangt `, reading <literal>` hinter dem Symbol —
derselbe Leser, drei verschieden greppbare Zeilen, und `seam-check` greppt
genau dieses Literal statt eines geratenen.
