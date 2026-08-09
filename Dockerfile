# =============================================================================
# LeechBot - Dockerfile
# =============================================================================
# Platforms:
#   linux/amd64
#   linux/arm64
# =============================================================================

FROM python:3.12-slim-bookworm

LABEL maintainer="Shinei Nouzen <https://github.com/Shineii86>" \
      description="Advanced Telegram File Transloader" \
      version="3.1.47"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# =============================================================================
# System dependencies
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

COPY requirements.txt .

# Install Python dependencies.
# Do not upgrade pip unnecessarily; use the pip bundled with the
# Python 3.12 base image.
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY . .

# Runtime directories
RUN mkdir -p \
    sessions \
    downloads \
    temp \
    work \
    thumbnails \
    logs

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

ENTRYPOINT ["tini", "--"]

CMD ["python", "-m", "leechbot"]
