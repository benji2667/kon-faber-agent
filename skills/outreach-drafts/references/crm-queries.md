# CRM Queries

SQL gegen `public.contacts` (Supabase project `qjkqcycdyeekacygihac`). Read-only Queries für den Outreach-Run. Updates → siehe [crm-updates.md](crm-updates.md).

## Schema-Spickzettel

Relevante Spalten:

- `id` (uuid), `name`, `venue`, `email`, `stadt`, `land` (`DE|AT|CH|NL|Sonstige`)
- `typ` (`Club|Festival|Open Air|Bar / Kneipe|Kulturzentrum|Sonstiges`)
- `status` (`Neu|Recherchiert|Angeschrieben|Antwort bekommen|In Verhandlung|Gig gebucht|Abgesagt|Eingeschlafen`)
- `prioritaet` (`Hoch|Mittel|Niedrig`)
- `kanal` (`E-Mail|Instagram|Beides`)
- `quelle` (`Akquise|Follow-up|Empfehlung|Inbound`)
- `personalization_tier` (int 1–3)
- `letzter_kontakt` (date), `naechste_aktion` (date)
- `notizen`, `booker_research`, `venue_research` (text)

Keine Spalte `touch_count` und keine `language`. **Touch-Zähler** kommt aus Gmail (outgoing-Messages im Thread). **Sprache** aus Org-Kontext per Draft (Domain, Website).

## Tagesbatch ziehen

```sql
SELECT id, name, venue, email, typ, status, prioritaet, land,
       letzter_kontakt, naechste_aktion, personalization_tier,
       notizen, booker_research, venue_research
FROM contacts
WHERE email IS NOT NULL
  AND email <> ''
  AND status IN ('Neu','Recherchiert','Angeschrieben')
  AND (naechste_aktion <= CURRENT_DATE OR naechste_aktion IS NULL)
ORDER BY
  CASE prioritaet WHEN 'Hoch' THEN 1 WHEN 'Mittel' THEN 2 WHEN 'Niedrig' THEN 3 ELSE 4 END,
  letzter_kontakt NULLS FIRST
LIMIT 30;
```

Filter lokal nach:
- `status = 'Angeschrieben'` → nur wenn `letzter_kontakt <= CURRENT_DATE - 4 days` (Cadence-Untergrenze, Toleranz 1 Tag früher OK).
- Doppelte Domain im Batch vermeiden (kein zweimal `@gardensofbabylon.com` am selben Tag).

## Pipeline-Health (für Refill-Entscheidung)

```sql
SELECT count(*) AS pipeline
FROM contacts
WHERE status IN ('Neu','Recherchiert')
  AND email IS NOT NULL AND email <> ''
  AND (naechste_aktion <= CURRENT_DATE OR naechste_aktion IS NULL);
```

Threshold: **< 15** → Refill triggern (siehe [acquisition-strategy.md](acquisition-strategy.md)).

## Reply-Sweep: Absender-Kontakt finden

Gmail liefert dir Absender-Mails — match in einer Query:

```sql
SELECT id, name, venue, email, status, typ, notizen, letzter_kontakt
FROM contacts
WHERE lower(email) = ANY (ARRAY[$1, $2, ...]::text[]);
```

(Lowercase auf beiden Seiten weil Gmail-Adressen case-insensitiv sind.)

## Lookalike-Suche (für Acquisition)

Welche Venues haben uns ein "Gig gebucht" gebracht — als Anker für Lookalikes:

```sql
SELECT venue, stadt, land, typ, notizen
FROM contacts
WHERE status = 'Gig gebucht'
ORDER BY letzter_kontakt DESC NULLS LAST
LIMIT 50;
```

Auch B1-Antworten (positive Signale) als sekundäre Anker:

```sql
SELECT venue, stadt, land, typ, notizen
FROM contacts
WHERE status IN ('In Verhandlung','Antwort bekommen','Gig gebucht')
ORDER BY letzter_kontakt DESC NULLS LAST;
```

## Stale-Detection (3+ Touches ohne Reply)

Es gibt keinen Counter — du erkennst Stale anhand `letzter_kontakt` und Gmail-Threads. SQL nur als Vorfilter:

```sql
SELECT id, name, venue, email, letzter_kontakt, notizen
FROM contacts
WHERE status = 'Angeschrieben'
  AND letzter_kontakt < CURRENT_DATE - INTERVAL '20 days';
```

Pro Treffer im Gmail-Thread zählen: 3+ Outgoing-Messages ohne Reply → in Summary als "stale" listen. Status-Wechsel auf `Eingeschlafen` macht `crm-sync`.

## Anti-Duplicate per Domain

Bevor ein neuer Lead via Acquisition reinkommt:

```sql
SELECT id, venue, email
FROM contacts
WHERE lower(split_part(email, '@', 2)) = lower($1);
```

Wenn Treffer → kein neuer Insert.
