#!/bin/bash
# fix2 retest: 顺时 backend from /workspace/fix2/ss (feat/ss-stack), own sqlite file, redis db 9, port 4293.
export SHUNSHI_ENV=development
export SHUNSHI_DATABASE_URL=sqlite:////workspace/ui_full_test/retest/run/ss3.db
export SHUNSHI_REDIS_URL=redis://127.0.0.1:16379/9
export SHUNSHI_JWT_SECRET=$(python3 -c "import secrets;print(secrets.token_hex(24))")
export SHUNSHI_MODEL_ROUTER_URL=http://127.0.0.1:9100
export SHUNSHI_CORS_ORIGINS="*"
export SHUNSHI_MINIMAX_API_KEY="$MINIMAX_CN_API_KEY"
export ADMIN_PASSWORD_HASH=$(python3 -c "import hashlib,secrets;print(hashlib.sha256(secrets.token_bytes(16)).hexdigest())")
export ADMIN_JWT_SECRET=$(python3 -c "import secrets;print(secrets.token_hex(24))")
cd /workspace/fix2/ss/backend
exec /workspace/uit/ssbox-venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 4293
