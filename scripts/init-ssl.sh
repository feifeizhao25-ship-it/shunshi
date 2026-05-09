#!/bin/bash
# =============================================================================
# 顺时 ShunShi — SSL 证书初始化脚本 (Let's Encrypt)
# =============================================================================
set -e

DOMAINS=("shunshi.cn" "api.shunshi.cn" "app.shunshi.cn")
EMAIL="admin@shunshi.cn"
CERTBOT_DIR="/var/www/certbot"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    err "请使用 sudo 运行此脚本"
    exit 1
fi

if ! command -v certbot &> /dev/null; then
    log "安装 certbot..."
    apt-get update && apt-get install -y certbot python3-certbot-nginx
fi

mkdir -p "$CERTBOT_DIR"

log "检查域名解析..."
for domain in "${DOMAINS[@]}"; do
    resolved_ip=$(dig +short "$domain" | head -1)
    server_ip=$(curl -s ifconfig.me)
    if [ "$resolved_ip" != "$server_ip" ]; then
        warn "$domain 解析到 $resolved_ip, 本机 IP 是 $server_ip"
    else
        log "$domain → $resolved_ip ✓"
    fi
done

log "申请 Let's Encrypt 证书..."
certbot certonly \
    --nginx --non-interactive --agree-tos \
    --email "$EMAIL" \
    --domains "${DOMAINS[*]}" \
    --webroot-path "$CERTBOT_DIR" \
    || { err "证书申请失败"; exit 1; }

log "配置自动续期..."
if ! crontab -l 2>/dev/null | grep -q certbot; then
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --nginx") | crontab -
    log "自动续期已配置 (每天 3:00)"
fi

log "SSL 配置完成! https://${DOMAINS[0]}"
