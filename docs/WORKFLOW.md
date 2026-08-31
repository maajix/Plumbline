# Der Flow

Acht Tore. Jedes hat einen Skill und eine Datei, die es hinterlässt.

```
1 SHAPE     shape-idea    -> interview.md, shape.md   nur Produktfragen
2 SPEC      write-spec    -> spec.md                  + cold-read
3 SLICE     cut-slices    -> NN-*.md                  + cold-read
4 BUILD     build-slice   -> Code + Nahttest          je Ticket eine Session
5 PROVE     seam-check    -> Nahtbericht im Ticket    einmal je Ticket, in Tor 4 §5
6 REVIEW    review-pass   -> Findings mit Schweregrad vier Achsen, drei Zyklen
7 VERDICT   hold-the-line -> eines von sechs Verdikten
8 CLOSE     close-effort  -> Effort endet             alle Schulden beglichen
```

Es gibt bewusst kein Ship-Tor. Ausliefern hängt an deiner Pipeline, nicht an
diesem Ablauf, und ein Tor ohne Skill ist eine Lücke, die wie ein Schritt
aussieht.

Tor 5 läuft genau einmal pro Ticket, als Schritt 5 von `build-slice`, und
hinterlässt seinen Bericht unter `## Seam check, <datum>` im Ticket. `/prove`
auf Zuruf und die Naht-Achse der Review **lesen** diesen Bericht; sie spielen
die Live-Blöcke nicht erneut ab und erhöhen `REPLAYS` nicht. Ohne diese Regel
liefe der volle Durchgang dreimal je Ticket.

## Der Ticket-Lebenszyklus, seit 0.3.0

`build-slice` setzt nie `resolved`. Das Ticket bleibt `claimed` durch Bau,
Resolution, Latte und Commit, und geht so in die Review — dadurch kann ein
`required`-Finding der Review als CRITERION auf genau diesem Ticket landen,
auch beim letzten Ticket eines Efforts. Jeder Review-Zyklus endet mit einem Review-Commit — er trägt Findings,
Verdikte und jede von einem Verdikt editierte Ticketdatei und ist der
Fixpunkt des nächsten Zyklus. Erst wenn kein Eintrag mehr `— verdict pending`
trägt und kein Kriterium auf dieses Ticket kam, schreibt `review-pass` im
selben Commit das `resolved`. REOPEN hängt später einen zweiten datierten
`## Resolution`-Block an; der letzte ist der gültige.

## Die drei gebündelten Basis-Skills

Seit 0.3.0 liefert das Plugin sie mit — als eigene Skills unter `skills/`,
weil sie auch außerhalb des Flows nützlich sind.

### `cold-read` — Tor 2, 3, 5 und 6

Seine Regel *"this is a read, not a repair"* ist die Bremse gegen die
Ticket-Schleife. Eine Review, die mitten im Durchgang repariert, liest den Rest
nicht zu Ende, und was sie nicht gelesen hat, findet die nächste Review.

- **Tor 2 und 3.** Spec und Ticketplan werden vor der Übergabe kalt gelesen.
  Ein Ticketplan ist genau das, was der Skill beschreibt: ein Artefakt, das eine
  andere Session ausführt. Vor Tor 4 gibt es noch keine Tickets und darum
  keine Verdikte: Findings dieser Lesungen werden nach dem vollständigen
  Durchgang direkt in Spec oder Plan eingearbeitet — `hold-the-line` beginnt,
  sobald es Tickets gibt, auf denen ein Verdikt landen kann.
- **Tor 5.** Der Nahtcheck läuft im Cold-Read-Modus: erst der ganze Durchgang,
  dann Findings, keine Reparatur unterwegs. Wer beim ersten Fund patcht,
  erreicht die letzte Naht nie, und die letzte ist meistens die kaputte.
- **Tor 6.** Die Review ist ein Cold Read. Ganzer Durchgang, dann Findings,
  dann `hold-the-line` für die Verdikte, dann erst reparieren.

