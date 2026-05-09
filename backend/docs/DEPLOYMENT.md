# SEASONS Backend - ECS Deployment Guide

> **Last updated:** 2026-03-24

---

## 🏗️ Architecture Overview

```
                    ┌─────────────────────────────────────────┐
                    │           Alibaba Cloud ECS              │
                    │           116.62.32.43                   │
  Internet ───────► │                                         │
                    │  Nginx (port 80/443)                   │
                    │  ├── /api/v1/seasons/*  ───► :4000     │
                    │  │   (SEASONS API)                     │
                    │  └── /api/v1/*            ───► :4001   │
                    │      (Energy API)                      │
                    │                                         │
                    │  Python/uvicorn                         │
                    │  ├── :4000  Shunshi SEASONS backend    │
                    │  └── :4001  Energy backend             │
                    │                                         │
                    │  PostgreSQL :5432                       │
                    │  Redis       :6379                      │
                    │  OpenClaw   :18789                      │
                    └─────────────────────────────────────────┘
```

---

## 🔑 Server Access

```bash
# SSH to ECS
ssh -i ~/.ssh/openclaw_key root@116.62.32.43

# SCP file transfer
scp -i ~/.ssh/openclaw_key ./local-file.txt root@116.62.32.43:/opt/shunshi/
```

---

## 📁 Directory Structure on ECS

```
/opt/shunshi/
├── backend/                 # SEASONS Python backend
│   ├── app/                 # Main application code
│   │   ├── main.py          # FastAPI entry point
│   │   ├── router/          # API route handlers
│   │   │   ├── seasons_api.py
│   │   │   ├── seasons_chat.py
│   │   │   ├── seasons_home.py
│   │   │   ├── seasons_audio.py
│   │   │   ├── seasons_subscription.py
│   │   │   ├── seasons_family.py
│   │   │   └── ...
│   │   ├── database/        # DB models and seed data
│   │   ├── llm/             # LLM integrations (SiliconFlow)
│   │   ├── rag/             # RAG knowledge base
│   │   └── ...
│   ├── .venv/               # Python virtual environment
│   ├── requirements.txt
│   └── logs/                # (if created)
├── energy/                  # Energy API backend (port 4001)
│   └── ...
└── certbot-dns-auth.sh      # SSL certbot DNS auth script
```

---

## 🚀 Service Management

```bash
# Check service status
systemctl status shunshi

# View live logs
journalctl -u shunshi -f

# View recent logs
journalctl -u shunshi --no-pager -n 50

# Restart service
systemctl restart shunshi

# Reload service
systemctl reload shunshi

# View nginx status
systemctl status nginx

# View all listening ports
ss -tlnp | grep -E '4000|4001|6379|80|443|5432'
```

---

## 🔄 Deployment Workflow

### Option 1: Using deploy.sh (Recommended)

```bash
cd /Users/feifei00/Documents/Shunshi

# Full deploy (syncs code, installs deps, restarts)
./deploy.sh

# Check status only
./deploy.sh --check

# Follow logs
./deploy.sh --logs
```

### Option 2: Manual Deploy

```bash
# 1. Sync code from local to ECS
rsync -az -e "ssh -i ~/.ssh/openclaw_key" \
  --exclude '__pycache__' --exclude '*.pyc' \
  --exclude '.venv' --exclude 'node_modules' \
  /Users/feifei00/Documents/Shunshi/backend/ \
  root@116.62.32.43:/opt/shunshi/backend/

# 2. SSH and install deps
ssh -i ~/.ssh/openclaw_key root@116.62.32.43
cd /opt/shunshi/backend
.venv/bin/pip install -r requirements.txt --upgrade

# 3. Restart
systemctl restart shunshi
```

---

## 🌐 API Access Points

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| SEASONS API (via Nginx) | `http://116.62.32.43/api/v1/seasons/` | 4000 | Main SEASONS backend |
| Energy API (via Nginx) | `http://116.62.32.43/api/v1/` | 4001 | Energy/wisdom API |
| SEASONS (direct) | `http://116.62.32.43:4000/` | 4000 | Direct (no nginx) |
| Energy (direct) | `http://116.62.32.43:4001/` | 4001 | Direct (no nginx) |
| Health Check | `http://116.62.32.43/api/v1/seasons/season/current` | - | Returns current season |

---

## 🔒 SSL / HTTPS Setup

### Current Status: ❌ Not configured (cert not obtained)

The SSL certbot scripts exist at `/opt/shunshi/` but have **not** successfully obtained a certificate yet.

