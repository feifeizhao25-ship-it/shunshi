# 顺时后端 Dockerfile — 生产优化版
# 多阶段构建，支持 SQLite / PostgreSQL
# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: dependency builder (cached separately from app code)
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: runtime image
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Runtime system libraries only (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

WORKDIR /app

# Copy application code
COPY . .

# Create required directories
RUN mkdir -p /app/data /app/logs /app/secrets

# Non-privileged user
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 4000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    APP_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health')"

# Start (2 workers for typical cloud VM; tune via UVICORN_WORKERS env var)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 4000 --workers ${UVICORN_WORKERS:-2}"]
