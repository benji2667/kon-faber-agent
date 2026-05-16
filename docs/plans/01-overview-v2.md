# Kon Faber Outreach Agent — Project Overview (v2.1)

_v2.1 • 2026-05-14 — added responder skill, dashboard, SKILL.md is ready, Notion deferred_

Supersedes [01-project-overview.md](../project-docs/01-project-overview.md).

## Vision

A **single-purpose, self-improving outreach agent** for the electronic live duo **Kon Faber**, running on Railway, drafting 6-8 personalized booking emails to venues/festivals **twice a week**, replying to incoming messages within minutes (not days), and getting smarter over time via a Telegram voice-note feedback loop. You review every draft in Gmail and send them yourself.

A small, beautiful **dashboard** gives you a single pane of glass on cost and activity.

## Two workflows

### 1. Scheduled outreach run (Tue + Fri, 09:00 Berlin)

This is exactly what your existing `SKILL.md` (`daily-outreach-drafts`) already encodes — no rewrite needed:

1. Load **Voice & Outreach Bible** (Notion later; bible-snapshot.md initially)
2. Query **Supabase CRM** (`contacts` table, 373 entries) for due follow-ups + new contacts
3. If pipeline < 10: **web research** to find more
4. **Gmail state check** — anti-duplicate logic decides action-type per contact (TOUCH_1/2/3, REPLY_DRAFT_B1, SKIP_*, etc.)
5. For new contacts: **research venue/festival**
6. **Draft 6-8 emails** following Bible templates (3-touch sequence: day 0/5/16)
7. **Reviewer skill** scores each draft against Bible rules + AI-pattern linter (fails → 1 revision pass)
8. **Save to Gmail Drafts** (never auto-send)
9. **Update CRM** — notes, next action, personalization tier
10. **Daily summary** posted to Telegram

### 2. Event-driven reply handler (continuous)

Triggered whenever a new reply lands in a thread we started:

1. **Detect** new incoming message (Gmail push or 15-min poll)
2. **Classify** the reply (B1 Positive / B2 Re-Route / B3 Negative / B4 OOO / B5 Unclear) per Bible
3. For B1: **draft a reply** directly in the Gmail thread (warm, specific, advances toward a date)
4. For B2/B5: **flag for your attention** in Telegram with a one-line summary
5. For B3/B4: **CRM update** only — no draft
6. **Ping Telegram** with a card: who replied, what bucket, link to the draft if any

This shifts reply handling from "next scheduled run" (2-3 day latency) to "minutes." Big leverage move for booking conversion.

## Success criteria

1. **Recursive learning loop** — emails improve over time (better reply rates, fewer Bible violations)
2. **Search effectiveness improves** — venue research learns which sources/genres yield good prospects
3. **Truly smart outreach assistant** — internalizes your voice, your past wins, your no-go list

## Cost target

**≤ €15/month all-in.** Currently far too expensive.

Levers (see architecture for details):
- Frequency: 7×/week → 2×/week (−71%)
- Model tiering: Sonnet only for drafting, Haiku for SQL/parsing
- Local STT (faster-whisper) for voice notes — no cloud transcription fees
- Brave Search free tier (2k queries/mo) for venue research
- Aggressive caching of venue research

## Key choices

| Decision | Choice | Rationale |
|---|---|---|
| Agent framework | **Hermes Agent (NousResearch)** | Native self-improving skills, Telegram voice memos, you want to learn it |
| Hosting | **Railway** | Always-on container needed for Telegram listener + responder; cheap flat rate |
| LLM access | **OpenRouter** | Lets us swap models freely for cost (Sonnet → Haiku → Gemini Flash etc.) |
| CRM | **Supabase** (kept as-is) | Already populated, schema works |
| Bible | **bible-snapshot.md** (v1) → **Notion** (later) | Defer Notion wiring until after agent is stable |
| Email | **Gmail Drafts** (kept as-is) | You review and send manually |
| Reply handling | **Event-driven** (Gmail push or 15-min poll) | Reply latency matters more than draft latency |
| Feedback channel | **Telegram bot** (voice + text) | Native Hermes integration |
| Dashboard | **Next.js + Tremor.so on Vercel free tier** | Modern UI, ~$0 hosting, reads Supabase directly |
| Observability | **Hermes built-in traces** + cost tracking in our dashboard | Add LangFuse only if needed later |

## Non-goals (v2.1)

- Auto-sending emails (you stay in the loop)
- Multi-user / multi-band support
- General-purpose assistant (this is single-purpose by design)
- Heavy dashboard (it's read-only — cost + activity only, no actions)
- Real-time chat — agent runs scheduled + event-driven, no human chat loop

## What changed from v1 → v2 → v2.1

**v2:**
- ✂️ Removed multi-agent decomposition into 4 services (one Hermes container)
- ✂️ Removed "Hermes as Socratic advisor" misinterpretation
- ➕ Telegram voice feedback loop, Reviewer skill, reply tracker, Bible auto-evolution
- ↓ Scope narrowed to Kon Faber outreach only
- ↓ Cost target €10/mo

**v2.1 (this revision):**
- ➕ **Responder skill** for event-driven reply drafting (was buried in outreach run)
- ➕ **Dashboard** on Vercel — cost & activity, beautiful, simple, ~$0
- ↻ Acknowledge **SKILL.md is complete** — Phase 1 is port + adapt, not author
- ↻ **Notion deferred** — start with bible-snapshot.md, wire Notion in Phase 6

## Open assumptions to confirm

1. **OpenRouter** as LLM gateway ✅ (confirmed)
2. **Cron schedule** Tue + Fri ✅ (confirmed)
3. **Notion deferred** ✅ (confirmed) — using bible-snapshot.md until later phase
4. Telegram bot identity = your personal Telegram (we register a new bot via @BotFather)
5. Bible auto-evolution requires Telegram approval before writing back
6. Skills are written in Python (Hermes' native language)
7. Dashboard on Vercel free tier (alternative: same Railway project as a second service)
8. Reply detection: Gmail push notifications via Pub/Sub OR 15-min polling — start with polling for simplicity
