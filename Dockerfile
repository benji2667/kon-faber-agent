# Pinned to a verified digest of nousresearch/hermes-agent:latest as of 2026-05-18.
# To re-pin: `docker manifest inspect nousresearch/hermes-agent:latest` and
# replace the sha256 below. Floating :latest was responsible for surprise base
# image changes; the CI workflow (./.github/workflows/build.yml) re-runs
# `docker build .` on every PR to catch base-image drift early.
FROM nousresearch/hermes-agent:latest@sha256:b6e41c155d6bfce5ad83c5d0fec670086db8a43250e4511c9474134be5482d33

# Our skills + references baked at /opt/agent (NOT under /opt/data — that path
# is the persistent volume mount, which would shadow image-baked files).
# Skills read references from /opt/agent/references at runtime.
COPY skills/      /opt/agent/skills/
COPY references/  /opt/agent/references/
COPY audit/       /opt/agent/audit/

# Custom MCP servers (currently: Gmail). Base image ships python3 but neither
# pip nor ensurepip; apt-install python3-pip, install pinned deps to system
# python, then drop the apt cache. Hermes itself runs out of /opt/hermes/.venv
# so system-python installs don't collide.
COPY mcp_servers/ /opt/agent/mcp_servers/
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-pip \
    && python3 -m pip install --no-cache-dir --break-system-packages \
        mcp==1.27.1 \
        google-auth==2.53.0 \
        google-api-python-client==2.196.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Startup wrapper: fixes volume perms + applies hermes config from env vars.
# Sits in front of the upstream entrypoint, which still handles the gosu drop.
COPY startup.sh /opt/agent/startup.sh
RUN chmod +x /opt/agent/startup.sh

ENV HERMES_HOME=/opt/data
ENV AGENT_ROOT=/opt/agent

EXPOSE 8642

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/agent/startup.sh"]
CMD ["hermes", "gateway", "run"]
