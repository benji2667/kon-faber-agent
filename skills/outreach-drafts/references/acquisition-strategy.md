# Acquisition Strategy

Wie der Agent neue Leads findet wenn die Pipeline ausläuft. **Keine fertigen Listen** hier — nur Taktiken die der Agent kombinieren kann, je nachdem was das CRM gerade hergibt und was die Saison ist.

**Trigger:** `outreach-drafts` SKILL Schritt 7 — Pipeline-Refill, wenn `count(status IN ('Neu','Recherchiert'))` unter 15.

**Quota pro Refill-Run:** 5–10 neue, qualifizierte Kontakte. Lieber 5 die passen als 10 die nicht passen.

**Bevor du startest, lies:**
- [../../../references/facts.md](../../../references/facts.md) — was Kon Faber spielt, wo gespielt wurde, mit wem geteilt.
- [../../../references/voice.md](../../../references/voice.md) — wie sich "passt" anfühlt (nicht nur Genre, auch Vibe).

## Fit-Profil (das Filter über allem)

Ein Venue passt wenn **mindestens zwei** stimmen:

1. **Genre-Nachbarschaft:** Melodic House / Organic / Driving Techno / Live-Electronic. Bookt Acts wie Acid Pauli, Monolink, Oliver Koletzki, Sainte Vie, Fejká, Madmotormiquel, Jacob Groening, Sebastian Mullaert, Bedouin, Adriatique, WhoMadeWho, Nu, Mathame.
2. **Format-Fit:** Klub mit Live-Slots **oder** Festival mit elektronischer Bühne **oder** Boutique-Open-Air. Reine Mainstage-EDM oder Tech-House-Only → nein.
3. **Size-Fit:** 200–2000 Cap (Club) bzw. <10k Visitors (Festival). Größer = Booking-Agentur-Territorium, kleiner = oft unbezahlt.
4. **Region:** DACH primär, NL/BE/SE/NO/EE/IT/PT sekundär, ZA/NZ/MX als bestehende Tour-Partner-Märkte.

Wenn weniger als zwei → kein Insert.

---

## Taktiken (mix & match — nicht eine starre Pipeline)

Pro Refill-Run such dir **2–3 Taktiken** aus, mehr nicht. Diversität schlägt Tiefe in einem einzelnen Run — wenn alle 8 neuen Leads aus derselben Quelle kommen, sind sie wahrscheinlich auch alle zur selben Zeit ausgelastet.

### T1 — Lookalike anhand "Gig gebucht"

Stärkstes Signal: ein Venue hat uns schon gebucht. Such Venues die ähnliche Acts/Vibe haben.

1. Query CRM nach `status = 'Gig gebucht'` und nach `status IN ('In Verhandlung','Antwort bekommen')` (siehe [crm-queries.md](crm-queries.md) — "Lookalike-Suche").
2. Für jedes Anker-Venue: `tavily_search` nach "Acts ähnlich wie X die im letzten Jahr in [Region] gespielt haben" → finde wer **die** gebucht hat.
3. Diese Booker/Venues sind die Leads.

Beispiel-Query-Muster (nicht copy-paste, formuliere für den Anker):
> `"venues that booked [Anker-Act] OR [zweiter Anker-Act] in [Region] 2025-2026 live electronic"`

### T2 — Lineup-Cross-Reference aus Facts

`facts.md` hat eine Liste DJ-Support-Credits (Koletzki, CIOZ, Jonas Rathsman, Armen Miran, Jacob Groening, Iorie). Such Venues die **diese Acts** in den letzten 6 Monaten gebucht haben — das ist Tier-1-Hook-Material (echte Lineup-Überlappung).

Query-Muster:
> `"[Artist] live booking [Stadt OR Region] 2025 OR 2026 -tickets -merch"`

Filtere auf Org-Sites, nicht auf Aggregatoren wie RA (RA ist gut für Discovery aber nicht für Booker-Mails).

### T3 — Reply-mined Re-Routes (B2)

Wenn eine bestehende Reply ein "wende dich an [Person bei anderem Venue]" enthielt (B2-Klassifizierung) — das ist ein Empfehlungs-Lead. Quelle: CRM-`notizen` nach "Reroute →" greppen, oder die aktuelle Run-Summary.

