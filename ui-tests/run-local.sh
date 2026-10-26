#!/bin/bash
# 本地界面测试：只起开发后端。模型走 SHUNSHI_LLM_STUB，不读取任何密钥文件。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p /tmp/shunshi-ui
export SHUNSHI_ENV=development
export SHUNSHI_LLM_STUB=1
export SHUNSHI_JWT_SECRET='ui-test-only-jwt-secret-32chars-min'
export SHUNSHI_DATABASE_URL='sqlite:////tmp/shunshi-ui/app.db'
export DATABASE_URL='sqlite:////tmp/shunshi-ui/product.db'
export SHUNSHI_CORS_ORIGINS='http://127.0.0.1:8090,http://localhost:8090,http://127.0.0.1:3008'
export SHUNSHI_REDIS_URL="${SHUNSHI_REDIS_URL:-redis://127.0.0.1:6379/0}"
export ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
export ADMIN_JWT_SECRET='ui-test-only-admin-jwt-secret-32ch'
# 假口令，只给本机界面测试登录管理后台。不要拿到其他环境使用。
export ADMIN_PASSWORD_HASH="$(printf '%s' 'ui-test-dummy-password' | sha256sum | awk '{print $1}')"
PY="${SHUNSHI_PYTHON:-/tmp/shunshi-venv/bin/python}"
cd "$ROOT/backend"
exec "$PY" -m uvicorn app.main:app --host 127.0.0.1 --port "${PORT:-4000}"
