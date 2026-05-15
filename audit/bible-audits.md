# Bible & skill audit log

Append-only log of Bible audits, skill regressions, and remediation actions. Maintained by the **`kon-faber-weekly-audit`** scheduled task (Sundays 19:00 local) and by manual notes during incidents.

Newest entries on top.

---

## 2026-05-15 — Bible refactor (manual)

Split monolithic `bible-snapshot.md` into five concern-specific files under `references/`. Workflow logic and AI-pattern regex linter moved out of the Bible into `skills/outreach.py` (Phase 1). Audit log moved here.

Rationale: previous Bible mixed voice (Grundton, Don'ts), facts (References, Tours), templates (Touch 1/2/3), workflow logic (Anti-duplicate, CRM-sync, Cadence), code-like rules (regex linter list), and operational notes (this audit log) in a single 460-line file. Hurt learnability — couldn't tell whether bad outputs were voice failures or workflow failures.

New structure:
- `references/voice.md` — Bible (voice + sacred lines + don'ts)
- `references/facts.md` — knowledge base
- `references/release-calendar.md` — date-bound tempus rules
- `references/templates.md` — exemplar mails (anchors, not scripts)
- `references/replies.md` — B1-B5 classification heuristics
- `skills/outreach.py` — workflow + linter (Phase 1)
- `audit/bible-audits.md` — this file

Best-practice grounding: 2026 cold-outreach research consistently emphasises "principles > templates" — agent-written emails that follow a fixed structure are increasingly flagged by inbox AI and read as templated by experienced bookers.

## 2026-05-11 — Audit: AKUT-FLAG

**Critical Bible-Don't violations across multiple existing drafts.** Findings:

**Bible ↔ Skill inconsistency:**
- Quality-Check missing: Hyperbole rule (mega/nice/krass), equipment-listing prohibition, one-link-per-mail rule, follow-up length (30-50W).
- AI-Pattern-Linter in skill missing EN pattern "drop a note".

**Determinism:**
- Subject-line "Kon Faber live [...]?" dominated 25+/27 drafts → no variation from Bible patterns (Slot frei?, Booking [Venue]?, Anfrage [Venue]).
- Proof order nearly identical (Fusion + NZ/ZA-Tour + SvT/Kotori).
- Personalization Tier logged in only 1/6 sampled contacts → systematic logging failure.

**Draft hygiene:**
- 27 total drafts, 6 ≥5 days old (oldest 2026-04-30 = 11 days), 5 more ~6 days.
- Anti-duplicate logic failures: 2× draft to info@gewoelbe.net (5./8.5.) and 2× to info@wakinglife.pt (3./7.5.).
- Content: 8+ drafts with em-dashes, 7+ with "Seebühne", 8+ with "neben Koletzki im Ritter Butzke", 3 with Frida-Darko remix, 6+ with "Earlier this year"/"Anfang des Jahres". Length mostly >80 words.
- Improvement visible from 2026-05-11 (Garbicz/Thuishaven/Phaex/Voodoo) — em-dashes gone, Seebühne gone.

**CRM-Sync:**
- Status "Angeschrieben" being set at drafting instead of at send → discrepancy for Hafen 49, Climax, Habitat, Waking Life, Garbicz etc. (Drafts sit unsent; CRM claims sent.)
- Touch-Notes ("Touch 1: [Date], Subject: [...], Tier [X]") missing from nearly all Notes fields.

**Voice drift:**
- Skill using outdated self-description "Synthesizer und Vocals" instead of Bible's "Synthesizern und einem treibenden, durchproduzierten Clubsound" in ALL checked drafts → 2026-04-30 cadence update never propagated to skill mail generation.

**Recommendations:**
1. Skill self-description block → corrected to verbatim Bible wording
2. Quality-Check → extended with missing Don'ts (hyperbole, equipment, one-link, follow-up length)
3. Anti-duplicate logic bug → fixed (two duplicates slipped through)
4. Status "Angeschrieben" → set on Bene's send confirmation, not on drafting
5. Personalization-Tier logging → made mandatory
6. Old drafts with Bible violations → audited and rewritten

## 2026-04-30 — Phase 1 Optimization

Mail length cap → <80 words. AI-Pattern-Linter extended. Personalization-Tier property introduced. Subject-line patterns documented. Self-Audit moved to a separate scheduled task.

## 2026-04-30 — Bible repair after verification check

Tables → lists. Removed example duplicates.

## 2026-04-30 — Cadence overhaul

Cadence → 5/16 (three touches). New self-description: "Synths + treibender, durchproduzierter Clubsound". Touch 2 = DJ-set Sisyphos. Touch 3 = Soft Breakup with Festival/Club variants. Touch 4 removed.

## 2026-04-30 — Initial consolidation

Em-dash prohibition. Koletzki-Butzke combination removed. "Seebühne" removed. Seasonal tempus logic introduced.
