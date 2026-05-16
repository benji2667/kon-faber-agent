# Plan v3 — Amendments after Reddit research

_2026-05-15 — review of [r/ClaudeCode "Running Claude Code on Railway with Telegram Channels"](https://old.reddit.com/r/ClaudeCode/comments/1sd0dmo/running_claude_code_on_railway_with_telegram/) (geekrebel, posted 2026-04-05, updated 2026-04-08)_

## TL;DR

One **potentially major** insight (auth) and **several concrete Dockerfile gotchas** to bake in. The architecture in v3 (Craft Agents on Railway as control plane, Hermes as worker) is **not contradicted** by the post. Recommend: proceed with v3 as written, but with two amendments — investigate the OAuth-token auth path before Phase 0, and bake the post's Dockerfile lessons into both the Craft Agents and Hermes containers.

---

## 1. Summary of relevant Reddit insights

The post is a hard-won writeup of running **Claude Code itself** (not a custom agent framework) headlessly on Railway, using Claude Code's native `--channels plugin:telegram@...` feature. Different architecture from ours, but the runtime gotchas overlap heavily.

### Top-comment conversation
- u/Any-You-4763 told the OP to drop the base64-credentials.json approach and use `claude setup-token` + `CLAUDE_CODE_OAUTH_TOKEN` instead. OP confirmed this works and updated the post.
- u/digibeta asked why not use Happy (wrapper). OP said no, "given recent news about Claude shutting down subscription use on 'claw'-like setups" — so OP is **aware of the April 2026 policy change** and considers the `setup-token` path distinct from third-party wrappers.

### Key technical findings (verbatim from post)

| # | Finding | Relevance to us |
|---|---|---|
| 1 | Claude Code config lives at `~/.claude.json` (root home), **not** `~/.claude/.claude.json` | High — applies to any Claude-Code-based container including Craft Agents server |
| 2 | Folder trust must be set under `~/.claude.json` → `projects["/app"].hasTrustDialogAccepted` | High — same |
| 3 | Entrypoint must `jq`-merge config, never overwrite — runtime state (auth, caches) gets clobbered otherwise | High — directly informs our auto-config startup script |
| 4 | tmux child processes don't inherit env vars; dump `export -p > /tmp/env.sh` and source inside the tmux command | Medium — we're not using tmux in v3, but useful pattern |
| 5 | **DO NOT SET** `DISABLE_TELEMETRY`, `DO_NOT_TRACK`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. They silently disable the GrowthBook flag (`tengu_harbor`) that gates the `--channels` feature. Symptom: "Channels are not currently available" with no further detail. | High — we'd very likely have set DISABLE_TELEMETRY by reflex |
| 6 | Telegram long-poll conflict: only one process can hold the bot token. Kill local pollers before remote goes live. | Medium — already implicit in our plan |
| 7 | **`CLAUDE_CODE_OAUTH_TOKEN`** from `claude setup-token` gives a `sk-ant-oat01-` token, ~1 year lifetime, no refresh-token race conditions, **uses the Claude Max subscription quota**. `/usage` doesn't work with it (only downside cited). | **POTENTIALLY HIGH** — could reopen the path we closed on 2026-04-04 |
| 8 | Safe stability flags: `DISABLE_AUTOUPDATER=1`, `DISABLE_ERROR_REPORTING=1`, `CLAUDE_ENABLE_STREAM_WATCHDOG=1` | Low — adopt verbatim |
| 9 | Symlink both `~/.claude` and `~/.claude.json` to the volume | Medium — confirms our Phase 0 volume design |

### Cost/architecture data points
- No concrete €/$ numbers in the post. OP runs a single Railway container, no separate orchestrator layer.
- Setup: Ubuntu 24.04, Node 24, Claude Code npm-installed globally, sshd as PID 1 for debug.
- Tested on Claude Code v2.1.92 (April 2026).

---

## 2. What changes for the v3 plan

### Amendment A — Investigate `CLAUDE_CODE_OAUTH_TOKEN` before Phase 0 (1 hour)

**Why it matters:** v3 currently routes Craft Agents' LLM calls through Anthropic API (paid, ~€5-15/mo) because we locked in on 2026-04-04 that "Claude Max via Hermes does NOT work post-2026-04-04 (Anthropic blocked subscription routing through 3rd-party agentic tools)."

The Reddit post (2026-04-05, updated 2026-04-08, with positive recent comment confirmation) claims `claude setup-token` + `CLAUDE_CODE_OAUTH_TOKEN` env var still works for headless Claude Code containers and consumes Max quota. The OP is **explicitly aware** of the policy change and treats the `setup-token` path as distinct from third-party wrapper bans.

**Action before committing Phase 0:**
1. Run `claude setup-token` locally on Bene's Mac, confirm it returns an `sk-ant-oat01-...` token.
2. Verify with a smoke test: `CLAUDE_CODE_OAUTH_TOKEN=... claude --print "hello"` in a fresh shell with no `ANTHROPIC_API_KEY` set.
3. Check the official Anthropic docs Bene was referenced to: https://docs.anthropic.com/en/docs/claude-code/setup#claude-code-headless-or-non-interactive (verify URL — search for current setup-token docs).
4. If it works: amend v3 Phase 0 to use `CLAUDE_CODE_OAUTH_TOKEN` instead of `ANTHROPIC_API_KEY` for Craft Agents on Railway. Saves €5-15/mo. Annual token rotation reminder needed.
5. If it doesn't work / policy explicitly forbids it: stay on Anthropic API key as v3 currently specifies. Decision recorded.

**Risk:** Anthropic could revoke this path at any time. Mitigation is acceptable because the `ANTHROPIC_API_KEY` fallback is a 1-line env var swap.

**Note for Hermes (Phase 3):** Hermes routes through OpenRouter today and that decision is independent — OpenRouter is the LLM gateway *for Hermes' multi-model orchestration*. We'd only swap auth on Craft Agents itself (the control plane), not on Hermes.

### Amendment B — Bake post's Dockerfile gotchas into Phase 0 startup script

Update the Phase 0 `startup.sh` spec to include:

```bash
# Symlink Claude Code state directories to the persistent volume
ln -sfn /data/.claude       "$HOME/.claude"
ln -sfn /data/.claude.json  "$HOME/.claude.json"

# Seed/merge config — never overwrite (preserves runtime auth + caches)
CLAUDE_JSON="$HOME/.claude.json"
REQUIRED='{
  "hasCompletedOnboarding": true,
  "theme": "dark",
  "projects": { "/app": { "hasTrustDialogAccepted": true,
                          "hasCompletedProjectOnboarding": true } }
}'
if [ -f "$CLAUDE_JSON" ]; then
  jq --argjson req "$REQUIRED" '. * $req' "$CLAUDE_JSON" > /tmp/cj.tmp \
    && mv /tmp/cj.tmp "$CLAUDE_JSON"
else
  echo "$REQUIRED" | jq . > "$CLAUDE_JSON"
fi

# Safe stability flags. DO NOT add DISABLE_TELEMETRY / DO_NOT_TRACK /
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC — they kill feature flags
# (tengu_harbor and friends) silently.
export DISABLE_AUTOUPDATER=1
export DISABLE_ERROR_REPORTING=1
export CLAUDE_ENABLE_STREAM_WATCHDOG=1
```

Applies to **Craft Agents server container** (Phase 0) primarily. Craft Agents is "powered by Claude Code" per the runtime banner, so the same config and env-var rules apply. Possibly also applies to Hermes if Hermes wraps Claude Code internals — TBD when we read the Hermes source in Phase 3.

### Amendment C — Add a "do not set" env-var block to plan docs

Add to v3 Phase 0 + Phase 3 a checklist of env vars to **avoid** on Railway:

- `DISABLE_TELEMETRY`
- `DO_NOT_TRACK`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`

Reason: silently breaks Claude Code feature flags (GrowthBook). If we're using `--channels` plugins (we might, for the Telegram side later), they fail with an unhelpful error.

### Amendment D — Capture the alternative architecture as a "future option, rejected for now"

The post describes an architecture where **Claude Code itself is the agent**, talking to Telegram via its native channel plugin, with no Hermes-style framework. This is simpler than v3 but lacks:
- Skill system with our outreach orchestration
- `delegate_task` parallelization
- The multi-model routing we get from Hermes via OpenRouter
- Reviewer/Responder split

So **v3 stays with Hermes as the worker**. But: if Hermes Phase 3 turns into another deployment slog, we have a fallback — drop Hermes, use Claude Code + Telegram channel plugin, implement outreach logic as Claude Code commands/MCPs. Worth keeping in our back pocket.

---

## 3. What stays the same

All locked v2.2 decisions still hold:

- ✅ **Craft Agents-first deployment order** — not contradicted; the post just doesn't have a control-plane layer
- ✅ **OpenRouter as Hermes' LLM gateway** — the auth amendment (A) only affects Craft Agents itself, not Hermes' model routing
- ✅ **Hermes orchestrator + `delegate_task`** pattern
- ✅ **Responder independent of cron**
- ✅ **Brave → Tavily** for venue research
- ✅ **Bible split into 5 files + audit out**
- ✅ **Dashboard on Railway**
- ✅ **Notion deferred to Phase 6** (or brought forward in v3 Phase 2 as already amended)
- ✅ **GitHub repo as source of truth, env vars at boot, no SSH-and-poke**

---

## 4. Recommended next action

**Proceed with v3 as written, with Amendments A–C applied before/during Phase 0.**

Order of operations:
1. **5 min:** Bene runs `claude setup-token` on his Mac, paste the resulting `sk-ant-oat01-` token into `SECRETS.local.md` (gitignored).
2. **15 min:** Quick smoke test that the token works in a non-interactive shell with no `ANTHROPIC_API_KEY` set.
3. **If smoke test passes:** Phase 0 of v3 uses `CLAUDE_CODE_OAUTH_TOKEN` instead of `ANTHROPIC_API_KEY` for the Craft Agents server. Add the do-not-set list and the jq-merge startup script.
4. **If smoke test fails or policy is unambiguous about banning it:** Phase 0 of v3 uses `ANTHROPIC_API_KEY` as originally specified.
5. Continue v3 Phase 0 → Phase 1 → ...

No need to rewrite the v3 plan doc — these amendments live here and the next session reads both `06-plan-v3-craft-agents-first.md` and `07-plan-v3-amendments.md`.

---

## Phase 0/1 outcome (executed 2026-05-16)

✅ **Both phases complete.** Craft Agents OSS server live on Railway, Bene's desktop app connected as thin client.

**Live URLs:**
- Public server: `wss://craft-agents-cloud-production.up.railway.app`
- WebUI: `https://craft-agents-cloud-production.up.railway.app/login`
- Railway project: `craft-agents-cloud` (ID `ca095996-03e4-4f28-8808-1bd0c3d67901`)
- Service: `craft-agents-cloud` (ID `bd29984f-3b25-4d38-9510-b9f5c628aef5`)
- GitHub fork: https://github.com/benji2667/craft-agents-cloud
- Volume: `/home/craftagents/.craft-agent` (persistent)
- Token: stored in [kon-faber-agent/SECRETS.local.md](../kon-faber-agent/SECRETS.local.md)

**Dockerfile.server patches that were needed** (upstream `craft-ai-agents/craft-agents-oss` v0.9.4 ships a `Dockerfile.server` that doesn't build clean against its own published source):

1. Removed `COPY apps/marketing/package.json` — directory doesn't exist in v0.9.4
2. Removed `COPY packages/craft-agents-commands/package.json` — package doesn't exist in v0.9.4
3. Removed `COPY packages/craft-cli/package.json` — package doesn't exist in v0.9.4 (CLI is at `apps/cli`)
4. Dropped `--frozen-lockfile` on `bun install` — incompatible with the three package removals above
5. Removed `USER craftagents` directive + added `ENV HOME=/home/craftagents` — Railway mounts volumes as root, EACCES otherwise
6. Appended `--allow-insecure-bind` to ENTRYPOINT — Railway terminates TLS at edge, container speaks plain `ws://` internally

**Plus one Railway-specific tweak:** `PORT=9100` env var set so Railway edge forwards to the right container port (default Railway behaviour didn't pick up `EXPOSE 9100` automatically — symptom was `502 x-railway-fallback: true`).

**Upstream issues worth filing later** (not now): the Dockerfile.server references three nonexistent paths in the v0.9.4 source. Either the Dockerfile was committed from a future branch state, or those packages got pulled before publishing.

---

## Decision log

- **2026-05-15** — Bene chose to skip the smoke test and trust the `setup-token` path. Phase 0 of v3 will use `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) as the auth for Craft Agents on Railway. Fallback if it breaks at runtime: switch the env var to `ANTHROPIC_API_KEY` (1-line swap, no code changes).
- Calendar reminder needed: **2027-05** — regenerate the OAuth token (~1 year lifetime).

### Amendment E — Auth happens post-deploy, not at boot (2026-05-16)

After inspecting the OSS repo's `Dockerfile.server` (already exists, production-grade), the server **takes no LLM env vars at boot**. Only required runtime envs are:
- `CRAFT_SERVER_TOKEN` (bearer auth between desktop and server)
- `CRAFT_RPC_HOST=0.0.0.0` (already defaulted in the Dockerfile via `ENV`)
- `CRAFT_RPC_PORT=9100` (defaulted)

LLM credentials (Claude Max OAuth, or API key) are configured per-workspace by the desktop app **after** the server is reachable. They land in the server's `~/.craft-agent/credentials.enc` and persist on the volume. So `CLAUDE_CODE_OAUTH_TOKEN` is not a Railway env var — it's set up via the desktop app once Phase 0 is green.

### Amendment F — Use Dockerfile.server from OSS directly (2026-05-16)

The OSS repo ships a well-tuned `Dockerfile.server` (Bun 1.3-slim + Node 20 for the WhatsApp worker, multi-stage with Vite WebUI build, non-root `craftagents` user, 4GB Node heap for build). It already sets `CRAFT_RPC_HOST=0.0.0.0`, `CRAFT_WEBUI_DIR`, `CRAFT_MESSAGING_WA_WORKER`, and exposes 9100. No reason to rewrite.

**Repo strategy:** Fork `lukilabs/craft-agents-oss` to `benji2667/craft-agents-cloud`. Railway builds from the fork using `Dockerfile.server`. Future customizations (startup script wrappers, extra plugins) layer cleanly. Pull upstream updates via `git pull upstream main`.

**Volume mount path:** `/home/craftagents/.craft-agent` (Dockerfile creates `craftagents` user with `HOME=/home/craftagents`). The earlier v3 doc said `/root/.craft-agent` — that was based on the README's `docker run` example which uses `--user 0:0`. Our deploy will run as the `craftagents` user as the Dockerfile intends.

## Open items

- [ ] Verify Craft Agents OSS startup behaviour around `~/.claude.json` — possible the OSS server doesn't read this file at all (only the Claude Code CLI does). If so, Amendment B applies less than expected. Confirm by reading the OSS repo in Phase 0 prep.
