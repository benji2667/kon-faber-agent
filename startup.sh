#!/usr/bin/env bash
# Wrapper around the upstream Hermes entrypoint.
#
# Two jobs, both done while we still have root:
#   1. Force-chown /opt/data → hermes:hermes. The volume can end up with
#      mismatched ownership across redeploys, which leaves stale files
#      (e.g. /opt/data/.env) unreadable by the hermes user and crashes
#      `hermes` at import time.
#   2. Apply hermes config from Railway env vars, so config changes happen
#      in the Railway UI rather than via interactive `railway ssh`.
#
# After that we exec the upstream entrypoint, which handles the gosu drop
# to the hermes user and the usual config/.env bootstrap.
#
# Note: we deliberately do NOT call `hermes gateway setup --platform telegram`
# here. The upstream Hermes entrypoint already discovers TELEGRAM_BOT_TOKEN
# from env and configures the Telegram gateway automatically. An earlier
# version of this script tried to call `gateway setup` and printed a
# `warn: gateway setup telegram failed` line on every boot — the upstream
# behaviour is what we want, so we let it happen and stay silent.

set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
HERMES_BIN=/opt/hermes/.venv/bin/hermes
UPSTREAM_ENTRYPOINT=/opt/hermes/docker/entrypoint.sh

if [ "$(id -u)" = "0" ]; then
    # 1. Repair volume perms.
    if [ -d "$HERMES_HOME" ]; then
        chown -R hermes:hermes "$HERMES_HOME" 2>/dev/null || \
            echo "[startup] warn: chown $HERMES_HOME failed (continuing)"
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
        if [ -n "$value" ]; then
            if gosu hermes "$HERMES_BIN" config set "$key" "$value" >/dev/null 2>&1; then
                echo "[startup] config set $key"
            else
                echo "[startup] warn: failed to set $key"
            fi
        fi
    }

    apply_config "model.provider"               "openrouter"
    apply_config "model.base_url"               "https://openrouter.ai/api/v1"
    apply_config "model.default"                "${HERMES_DEFAULT_MODEL:-}"
    apply_config "model.fast"                   "${HERMES_FAST_MODEL:-}"
    apply_config "provider.openrouter.api_key"  "${OPENROUTER_API_KEY:-}"
    apply_config "provider.tavily.api_key"      "${TAVILY_API_KEY:-}"
fi

# Hand off to upstream entrypoint. It does the gosu drop and final exec.
exec "$UPSTREAM_ENTRYPOINT" "$@"
