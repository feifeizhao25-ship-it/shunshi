#!/bin/bash
for i in $(seq 1 60); do
  echo "[$i] Attempting SSL certificate..."
  certbot certonly --webroot -w /var/www/certbot \
    -d shunshiapp.com -d www.shunshiapp.com -d seasons.shunshiapp.com -d api.shunshiapp.com \
    --email admin@shunshiapp.com --agree-tos --no-eff-email \
    --non-interactive 2>&1 | tail -3
  
  if [ -f /etc/letsencrypt/live/shunshiapp.com/fullchain.pem ]; then
    echo "SUCCESS! Certificate obtained."
    
    # Update nginx to use SSL
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
    
    nginx -t && systemctl restart nginx
    echo "HTTPS configured!"
    break
  fi
  
  echo "DNS not ready, waiting 60s..."
  sleep 60
done
