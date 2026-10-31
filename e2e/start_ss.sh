#!/bin/bash
source /workspace/ui_full_test/run/ss_env.sh
cd /workspace/ui_full_test/src/shunshi/backend
exec /workspace/uit/ssbox-venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 4000
