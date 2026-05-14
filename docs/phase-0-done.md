# Phase 0 — done

Hermes container running on Railway, Telegram bot responding via OpenRouter.

## What works

- Docker image built from this repo's `Dockerfile` (inherits `nousresearch/hermes-agent`)
- Deployed to Railway (`hermes-agent` service)
- Persistent volume at `/opt/data` (HERMES_HOME) — config + skill memory survive restarts
- Telegram bot paired with user (`benji2667`, ID `5930243179`)
- LLM routing: OpenRouter, model `anthropic/claude-sonnet-4.5`
- `/sethome` set so cron deliveries land in our DM with the bot

## Lessons learned (so we don't repeat them)

1. **Railway's "Custom Start Command" replaces both ENTRYPOINT and CMD.**
   The Hermes image ships with an entrypoint script (`/opt/hermes/docker/entrypoint.sh`) that does user-switching, skill syncing, and PATH setup. Overriding the start command bypasses all that.
   **Fix:** deploy from our own Dockerfile (which only sets CMD), not from the public image directly. Railway preserves the upstream image's ENTRYPOINT when we build via Dockerfile.

2. **Env vars aren't auto-imported into Hermes' config.**
   Setting `OPENROUTER_API_KEY` and `HERMES_DEFAULT_MODEL` in Railway Variables wasn't enough. The gateway uses Hermes' own config file (`/opt/data/config.yaml`).
   **Fix:** run `hermes model` inside the container (via `railway ssh`) once to set provider + model + API key in the config. Since the config lives on the persistent volume, it survives restarts.

3. **The `hermes` binary lives at `/opt/hermes/.venv/bin/hermes`.**
   It's only in PATH when running as the `hermes` user via the entrypoint. SSH lands as root with empty PATH, so we use the absolute path.

4. **Pairing-code approval required.**
   Hermes' security model: even with `TELEGRAM_ALLOWED_USERS`, the first message from a user triggers a pairing-code flow. Approve via `hermes pairing approve telegram <code>` once per user.

5. **Tokens with literal `<>` brackets get rejected.**
   When pasting env var values, never include the angle bracket placeholders.

## Current Railway config

- Project: `kon-faber-agent`
- Service: `hermes-agent`
- Source: GitHub repo `benji2667/kon-faber-agent` (main branch)
- Volume: `/opt/data` (persistent)
- Custom Start Command: **empty** (Dockerfile CMD is used)
- Env vars set:
  - `HERMES_HOME=/opt/data`
  - `TELEGRAM_BOT_TOKEN`
  - `OPENROUTER_API_KEY`
  - `TELEGRAM_ALLOWED_USERS` (Bene's user ID)
  - `HERMES_DEFAULT_MODEL` (informational — actual setting lives in Hermes config)
  - `HERMES_FAST_MODEL` (informational)

## Per-container config (set via `hermes model` in SSH)

These live in `/opt/data/config.yaml` on the persistent volume:
- `model.default = anthropic/claude-sonnet-4.5`
- `model.provider = openrouter`
- `model.base_url = https://openrouter.ai/api/v1`
- `provider.openrouter.api_key = sk-or-v1-...`

## Open follow-up

- Bake the model selection into the Dockerfile or a startup script so fresh deploys don't need a manual `hermes model` run. (Defer until we hit it again.)
