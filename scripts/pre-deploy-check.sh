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

check_pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
check_fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }

echo "============================================"
echo "  顺时 ShunShi — 部署前环境检查"
echo "============================================"
echo ""

# 1. 环境变量检查
echo "--- 环境变量 ---"
REQUIRED_ENVS=("SHUNSHI_JWT_SECRET" "SHUNSHI_DATABASE_URL" "SILICONFLOW_API_KEY" "SHUNSHI_CORS_ORIGINS")
for env in "${REQUIRED_ENVS[@]}"; do
    if [ -n "${!env}" ]; then
        check_pass "$env 已设置"
    else
        check_fail "$env 未设置 (生产环境必需)"
    fi
done

# JWT 密钥强度检查
if [ -n "$SHUNSHI_JWT_SECRET" ]; then
    LEN=${#SHUNSHI_JWT_SECRET}
    if [ "$LEN" -ge 32 ]; then
        check_pass "SHUNSHI_JWT_SECRET 长度足够 ($LEN 字符)"
    else
        check_fail "SHUNSHI_JWT_SECRET 太短 ($LEN 字符, 必须 >= 32)"
    fi
fi

# 2. 数据库检查
echo ""
echo "--- 数据库 ---"
if echo "$SHUNSHI_DATABASE_URL" | grep -q "postgresql"; then
    check_pass "使用 PostgreSQL (生产环境推荐)"
else
    check_warn "使用 SQLite (生产环境建议迁移到 PostgreSQL)"
fi

# 3. CORS 检查
echo ""
echo "--- CORS 配置 ---"
if [ -n "$SHUNSHI_CORS_ORIGINS" ] && [ "$SHUNSHI_CORS_ORIGINS" != "*" ]; then
    check_pass "CORS 已限制: $SHUNSHI_CORS_ORIGINS"
else
    check_fail "SHUNSHI_CORS_ORIGINS 未设置或设为 * (生产环境必须限制)"
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
if [ -f "k8s/secret.yaml" ]; then
    check_pass "Kubernetes Secret 字段模板存在（生产部署不会直接 apply）"
else
    check_fail "k8s/secret.yaml 字段模板不存在"
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
if echo | openssl s_client -connect shunshi.app:443 -servername shunshi.app -verify_return_error >/dev/null 2>&1; then
    check_pass "shunshi.app TLS 握手与证书链正常"
else
    check_warn "shunshi.app TLS 尚未就绪；部署 Ingress/cert-manager 并配置 DNS 后复验"
fi

# 8. Kubernetes 工具检查
echo ""
echo "--- Kubernetes 工具 ---"
if command -v kubectl >/dev/null 2>&1; then
    check_pass "kubectl 已安装"
else
    check_fail "kubectl 未安装"
fi

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
