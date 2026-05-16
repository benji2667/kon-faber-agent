# Kon Faber Outreach Agent — Project Plan (v2.1)

_v2.1 • 2026-05-14 — added Responder phase, Dashboard phase; reordered_

Supersedes [02-project-plan.md](../project-docs/02-project-plan.md).

Phased rollout. Each phase ends with something **usable end-to-end** before adding the next layer.

## Phase 0 — Foundation (~half a day)

- [ ] Verify Hermes Agent installs cleanly in a Docker container
- [ ] Create Railway project: `kon-faber-agent`
- [ ] Single Railway service running the Hermes Docker image
- [ ] Add Railway persistent volume (`/data`) for Hermes memory + skill store
- [ ] Set env vars: `OPENROUTER_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `NOTION_API_KEY`, `GMAIL_*`, `TELEGRAM_BOT_TOKEN`
- [ ] Open Hermes Telegram bot via @BotFather, link to Hermes
- [ ] Smoke test: send "hello" to Telegram bot → get a response

**Done when:** Hermes is running on Railway, you can text it on Telegram and get a response.

## Phase 1 — Outreach skill MVP (~1-2 days, SKILL.md already exists)

- [ ] **Port** existing `SKILL.md` (293 lines, already complete) into Hermes skill format — mostly mechanical
- [ ] Use **`bible-snapshot.md`** as Bible source for v1 (Notion deferred to Phase 6)
- [ ] Connect MCP sources to Hermes: Supabase, Gmail
- [ ] Brave Search integration for venue research
- [ ] Manual trigger: `/outreach 2` command in Telegram → runs workflow against 2 test contacts

**Done when:** `/outreach 2` in Telegram drafts 2 emails into Gmail Drafts, correctly using Bible voice and CRM data, action-types route properly.

## Phase 2 — Reviewer skill + autonomous cron (~1-2 days)

- [ ] Add **Reviewer sub-skill**: scores drafts against Bible rules
  - Checks already specified in SKILL.md (§4d): AI-pattern detection, em-dashes, length caps, exact self-description, tone match, hyperbole, equipment lists
  - Pass → save to Gmail Drafts; Fail → one revision pass with reviewer feedback in context
- [ ] Set up Hermes cron: 2×/week (Tue + Fri at 09:00 Berlin time)
- [ ] Daily summary report posted to Telegram (per SKILL.md §7)
- [ ] CRM update logic per SKILL.md §6 matrix

**Done when:** the agent runs autonomously twice a week, posts a summary, drafts pass the reviewer, no manual trigger needed.

## Phase 3 — Responder skill (event-driven reply drafting) (~2 days) ★ NEW

The outreach run already drafts replies for B1 cases, but only when it next fires. This phase makes reply handling **continuous** — replies get drafted within minutes, not days.

- [ ] **Responder skill** triggered by new Gmail messages on threads we initiated
  - Detection: start with **15-minute Gmail polling** (simpler than push notifications)
  - Upgrade path: Gmail Pub/Sub push notifications via Google Cloud (free tier) — optional later
- [ ] **Classify** incoming reply per SKILL.md §2.5b (B1 Positive / B2 Re-Route / B3 Negative / B4 OOO / B5 Unclear)
- [ ] **B1**: draft warm, specific reply in the existing Gmail thread, advancing toward a date/concrete next step
- [ ] **B2/B5**: post to Telegram with summary + thread link, no auto-draft
- [ ] **B3/B4**: CRM update only, ping Telegram with one-line FYI
- [ ] **Telegram card per reply**: who, bucket, summary, draft link if any
- [ ] Anti-duplicate: skip if a reply-draft already exists in the thread

**Done when:** a real reply lands in your inbox; within 15 min you get a Telegram card; for B1 you find a polished draft in the thread ready to send.

## Phase 4 — Dashboard (~2-3 days) ★ NEW

A small, beautiful read-only UI for cost and activity.

- [ ] Next.js 15 + Tremor.so + Tailwind, dark theme by default
- [ ] Deploy as a **second Railway service** in the same project (user wants Railway practice)
- [ ] Single password gate (env var) — minimal auth
- [ ] Reads from Supabase directly with service key (server-side only)
- [ ] **Three views**:
  - **Today**: this week's runs, drafts created, replies received, current pipeline state, today's spend
  - **Activity**: timeline of runs, drafts, replies, voice-note lessons — filterable
  - **Cost**: month-to-date spend, projected, by model, by skill (outreach vs responder vs reviewer)
- [ ] Cost tracking: every LLM call logged to a new `llm_calls` table (model, tokens-in/out, est. cost, skill, run_id)
- [ ] Optional: small "/dashboard" command in Telegram → returns a short text summary

**Done when:** you can open the dashboard from your phone, see what your agent did this week and how much it cost, on a UI that doesn't make you wince.

## Phase 5 — Telegram voice feedback loop (~1-2 days)

- [ ] Configure local STT in Hermes (faster-whisper, runs inside container, free)
- [ ] **Feedback parser**: voice note → transcribed → lesson extracted → tagged to draft/contact
- [ ] Store lessons in Hermes skill memory + Supabase `feedback` table
- [ ] Next run loads recent lessons as context for the drafter

**Done when:** voice note "tone was too pushy" → next run's drafts are visibly less pushy.

## Phase 6 — Reply tracker + Notion + Bible auto-evolution (~3-4 days)

- [ ] **Wire Notion MCP** finally — the Bible moves from snapshot.md to live Notion
- [ ] **Reply tracker** (daily cron): aggregate which templates/touches produce which reply sentiments
- [ ] Build template_performance view in Supabase (already specced in architecture doc)
- [ ] **Bible-edit proposer**: weekly Telegram summary with data-driven Bible change suggestions
- [ ] Approval flow via Telegram → if approved, agent writes Bible edit to Notion

**Done when:** weekly Telegram digest shows performance stats and concrete Bible diff proposals.

## Phase 7 — Inbox triage + invoice forwarding ★ NEW

First concierge skills — start expanding from outreach to full inbox assistant.

- [ ] **Inbox triager skill**: every new inbound mail → classify (work / outreach reply / invoice / newsletter / shipping / calendar / personal / other) → apply Gmail label
- [ ] **Invoice forwarder skill**: invoice-classified emails → draft forward to your accountant → request approval via Telegram → send on approve
- [ ] **Reusable `telegram_approval` skill**: posts card with inline approve/reject buttons, awaits response, returns decision
- [ ] Re-consent Gmail OAuth with broader scopes: `gmail.send`, `gmail.modify`

## Phase 8 — Unsubscriber + flight check-in + calendar triage ★ NEW

Heavier concierge features. Each is a skill, no architecture changes.

- [ ] **Unsubscriber skill**: classifier flags newsletter → list-unsubscribe header or web flow → Hermes' browser (Playwright pre-baked) clicks the link → approval per-newsletter, learn patterns for repeat senders
- [ ] **Flight check-in skill**: parses flight confirmations → cron triggers 24h before flight → browser flow → seat selection requires approval
- [ ] **Calendar triage skill**: ICS attachment in inbound mail → suggest accept/decline → request approval

## Phase 9 — Polish & quality of life

- [ ] Per-venue knowledge graph in Supabase
- [ ] Research caching: don't re-research recently-researched contacts
- [ ] LangFuse if Hermes' built-in tracing isn't enough
- [ ] Voice replies from agent (TTS) for two-way voice
- [ ] Multiple Bible variants for A/B testing
- [ ] **Railway CLI in container** + Railway API token → agent can redeploy / inspect logs itself
- [ ] Package delivery tracker
- [ ] Multi-account support (personal + work Gmail)

## Cost forecast

| Item | Estimate/month |
|---|---|
| Railway Hobby plan + small container | €5-10 |
| Railway dashboard service (Hobby) | €3-5 |
| LLM via OpenRouter (tiered Sonnet/Haiku, both skills) | €2-5 |
| Brave Search | €0 (free tier covers 2k queries/mo) |
| Telegram bot | €0 |
| Local STT (faster-whisper) | €0 |
| Supabase | €0 (free tier covers our scale) |
| Notion API | €0 |
| **Total** | **€10-20/month** |

The responder skill adds modest LLM cost (~€0.50-2/mo extra) — each reply is just one classification + one draft (~3-5k tokens each). Even at 20 replies/week that's <€2/mo.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Hermes is bleeding edge (released Feb 2026) — possible bugs | Stick to v0.2+ releases; subscribe to release notes; have a fallback plan to Craft Agents |
| Voice transcription quality (faster-whisper on small models) | Test with a few of your voice notes first; upgrade to `medium` or `large-v3` model if needed |
| Reviewer agent rejects too aggressively → wasted tokens | Set max 2 revision passes; if still failing, save with warning tag |
| Bible drift (auto-evolution dilutes voice) | Require Telegram approval for every Bible edit; weekly digest, never silent |
| Cron misfires when agent is mid-conversation | Hermes handles this; cron tasks queue, don't interrupt active sessions |
| Railway charges spike unexpectedly | Set Railway spend alert; container is small, should stay <€15 even worst-case |
| OpenRouter outage | Configure fallback to Anthropic direct API |

## Time budget

End-to-end estimate: **~10-14 working days** spread over 3-4 weeks of evenings.

Minimum viable subset to ship something useful fast:
- Phase 0 + Phase 1 + Phase 2 = autonomous drafting twice a week → **~4-5 days**
- Add Phase 3 (responder) for fast replies → **+2 days**
- Add Phase 4 (dashboard) for visibility → **+2-3 days**

Phases 5, 6, 7 are the "smart over time" upgrade — defer until the base agent is proving itself.