Seine Regel *"other agents' summaries, ticket text and code comments are leads,
not evidence"* wird zur Review-Pflicht: ein Ticket, das sich selbst als
`resolved` bezeichnet, ist kein Beleg.

### `price-the-wall` — Tor 4

Zwei Dinge kommen aus diesem Skill, und nur eines davon ist ein Aufruf.

Seine Kernregel ist die Lösung des Nahtfehlers: *eine Behauptung über ein
Interface hat zwei Enden, ein gelesenes Ende ist eine Vermutung mit
Zeilennummer.* Diese Regel steckt fest in `cut-slices`, in den Zeilen
`PRODUCES` / `CONSUMED BY` / `CONSUMES`. Tor 3 ruft den Skill nicht auf, es
trägt seine Regel schon.

Aufgerufen wird er vor allem an einer Stelle: **Tor 4, beim Bauen.** Sobald
der Agent im Ticket auf "geht nicht" stößt, läuft `price-the-wall` **bevor**
er drumherum baut. Sein eigener Trigger ist breiter — er feuert auch beim
Schreiben von Docs, Specs und Playbooks, die ein anderer Agent ausführt; das
gilt hier unverändert, nur ruft der Flow ihn dort nicht eigens auf. Ohne das entsteht Code, der beschreibt, was er nicht kann — und daraus
wird später ein Ticket. Die vier Zeilen `WALL`, `PRICE`, `PURPOSE`, `RULE`
stehen im Skill selbst; eine bepreiste Wand geht als Finding mit Schweregrad
an `hold-the-line`.

### `structured-debugging` — Tor 4, nur bei unbekannter Ursache

Nicht bei jedem Fehler. Nur wenn die Ursache unbekannt ist. Ein Agent, der
mitten im Ticket rät statt vier Hypothesen zu schreiben, produziert die
Reparatur, die später das nächste Ticket wird.

## Warum Tor 2 einen eigenen Skill hat

Pococks `to-spec` verlangt *"a LONG, numbered list of user stories … extremely
extensive"* plus einen Abschnitt `Implementation Decisions`. Ein Spec dieser
Form beschreibt Komponenten. Der Ticketschneider folgt der Form des Specs, nicht
dem Grundsatz im Skill — und genau so entstehen horizontale Tickets, obwohl
`to-tickets` wörtlich "vertikal" fordert.

`write-spec` dreht die Gliederung um: zuerst die Pfade, die laufen, danach die
Teile, jedes mit den Pfadnummern, denen es dient. Ein Teil ohne Pfad ist ein
Teil, den niemand bestellt hat.

## Die drei neuen Regeln, kurz

1. **Das erste gebaute Ticket läuft durch.** Dünnster Ende-zu-Ende-Pfad, echt,
   bleibt.
2. **Jedes Ticket nennt beide Enden seiner Naht** und hat einen Test, der die
   Naht kreuzt, nicht die Komponente prüft.
3. **Jedes Finding bekommt genau ein Verdikt** aus den sechs in
   `hold-the-line`. Der Schweregrad entscheidet, und ein `blocker` wird nie ein
   aufgeschobenes Kriterium.

## Die Sessiongrenze

Die drei Regeln oben sind an Ticketzahlen gemessen. Was hier folgt, ist es
**nicht**. Es folgt aus einem Strukturbefund, nicht aus einer Messung, und das
gehört dazugesagt — sonst liest es sich wie belegt, und die Belegkette der drei
Regeln wäre danach weniger wert.

Der Befund: die Session ist in allen Skills die Arbeitseinheit, und kein
Skill sagte, wodurch sie begrenzt ist oder was passiert, wenn sie vor dem Ticket
endet. `cut-slices` Regel 4 sagt es selbst — *"Nothing measures a session, so
this is a sizing instinct, not a gate."* Drei Stellen schoben die Session aktiv
über genau diesen Punkt:

