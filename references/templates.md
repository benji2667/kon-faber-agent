# Templates

These are **exemplars, not scripts.** The agent reads them to anchor its sense of what "right" looks like — not to copy structure verbatim.

If the agent produces an email that *follows* one of these so closely that the only changes are venue name and lineup hook, the result will be detectable as templated. The point is to internalise the *feel*, then write fresh.

When the agent uses one of these as a starting reference, it should:
1. Take the rhythm (sentence count, opening cadence)
2. Take the voice register
3. **Throw away the specific phrasing** and rewrite for the contact

---

## Touch 1 exemplars

### Touch 1, English (international org, before 2026-07-01)

> Hey there!
>
> Sainte Vie and Fejká at your events show we're moving in the same musical world. We're Kon Faber, an electronic live duo from Berlin, with synthesizers and a driving, polished club sound. We'd love to play a live set at Wild as the Moon.
>
> We just toured New Zealand and South Africa, and our remix for Oliver Koletzki is out in July on Stil Vor Talent.
>
> EPK: konfaber.com/epk
>
> Where are you at with summer 2026?
>
> Bene & Nils

### Touch 1, German (DACH, before 2026-07-01)

> Hey!
>
> Dass ihr Acid Pauli und Monolink bucht, zeigt dass wir musikalisch sehr nah beieinander liegen. Wir sind Kon Faber, ein elektronisches Live-Duo aus Berlin, mit Synthesizern und einem treibenden, durchproduzierten Clubsound. Hätten richtig Lust, ein Live-Set bei euch zu spielen.
>
> Wir sind gerade in Neuseeland und Südafrika getourt, und im Juli kommt unser Remix für Oliver Koletzki auf Stil Vor Talent.
>
> EPK: konfaber.com/epk
>
> Habt ihr noch Slots frei für Sommer 2026?
>
> Bene & Nils

## Touch 2 exemplars

**Strategy:** Sisyphos DJ-set as a new angle. Adds a second booking option without undermining the Touch-1 live pitch. Short routing question for cases where the booking contact wasn't clear.

### Touch 2, English

> Hey, just released our DJ set from Sisyphos in Berlin: [Sisyphos link]. Wanted to add that we play DJ sets as well, in case that's useful for your booking.
>
> Who would be the right person to talk to about a slot?
>
> Bene & Nils

### Touch 2, German

> Hey, wir haben gerade unser DJ-Set aus dem Sisyphos veröffentlicht: [Sisyphos link]. Wollten kurz nachreichen, dass wir neben Live auch DJ-Sets spielen, falls das für euer Programm relevant ist.
>
> An wen können wir uns wegen eines Gigs wenden?
>
> Bene & Nils

**Sisyphos link** (single canonical URL): https://soundcloud.com/kon-faber/halligalli-im-sisyphos-kon-faber

## Touch 3 exemplars (Soft Breakup)

**Strategy:** Last nudge. Warm, no hard deadline, easy to come back to. The skill picks the variant based on the contact's `Typ`:
- `Typ = "Festival"` → festival variant (season-bound)
- otherwise → default variant (time-agnostic)

### Touch 3 default (Club / Bar / Kulturzentrum / Sonstiges)

**DE:**
> Hey,
>
> wir melden uns ein letztes Mal. Falls grundsätzlich Interesse besteht, freuen wir uns immer von euch zu hören, ganz zeitunabhängig. Sonst auch alles gut, wir behalten euch auf dem Schirm.
>
> EPK: konfaber.com/epk
>
> Bene & Nils

**EN:**
> Hey,
>
> last note from our side. If you're generally interested in having us at some point, drop us a line whenever, no pressure on timing. Otherwise all good, we'll keep you in mind.
>
> EPK: konfaber.com/epk
>
> Bene & Nils

### Touch 3 festival variant

**DE:**
> Hey,
>
> wir melden uns ein letztes Mal vor eurer aktuellen Saison. Falls dieses Jahr noch was Live oder DJ bei euch passt, lasst es uns wissen. Sonst alles gut, wir freuen uns einfach wenn sich unsere Wege irgendwann kreuzen, ob bei einer kommenden Edition oder anderswo.
>
> EPK: konfaber.com/epk
>
> Bene & Nils

**EN:**
> Hey,
>
> last note before your current season. If something live or DJ still fits this year, let us know. Otherwise no worries, we'd love to cross paths at some point, whether at a future edition or elsewhere.
>
> EPK: konfaber.com/epk
>
> Bene & Nils

## B1 reply exemplars (auto-handle)

These get used when the responder skill auto-classifies a reply as B1 (positive interest). The drafted reply goes in the same Gmail thread.

### B1 reply to "send tech rider / more info"

**DE:**
> Hey [Name],
>
> klasse, freut uns. Tech-Rider und Hospitality-Rider sind beim EPK verlinkt: konfaber.com/epk. Falls ihr was Konkretes braucht, sagt einfach kurz Bescheid.
>
> Liebe Grüße,
>
> Bene & Nils

**EN:**
> Hey [Name],
>
> awesome, glad to hear. Tech rider and hospitality rider are linked from the EPK: konfaber.com/epk. Let us know if you need anything specific.
>
> All the best,
>
> Bene & Nils

### B1 reply to "do you have [date]?"

**DE:**
> Hey [Name],
>
> [Datum/Zeitraum] passt grundsätzlich. Ist es noch für ein Live-Set oder DJ-Set? Und liegt das Honorar in eurer üblichen Range für Acts auf unserem Level?
>
> Liebe Grüße,
>
> Bene & Nils

**EN:**
> Hey [Name],
>
> [date/window] works for us in principle. Live set or DJ set? And is the fee in line with what you usually pay acts at our level?
>
> All the best,
>
> Bene & Nils

### B1 reply to vague "sounds good, let's talk"

**DE:**
> Hey [Name],
>
> freut uns. Habt ihr ein konkretes Date oder einen Zeitraum im Kopf, in den wir reinschauen sollten? Sonst gerne ein kurzer Call, mein Kalender liegt offen.
>
> Liebe Grüße,
>
> Bene & Nils

**EN:**
> Hey [Name],
>
> glad to hear. Do you have a specific date or window in mind we should look at? Otherwise happy to jump on a quick call.
>
> All the best,
>
> Bene & Nils

## Hard requirements for reply drafts

- **Same Gmail thread** — use the existing `threadId`, never start a new thread
- **No self-introduction** — they know us
- **No EPK opener** — they already have it; reference only when relevant
- **End with a concrete question** — keeps the thread moving
