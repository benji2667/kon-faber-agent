---
name: crm-sync
description: Reconciliation zwischen Gmail und Supabase contacts. Setzt status, letzter_kontakt aufgrund von tatsächlich gesendeten Mails und empfangenen Replies. Läuft separat von outreach-drafts.
---

# crm-sync

Diese Skill ist die einzige die `status` und `letzter_kontakt` schreibt. Sie liest Gmail als Source-of-Truth und schreibt das ins CRM. `outreach-drafts` erzeugt nur Drafts und Logzeilen — die werden hier nicht doppelt verarbeitet.

**Voice-Bibel nicht relevant** für diese Skill — keine Mails werden hier geschrieben. Bibel wird **nie** geladen.

## Tools

- **Supabase:** `execute_sql` (Schema-Spickzettel siehe [../outreach-drafts/references/crm-queries.md](../outreach-drafts/references/crm-queries.md))
- **Gmail:** `search_threads`, `get_thread`
- **Filesystem / Git** (für Drift-Logs in `audit/bible-audits.md` — siehe Schritt 5)

## Wann läuft das

**Zwei Cron-Slots:**

1. **Direkt nach jedem `outreach-drafts` Run.** Fängt den frischen State ein — was die Skill grade an Replies klassifiziert hat, wird hier zu Status-Übergängen.
2. **Nächtlicher Standalone-Run (z.B. 23:30 lokal).** Fängt Mails ein die der Mensch tagsüber manuell rausgeschickt hat (von der Hand oder aus dem Gmail-UI), ohne dass `outreach-drafts` lief.

Beide Läufe verwenden den gleichen Workflow. Idempotent — ein zweiter Run im selben Slot ändert nichts.

## Workflow

### 1. Gerade-gesendet-Sweep

```
search_threads(q='in:sent newer_than:2d')
```

Für jeden Thread:
- Empfänger-Mail extrahieren.
- Match gegen `contacts.email`.
- Letzte gesendete Message-Datum lesen.

Wenn Match und `contacts.letzter_kontakt < send_date` (oder NULL):

```sql
UPDATE contacts
SET letzter_kontakt = $1,
    status = CASE
      WHEN status IN ('Neu','Recherchiert') THEN 'Angeschrieben'
      ELSE status
    END,
    updated_at = now()
WHERE id = $2;
```

Status wird **nur** Neu/Recherchiert → Angeschrieben gepusht. Spätere Stati ('Antwort bekommen' etc.) werden hier nicht überschrieben.

### 2. Inbound-Reply-Sweep

```
search_threads(q='in:inbox newer_than:2d -from:me')
```

Für jeden Thread mit Match in contacts:
- Wenn `status = 'Angeschrieben'` → `status = 'Antwort bekommen'`.
- `letzter_kontakt` nicht aus Inbound setzen — das bleibt Outbound-Marker.
- `naechste_aktion = CURRENT_DATE` (damit der Mensch / outreach-drafts es sieht).

```sql
UPDATE contacts
SET status = 'Antwort bekommen',
    naechste_aktion = CURRENT_DATE,
    updated_at = now()
WHERE id = $1 AND status = 'Angeschrieben';
```

### 3. Decline-Sweep (aus outreach-drafts Run-Summary)

Wenn die `outreach-drafts` Skill in ihrer Summary B3-Declines listet (per `notizen` "Decline B3" oder direkter Payload-Übergabe):

```sql
UPDATE contacts
SET status = 'Abgesagt',
    naechste_aktion = NULL,
    updated_at = now()
WHERE id = $1;
```

### 4. Stale → Eingeschlafen

Kontakte mit 3+ Outgoing-Touches im Gmail-Thread und keinem Reply, letzter Touch > 30 Tage:

```sql
SELECT id, email FROM contacts
WHERE status = 'Angeschrieben'
  AND letzter_kontakt < CURRENT_DATE - INTERVAL '30 days';
```

Pro Kandidat im Gmail-Thread Outgoing zählen (≥3) und Inbound = 0 prüfen. Treffer:

```sql
UPDATE contacts
SET status = 'Eingeschlafen',
    naechste_aktion = NULL,
    updated_at = now()
WHERE id = $1;
```

### 5. Sanity-Checks (Logs + Audit-File-Append)

Finde Drift — nicht selbst korrigieren, aber dokumentieren:

- `status = 'Angeschrieben'` aber kein Gmail-Outgoing in den letzten 60 Tagen → Status wahrscheinlich falsch.
- `status = 'Antwort bekommen'` aber kein Inbound-Reply im Thread → Status wahrscheinlich falsch.
- `letzter_kontakt` in der Zukunft → Datenfehler.
- Kontakt mit Gmail-Send-Event aber `letzter_kontakt` NULL nach Schritt 1 → Match-Failure (z.B. Mail an andere Adresse als in CRM).

**Wenn mindestens ein Drift-Eintrag** → append dated section to `audit/bible-audits.md` (newest entries on top, format passt zu vorhandenen Einträgen):

```markdown
## {YYYY-MM-DD} — crm-sync drift report

Run: {nightly|post-outreach}. {N} drift findings, no auto-fix:

- **{contact_name} ({venue})** — status `Angeschrieben`, kein Gmail-Outgoing seit 73 Tagen. Vermutlich nie gesendet oder andere Mail-Adresse.
- **{contact_name} ({venue})** — status `Antwort bekommen`, aber Thread enthält keinen Inbound. Vermutlich falsch gesetzt.
- ...

Kein Drift-Eintrag bedeutet kein Block hier. Mensch reviewt manuell bei Gelegenheit.
```

Wenn **null Drift** in dem Run → **keine** Zeile in `audit/bible-audits.md` schreiben (das File wächst sonst mit Rauschen).

Gleicher Drift-Block landet auch in der Telegram-Summary (Abschnitt "CRM drift").

## Harte Regeln

- **Nie** Status downgrade'n außer durch explizite "Decline B3" oder "Stale → Eingeschlafen" (siehe oben).
- **Nie** `notizen` überschreiben — nur append (siehe `outreach-drafts` Skill, hier passiert kein Append).
- **Nie** Drafts erstellen oder Mails senden — read-only auf Gmail.
- **Nie** Daten erfinden — wenn Gmail leer ist, bleibt das CRM-Feld leer.
- **Nie** in `audit/bible-audits.md` schreiben wenn null Drift — leere Daily-Einträge sind Rauschen.

## Output

Kurze Telegram-Summary:

- Status-Übergänge: `Neu → Angeschrieben: X, Angeschrieben → Antwort bekommen: Y, → Abgesagt: Z, → Eingeschlafen: W`
- CRM drift (Sanity-Checks Treffer) — dieselben Einträge die auch im `audit/bible-audits.md` landen
- Threads die der Mensch reviewen sollte

## Out of Scope

- Inhaltliche Reply-Klassifizierung (B1–B5) → das ist `outreach-drafts`.
- Notion-Sync → Notion ist veraltet, kein Sync.
- Neue Leads → `outreach-drafts` Schritt 7.