### Prerequisites
1. **DNS must be active** — `shunshiapp.com` was previously on `clientHold`. Verify it's unblocked:
   ```bash
   dig shunshiapp.com +short
   # Should return: 116.62.32.43
   ```

2. **Aliyun DNS credentials** — Required for DNS-01 challenge:
   ```bash
   cat /etc/letsencrypt/dns-aliyun-credentials.ini
   ```

### Steps to Enable HTTPS

```bash
# 1. Verify DNS is pointing to ECS
dig shunshiapp.com +short
# Expected: 116.62.32.43

# 2. Run SSL certbot script
ssh -i ~/.ssh/openclaw_key root@116.62.32.43
/opt/shunshi/get-ssl.sh

# 3. If successful, deploy HTTPS nginx config
# Edit /etc/nginx/conf.d/shunshi.conf and uncomment HTTPS server blocks

# 4. Reload nginx
nginx -s reload
```

### Manual Certbot (DNS-01 Challenge via Aliyun)

```bash
certbot certonly -a dns-aliyun \
  --dns-aliyun-credentials /etc/letsencrypt/dns-aliyun-credentials.ini \
  --dns-aliyun-propagation-seconds 120 \
  -d shunshiapp.com \
  -d www.shunshiapp.com \
  -d seasons.shunshiapp.com \
  -d api.shunshiapp.com \
  --email admin@shunshiapp.com --agree-tos --no-eff-email \
  --non-interactive
```

---

## 🗄️ Database

**PostgreSQL 16** is running and used for the SEASONS backend.

```bash
# Connect to PostgreSQL
sudo -u postgres psql -d shunshi

# List tables
\dt

# Check record counts
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM articles;

# Check extensions
SELECT * FROM pg_extension;
```

### Key Tables
- `users` — User accounts (0 rows — needs seeding)
- `articles` — SEASONS content (4 rows)
- `acupoints`, `recipes`, `beverages`, `movement_practices` — Wellness content
- `body_types`, `body_type_questions`, `body_type_test_records` — Constitution system
- `chat_sessions`, `chat_messages` — Chat history
- `family_members` — Family sharing

### Database Backup
```bash
# Manual pg_dump
sudo -u postgres pg_dump shunshi > /tmp/shunshi-backup-$(date +%Y%m%d).sql

# Restore
sudo -u postgres psql shunshi < /tmp/shunshi-backup-YYYYMMDD.sql
```

---

## 🔴 Redis

```bash
# Check Redis
redis-cli ping
# Expected: PONG

# Monitor Redis
redis-cli monitor

# Check memory usage
redis-cli info memory
```

---

## 📱 Flutter App Build & Deploy

```bash
cd /Users/feifei00/Documents/Shunshi

# Build all 4 variants
./build-all-apps.sh

# Build specific variant
./build-all-apps.sh ios-cn
./build-all-apps.sh android-cn
./build-all-apps.sh ios-global
./build-all-apps.sh android-global

# Build CN variants only
./build-all-apps.sh cn

# Build outputs go to ./build-output/
ls -lh ./build-output/
```

### API Endpoints by App

| App Variant | API Base URL |
|-------------|--------------|
| ios-cn / android-cn | `http://116.62.32.43/api/v1` |
| ios-global / android-global | `https://api.seasonsapp.com/api/v1` |

---

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check logs
journalctl -u shunshi --no-pager -n 50

# Common issues:
# - Port 4000 already in use: kill $(lsof -ti:4000)
# - Missing env vars: check .env or systemd service
# - DB connection failed: check PostgreSQL is running
```

### Nginx 502 Bad Gateway
```bash
# Check backend is listening
curl http://127.0.0.1:4000/health
curl http://127.0.0.1:4001/

# Check nginx error logs
tail /var/log/nginx/error.log
```

### Database migration issues
```bash
# Check DB connectivity
ssh -i ~/.ssh/openclaw_key root@116.62.32.43
cd /opt/shunshi/backend
.venv/bin/python -c "
from app.database.db import engine
from sqlalchemy import text
with engine.connect() as conn:
    print('OK:', conn.execute(text('SELECT 1')).scalar())
"
```

---

## 📊 Health Monitoring

```bash
# Quick health check
./deploy.sh --check

# Manual checks
curl http://127.0.0.1:4000/health
curl http://127.0.0.1:4000/api/v1/seasons/season/current
curl http://127.0.0.1:4001/api/v1/  # Energy API
redis-cli ping
sudo -u postgres psql -d shunshi -c "SELECT 1"
```
