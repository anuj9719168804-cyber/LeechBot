# =============================================================================
# LeechBot - Dockerfile
# =============================================================================

FROM python:3.12-slim AS base

LABEL maintainer="Shinei Nouzen <https://github.com/Shineii86>" \
      description="Advanced Telegram File Transloader" \
      version="3.1.47"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        aria2 \
        p7zip-full \
        unzip \
        python3-libtorrent \
        curl \
        tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends megatools \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    || (curl -fsSL https://github.com/megous/megatools/releases/download/1.11.1/megatools-1.11.1.tar.gz | tar xz \
        && cd megatools-1.11.1 && ./configure && make && make install && cd .. \
        && rm -rf megatools-1.11.1)

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p sessions downloads temp work thumbnails logs

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

ENTRYPOINT ["tini", "--"]

CMD ["python3", "-m", "leechbot"]
