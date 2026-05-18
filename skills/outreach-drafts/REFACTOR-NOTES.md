# Refactor notes — skill-refactor-v1

Branch: `skill-refactor-v1` off `main` (0e006a4). For human review — no PR opened, no merge to main.

## Files added

```
skills/
  outreach-drafts/
    SKILL.md
    REFACTOR-NOTES.md (this file)
    references/
      crm-queries.md
      crm-updates.md
      voice-linter.md
      acquisition-strategy.md
  crm-sync/
    SKILL.md
```

## Token / line counts

| File | Lines |
|---|---|
| Legacy `daily-outreach-drafts/SKILL.md` (per brief) | ~290 |
| New `outreach-drafts/SKILL.md` | ~110 |
| `references/crm-queries.md` | ~110 |
| `references/crm-updates.md` | ~85 |
| `references/voice-linter.md` | ~60 |
| `references/acquisition-strategy.md` | ~120 |
| `crm-sync/SKILL.md` | ~130 |

The SKILL.md alone went from ~290 lines → ~110 lines. Total surface area grew because content was unpacked into per-concern reference files — but per-run loaded context shrinks: in a typical "empty inbox + due batch = 0" run, the agent only loads the lean SKILL.md and `crm-queries.md`. Bible (voice.md, facts.md, templates.md) is only loaded once a draft is actually being written.

## What was moved out of the SKILL.md

| From legacy section | Moved to | Why |
|---|---|---|
| 4d Quality-Check + AI-Pattern-Linter | `references/voice-linter.md` | One concern per file; linter only matters at draft-time. |
| 4b Touch templates + VERBATIM intros + link URLs | already in repo Bible (`references/templates.md`, `voice.md`) | SKILL.md now points at them via relative path. |
| 6 CRM-Update-Matrix table | `references/crm-updates.md` | Table is dense reference, not per-step workflow. |
| SQL examples | `references/crm-queries.md` | Same — read once when needed, not in every run. |
| 2.5d Action-Type-Routing table | deleted | Redundant with prose in step 1 (Inbox sweep) — four real outcomes, not 15 rows. |
| 2.5c CRM-Sync-Korrektur | `skills/crm-sync/SKILL.md` | Split skill so it can run independently / on its own schedule. |

## What was rewritten

- **B1–B5 classifier:** The 15-row Action-Type enum is gone. Step 1 of the workflow describes four outcomes in prose (reply / reroute / decline / OOO / unclear). Classification anchors still come from `references/replies.md` in the repo — that file already exists and stays canonical.
- **Cadence rules:** Now prose ("Day 0 → +5 → +16, Toleranz ±1 Tag"), not a typed schedule table.
- **Subject lines:** "Pick one good subject" — no more "3 variants, log in Notes". `voice.md` already lists anchor patterns.
- **Personalization tier:** Mandatory per draft, logged in `notizen` — same as before, just compressed.

## What is new (beyond cleanup)

1. **Inbox-Sweep first.** Step 1 of the SKILL.md is now a Gmail-wide unread sweep across **all** past-outreach threads, not just today's batch. Replies always preempt outbound — and if the run hits the 6–8 draft cap on replies alone, no new outbound goes out that day.
2. **Pipeline refill.** Step 7 runs only when `count(Neu+Recherchiert) < 15`. When triggered, agent works `references/acquisition-strategy.md`.
3. **Acquisition strategy file.** Seven named tactics (T1–T7) covering: lookalikes off `status='Gig gebucht'`, lineup cross-reference, reply-mined B2 reroutes, festival-season heuristic, geographic tour-lookahead, curator/promoter recherche, active-calendar scrape. **No seeded venue lists** — tactics only, agent picks 2–3 per refill.

## Tool naming

The brief listed: `execute_sql`, `list_drafts`, `create_draft`, `get_thread`, `search_threads`, `delete_draft`, `tavily_search`. All used verbatim. No tool names invented or renamed.

## Decisions I made without checking

- **Voice-linter as its own file vs folded into `voice.md`.** Kept it separate (`references/voice-linter.md` inside the skill). Reason: `voice.md` in the repo Bible reads as taste/feel for humans + agent, and explicitly says "agent should *feel* these, not check a list." A regex-style backstop list belongs adjacent to the skill that runs it, not in the Bible's tone-of-voice doc. If you'd rather have it merged, easy move.
- **No `touch_count` column in `contacts` schema.** I treat touch count as derived from Gmail (count outgoing messages in thread), not stored in CRM. Avoids the dual-source-of-truth problem.
- **No `language` column either.** Per-draft, language is decided from org context (domain, website) — already the rule in `voice.md`.
- **`crm-sync` lives at `skills/crm-sync/SKILL.md`** (no nested `references/`) — it references `outreach-drafts/references/crm-queries.md` for the schema cheatsheet. Reuse over duplication.
- **CRM updates from `outreach-drafts` never touch `status`** at all (except `INSERT` on new acquisition leads as `'Neu'`). All `status` transitions are owned by `crm-sync`. This is the cleanest enforcement of "Gmail = source of truth".

## Open questions for you

1. **Where is the actual legacy `SKILL.md`?** It wasn't attached to this session and isn't in the repo (only `skills/.gitkeep` exists). I refactored from the diagnosis in your brief + the existing `references/*.md`. If the original has more rules I didn't infer, point me at it and I'll fold them in.
2. **`crm-sync` trigger.** I wrote it to run after every `outreach-drafts` run. Do you want it on its own cron schedule too (e.g., a nightly run to catch human-sent mails)? The skill itself supports both modes — just needs an orchestration decision.
3. **Reply auto-handle for B1.** Right now `outreach-drafts` drafts B1 replies. The legacy `references/README.md` mentions a separate `responder.py` skill. Want B1 reply drafting kept inside `outreach-drafts` (current choice — fewer skills, single Telegram summary) or split out into its own skill?
4. **`personalization_tier` on acquisition inserts.** I leave it `NULL` at insert time and let the later Touch-1 draft set it. Alternative: set it speculatively from the research quality. Your call.
5. **Stale threshold.** Currently 3+ outgoing touches + 30 days since last touch → `Eingeschlafen`. Legacy may have used a different number — confirm and I'll align.
6. **`audit/bible-audits.md`** is referenced from `references/README.md`. The new skills don't write there. Should `crm-sync` log status-drift findings into it, or just into the Telegram summary?
7. **Notion mirror.** I treat Notion as stale per your brief and don't touch it. If you ever want a one-way push from Supabase → Notion, that's a separate skill — flag and I'll spec it.

## Anything I couldn't decide

- **`skills/.gitkeep`.** I left it in place. It's harmless once real skills exist; if you'd rather have it gone, delete in a separate commit so the diff stays clean.
- **Cross-skill state passing.** `outreach-drafts` end-of-run could write a tiny JSON manifest (which contacts got drafts, which got B3 declines surfaced) that `crm-sync` reads, instead of `crm-sync` re-deriving everything from Gmail. Cleaner contract but more moving parts. I went with re-derivation for now (simpler, more robust to crashes). Happy to add the manifest if you want stricter coupling.
