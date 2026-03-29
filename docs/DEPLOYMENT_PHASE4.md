# Phase 4 Deployment Guide - Alibaba Cloud (阿里云部署)

> **Status:** Pending Cloud Resources (等待云资源)
> **Date:** 2026-03-20
> **Project:** 顺时 (Shunshi) 国内版

---

## 1. 环境要求 / Environment Requirements

### 1.1 ECS 服务器
| Item | Spec |
|------|------|
| OS | Ubuntu 22.04 LTS (推荐) / Alibaba Cloud Linux 3 |
| CPU | 2 vCPU (最低) / 4 vCPU (推荐) |
| Memory | 4 GB RAM (最低) / 8 GB RAM (推荐) |
| Disk | 40 GB SSD (最低) / 80 GB SSD (推荐) |
| Bandwidth | 5 Mbps (最低) / 10 Mbps (推荐) |
| Region | 推荐: 华北2 (北京) / 华东1 (杭州) |

### 1.2 RDS MySQL
| Item | Spec |
|------|------|
| Version | MySQL 8.0 |
| Instance Type | mysql.n2.medium.2 (最低) |
| Storage | 20 GB 起 |
| Multi-AZ | 推荐开启 |
| Character Set | utf8mb4 |
| collation_server | utf8mb4_unicode_ci |

### 1.3 Redis
| Item | Spec |
|------|------|
| Version | Redis 7.0 |
| Instance Type | redis.master.small.default (最低) |
| Memory | 1 GB (最低) / 2 GB (推荐) |
| Max Connections | 10000 |
| Persistence | 推荐开启 AOF |

### 1.4 OSS (Object Storage)
| Item | Spec |
|------|------|
| Bucket Region | 同 ECS Region |
| ACL | Private |
| Storage Class | Standard |
| CDN | 推荐开启 |

---

## 2. Docker 部署配置 / Docker Deployment

### 2.1 Dockerfile (Backend)

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backend/requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY backend/ .

EXPOSE 4000

ENV PYTHONUNBUFFERED=1
ENV PORT=4000

CMD ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4000"]
```

### 2.2 docker-compose.yml

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: shunshi-backend
    restart: unless-stopped
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - OSS_ACCESS_KEY_ID=${OSS_ACCESS_KEY_ID}
      - OSS_ACCESS_KEY_SECRET=${OSS_ACCESS_KEY_SECRET}
      - OSS_BUCKET=${OSS_BUCKET}
      - OSS_ENDPOINT=${OSS_ENDPOINT}
      - JWT_SECRET=${JWT_SECRET}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./backend:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  default:
    name: shunshi-network
```

---

## 3. 环境变量清单 / Environment Variables

### 3.1 .env.production

```bash
# ========================
# Shunshi Backend - Production Environment
# ========================

# Server
PORT=4000
HOST=0.0.0.0
DEBUG=false

# ========================
# Database
# ========================
DATABASE_URL=mysql+pymysql://user:password@rm-xxx.mysql.rds.aliyuncs.com:3306/shunshi_db

# ========================
# Redis
# ========================
REDIS_URL=redis://r-xxx.redis.rds.aliyuncs.com:6379/0

# ========================
# Alibaba Cloud OSS
# ========================
OSS_ACCESS_KEY_ID=your_access_key_id
OSS_ACCESS_KEY_SECRET=your_access_key_secret
OSS_BUCKET=shunshi-production
OSS_ENDPOINT=oss-cn-beijing.aliyuncs.com

# ========================
# Security
# ========================
JWT_SECRET=your_super_secret_jwt_key_min_32_chars
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=720

# ========================
# External APIs
# ========================
OPENAI_API_KEY=sk-your-openai-api-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini

# ========================
# Application
# ========================
APP_NAME=Shunshi
APP_VERSION=1.0.0
FRONTEND_URL=https://app.shunshi.com
CORS_ORIGINS=https://app.shunshi.com,https://www.shunshi.com
```

---

## 4. 数据库迁移步骤 / Database Migration

### 4.1 迁移前准备

```bash
# 1. 登录 RDS 管理控制台，创建数据库和用户
# 数据库名: shunshi_db
# 用户名: shunshi_user

# 2. 在 ECS 上安装 MySQL 客户端
apt-get install -y mysql-client
```

### 4.2 迁移执行

```bash
# 1. 导出本地数据 (开发环境)
cd ~/Documents/Shunshi/backend
pg_dump -h localhost -U shunshi_user shunshi_db > migration.sql

# 2. 转换为 MySQL 格式 (如使用 SQLAlchemy 可直接迁移)
# 编辑 models/ 目录下的 model 文件，确保使用 MySQL dialect

# 3. 执行迁移
mysql -h rm-xxx.mysql.rds.aliyuncs.com -u shunshi_user -p shunshi_db < migration.sql

# 4. 验证
mysql -h rm-xxx.mysql.rds.aliyuncs.com -u shunshi_user -p -e "SHOW TABLES;" shunshi_db
```

