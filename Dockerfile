# =============================================================================
# LeechBot - Dockerfile
# =============================================================================
# Multi-stage compatible Dockerfile
# Python 3.12
# =============================================================================

FROM python:3.12-slim AS base

LABEL maintainer="Shinei Nouzen <https://github.com/Shineii86>" \
      description="Advanced Telegram File Transloader" \
      version="3.1.47"

# =============================================================================
# Python / pip environment
# =============================================================================

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# =============================================================================
# System dependencies
# =============================================================================
# ffmpeg             - video/audio processing
# aria2              - HTTP/FTP/Bittorrent downloader
# p7zip-full         - archive extraction
# unzip              - ZIP archive extraction
# python3-libtorrent - torrent/magnet support
# curl               - health checks
# tini               - proper PID 1 signal handling
# gcc/g++/make       - build Python packages such as tgcrypto
#
# NOTE:
# Debian Trixie does not provide the "unrar" package in the default
# repository, so it is intentionally not installed here.
# =============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        aria2 \
        p7zip-full \
        unzip \
        python3-libtorrent \
        curl \
        tini \
        gcc \
        g++ \
        make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install megatools
# =============================================================================
# Try Debian package first.
# If unavailable, build megatools from source.
# =============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends megatools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    || ( \
        curl -fsSL \
        https://github.com/megous/megatools/releases/download/1.11.1/megatools-1.11.1.tar.gz \
        | tar xz \
        && cd megatools-1.11.1 \
        && ./configure \
        && make \
        && make install \
        && cd .. \
        && rm -rf megatools-1.11.1 \
    )

# =============================================================================
# Application directory
# =============================================================================

WORKDIR /app

# =============================================================================
# Python dependencies
# =============================================================================
# Copy requirements separately so Docker can cache this layer.
# =============================================================================

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# =============================================================================
# Application source
# =============================================================================

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
# Web dashboard port
# =============================================================================

EXPOSE 8080

# =============================================================================
# Health check
# =============================================================================

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=15s \
    --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# =============================================================================
# PID 1 / graceful shutdown
# =============================================================================

ENTRYPOINT ["tini", "--"]

# =============================================================================
# Start LeechBot
# =============================================================================

CMD ["python3", "-m", "leechbot"]
