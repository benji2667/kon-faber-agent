# Phase 3 — done

_2026-05-17 — Hermes deployed to a fresh Railway project, driven from inside the remote Craft Agents session._

## Done-criterion met

`hello` to `@kf_outreach_bot` returns a Claude reply (verified by Bene in Telegram).

## What's live

- **Railway project:** `kon-faber-hermes` (ID `29eb22ed-d272-4b83-bab2-863c95d16452`)
- **Service:** `hermes-agent` (ID `a0ffa020-9ea4-4143-86ea-ef88929f355b`)
- **Production environment:** `a0aab1ec-fd32-484e-b2f2-af4939bee71d`
- **Persistent volume:** `/opt/data` (id `64f8581f-1755-4d49-aeb6-5bbcde2498d5`)
- **GitHub source:** `benji2667/kon-faber-agent` main (auto-deploys on push)
- **Telegram bot:** `@kf_outreach_bot` (id `8617121930`)
- **LLM:** OpenRouter, `anthropic/claude-sonnet-4.5` (default) and `claude-haiku-4.5` (fast)

## What's different from Phase 0

| Phase 0 | Phase 3 |
|---|---|
| Custom Start Command in Railway UI | `railway.json` pins Dockerfile path |
| Manual `railway ssh` + `hermes config set` after first deploy | `startup.sh` auto-applies model/provider/Tavily config from env vars |
| Pairing-code approval needed on first message | `TELEGRAM_ALLOWED_USERS=5930243179` bypasses pairing |
| Bene drove deploy from Railway UI/CLI | Remote Craft Agents drove it via Railway MCP + GitHub MCP |

## Operational gotchas (worth keeping)

1. **Railway's `service_restart` MCP tool removes the deployment** rather than restarting it (observed). Use `deployment_trigger` with a commit SHA instead.
2. **`@jasontanswe/railway-mcp` returns empty for `project_list`** even when projects exist. Use direct GraphQL (`https://backboard.railway.app/graphql/v2`) for discovery; the MCP is fine for per-project mutations once you have the IDs.
3. **Railway's GraphQL uses `workspaceId`** for `projectCreate` (`teamId` is legacy/rejected).
4. **Hermes auto-detects `TELEGRAM_BOT_TOKEN`** from env — do NOT call `hermes gateway setup --platform telegram` in startup.sh, it fails silently and is unnecessary. Earlier version of this script had it; current version removed it.
5. **Telegram polling conflict on cutover:** when migrating to a new project that reuses an existing bot, the old service's running container must be stopped before the new one starts polling. `deploymentStop` GraphQL mutation works. Conflict log: `telegram.error.Conflict: terminated by other getUpdates request`.

## Legacy project status

The original `kon-faber-agent` Railway project has been deleted (2026-05-17) per Bene's confirmation. All Phase 0 work lives on as commit history in the GitHub repo and as `docs/phase-0-done.md`.

## Env vars set on the service

```
HERMES_HOME=/opt/data
TELEGRAM_BOT_TOKEN=<bot token>
OPENROUTER_API_KEY=<openrouter key>
HERMES_DEFAULT_MODEL=anthropic/claude-sonnet-4.5
HERMES_FAST_MODEL=anthropic/claude-haiku-4.5
TELEGRAM_ALLOWED_USERS=5930243179
TAVILY_API_KEY=<tavily key>
PORT=8642
```

Supabase/Gmail/Notion keys NOT set yet — those come in Phase 4 (outreach skill needs Supabase CRM + Gmail draft writes; Notion is deferred to Phase 6).

## Next: Phase 4

Outreach Skill MVP. See [../plans/06-plan-v3-craft-agents-first.md](../plans/06-plan-v3-craft-agents-first.md) Phase 4 for scope. Gmail OAuth setup is the blocker to start.
