FROM nousresearch/hermes-agent:latest

# Our skills + references baked at /opt/agent (NOT under /opt/data — that path
# is the persistent volume mount, which would shadow image-baked files).
# Skills read references from /opt/agent/references at runtime.
COPY skills/      /opt/agent/skills/
COPY references/  /opt/agent/references/
COPY audit/       /opt/agent/audit/

# Custom MCP servers (currently: Gmail). Run in a dedicated venv so we don't
# clash with Hermes' own /opt/hermes/.venv.
COPY mcp_servers/ /opt/agent/mcp_servers/
RUN python3 -m venv /opt/agent/mcp_venv \
    && /opt/agent/mcp_venv/bin/pip install --no-cache-dir \
        mcp \
        google-auth \
        google-api-python-client

# Startup wrapper: fixes volume perms + applies hermes config from env vars.
# Sits in front of the upstream entrypoint, which still handles the gosu drop.
COPY startup.sh /opt/agent/startup.sh
RUN chmod +x /opt/agent/startup.sh

ENV HERMES_HOME=/opt/data
ENV AGENT_ROOT=/opt/agent

EXPOSE 8642

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/agent/startup.sh"]
CMD ["hermes", "gateway", "run"]