### 4.3 后端初始化

```bash
# SSH 到 ECS
ssh root@your-ecs-ip

# Clone 或上传代码
git clone https://your-repo/shunshi.git
cd shunshi/backend

# 安装依赖
pip3 install -r requirements.txt

# 初始化数据库表
python3 -c "from database import engine, Base; Base.metadata.create_all(engine)"

# 导入种子数据 (如需要)
python3 scripts/seed_data.py
```

---

## 5. HTTPS / 域名配置 / Domain & SSL

### 5.1 域名配置

```bash
# 1. 在阿里云域名控制台添加 DNS 记录
# 类型: A
# 主机记录: @, www, api
# 记录值: your-ecs-public-ip

# 2. 等待 DNS 生效 (通常 10-30 分钟)
dig api.shunshi.com
```

### 5.2 SSL 证书 (Let's Encrypt / 阿里云免费证书)

```bash
# 使用 Certbot 获取 Let's Encrypt 证书
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d api.shunshi.com

# 或使用阿里云免费证书，在控制台上传
```

### 5.3 Nginx 反向代理配置

```nginx
# /etc/nginx/sites-available/shunshi-backend

upstream shunshi_backend {
    server 127.0.0.1:4000;
    keepalive 32;
}

server {
    listen 80;
    server_name api.shunshi.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.shunshi.com;

    ssl_certificate /etc/letsencrypt/live/api.shunshi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.shunshi.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    client_max_body_size 20M;

    location / {
        proxy_pass http://shunshi_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        proxy_pass http://shunshi_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

```bash
# 启用配置
ln -s /etc/nginx/sites-available/shunshi-backend /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

---

## 6. 部署检查清单 / Deployment Checklist

### 6.1 部署前检查 (Pre-Deployment)

- [ ] ECS 实例已创建并运行
- [ ] RDS MySQL 已创建，数据库和用户已配置
- [ ] Redis 已创建并可访问
- [ ] OSS Bucket 已创建
- [ ] 域名已注册，DNS 记录已配置
- [ ] SSL 证书已申请
- [ ] 代码已推送到 Git 仓库
- [ ] `.env.production` 已准备好
- [ ] 手机号/短信服务已开通 (阿里云短信)

### 6.2 部署执行 (Deployment)

- [ ] ECS 登录成功
- [ ] Docker & Docker Compose 已安装
- [ ] 代码已 Clone 到 ECS
- [ ] `.env.production` 已配置
- [ ] 数据库迁移已完成
- [ ] Docker 容器已构建并启动
- [ ] Nginx 已配置并启用
- [ ] SSL 证书已配置
- [ ] 防火墙端口已开放 (80, 443)

### 6.3 部署后验证 (Post-Deployment)

- [ ] API 健康检查: `curl https://api.shunshi.com/health`
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] OSS 上传/下载正常
- [ ] 登录/注册流程正常
- [ ] 核心 API 端点测试通过
- [ ] Android APK 可正常下载安装
- [ ] iOS 可正常打包

### 6.4 监控与运维 (Monitoring)

- [ ] 阿里云 CloudMonitor 已配置
- [ ] 日志已配置 (阿里云 SLS 或本地)
- [ ] 备份策略已配置 (数据库每日备份)
- [ ] 告警规则已配置 (CPU > 80%, 内存 > 85%, 磁盘 > 80%)
- [ ] 应急响应流程已制定

---

## 7. 快速部署脚本 / Quick Deploy Script

```bash
#!/bin/bash
# deploy.sh - 在 ECS 上运行

set -e

APP_DIR="/opt/shunshi"
BACKEND_DIR="$APP_DIR/backend"

echo "=== Shunshi Backend Deployment ==="

# Pull latest code
cd $APP_DIR
git pull origin main

# Stop existing containers
cd $BACKEND_DIR
docker-compose down

# Rebuild and start
docker-compose build --no-cache
docker-compose up -d

# Verify
sleep 5
curl -f http://localhost:4000/ || { echo "Health check failed!"; exit 1; }

echo "=== Deployment Complete ==="
```

---

## 8. 关键 API 端点 / Key API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | 健康检查 |
| `/api/v1/auth/send-code` | POST | 发送验证码 |
| `/api/v1/auth/login` | POST | 登录 |
| `/api/v1/constitutions` | GET | 体质列表 |
| `/api/v1/constitutions/{id}` | GET | 体质详情 |
| `/api/v1/solar-terms/enhanced/{name}` | GET | 节气详情 (增强) |
| `/api/v1/daily-wellness` | GET | 每日养生方案 |
| `/api/v1/lifecycle/profile` | GET | 生命周期档案 |
| `/api/v1/family/members` | GET | 家庭成员列表 |

---

## 9. 联系支持 / Support

- **技术负责人:** 开发团队
- **文档版本:** v1.0.0
- **最后更新:** 2026-03-20
