# Used from Phase 1 onwards once we add our own skills.
# Phase 0 deploys the upstream image directly (no custom Dockerfile needed).

FROM nousresearch/hermes-agent:latest

# Our skills + references baked into the image so deploys are reproducible
COPY skills/ /opt/data/skills/
COPY references/ /opt/data/references/

# Hermes state (config, memory, skill registry, sqlite) lives in /opt/data.
# A Railway persistent volume should be mounted here so state survives restarts.
ENV HERMES_HOME=/opt/data

EXPOSE 8642

# Daemon command. Explicit `hermes` prefix in case ENTRYPOINT is overridden.
CMD ["hermes", "gateway", "run"]
