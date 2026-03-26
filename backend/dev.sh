#!/bin/bash
# 本地开发启动脚本
cd "$(dirname "$0")"

# 检查依赖
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "[Setup] 安装依赖..."
    pip3 install fastapi uvicorn pydantic aiohttp
fi

echo "[Start] 启动顺时后端 (端口 8000)..."
python3 -m uvicorn app.api:app --host 0.0.0.0 --port 8000 --reload
