#!/bin/bash
# =============================================================================
# 顺时 ShunShi — 部署前环境验证脚本
# =============================================================================
# 在部署到生产环境前运行，检查所有必要条件
#
# 使用方法:
#   chmod +x pre-deploy-check.sh
#   ./pre-deploy-check.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "${GREEN}✓${NC} $1"; ((PASS++)); }
check_fail() { echo -e "${RED}✗${NC} $1"; ((FAIL++)); }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARN++)); }

echo "============================================"
echo "  顺时 ShunShi — 部署前环境检查"
echo "============================================"
echo ""

# 1. 环境变量检查
echo "--- 环境变量 ---"
REQUIRED_ENVS=("JWT_SECRET" "DATABASE_URL" "SILICONFLOW_API_KEY")
for env in "${REQUIRED_ENVS[@]}"; do
    if [ -n "${!env}" ]; then
        check_pass "$env 已设置"
    else
        check_fail "$env 未设置 (生产环境必需)"
    fi
done

# JWT_SECRET 强度检查
if [ -n "$JWT_SECRET" ]; then
    LEN=${#JWT_SECRET}
    if [ "$LEN" -ge 32 ]; then
        check_pass "JWT_SECRET 长度足够 ($LEN 字符)"
    else
        check_warn "JWT_SECRET 太短 ($LEN 字符, 建议 >= 32)"
    fi
fi

# 2. 数据库检查
echo ""
echo "--- 数据库 ---"
if echo "$DATABASE_URL" | grep -q "postgresql"; then
    check_pass "使用 PostgreSQL (生产环境推荐)"
else
    check_warn "使用 SQLite (生产环境建议迁移到 PostgreSQL)"
fi

# 3. CORS 检查
echo ""
echo "--- CORS 配置 ---"
if [ -n "$CORS_ORIGINS" ] && [ "$CORS_ORIGINS" != "*" ]; then
    check_pass "CORS 已限制: $CORS_ORIGINS"
else
    check_fail "CORS_ORIGINS 未设置或设为 * (生产环境必须限制)"
fi

# 4. Python 依赖检查
echo ""
echo "--- Python 依赖 ---"
if python3 -c "import fastapi" 2>/dev/null; then
    check_pass "FastAPI 已安装"
else
    check_fail "FastAPI 未安装"
fi

if python3 -c "import gunicorn" 2>/dev/null; then
    check_pass "gunicorn 已安装"
else
    check_warn "gunicorn 未安装 (Docker 构建时会安装)"
fi

# 5. 文件检查
echo ""
echo "--- 文件检查 ---"
if [ -f "backend/.env" ]; then
    check_pass "backend/.env 存在"
else
    check_fail "backend/.env 不存在"
fi

if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml 存在"
else
    check_fail "docker-compose.yml 不存在"
fi

# 6. Docker 检查
echo ""
echo "--- Docker ---"
if command -v docker &> /dev/null; then
    check_pass "Docker 已安装"
    if command -v docker compose &> /dev/null; then
        check_pass "Docker Compose 已安装"
    else
        check_warn "Docker Compose 插件未安装"
    fi
else
    check_warn "Docker 未安装"
fi

# 7. SSL 检查
echo ""
echo "--- SSL 证书 ---"
if [ -d "/etc/letsencrypt/live/shunshi.cn" ]; then
    check_pass "SSL 证书已存在"
    # 检查过期时间
    EXPIRY=$(openssl x509 -in /etc/letsencrypt/live/shunshi.cn/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)
    check_pass "证书过期时间: $EXPIRY"
else
    check_warn "SSL 证书未找到，运行 scripts/init-ssl.sh 申请"
fi

# 8. 端口检查
echo ""
echo "--- 端口占用 ---"
for port in 80 443 4000; do
    if ss -tlnp | grep -q ":$port "; then
        check_warn "端口 $port 已被占用"
    else
        check_pass "端口 $port 可用"
    fi
done

# 总结
echo ""
echo "============================================"
echo "  检查结果"
echo "============================================"
echo -e "通过: ${GREEN}$PASS${NC}"
echo -e "失败: ${RED}$FAIL${NC}"
echo -e "警告: ${YELLOW}$WARN${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}部署被阻止: 有 $FAIL 个失败项必须修复${NC}"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}可以部署，但有 $WARN 个警告建议处理${NC}"
    exit 0
else
    echo -e "${GREEN}所有检查通过，可以安全部署!${NC}"
    exit 0
fi
