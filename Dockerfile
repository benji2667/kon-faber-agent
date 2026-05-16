FROM nousresearch/hermes-agent:latest

# Our skills + references baked at /opt/agent (NOT under /opt/data — that path
# is the persistent volume mount, which would shadow image-baked files).
# Skills read references from /opt/agent/references at runtime.
COPY skills/      /opt/agent/skills/
COPY references/  /opt/agent/references/
COPY audit/       /opt/agent/audit/

# Startup wrapper: fixes volume perms + applies hermes config from env vars.
# Sits in front of the upstream entrypoint, which still handles the gosu drop.
COPY startup.sh /opt/agent/startup.sh
RUN chmod +x /opt/agent/startup.sh

ENV HERMES_HOME=/opt/data
ENV AGENT_ROOT=/opt/agent

EXPOSE 8642

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/agent/startup.sh"]
CMD ["hermes", "gateway", "run"]