- **Der Walking Skeleton ist vom Größendeckel ausgenommen** (Regel 1). Das
  größte Ticket jedes Efforts ist damit das, auf das die Größenregel nie
  angewandt wurde — und es ist das erste gebaute. Es ist der wahrscheinlichste
  Übergabefall des Efforts, nicht der unwahrscheinlichste.
- **`live-inputs.md` wuchs monoton.** Ticket 20 spielte jeden vorherigen Block
  mit ab: die Ticketgröße war gedeckelt, die Live-Lauf-Last nicht. Die Datei
  hat jetzt eine Form und eine Promotionsregel — ein zweimal unverändert
  wiedergespielter Block wird zu einem Test und fällt aus dem Handlauf heraus.
- **Die Review überlebte eine Grenze nur als Zahl.** Der Zykluszähler stand im
  Ticket, die Findings ohne Verdikt nicht. Vier Subagents, die einander nicht
  sehen, berichteten in einen Kontext, der enden kann. Findings stehen jetzt im
  Ticket, sobald die vier Leser berichten, markiert mit `— verdict pending`, und
  der Zähler nennt die Achse dazu.

Die Antwort auf den ersten Fall steht in `build-slice`: ein `## Handoff`-Block
im Ticket, vier Zeilen, keine Zusammenfassung. Was die nächste Session nicht
neu ableiten kann, ist, welchen Fehlschlag die letzte gerade ansah und was schon
entschieden war — mehr trägt der Block nicht, denn eine Übergabe, die das
Reasoning zusammenfasst, ist die Compaction, die sie ersetzen soll.
`**Status:** claimed` bleibt dabei stehen: beansprucht ist das Ticket, nicht die
Session. `build-slice` §0 macht jedes `claimed`-Ticket zur Frontier vor jedem
`open` — REOPEN und abgebrochene Session sind derselbe Fall —, also findet die
nächste Session die Übergabe, ohne sie zu suchen.

Übergeben heißt nicht umplanen. Eine Session, die nicht reicht, ist kein
Anlass, mitten im Flug neu zu schneiden; das Neuschneiden gehört
`hold-the-line`, nach der Review.

Dazu die passende Hälfte an der Latte: `references/standing-bar.md` trennt
"Per ticket" in Zeilen mit Kommando und Zeilen, die ausdrücklich Urteil
sind. Eine Checkliste, die ein sechs Stunden alter Agent abgeht, degradiert mit
dem Kontext; ein Kommando nicht. Eine Zeile ohne Kommando und ohne
Urteils-Markierung ist Dekoration. Was die Kommandos drucken, steht seit 0.3.0
unter `## Bar, <datum>` im Ticket — eine Latte, die nur im Sessionkontext
gelaufen ist, ist für die nächste Session wieder eine Checkliste.

Das eine Kommando, das die Latte dafür braucht, kommt vom Skeleton: er läuft
ohnehin durch die echte Toolchain, also trägt seine Session das
Verify-Kommando ins Spec nach, unter `## Verify command` (`cut-slices` Regel 1,
`write-spec`). Das Plugin liefert kein Skript — es kennt die Toolchain des
Zielrepos nicht.

Gemessen ist daran inzwischen einiges: im zweiten Testlauf (siehe
`docs/VALIDATION.md`, letzter Nachtrag) starb eine Session absichtlich mitten
in §2, eine frische setzte über Handoff und §0 fort, und eine Review starb
mit offenen Verdikten und wurde von der nächsten Session geschlossen — die
Prämisse hielt. Ungemessen bleiben Brownfield und Nachfolge-Efforts.

## Obergrenzen

Drei Fragerunden beim Shapen. 25 Tickets je Effort. Drei Review-Zyklen je
Review — ein späteres REOPEN startet eine neue Review mit frischer Zählung;
der Deckel begrenzt die Review, nicht die Lebensgeschichte des Tickets. Ein
erreichter Deckel ist ein Signal zum Teilen, nie ein Grund, den Deckel
anzuheben.
