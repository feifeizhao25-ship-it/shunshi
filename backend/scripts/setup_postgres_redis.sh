#!/bin/bash
# ============================================================
# 顺时 — PostgreSQL + Redis 一键配置
# 在 ECS 服务器上运行
# ============================================================

set -euo pipefail

echo "==================== PostgreSQL + Redis 配置 ===================="

# ==================== PostgreSQL ====================
echo ""
echo "[1/4] 安装 PostgreSQL..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq postgresql postgresql-contrib
elif command -v yum &>/dev/null; then
    yum install -y postgresql-server postgresql-contrib
    postgresql-setup --initdb 2>/dev/null || true
fi

# 启动 PostgreSQL
systemctl enable postgresql
systemctl start postgresql

echo "✅ PostgreSQL 已安装并启动"

# ==================== 创建数据库和用户 ====================
echo ""
echo "[2/4] 创建数据库和用户..."

# 检查用户和数据库是否已存在
su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='shunshi'\"" | grep -q 1 || \
    su - postgres -c "psql -c \"CREATE USER shunshi WITH PASSWORD 'shunshi123';\""

su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname='shunshi'\"" | grep -q 1 || \
    su - postgres -c "psql -c \"CREATE DATABASE shunshi OWNER shunshi;\""

# 授权
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE shunshi TO shunshi;\""

# 允许密码登录
PG_HBA=$(su - postgres -c "psql -t -c 'SHOW hba_file'" | xargs)
if ! grep -q "shunshi" "$PG_HBA" 2>/dev/null; then
    echo "local   shunshi   shunshi   md5" >> "$PG_HBA"
    echo "host    shunshi   shunshi   127.0.0.1/32   md5" >> "$PG_HBA"
    systemctl reload postgresql
fi

echo "✅ 数据库 'shunshi' 和用户已创建"

# 验证连接
PGPASSWORD=shunshi123 psql -U shunshi -d shunshi -h localhost -c "SELECT 1" > /dev/null 2>&1 && \
    echo "✅ PostgreSQL 连接验证成功" || \
    echo "⚠️  PostgreSQL 连接失败，请检查 pg_hba.conf"

# ==================== Redis ====================
echo ""
echo "[3/4] 安装 Redis..."
if command -v apt-get &>/dev/null; then
    apt-get install -y -qq redis-server
elif command -v yum &>/dev/null; then
    yum install -y redis
fi

# 配置 Redis
REDIS_CONF="/etc/redis/redis.conf"
[ -f "$REDIS_CONF" ] || REDIS_CONF="/etc/redis.conf"

if [ -f "$REDIS_CONF" ]; then
    # 只绑定本地
    sed -i 's/^bind .*/bind 127.0.0.1/' "$REDIS_CONF"
    # 设置最大内存
    grep -q "^maxmemory" "$REDIS_CONF" || echo "maxmemory 256mb" >> "$REDIS_CONF"
    grep -q "^maxmemory-policy" "$REDIS_CONF" || echo "maxmemory-policy allkeys-lru" >> "$REDIS_CONF"
fi

systemctl enable redis-server 2>/dev/null || systemctl enable redis 2>/dev/null
systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null

echo "✅ Redis 已安装并配置"

# 验证 Redis
redis-cli ping > /dev/null 2>&1 && \
    echo "✅ Redis 连接验证成功 (PONG)" || \
    echo "⚠️  Redis 连接失败"

# ==================== 数据库迁移 ====================
echo ""
echo "[4/4] 运行数据库迁移..."
cd /opt/shunshi/backend

if [ -d "venv" ]; then
    source venv/bin/activate
fi

# 设置环境变量
export DATABASE_URL="postgresql+psycopg2://shunshi:shunshi123@localhost:5432/shunshi"
export REDIS_URL="redis://localhost:6379/0"

# 使用 Alembic 迁移（如果有 versions）
if [ -d "alembic/versions" ] && ls alembic/versions/*.py 1>/dev/null 2>&1; then
    python -m alembic upgrade head
    echo "✅ Alembic 迁移完成"
else
    # 首次：直接用 SQLAlchemy create_all
    python -c "
from app.db.database import init_db
init_db()
print('✅ 数据库表创建完成 (create_all)')
"
fi

echo ""
echo "==================== 配置完成 ===================="
echo ""
echo "PostgreSQL: postgresql://shunshi:shunshi123@localhost:5432/shunshi"
echo "Redis:      redis://localhost:6379/0"
echo ""
echo "环境变量已设置在 .env.production 中，确保后端使用："
echo "  DATABASE_URL=postgresql+psycopg2://shunshi:shunshi123@localhost:5432/shunshi"
echo "  REDIS_URL=redis://localhost:6379/0"
echo "======================================================"
