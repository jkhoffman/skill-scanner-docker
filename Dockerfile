# ── Stage 1: Build ───────────────────────────────────────────────
FROM python:3.12-slim AS builder

# Version can be passed at build time (needed because hatch-vcs relies on
# git history which is excluded from the Docker context for size reasons).
#   docker build --build-arg VERSION=1.2.3 .
# If omitted, falls back to "0.0.0+docker".
ARG VERSION=0.0.0+docker
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libyara-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast, reproducible installs
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /build

# Build the venv at its final runtime path so shebangs are correct after copy
ENV VENV=/home/scanner/.venv

# Copy dependency metadata first (cache-friendly layer)
COPY pyproject.toml uv.lock ./

# Create venv and install dependencies
RUN uv venv ${VENV} && \
    uv pip install --python ${VENV}/bin/python -r pyproject.toml

# Copy source
COPY . .

# Install the project itself
RUN uv pip install --python ${VENV}/bin/python --no-deps .

# ── Stage 2: Runtime ─────────────────────────────────────────────
FROM python:3.12-slim

# libyara is needed at runtime by yara-python
RUN apt-get update && apt-get install -y --no-install-recommends \
        libyara10 \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd --create-home scanner
USER scanner

# Bring the venv from the builder
COPY --from=builder --chown=scanner:scanner /home/scanner/.venv /home/scanner/.venv
ENV PATH="/home/scanner/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Working directory — mount skill directories here
WORKDIR /scan

# API server default port
EXPOSE 8000

# Default: run the CLI.
# Override entrypoint for the API server:
#   docker run … --entrypoint skill-scanner-api skill-scanner --host 0.0.0.0
ENTRYPOINT ["skill-scanner"]
