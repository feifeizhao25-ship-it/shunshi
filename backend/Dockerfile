# 顺时后端 Dockerfile - 生产优化版
# 多阶段构建，支持 SQLite / PostgreSQL
FROM python:3.12-slim AS base

# 系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 依赖安装层 (利用 Docker 缓存)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 安装生产额外依赖
RUN pip install --no-cache-dir \
    alembic \
    asyncpg \
    psycopg2-binary \
    aiosqlite \
    python-alipay-sdk \
    firebase-admin \
    apns2

# 复制应用代码
COPY . .

# 创建必要目录
RUN mkdir -p /app/data /app/logs /app/secrets

# 非特权用户
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 4000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_ENV=production

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health')"

# 启动
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4000", "--workers", "2"]
