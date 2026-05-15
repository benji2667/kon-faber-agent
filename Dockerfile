# Used from Phase 1 onwards once we add our own skills.
# Phase 0 deploys the upstream image directly (no custom Dockerfile needed).

FROM nousresearch/hermes-agent:latest

# Our skills + references baked at /opt/agent (NOT under /opt/data — that path
# is the persistent volume mount, which would shadow image-baked files).
# Skills read references from /opt/agent/references at runtime.
COPY skills/      /opt/agent/skills/
COPY references/  /opt/agent/references/
COPY audit/       /opt/agent/audit/

# Hermes state (config, memory, skill registry, sqlite) lives in /opt/data —
# the Railway persistent volume mount. Survives container restarts.
ENV HERMES_HOME=/opt/data
ENV AGENT_ROOT=/opt/agent

EXPOSE 8642

# Daemon command. Explicit `hermes` prefix in case ENTRYPOINT is overridden.
CMD ["hermes", "gateway", "run"]
