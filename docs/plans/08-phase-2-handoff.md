# Phase 2 — Start Here (Handoff)

_Created 2026-05-16 after Phase 0/1 completion_

This document is the entry point for the next session, which should run **on the remote Craft Agents server** (not the Mac desktop workspace). Read this first.

## What's done (Phases 0 + 1)

✅ **Phase 0** — Craft Agents OSS v0.9.4 deployed on Railway. Live at `wss://craft-agents-cloud-production.up.railway.app`. Persistent volume mounted at `/home/craftagents/.craft-agent`. Six Dockerfile patches landed in `benji2667/craft-agents-cloud` fork (see [07-plan-v3-amendments.md](07-plan-v3-amendments.md)).

✅ **Phase 1** — Bene's Mac desktop app connected to the remote as thin client via the "Connect to remote server" UI flow. Workspace runs on Railway.

## What's still TBD (read me to orient)

| Source doc | Why read |
|---|---|
| [06-plan-v3-craft-agents-first.md](06-plan-v3-craft-agents-first.md) | The full v3 plan, Phase 2 onwards |
| [07-plan-v3-amendments.md](07-plan-v3-amendments.md) | Amendments + Phase 0/1 outcome + Dockerfile patches |
| [05-phase-1-handover.md](05-phase-1-handover.md) | The pre-v3 handoff, has locked decisions (still valid) |
| [04-architecture-update-v2.2.md](04-architecture-update-v2.2.md) | Hermes orchestrator + delegate_task pattern |
| `../kon-faber-agent/SECRETS.local.md` | All tokens/keys (gitignored, on local Mac) |

## Phase 2 — Wire MCPs into the remote workspace (~1 hour)

**Goal:** The remote Craft Agents has all the integrations the outreach project needs.

Per v3 plan, set up these sources/MCPs *from inside a session on the remote*:

- [ ] **Railway MCP** — the agent inside the remote will need this to drive Phase 3 (Hermes deploy). Trigger OAuth via the source.
- [ ] **Supabase MCP** — project ID `qjkqcycdyeekacygihac`, service role key in SECRETS.local.md
- [ ] **GitHub MCP** — for repo automation (the agent may need to push fixes)
- [ ] **Gmail MCP** — OAuth flow with `bmncnfaber@gmail.com`. Refresh token persists on the server volume.
- [ ] **Notion MCP** — Bible page ID `338ddd65-5206-8104-a0c2-da445ad9c43a`
- [ ] **Tavily** (or Brave) — for venue research

**Important: the LLM provider for the remote workspace must be set up first.** Per Amendment A in plans/07, plan was `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`. Server's startup log shows it already picked up an OAuth access token from somewhere (`hasOAuthAccess=true`, fetched 9 Anthropic models including Claude Opus 4.7). Verify which connection is active in the workspace settings before proceeding.

If `claude setup-token` hasn't been run yet on Bene's Mac, do so now and paste into the workspace settings:
```bash
npm install -g @anthropic-ai/claude-code   # if not installed
claude setup-token                         # outputs sk-ant-oat01-...
```

**Done when:** A session in the remote Craft Agents can call each MCP tool successfully (test with a trivial read op per source).

## Phase 3 — Deploy Hermes from within the remote (~2 hours)

Once Phase 2 sources are wired, the remote Craft Agents drives Hermes deployment using its Railway MCP + GitHub MCP. The `kon-faber-agent` repo (https://github.com/benji2667/kon-faber-agent) already has Phase 0 work — Dockerfile, references, gitignored secrets. Recommendation in v3 plan: **fresh** Railway project rather than retrofitting the broken `kon-faber-agent` project.

Lessons from this Phase 0 (Craft Agents) deploy that apply to Hermes:
- Add `railway.json` with `dockerfilePath` pinned (don't rely on env var)
- Set `PORT` env var explicitly to match the app's listen port
- If Railway volumes are needed: run as root or chmod the mount in entrypoint
- Test the binary's startup flags locally before deploying

**Done when:** `hello` to the Hermes Telegram bot returns a Claude reply.

## Phases 4–7 — Outreach skill, reviewer/cron, responder/dashboard, voice/Notion/inbox

Same as [v3 plan](06-plan-v3-craft-agents-first.md). Driven from the remote agent.

## Key context the agent must hold

- **User:** Bene (Berlin, German speaker, electronic live duo Kon Faber)
- **GitHub:** `benji2667`
- **Email:** `bmncnfaber@gmail.com`
- **Telegram user ID for Hermes bot:** `5930243179`
- **Cost target:** ~€15-35/mo for v3 (incl. Craft Agents server)
- **Locked decisions (don't re-litigate):** see [05-phase-1-handover.md](05-phase-1-handover.md) table — Hermes orchestrator pattern, Responder independent of cron, OpenRouter as Hermes LLM gateway, Bible split into 5 files

## Immediate next action

In the **remote workspace** on Bene's desktop app:
1. Open workspace settings → verify LLM connection (Claude Max OAuth or API key) is active
2. Start a fresh session
3. Point that session at this doc as its entry point
4. Begin Phase 2 source-by-source

If the LLM connection isn't set, that's the blocker — Bene needs to run `claude setup-token` and paste into workspace settings.
