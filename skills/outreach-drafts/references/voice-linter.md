# Voice Linter

Letzter Check vor `create_draft`. **Nicht** als Ersatz für [voice.md](../../../references/voice.md) — sondern als grobes Netz gegen die häufigsten AI-Tells und Voice-Brüche, die sich nicht im Modell "intuitiv" rausdrücken.

Wenn der Linter trifft: **nicht patchen, umschreiben.** Patch-Edits hinterlassen oft den AI-Geschmack drumherum, auch wenn das einzelne Wort raus ist.

---

## Hard fails (immer umschreiben)

| Pattern | Warum | Fix |
|---|---|---|
| `—` (em-dash) oder `–` (en-dash) | Klassischer AI-Tell. | Komma, Punkt, oder Satz neu bauen. Bindestriche in Komposita (`Live-Set`, `Open-Air`) sind OK. |
| `mega`, `krass`, `der Wahnsinn`, `nice` (als adj.) | Hype-Sprache. | "gefällt uns sehr", "richtig Lust", "schöne Ergänzung". |
| `incredible`, `amazing`, `truly unique`, `mind-blowing` | EN-Pendant. | "happy", "would love", "great fit". |
| `Sehr geehrte Damen und Herren`, `Dear Sir or Madam` | Verboten in jedem Kontext. | "Hey!" oder "Hey [Name]". |
| Drei Adjektive hintereinander (`authentic, raw, electric`) | Marketing-Tricolon. | Eins behalten oder ganz raus. |
| Zwei Links in einer Mail | Filter-Trigger + Marketing-Optik. | Ein Link je Mail. Touch 1/3 = EPK, Touch 2 = Sisyphos. |
| Equipment-Listen (`Moog`, `Vocals`, `Controller`, gemeinsam) | Niemand interessiert das Gear. | "Synths und Vocals" max. |
| Erfundene Connection ("habe gehört euer Booker XY ist …") wo `facts.md` keine Quelle hat | Halluzination. | Fallback auf Tier-3 Hook (Genre/City). |
| `Re:` Manipulation bei Touch 1 (ohne echten vorherigen Thread) | Spam-Taktik. | Frisches Subject. |
| ALL CAPS in Subject oder Body | Schreierei. | Normal. |
| Emoji im Subject | Marketing-Tell. | Raus. |
| `Anfang des Jahres`, `earlier this year`, `last year` (jahresbezogen) | Altert schlecht. | "gerade", "just". |

## Soft fails (denk drüber nach, fast immer umschreiben)

| Pattern | Warum | Was tun |
|---|---|---|
| Genau drei Paragraphen je 2–3 Sätze | Universelle Cold-Mail-Form. | Rhythmus brechen — kürzer, oder anders gewichtet. |
| Hook nicht im ersten Satz | Bookers skimmen. | Hook nach vorn. |
| Touch 1 > 90 Wörter | Bibel-Cap (60–90). | Kürzen, nicht polieren. |
| Touch 2/3 > 60 Wörter | Cap 30–50. | Kürzen. |
| Self-intro paraphrasiert statt verbatim | Sacred line. | Exakt aus voice.md übernehmen. |
| Proof vor Ask | "CV vor Anfrage" → unsicher. | Ask vor Proof. |
| `wir würden uns sehr freuen` + `es wäre schön wenn` im selben Mail | Doppelt höflich. | Einmal reicht. |
| Sign-off ≠ `Bene & Nils` | Voice-Anker. | Korrigieren. |
| Reply-Draft mit Self-Intro / EPK-Opener | Kennen uns schon. | Beides raus. |
| Reply-Draft ohne konkrete Frage am Ende | Thread stoppt. | Eine Frage dranhängen. |

## Off-limits content (aus facts.md)

- **"Oliver Koletzki + Ritter Butzke"** im selben Mail-Kontext → never. Reads as overreach.
- **Kotori EP** vor `2026-07-01` → never erwähnen (siehe release-calendar.md).

## Self-check Fragen (bevor du `create_draft` callst)

1. Würde Bene oder Nils das so schreiben, wenn sie's getippt hätten?
2. Klingt der Hook spezifisch für **dieses** Venue, oder funktioniert er copy-paste für 50?
3. Ist die "Wir sind Kon Faber…" Zeile **wortwörtlich** drin (Touch 1)?
4. Ein Link?
5. Sign-off "Bene & Nils"?
6. Bei Reply: kein Self-Intro, konkrete Frage am Ende?

Wenn auch nur eine Antwort schwächelt → neu schreiben, nicht patchen.

## Was dieser Linter **nicht** ersetzt

- [voice.md](../../../references/voice.md) — die echten Geschmacksregeln. Linter ist Backstop, nicht Bibel.
- [templates.md](../../../references/templates.md) — Rhythmus-Anker. Linter sieht nicht ob ein Mail "klingt".
- Den eigentlichen Sprachfluss. Wenn der Linter clean ist und die Mail trotzdem komisch klingt → das Gefühl gewinnt.
