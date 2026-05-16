# Phase 1 — Start Here (Handover)

_Created 2026-05-15 to start a fresh session with clean context_

This document is the entry point for the next session. Read this first, then follow the **Next actions** at the bottom.

## What's done

- ✅ **Phase 0** — Hermes Agent v0.13.0 deployed on Railway (`hermes-agent` service in `kon-faber-agent` project), Telegram bot paired with Bene (`benji2667`, user ID `5930243179`), `/sethome` set. Details: [kon-faber-agent/docs/phase-0-done.md](../kon-faber-agent/docs/phase-0-done.md)
- ✅ **Bible refactor** — split monolithic `bible-snapshot.md` into five concern-specific files under `kon-faber-agent/references/`. Workflow logic stays out (lives in skill code). Audit log moved to `kon-faber-agent/audit/`. See [kon-faber-agent/references/README.md](../kon-faber-agent/references/README.md)
- ✅ **Phase 1 prep keys** — Supabase service role key + Tavily API key added to Railway Variables. `OPENROUTER_API_KEY` already there.

## What might be broken

User reported the deployment crashing **after** adding the Tavily key. Crash log not yet captured. **Diagnose this first** before continuing.

## Key decisions made (don't re-litigate)

| Decision | Status | Notes |
|---|---|---|
| **OpenRouter as LLM gateway** | Locked in | Claude Max via Hermes does NOT work post-2026-04-04 (Anthropic blocked subscription routing through 3rd-party agentic tools). Keep OpenRouter. |
| **Hermes topology: orchestrator + `delegate_task`** | Locked in | Single Hermes container, delegated workers for parallel/isolated subtasks. See [plans/04-architecture-update-v2.2.md](04-architecture-update-v2.2.md). |
| **Responder runs independently** | Locked in | Event-driven via 15-min Gmail polling, NOT part of cron. |
| **Brave → Tavily** | Locked in | Tavily has native Hermes integration and AI-tuned summary output. |
| **Bible split into 5 files + audit out** | Locked in | See `kon-faber-agent/references/README.md`. |
| **Dashboard on Railway (not Vercel)** | Locked in | Phase 4. |
| **Notion deferred** | Locked in | Phase 6. Until then, agent reads `references/*.md` from baked image at `/opt/agent/references/`. |
| **Gmail via MCP, not raw API** | NEW | Use Hermes' bundled `google-workspace` skill (already in the 87 bundled skills we saw at boot). Saves us writing OAuth code from scratch. |

## What's pending

### Right now (blocking)

1. **Diagnose the current crash.** Run `railway logs 2>&1 | tail -100 > /tmp/railway.log && open /tmp/railway.log` from the project folder. Likely culprits: a stray env-var character, the `/opt/agent/` Dockerfile move, or something with the Tavily key.

### Phase 1 work (priority order)

2. **Add auto-config startup script** — eliminate the manual `hermes config set ...` we've been running via SSH. Wrap Hermes' entrypoint with a small script that reads env vars and configures Hermes on every container start. Once done, every config change happens in Railway Variables → save → auto-redeploy. No more SSH-and-poke. *15 minutes to write.*

3. **Set up Gmail via the `google-workspace` Hermes bundled skill** — this skill ships with the Hermes image. Find its config requirements (likely OAuth credentials JSON file path + scopes). One-time browser consent for Bene's `bmncnfaber@gmail.com`, then store refresh token on the persistent volume.

4. **Wire Supabase access** — Hermes can connect via the Supabase MCP server (or via `psycopg`/`supabase-py` inside a skill). MCP path is preferred. Confirm whether Hermes has a bundled Supabase skill or if we add the Supabase MCP source.

5. **Port the original SKILL.md to a Hermes skill** — file at `/Users/bf/.craft-agent/workspaces/my-workspace/sessions/260513-lean-waterfall/attachments/aceaf860-d3bf-4fd1-9a64-029d20ae7639_SKILL.md`. **Refactor into orchestrator + delegated workers.** Outreach skill = orchestrator. Reviewer = `delegate_task`. Workflow logic (cadence, anti-duplicate, CRM-sync) goes IN the skill, NOT in the Bible. The Bible files at `references/*.md` are loaded as voice/facts/templates inputs.

6. **Implement the AI-pattern regex linter** in the outreach skill code (moved out of Bible per refactor).

7. **Test `/outreach 2`** — runs the workflow against 2 test contacts. Verify Gmail drafts created, CRM updated.

