#!/bin/bash
# ============================================================
# 顺时 — SSL 证书 + Nginx 一键配置
# 在 ECS 服务器上运行
# ============================================================

set -euo pipefail

DOMAIN="api.shunshiapp.com"
EMAIL="admin@shunshiapp.com"  # Let's Encrypt 通知邮箱

echo "==================== SSL 证书配置 ===================="

# Step 1: 安装 Nginx + Certbot
echo "[1/4] 安装 Nginx 和 Certbot..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq nginx certbot python3-certbot-nginx
elif command -v yum &>/dev/null; then
    yum install -y epel-release
    yum install -y nginx certbot python3-certbot-nginx
fi

# Step 2: 创建 Nginx 配置
echo "[2/4] 配置 Nginx..."
mkdir -p /var/www/certbot
mkdir -p /var/log/shunshi

# 临时 HTTP 配置（用于 certbot 验证）
cat > /etc/nginx/conf.d/shunshi-temp.conf << 'NGINX'
server {
    listen 80;
    server_name api.shunshiapp.com shunshiapp.com www.shunshiapp.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX

nginx -t && systemctl reload nginx

# Step 3: 获取 SSL 证书
echo "[3/4] 申请 SSL 证书..."
certbot certonly --webroot \
    -w /var/www/certbot \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive

# Step 4: 部署完整 Nginx 配置
echo "[4/4] 部署完整配置..."
rm -f /etc/nginx/conf.d/shunshi-temp.conf
cp /opt/shunshi/backend/nginx/shunshi.conf /etc/nginx/conf.d/shunshi.conf
nginx -t && systemctl reload nginx

# 设置自动续期
echo "0 0 * * 0 root certbot renew --quiet && systemctl reload nginx" > /etc/cron.d/certbot-renew

echo ""
echo "✅ SSL 配置完成！"
echo "   HTTPS: https://$DOMAIN"
echo "   证书路径: /etc/letsencrypt/live/$DOMAIN/"
echo "   自动续期: 每周日凌晨"
echo "======================================================"
