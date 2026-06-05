# ============================================================================
# Hunter Agent — Dockerfile
# A containerized Hermes agent specialized for security code analysis.
# Base: python:3.11-slim  |  Deployed on: Fly.io
# ============================================================================

FROM python:3.11-slim AS base

# Prevent interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ── System dependencies ──
# git: clone target repos  |  curl/wget: web tools  |  ripgrep: search_files
# jq: JSON processing  |  build-essential: compile native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    ripgrep \
    build-essential \
    ca-certificates \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ── Install Hermes Agent from PyPI ──
# Install hermes-agent and its dependencies
RUN pip install hermes-agent

# ── Install additional analysis tools ──
RUN pip install \
    semgrep \
    bandit \
    safety \
    && rm -rf /root/.cache/pip

# ── Application layer ──
WORKDIR /app

# Copy repo contents (skills, config, scripts, docs)
COPY . /app/

# Make boot script executable
RUN chmod +x /app/scripts/boot.sh

# ── Create working directories ──
RUN mkdir -p /app/reports /app/targets /root/.hermes/skills

# ── Health check ──
# The Hunter is a batch job, not a server — but Fly wants something.
# We just check the process is alive.
HEALTHCHECK --interval=60s --timeout=5s --retries=3 \
    CMD pgrep -f "hermes" || exit 1

# ── Entrypoint ──
ENTRYPOINT ["/app/scripts/boot.sh"]