### Done-when (Phase 1 exit)

- `/outreach 2` in Telegram drafts 2 emails into Gmail Drafts, correctly using Bible voice (reads from `references/*.md`), with CRM updated, action-types routed properly.

## Where everything lives

```
sessions/260513-lean-waterfall/
├── plans/                          # all planning docs
│   ├── 01-overview-v2.md           # superseded by v2.1
│   ├── 02-plan-v2.md               # v2.1 phased plan (latest)
│   ├── 03-architecture-v2.md       # v2.1 architecture (latest)
│   ├── 04-architecture-update-v2.2.md  # decisions update
│   └── 05-phase-1-handover.md      # THIS FILE
├── project-docs/                   # v1 docs, superseded — keep for context
├── kon-faber-agent/                # the actual repo (git-tracked, pushed to GitHub)
│   ├── Dockerfile                  # builds the Hermes container
│   ├── README.md
│   ├── SECRETS.local.md            # gitignored, contains the secrets
│   ├── docs/
│   │   └── phase-0-done.md         # Phase 0 retrospective + gotchas
│   ├── references/                 # the new split Bible
│   │   ├── README.md
│   │   ├── voice.md                # the Bible (tone + sacred + don'ts)
│   │   ├── facts.md                # tours, references, achievements
│   │   ├── release-calendar.md     # date-bound tempus rules
│   │   ├── templates.md            # exemplars (not scripts)
│   │   └── replies.md              # B1-B5 heuristics
│   ├── audit/
│   │   └── bible-audits.md         # operational log
│   └── skills/                     # empty — Phase 1 skill code goes here
└── attachments/                    # user-attached files (SKILL.md, screenshots, etc.)
```

GitHub: https://github.com/benji2667/kon-faber-agent (private, owned by `benji2667`)

## Secrets

`SECRETS.local.md` (gitignored) holds:
- Telegram bot token (live, in Railway env vars)
- OpenRouter API key (live, in Railway env vars + Hermes config)
- Supabase service role key (live, in Railway env vars)
- Tavily API key (live, in Railway env vars — but Hermes-side config not yet set)
- Bible page ID in Notion: `338ddd65-5206-8104-a0c2-da445ad9c43a` (for Phase 6)

## Railway state

- Project: `kon-faber-agent`
- Service: `hermes-agent`
- Source: GitHub `benji2667/kon-faber-agent` main branch (auto-builds on push)
- Volume: `/opt/data` (persistent)
- Custom Start Command: **EMPTY** (Dockerfile's CMD is used — DO NOT override)
- Env vars set: `HERMES_HOME`, `TELEGRAM_BOT_TOKEN`, `OPENROUTER_API_KEY`, `TELEGRAM_ALLOWED_USERS`, `HERMES_DEFAULT_MODEL`, `HERMES_FAST_MODEL`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `TAVILY_API_KEY`

## Hermes config (lives on `/opt/data/config.yaml`, persistent)

Set during Phase 0 setup via `hermes model`:
- `model.default = anthropic/claude-sonnet-4.5`
- `model.provider = openrouter`
- `model.base_url = https://openrouter.ai/api/v1`
- `provider.openrouter.api_key = sk-or-v1-...` (live)

Pending — add when relevant:
- `provider.tavily.api_key = ...` (key already in Railway env, just needs config setting)
- Whatever the `google-workspace` skill needs

## Useful commands

```bash
# from kon-faber-agent/
cd /Users/bf/.craft-agent/workspaces/my-workspace/sessions/260513-lean-waterfall/kon-faber-agent

# Railway
railway logs                  # stream logs
railway logs --build          # build-only logs
railway status                # current deployment state
railway redeploy              # trigger new deploy from main
railway ssh                   # shell into running container

# Inside container (after railway ssh)
/opt/hermes/.venv/bin/hermes config show     # see current Hermes config
/opt/hermes/.venv/bin/hermes config set ...  # change config (manual, will be replaced by startup script)
/opt/hermes/.venv/bin/hermes doctor           # health check

# Git workflow
git status
git commit -am "..."
git push                       # Railway auto-builds on push to main
```

## How to start

1. Pull recent logs to see crash state
2. Fix whatever broke
3. Add the auto-config startup script (kills the "manual SSH for config" pattern forever)
4. Then proceed with Gmail (`google-workspace` skill) → Supabase → SKILL.md port → test

Stay in **Execute** mode for build work, switch to Explore if you need to plan/research.
