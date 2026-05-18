# CRM Updates

Was die `outreach-drafts` Skill ins CRM schreibt — und was sie **nicht** schreibt.

**Leitprinzip:** Gmail ist die Wahrheit für Sende-Status. Diese Skill erzeugt nur Drafts, daher flippt sie nie `status` auf "Angeschrieben". Das ist Job der [crm-sync](../../crm-sync/SKILL.md) Skill nach echtem Send.

---

## Update-Matrix per Event

| Event | `status` | `letzter_kontakt` | `naechste_aktion` | `notizen` (append) | `personalization_tier` |
|---|---|---|---|---|---|
| Touch-1 Draft erstellt | **unverändert** | unverändert | heute + 5 | + Logzeile | setzen (1\|2\|3) |
| Touch-2 Draft erstellt | **unverändert** | unverändert | heute + 11 | + Logzeile | unverändert |
| Touch-3 Draft erstellt | **unverändert** | unverändert | heute + 30 | + Logzeile | unverändert |
| Reply-Draft (B1) erstellt | **unverändert** | unverändert | heute + 3 (Soft-Bump) | + Logzeile | unverändert |
| B2 Re-Route empfangen | unverändert | heute | NULL | + "Reroute → <Name/Mail>" | unverändert |
| B3 Decline empfangen | unverändert (crm-sync setzt "Abgesagt") | heute | NULL | + "Decline B3" | unverändert |
| B4 OOO mit Datum | unverändert | unverändert | Rückkehr + 1 | + "OOO bis <date>" | unverändert |
| B5 Unklar | unverändert | unverändert | unverändert | + "B5 unklar: <excerpt 80 Zeichen>" | unverändert |
| Stale (3+ Touches, kein Reply) | unverändert (crm-sync setzt "Eingeschlafen") | unverändert | NULL | + "Stale nach Touch 3" | unverändert |
| Neuer Lead via Acquisition | `Neu` | NULL | heute + 1 | + "Akquise via <Tactic>, <Source-URL>" | NULL (Draft setzt sie später) |

## Logzeilen-Format in `notizen`

Eine Zeile pro Event, prepended (neueste oben), Format strikt — damit später parsebar:

```
{YYYY-MM-DD} {EVENT} · {DETAILS}
```

Beispiele:

```
2026-05-18 Touch 1 draft · tier 1 · hook: "Acid Pauli + Monolink im Lineup"
2026-05-18 Touch 2 draft · Sisyphos angle · routing question
2026-05-18 B1 reply draft · re: "habt ihr 14.08. frei?"
2026-05-18 B2 reroute · → mara@venue.de
2026-05-18 Akquise via lookalike(Sisyphos) · https://ra.co/clubs/12345
```

## SQL-Snippets

### Notiz prepend + `naechste_aktion` setzen

```sql
UPDATE contacts
SET notizen = $1 || E'\n' || COALESCE(notizen, ''),
    naechste_aktion = $2,
    personalization_tier = COALESCE($3, personalization_tier),
    updated_at = now()
WHERE id = $4;
```

`$1` = neue Logzeile (ohne Trailing-Newline), `$2` = date oder NULL, `$3` = tier oder NULL.

### Neuer Lead aus Acquisition

```sql
INSERT INTO contacts
  (name, venue, email, stadt, land, typ, status, prioritaet, quelle,
   kanal, booker_research, venue_research, notizen, naechste_aktion)
VALUES
  ($1, $2, $3, $4, $5, $6, 'Neu', 'Mittel', 'Akquise',
   'E-Mail', $7, $8, $9, CURRENT_DATE + INTERVAL '1 day')
ON CONFLICT DO NOTHING
RETURNING id;
```

Vor dem Insert immer Anti-Duplicate-Check per Domain (siehe [crm-queries.md](crm-queries.md)).

## Was diese Skill **nie** schreibt

- `status` (außer beim Insert eines neuen Leads als `Neu`) — Status-Übergänge sind `crm-sync` Job.
- `letzter_kontakt` für Send-Events — `crm-sync` setzt das nach echtem Gmail-Send.
- `notion_id` — out of scope, Notion-Mirror ist veraltet.
- Lösch-Operationen — nie `DELETE` aus dieser Skill.

## Idempotenz

Wenn die Skill zweimal pro Tag läuft (sollte nicht passieren, aber):
- Vor jedem Draft Gmail-State-Check (offener Draft → skip).
- Logzeilen sind tolerant gegenüber Duplikaten (eine Zeile pro Draft-Erstellung).
- `naechste_aktion` darf neu gesetzt werden, der neuere Wert gewinnt.
