#!/bin/bash
# ============================================================
# 顺时后端 — ECS 部署脚本
# 用法: bash deploy_ecs.sh
# 前提: 已配置 SSH 密钥 ~/.ssh/ecs_shunshi
# ============================================================

set -euo pipefail

# ==================== 配置 ====================
ECS_HOST="116.62.32.43"
ECS_USER="root"
ECS_SSH_KEY="${HOME}/.ssh/id_rsa"  # 修改为你的实际密钥路径
REMOTE_DIR="/opt/shunshi/backend"
LOCAL_BACKEND_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==================== 顺时后端部署 ===================="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "本地目录: $LOCAL_BACKEND_DIR"
echo "目标服务器: $ECS_USER@$ECS_HOST:$REMOTE_DIR"
echo "======================================================"

# Step 1: 同步代码到 ECS
echo ""
echo "[1/5] 同步代码到 ECS..."
rsync -avz --delete \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude '.env' \
    --exclude 'shunshi.db' \
    --exclude 'venv' \
    --exclude '.git' \
    -e "ssh -i $ECS_SSH_KEY" \
    "$LOCAL_BACKEND_DIR/" \
    "$ECS_USER@$ECS_HOST:$REMOTE_DIR/"

echo "✅ 代码同步完成"

# Step 2: 上传生产环境配置
echo ""
echo "[2/5] 上传生产环境配置..."
scp -i "$ECS_SSH_KEY" \
    "$LOCAL_BACKEND_DIR/.env.production" \
    "$ECS_USER@$ECS_HOST:$REMOTE_DIR/.env"
echo "✅ 生产配置已覆盖 .env"

# Step 3: 安装依赖
echo ""
echo "[3/5] 安装 Python 依赖..."
ssh -i "$ECS_SSH_KEY" "$ECS_USER@$ECS_HOST" << 'EOF'
cd /opt/shunshi/backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt --quiet 2>&1 | tail -5
echo "✅ 依赖安装完成"
EOF

# Step 4: 重启服务
echo ""
echo "[4/5] 重启后端服务..."
ssh -i "$ECS_SSH_KEY" "$ECS_USER@$ECS_HOST" << 'EOF'
cd /opt/shunshi/backend

# 停止旧进程
pkill -f "uvicorn app.main:app" 2>/dev/null || true
sleep 2

# 启动新进程
source venv/bin/activate
nohup uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 4000 \
    --workers 2 \
    --timeout-keep-alive 30 \
    > /var/log/shunshi/api.log 2>&1 &

echo "✅ 服务已重启 (PID: $!)"
EOF

# Step 5: 健康检查
echo ""
echo "[5/5] 健康检查..."
sleep 5

HEALTH=$(curl -s --max-time 10 "http://$ECS_HOST:4000/health" 2>/dev/null || echo '{"status":"unreachable"}')
echo "健康检查结果: $HEALTH"

if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    echo ""
    echo "🎉 部署成功！"
elif echo "$HEALTH" | grep -q '"status":"degraded"'; then
    echo ""
    echo "⚠️  部署完成但服务降级（检查 Redis/DB 配置）"
else
    echo ""
    echo "❌ 部署可能失败，请检查日志:"
    echo "   ssh $ECS_USER@$ECS_HOST 'tail -50 /var/log/shunshi/api.log'"
fi

echo ""
echo "==================== 部署完成 ===================="
echo "API: http://$ECS_HOST:4000"
echo "健康: http://$ECS_HOST:4000/health"
echo "文档: http://$ECS_HOST:4000/docs"
echo "======================================================"
