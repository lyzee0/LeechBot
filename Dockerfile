# =============================================================================
# LeechBot - Dockerfile
# =============================================================================
# Multi-platform:
#   - linux/amd64
#   - linux/arm64
#
# Python:
#   - 3.12
#
# Build:
#   docker buildx build --platform linux/amd64,linux/arm64 .
# =============================================================================

FROM python:3.12-slim-bookworm

LABEL maintainer="Shinei Nouzen <https://github.com/Shineii86>" \
      description="Advanced Telegram File Transloader" \
      version="3.1.47"

# =============================================================================
# Environment
# =============================================================================

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# =============================================================================
# System dependencies
# =============================================================================
#
# IMPORTANT:
# Do NOT install python3-libtorrent here.
#
# Debian Bookworm's python3-libtorrent package targets Python 3.11 and is
# incompatible with the Python 3.12 interpreter in this image.
#
# libtorrent is installed from PyPI in requirements.txt. Current libtorrent
# releases provide CPython 3.12 wheels for both AMD64 and ARM64.
# =============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        aria2 \
        p7zip-full \
        unrar-free \
        unzip \
        megatools \
        curl \
        ca-certificates \
        tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Application
# =============================================================================

WORKDIR /app

# Copy requirements first for maximum Docker layer caching.
COPY requirements.txt .

# Install Python dependencies.
RUN python -m pip install --upgrade pip && \
    python -m pip install --no-cache-dir -r requirements.txt

# Copy application source.
COPY . .

# =============================================================================
# Runtime directories
# =============================================================================

RUN mkdir -p \
        sessions \
        downloads \
        temp \
        work \
        thumbnails \
        logs

# =============================================================================
# Port
# =============================================================================

EXPOSE 8080

# =============================================================================
# Health check
# =============================================================================

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=20s \
    --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/api/health || exit 1

# =============================================================================
# Runtime
# =============================================================================

# tini becomes PID 1 and forwards SIGTERM/SIGINT correctly.
ENTRYPOINT ["tini", "--"]

CMD ["python", "-m", "leechbot"]
