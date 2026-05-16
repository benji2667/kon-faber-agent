# Architecture update — v2.2

_2026-05-15 — challenges resolved, inbox-concierge vision added_

This is an addendum to [01-overview-v2.md](01-overview-v2.md), [02-plan-v2.md](02-plan-v2.md), and [03-architecture-v2.md](03-architecture-v2.md).

## Decisions made

### 1. Topology: **Option 3 (orchestrator + delegations)** — confirmed

Single Hermes container on Railway. The "outreach" skill is the orchestrator's playbook. Heavy/parallelisable sub-tasks are delegated to ephemeral child agents via Hermes' built-in `delegate_task` tool.

**Rejected alternatives:**

- **Option 1 (one Hermes per subprocess):** N× hosting, fragmented learning (each silo builds its own you-model, can't share lessons), coordination overhead. The "intelligence loop in each aspect" intuition is wrong — it actively *hurts* learning because lessons don't cross silos.
- **Option 2 (one Hermes doing everything inline):** Cheap and simple, but the outreach workflow has many steps that would balloon context and serialise work. No isolation between drafting and reviewing.

**Why Option 3:**

- Hermes' `delegate_task` is native and battle-tested
- Single container, single bill, single learning loop on the orchestrator
- Subagents get isolated context (so the reviewer doesn't see the draft author's prompt)
- Parallel delegations (8 venue researches finish in 1× the wall-clock time)
- Skills are shared across all delegations — every improvement compounds

### 2. Responder is independent, not part of the cron run

Cron-triggered outreach handles outbound drafting Tue + Fri. The **responder** is event-driven via Gmail polling every 15 min. Two independent triggers, two independent skill invocations. Reply latency matters more than draft latency.

### 3. Self-config (no more `railway ssh` for setup)

Phase 0 wrap-up taught us that `hermes config set` had to be run manually inside the container. **Phase 1 deliverable:** bake config bootstrap into the Dockerfile / startup script so fresh deploys auto-configure from env vars. No more SSH-and-poke after a redeploy.

Implementation: a small `entrypoint.sh` wrapper that runs `hermes config set` commands from env vars on container start, then `exec`s the original entrypoint. The original Hermes entrypoint still handles user-switching and skill sync.

### 4. Reusable human-approval pattern

Build once as a skill: `telegram_approval(action_summary)` → returns `approved | rejected | timed_out`. Posts a Telegram card with inline buttons; awaits response with a configurable timeout.

Every "external write" skill calls this before acting. Drafts to Gmail don't need approval (low blast radius — Bene reviews in Gmail). But sending, deleting, forwarding, clicking external links — those route through this gate.

### 5. Railway-CLI-in-container deferred to Phase 7+

Nice-to-have so the agent can redeploy/log-inspect itself. But: adds an attack surface (an agent that can redeploy itself can also bork itself). Defer until after the outreach loop is solid.

Mitigation when we do add it: split capabilities — read-only ops (logs, status) ungated, writes (env vars, redeploy) require `telegram_approval` first.

## Vision: future "inbox concierge" use cases

These extend the agent from "outreach assistant" to "full inbox concierge." The architecture above supports them without changes — they're additional skills on the same Hermes container.

| Use case | New skill | Triggers | Extra Gmail scope needed | Approval needed |
|---|---|---|---|---|
| Auto-classify inbound mail | `inbox-triager` | every new email | `gmail.modify` (labels) | No (just labels) |
| Forward invoices to accountant | `invoice-forwarder` | classifier flags as invoice | `gmail.send` | **Yes** |
| Auto-unsubscribe from junk | `unsubscriber` | classifier flags + you confirm pattern | `gmail.modify` + browser | **Yes** per-newsletter, then learn pattern |
| Flight check-in 24h prior | `flight-checkin` | cron, parses flight confirmations | `gmail.readonly` + browser | **Yes** (seat selection) |
| Calendar invite triage | `cal-triager` | new ICS attachment | `gmail.modify` + calendar scope | No for read, **yes** for accept |
| Track package deliveries | `package-tracker` | classifier flags shipping email | none (read existing) | No |

**Architectural implications: none.** Each is a skill. The orchestrator routes inbound emails to a classifier sub-agent, the classifier dispatches to specialist skills, specialists call `telegram_approval` where needed. Same Hermes container, same Gmail OAuth (with progressively more scopes), same Telegram bot, same observability.

**Worth designing for now:**
- Gmail OAuth helper takes a scope list — request minimal set in Phase 1, add scopes later via re-consent
- `telegram_approval` skill built reusably from day one
- Inbox poller designed as a multiplexer — same poller feeds the responder AND future inbox-concierge skills

## Updated roadmap

| Phase | What | Status |
|---|---|---|
| 0 | Hermes on Railway + Telegram | ✅ done |
| 1 | Port SKILL.md, bible-snapshot, manual `/outreach`, **self-config in Dockerfile** | next |
| 2 | Reviewer skill + autonomous cron Tue+Fri | |
| 3 | Responder skill (event-driven reply drafting) | |
| 4 | Dashboard on Railway (Next.js + Tremor) | |
| 5 | Voice feedback loop (Telegram + faster-whisper) | |
| 6 | Notion wiring + Reply tracker + Bible auto-evolution | |
| 7 | **Inbox triage + invoice forwarding** (first concierge skills) | |
| 8 | **Unsubscriber + flight check-in + calendar triage** | |
| 9 | Polish: Railway-CLI-in-container, package tracking, multi-account | |

## What's needed for Phase 1 (next session)

In priority order, all on you:

1. **Bible snapshot** — paste current Notion Bible text into `kon-faber-agent/references/bible-snapshot.md`
2. **Supabase service role key** — into `SECRETS.local.md` + Railway env vars
3. **Decision on Brave Search** — sign up now (~5 min) or defer
4. **Gmail OAuth** — Google Cloud project + Desktop OAuth credentials + one-time refresh-token flow (we'll do this together)

Then I port your `SKILL.md` into Hermes skill format, add the self-config startup script, push, and we test `/outreach 2`.
