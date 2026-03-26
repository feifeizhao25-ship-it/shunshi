#!/bin/bash
echo "=== $(date): Attempting SSL ==="
certbot certonly -a dns-aliyun \
  --dns-aliyun-credentials /etc/letsencrypt/dns-aliyun-credentials.ini \
  --dns-aliyun-propagation-seconds 120 \
  -d shunshiapp.com \
  --email admin@shunshiapp.com --agree-tos --no-eff-email \
  --non-interactive 2>&1

if [ -f /etc/letsencrypt/live/shunshiapp.com/fullchain.pem ]; then
    echo "SSL CERTIFICATE OBTAINED!"
    cat > /etc/nginx/conf.d/shunshi.conf << 'NGINX'
server {
    listen 80;
    server_name shunshiapp.com www.shunshiapp.com seasons.shunshiapp.com api.shunshiapp.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name shunshiapp.com www.shunshiapp.com seasons.shunshiapp.com api.shunshiapp.com;
    ssl_certificate /etc/letsencrypt/live/shunshiapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shunshiapp.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
        proxy_send_timeout 120s;
    }
}
NGINX
    nginx -t && systemctl reload nginx
    echo "HTTPS ENABLED!"
    exit 0
else
    echo "Failed, retrying in 3 min"
fi
