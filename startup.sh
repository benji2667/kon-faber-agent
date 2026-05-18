#!/usr/bin/env bash
# Wrapper around the upstream Hermes entrypoint.
#
# Three jobs, all done while we still have root:
#   1. Force-chown /opt/data → hermes:hermes. The volume can end up with
#      mismatched ownership across redeploys, which leaves stale files
#      (e.g. /opt/data/.env) unreadable by the hermes user and crashes
#      `hermes` at import time.
#   2. Apply hermes config from Railway env vars, so config changes happen
#      in the Railway UI rather than via interactive `railway ssh`.
#   3. Inject the mcp_servers block (Gmail + Supabase) into config.yaml
#      so Hermes spawns those MCP servers on boot. Idempotent — only
#      written if the block is missing.
#
# After that we exec the upstream entrypoint, which handles the gosu drop
# to the hermes user and the usual config/.env bootstrap.
#
# Note: we deliberately do NOT call `hermes gateway setup --platform telegram`
# here. The upstream Hermes entrypoint already discovers TELEGRAM_BOT_TOKEN
# from env and configures the Telegram gateway automatically.

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
HERMES_BIN=/opt/hermes/.venv/bin/hermes
UPSTREAM_ENTRYPOINT=/opt/hermes/docker/entrypoint.sh
MCP_PYTHON=python3

log() { echo "[startup] $*"; }
warn() { echo "[startup] WARN: $*" >&2; }
fatal() { echo "[startup] FATAL: $*" >&2; exit 1; }

# Sanity check upstream artifacts before we even try to run.
[ -x "$HERMES_BIN" ]            || fatal "hermes binary missing at $HERMES_BIN — base image changed?"
[ -x "$UPSTREAM_ENTRYPOINT" ]   || fatal "upstream entrypoint missing at $UPSTREAM_ENTRYPOINT"
command -v gosu >/dev/null      || fatal "gosu missing in base image"

if [ "$(id -u)" = "0" ]; then
    # 1. Repair volume perms.
    if [ -d "$HERMES_HOME" ]; then
        chown -R hermes:hermes "$HERMES_HOME" 2>/dev/null || \
            warn "chown $HERMES_HOME failed (continuing)"
    fi

    # 2. Apply config from env vars as the hermes user.
    # The upstream entrypoint will (re)create .env/config.yaml from examples
    # if missing — but only on its later pass. Bootstrap them here so
    # `hermes config set` has something to write to.
    [ -f "$HERMES_HOME/.env" ]        || cp /opt/hermes/.env.example          "$HERMES_HOME/.env"
    [ -f "$HERMES_HOME/config.yaml" ] || cp /opt/hermes/cli-config.yaml.example "$HERMES_HOME/config.yaml"
    chown hermes:hermes "$HERMES_HOME/.env" "$HERMES_HOME/config.yaml" 2>/dev/null || true

    apply_config() {
        local key="$1"
        local value="$2"
        if [ -z "$value" ]; then
            return 0
        fi
        local err
        if err=$(gosu hermes "$HERMES_BIN" config set "$key" "$value" 2>&1 >/dev/null); then
            log "config set $key"
        else
            warn "failed to set $key: ${err:-unknown error}"
        fi
    }

    apply_config "model.provider"               "openrouter"
    apply_config "model.base_url"               "https://openrouter.ai/api/v1"
    apply_config "model.default"                "${HERMES_DEFAULT_MODEL:-}"
    apply_config "model.fast"                   "${HERMES_FAST_MODEL:-}"
    apply_config "provider.openrouter.api_key"  "${OPENROUTER_API_KEY:-}"
    apply_config "provider.tavily.api_key"      "${TAVILY_API_KEY:-}"

    # 3. Inject mcp_servers config block (idempotent).
    # Writes literal secret values into config.yaml at boot rather than relying
    # on Hermes doing env-var substitution. Re-runs on every boot are no-ops
    # once the block is present.
    CFG="$HERMES_HOME/config.yaml"
    if grep -q "^mcp_servers:" "$CFG" 2>/dev/null; then
        log "mcp_servers already present in config.yaml"
    else
        missing=()
        [ -z "${GMAIL_CLIENT_ID:-}" ]        && missing+=(GMAIL_CLIENT_ID)
        [ -z "${GMAIL_CLIENT_SECRET:-}" ]    && missing+=(GMAIL_CLIENT_SECRET)
        [ -z "${GMAIL_REFRESH_TOKEN:-}" ]    && missing+=(GMAIL_REFRESH_TOKEN)
        [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]  && missing+=(SUPABASE_ACCESS_TOKEN)
        if [ ${#missing[@]} -ne 0 ]; then
            warn "mcp_servers block SKIPPED — missing env vars: ${missing[*]}"
            warn "Hermes will boot WITHOUT Gmail/Supabase MCP. Set these in Railway and redeploy."
        else
            cat >> "$CFG" <<EOF

mcp_servers:
  supabase:
    command: "npx"
    args: ["-y", "@supabase/mcp-server-supabase@latest"]
    env:
      SUPABASE_ACCESS_TOKEN: "${SUPABASE_ACCESS_TOKEN}"
  gmail:
    command: "${MCP_PYTHON}"
    args: ["/opt/agent/mcp_servers/gmail_server.py"]
    env:
      GMAIL_CLIENT_ID: "${GMAIL_CLIENT_ID}"
      GMAIL_CLIENT_SECRET: "${GMAIL_CLIENT_SECRET}"
      GMAIL_REFRESH_TOKEN: "${GMAIL_REFRESH_TOKEN}"
EOF
            chown hermes:hermes "$CFG" 2>/dev/null || true
            log "mcp_servers injected (gmail + supabase)"
        fi
    fi
fi

# Hand off to upstream entrypoint. It does the gosu drop and final exec.
exec "$UPSTREAM_ENTRYPOINT" "$@"