Diese kommen **bevorzugt** in den Refill, weil sie warm sind. Hook in der späteren Touch 1: "[Originaler Venue] hat euch erwähnt."

### T4 — Festival-Saison-Heuristik

Aktuelles Datum nutzen:
- **Nov–Feb:** Festival-Booking-Saison. Such Open-Airs für Sommer DE/AT/NL/BE/SE.
- **Mar–Apr:** Late-Booking-Fenster für Spätsommer/Herbst-Festivals.
- **Mai–Aug:** Festival-Operationen-Phase — Festivals nicht jetzt anfassen, stattdessen Clubs für Winter-Saison.
- **Sep–Oct:** Club-Programming-Saison für Winter.

Query-Muster passend zur Saison:
> `"electronic music festival 2026 [Region] booking submissions open"` oder
> `"club Berlin booking [Quartal] electronic live"`

### T5 — Geographic Tour-Lookahead

Tour-Pläne aus `facts.md` (Highlights 2025/26 + Routinen) checken — wo wären wir sowieso? Cluster für Backlines/Routings:

- Wenn nächste Tour z.B. NL ansteht → vor und nach den fixen Daten Lücken füllen mit anderen NL-Venues.
- Cross-reference mit `letzter_kontakt` älter 12 Monate in derselben Region — alte Kontakte reaktivieren.

### T6 — Curator-/Promoter-Recherche statt Venue

Manchmal ist das Venue gar nicht das Subjekt — sondern der Booker/Promoter der mehrere Venues kuratiert. Such per `tavily_search`:
> `"booker electronic Berlin OR Hamburg OR Vienna live duo synth"`

Promoter-Kontakte sind hoch-Leverage: ein Kontakt → potenziell mehrere Slots.

### T7 — Calendar-Scrape Venues mit echter Aktivität

Statt "elektronische Clubs in Berlin" pauschal — such Venues mit Events **diese Woche oder im nächsten Monat** im Zielgenre. Aktive Venues > schlafende Venues.

Query-Muster:
> `"[Venue-Typ] events this week [Region] melodic house OR organic OR live"`

Aktiv = bookt grade = potenziell näher am nächsten Slot.

---

## Per Lead: Required Output ins CRM

Bevor du `INSERT`-est, brauchst du:

- `name` — Booker-Name wenn auffindbar, sonst "Booking [Venue]"
- `venue` — Venue-Name (Pflicht)
- `email` — eine echte Mail. **Wenn nur Kontaktformular**, skip (Skill kann keine Forms ausfüllen). Wenn nur `info@…`, geht als Last Resort, dann `personalization_tier` realistisch.
- `stadt`, `land` (constrained, siehe Schema)
- `typ` (constrained)
- `booker_research` — 1–2 Sätze: wer ist der Booker, was bucht das Venue typischerweise
- `venue_research` — 1–2 Sätze: warum passt das (welche Acts, welche Größe, welche Vibe)
- `notizen` Logzeile: `{YYYY-MM-DD} Akquise via {T1|T2|...} · {Source-URL}`

Anti-Duplicate: vor Insert Domain-Check (siehe [crm-queries.md](crm-queries.md)).

## Was du **nicht** tust

- Keine Domain-Wide-Scrapes. Tavily-Queries gezielt formulieren.
- Keine Kontaktformulare als `email` eintragen. Lieber skip.
- Keine erfundenen Booker-Namen. Wenn nicht auffindbar → "Booking [Venue]".
- Keine Pauschal-Suchen ("techno venues berlin") — die liefern Mainstream-Genres die nicht passen.
- Keine Cold-Inserts ohne `booker_research` + `venue_research` — der spätere Draft wird sonst Tier 3 und Tier 3 verbrennt Pipeline-Plätze.

## Quality-Signal

Ein guter Refill-Run produziert Leads mit denen der spätere Touch 1 **Tier 1 oder Tier 2** sein kann. Wenn der Refill nur Tier-3-fähige Leads produziert (nichts Spezifisches zu sagen), war der Refill zu pauschal — beim nächsten Mal andere Taktiken kombinieren.
