# Kon Faber Outreach Agent

Self-improving booking outreach agent for Kon Faber, built on [Hermes Agent](https://github.com/NousResearch/hermes-agent) and hosted on Railway.

See [`../plans/`](../plans/) for full architecture, plan, and decision log.

---

## Phase 0 — Foundation

Goal: get a vanilla Hermes container running on Railway, talking to a Telegram bot you control.

### What you need to do before we deploy

1. **Create a Telegram bot**
   - Open Telegram → message [@BotFather](https://t.me/BotFather)
   - Send `/newbot`
   - Pick a name (e.g. `Kon Faber Outreach`) and a username (e.g. `konfaber_outreach_bot`)
   - **Save the token** that BotFather returns. Looks like `123456789:ABC...`

2. **Create an OpenRouter account**
   - Sign up at https://openrouter.ai/
   - Add a small balance (€5 is plenty for testing)
   - Go to https://openrouter.ai/keys → create a new API key
   - **Save the key.** Looks like `sk-or-v1-...`

3. **Confirm your Railway account works**
   - Log in at https://railway.com/
   - Hobby plan is enough (~€5/mo + small usage)

That's it for Phase 0. We don't need Supabase, Gmail, or Notion credentials yet — those come in Phase 1.

### Deployment steps (we'll do this together)

1. **Create a Railway project** named `kon-faber-agent`

2. **Add the Hermes service** from a Docker image:
   - In Railway: `+ New` → `Deploy from Docker Image`
   - Image: `nousresearch/hermes-agent`
   - Start command: `gateway run`

3. **Add a persistent volume**:
   - Service Settings → Volumes → New Volume
   - Mount path: `/opt/data`
   - This is where Hermes stores config, memory, skills (so restarts don't wipe state)

4. **Set environment variables** (Variables tab):

```env
HERMES_HOME=/opt/data
TELEGRAM_BOT_TOKEN=<your bot token from BotFather>
OPENROUTER_API_KEY=<your OpenRouter key>
HERMES_DEFAULT_MODEL=anthropic/claude-sonnet-4.5
```

5. **Deploy** — Railway will pull the image and run `gateway run`.

6. **First-time setup** (via Railway shell, one-off):
   - In Railway → click the service → `Connect` → open shell
   - Run:
     ```bash
     hermes config set model.default anthropic/claude-sonnet-4.5
     hermes config set model.fast anthropic/claude-haiku-4.5
     hermes config set provider.openrouter.api_key $OPENROUTER_API_KEY
     hermes gateway setup --platform telegram --token $TELEGRAM_BOT_TOKEN
     ```
   - Restart the service so `gateway run` picks up the new config.

7. **Smoke test**:
   - Open your Telegram bot
   - Send `hello`
   - You should get a response from the agent

If that works, Phase 0 is done.

---

## Project layout

```
kon-faber-agent/
├── README.md             # this file
├── Dockerfile            # used from Phase 1+ once we add skills
├── .dockerignore
├── .env.example          # env var template for local dev
├── skills/               # Hermes skills (Phase 1+)
└── references/
    └── bible-snapshot.md # fallback when Notion is unavailable
```

## Phases

See [../plans/02-plan-v2.md](../plans/02-plan-v2.md) for the full phased plan. Short version:

- **Phase 0** (this) — Hermes on Railway + Telegram bot
- **Phase 1** — Port your SKILL.md → Hermes skill, manual `/outreach` command
- **Phase 2** — Reviewer skill + autonomous cron Tue+Fri
- **Phase 3** — Responder skill (event-driven reply drafting)
- **Phase 4** — Dashboard (Next.js on Railway)
- **Phase 5** — Voice feedback loop
- **Phase 6** — Notion wiring + Bible auto-evolution
- **Phase 7** — Polish

## Sources

- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
- [Hermes Docker docs](https://hermes-agent.nousresearch.com/docs/user-guide/docker)
- [Hermes Docker image on Docker Hub](https://hub.docker.com/r/nousresearch/hermes-agent)
- [Railway docs](https://docs.railway.com/)
- [OpenRouter](https://openrouter.ai/)
