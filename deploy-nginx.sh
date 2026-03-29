#!/bin/bash
# =============================================================================
# Deploy Nginx Configuration to ECS
# Usage: ./deploy-nginx.sh [--dry-run]
# =============================================================================

set -e

SSH_KEY="~/.ssh/openclaw_key"
ECS_HOST="116.62.32.43"
ECS_USER="root"
LOCAL_DIR="/Users/feifei00/Documents/Shunshi"

# Nginx config template for SEASONS + Energy backends
NGINX_CONF="server {
    listen 80;
    server_name shunshiapp.com www.shunshiapp.com seasons.shunshiapp.com api.shunshiapp.com;

    # Certbot ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # SEASONS backend (port 4000)
    location ~ ^/api/v1/seasons/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 120s;
    }

    # Energy backend (port 4001) - catches auth, users, projects, etc.
    location ~ ^/api/v1/(auth|users|projects|resource|finance|ai|operations|dashboard|alerts|research|energy) {
        proxy_pass http://127.0.0.1:4001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 120s;
    }

    # Default: redirect to SEASONS web frontend (port 4000)
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# HTTPS server (activated after SSL cert is obtained)
# Uncomment after running: ./get-ssl.sh
# server {
#     listen 443 ssl http2;
#     server_name shunshiapp.com www.shunshiapp.com seasons.shunshiapp.com api.shunshiapp.com;
#
#     ssl_certificate /etc/letsencrypt/live/shunshiapp.com/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/shunshiapp.com/privkey.pem;
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers HIGH:!aNULL:!MD5;
#     ssl_prefer_server_ciphers on;
#     ssl_session_cache shared:SSL:10m;
#     ssl_session_timeout 10m;
#
#     # SEASONS backend
#     location ~ ^/api/v1/seasons/ {
#         proxy_pass http://127.0.0.1:4000;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto https;
#         proxy_http_version 1.1;
#     }
#
#     # Energy backend
#     location ~ ^/api/v1/(auth|users|projects|resource|finance|ai|operations|dashboard|alerts|research|energy) {
#         proxy_pass http://127.0.0.1:4001;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto https;
#         proxy_http_version 1.1;
#     }
#
#     location / {
#         proxy_pass http://127.0.0.1:4000;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto https;
#         proxy_http_version 1.1;
#     }
# }
#
# # HTTP → HTTPS redirect
# server {
#     listen 80;
#     server_name shunshiapp.com www.shunshiapp.com seasons.shunshiapp.com api.shunshiapp.com;
#     return 301 https://\$host\$request_uri;
# }
"

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "[DRY RUN] Would write the following config to ECS:"
    echo "$NGINX_CONF"
    exit 0
fi

SSH_CMD="ssh -i $SSH_KEY -o StrictHostKeyChecking=no $ECS_USER@$ECS_HOST"

echo "Deploying Nginx configuration to ECS ($ECS_HOST)..."

# Backup current config
$SSH_CMD "cp /etc/nginx/conf.d/shunshi.conf /etc/nginx/conf.d/shunshi.conf.bak.$(date +%Y%m%d-%H%M%S)"

# Write new config via heredoc
$SSH_CMD "cat > /etc/nginx/conf.d/shunshi.conf << 'NGINX_EOF'
$NGINX_CONF
NGINX_EOF"

# Test nginx config
$SSH_CMD "nginx -t 2>&1"

# Reload nginx
$SSH_CMD "nginx -s reload"

echo "Nginx config deployed and reloaded."
echo ""
echo "To enable HTTPS:"
echo "  1. Ensure shunshiapp.com DNS is not on clientHold"
echo "  2. Run: ssh -i ~/.ssh/openclaw_key root@116.62.32.43 '/opt/shunshi/get-ssl.sh'"
echo "  3. Uncomment the HTTPS server block in the config"
