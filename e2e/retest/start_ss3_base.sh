#!/bin/bash
# fix2 retest: 顺时 backend from /workspace/fix2/ss (base 842b552f), own sqlite file, redis db 9, port 4293.
export SHUNSHI_ENV=development
export SHUNSHI_DATABASE_URL=sqlite:////workspace/ui_full_test/retest/run/ss3_base.db
export SHUNSHI_REDIS_URL=redis://127.0.0.1:16379/12
export SHUNSHI_JWT_SECRET=$(python3 -c "import secrets;print(secrets.token_hex(24))")
export SHUNSHI_MODEL_ROUTER_URL=http://127.0.0.1:9100
export SHUNSHI_CORS_ORIGINS="*"
export SHUNSHI_MINIMAX_API_KEY="$MINIMAX_CN_API_KEY"
export ADMIN_PASSWORD_HASH=$(python3 -c "import hashlib,secrets;print(hashlib.sha256(secrets.token_bytes(16)).hexdigest())")
export ADMIN_JWT_SECRET=$(python3 -c "import secrets;print(secrets.token_hex(24))")
export SHUNSHI_KNOWLEDGE_DIR="/workspace/fix2/ss/参考文档，知识库"
cd /workspace/fix2/ui_retest/ss_base/backend
exec /workspace/uit/ssbox-venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 4296
