# Refactor notes — skill-refactor-v1

Branch: `skill-refactor-v1` off `main` (0e006a4). Five commits. For human review — no PR opened, no auto-merge.

## Final file layout

```
skills/
  outreach-drafts/
    SKILL.md                       (~110 lines, workflow only)
    REFACTOR-NOTES.md              (this file)
    references/
      crm-queries.md
      crm-updates.md
      voice-linter.md
      acquisition-strategy.md
  crm-sync/
    SKILL.md                       (owns all status + letzter_kontakt writes)
```

`skills/.gitkeep` removed.

## Line counts

| File | Lines |
|---|---|
| Legacy `daily-outreach-drafts/SKILL.md` (per brief) | ~290 |
| New `outreach-drafts/SKILL.md` | 127 |
| `references/crm-queries.md` | 110 |
| `references/crm-updates.md` | 84 |
| `references/voice-linter.md` | 61 |
| `references/acquisition-strategy.md` | 118 |
| `crm-sync/SKILL.md` | 153 |

The lean SKILL.md is what loads on every run. Bible (voice/templates/facts/release-calendar) loads only after a non-empty batch passes the Gmail state check. Empty-batch days never load the Bible at all.

## What was moved out of the SKILL.md

| From legacy section | Moved to | Why |
|---|---|---|
| 4d Quality-Check + AI-Pattern-Linter | `references/voice-linter.md` | One concern per file; linter only matters at draft-time. |
| 4b Touch templates + VERBATIM intros + link URLs | Bible (`references/templates.md`, `voice.md`) | SKILL.md now points at them via relative path. |
| 6 CRM-Update-Matrix table | `references/crm-updates.md` | Dense reference, not per-step workflow. |
| SQL examples | `references/crm-queries.md` | Read once when needed, not in every run. |
| 2.5d Action-Type-Routing table | deleted | Redundant with prose in step 1 — four real outcomes, not 15 rows. |
| 2.5c CRM-Sync-Korrektur | `skills/crm-sync/SKILL.md` | Own skill, own schedule. |

## What was rewritten

- **B1–B5 classifier:** 15-row Action-Type enum gone. Step 1 of the workflow describes four outcomes in prose (reply / reroute / decline / OOO / unclear). Classification anchors stay canonical in `references/replies.md`.
- **Cadence rules:** Prose ("Day 0 → +5 → +16, Toleranz ±1 Tag"), not a typed table.
- **Subject lines:** "Pick one good subject" — no more "3 variants, log in Notes". `voice.md` has anchor patterns.
- **Personalization tier:** Mandatory per draft, logged in `notizen`. Tier 1 = Lineup-Hook, 2 = Vibe-Match, 3 = Genre/City-only fallback.

## What is new (beyond cleanup)

1. **Inbox-Sweep first.** Step 1 is now a Gmail-wide unread sweep across **all** past-outreach threads, not just today's batch. Replies preempt outbound. If reply drafts alone hit the 6–8 cap, no new outbound goes that day.
2. **Pipeline refill.** Step 7 runs only when `count(Neu+Recherchiert) < 15`. When triggered, the agent works `references/acquisition-strategy.md`.
3. **Acquisition strategy file.** Seven named tactics (T1–T7): lookalikes off `status='Gig gebucht'`, lineup cross-reference, B2-reroute mining, festival-season heuristic, tour-routing, promoter recherche, active-calendar scrape. No seeded venue lists — tactics only, agent picks 2–3 per refill.
4. **`crm-sync` runs on two cron slots.** Once right after `outreach-drafts`, once nightly (~23:30 local) to catch mails the human sent manually. Idempotent.
5. **`crm-sync` writes drift findings into `audit/bible-audits.md`** as dated sections — only when there's ≥1 finding (no noise on clean runs).

## Architecture invariants

- **Gmail is the source of truth for send-state.** `outreach-drafts` never touches `status` (except `INSERT` on new acquisition leads as `'Neu'`) and never touches `letzter_kontakt`. All status transitions are owned by `crm-sync`, re-derived from Gmail each run.
- **`crm-sync` is read-only on Gmail.** Never drafts, never sends. Only reads threads and writes CRM.
- **Cross-skill state is Gmail + the CRM, not a shared manifest file.** If `outreach-drafts` crashes mid-run, `crm-sync` still picks up whatever actually landed in Gmail. Robustness over coupling.
- **No `touch_count` or `language` column** in `contacts`. Touch count is derived from Gmail outgoing-message count in the thread. Language is decided per-draft from org context (domain, website).

## Tool naming

The brief listed: `execute_sql`, `list_drafts`, `create_draft`, `get_thread`, `search_threads`, `delete_draft`, `tavily_search`. All used verbatim. No tool names invented or renamed.

## Resolved decisions

| Topic | Resolution |
|---|---|
| `crm-sync` cron schedule | Two slots: post-`outreach-drafts` + nightly standalone (23:30 local). |
| B1 reply drafting | Stays inside `outreach-drafts` (token-efficient, no thread race). |
| Stale threshold | 3+ outgoing touches + 30 days since last touch → `Eingeschlafen`. |
| `audit/bible-audits.md` writes | `crm-sync` appends dated drift sections, only when findings ≥ 1. |
| `skills/.gitkeep` | Deleted. |
| Cross-skill state passing | Re-derivation from Gmail. No JSON manifest. |
| Voice-linter location | Stays in `references/voice-linter.md` inside the skill, not folded into Bible's `voice.md`. |
| `personalization_tier` on acquisition inserts | Left NULL at insert; the eventual Touch-1 draft sets it. |
| Notion mirror | Not built. Notion treated as stale. Available as separate skill on request. |

## Still open / on the user

1. **Legacy `SKILL.md` reconciliation.** The user mentioned a reworked skill from another session "already in the repo", but `main` is still at `0e006a4` and no other branch exists. If there's a version that needs to be merged or compared against this branch, it has to be surfaced before this branch merges to `main`.
2. **Pre-merge test fire.** Whether to manually trigger one `outreach-drafts` run against live CRM + Gmail before merging to `main` (Hermes auto-redeploys on push). Gmail source currently `needs auth` — would need to be authorised first.
3. **Merge mechanic.** Fast-forward, squash, or merge commit. User decides on review.
