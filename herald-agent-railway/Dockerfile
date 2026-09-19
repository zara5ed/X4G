# syntax=docker/dockerfile:1
# ──────────────────────────────────────────────────────────────────────────────
#  Herald · AI agent gateway — Railway edition
#
#  Thin overlay on the official Hermes Agent image (MIT, Nous Research).
#  The upstream image already ships a supervised runtime (s6-overlay), Python,
#  Node, Playwright and the `hermes` CLI, so there is nothing to compile here:
#  we only add the Railway bootstrap, a health endpoint and a default persona.
#
#  The image's ENTRYPOINT is intentionally left untouched. It must stay first in
#  the chain because it performs the first-boot volume ownership fix and drops
#  privileges to the unprivileged `hermes` user before the agent starts.
#  Overriding it would both break that and remove orphan-process reaping.
#
#  Pin HERMES_IMAGE to a tag or digest for reproducible deploys, e.g.
#    railway variables --set HERMES_IMAGE=nousresearch/hermes-agent:v2026.9.7
# ──────────────────────────────────────────────────────────────────────────────
ARG HERMES_IMAGE=nousresearch/hermes-agent:latest
FROM ${HERMES_IMAGE}

LABEL org.opencontainers.image.title="Herald — AI agent gateway (Railway edition)" \
      org.opencontainers.image.description="Self-hosted AI agent for chat apps, deployment wrapper for Hermes Agent (MIT)." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/NousResearch/hermes-agent"

# Railway bootstrap, health endpoint and default persona.
# Files are world-readable and root-owned: the `hermes` user only needs to read them.
COPY app/health_server.py /opt/herald/health_server.py
COPY scripts/bootstrap.sh  /opt/herald/bootstrap.sh
COPY assets/soul.md        /opt/herald/soul.md

RUN chmod 0755 /opt/herald /opt/herald/bootstrap.sh /opt/herald/health_server.py \
 && chmod 0644 /opt/herald/soul.md

ENV HERALD_VERSION="1.0.0" \
    PYTHONUNBUFFERED="1" \
    PYTHONDONTWRITEBYTECODE="1"

# `bash` resolves on PATH, so the image's dispatcher execs our script directly
# after the first-boot hook has finished. The script validates the Railway
# variables, starts the health endpoint and hands over to `hermes gateway run`.
CMD ["bash", "/opt/herald/bootstrap.sh"]
