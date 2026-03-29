# DEPLOYMENT.md - 顺时中国版 部署文档

## 部署阶段

| 阶段 | 用户规模 | 架构 | 预估成本 |
|------|----------|------|---------|
| Dev | < 1,000 | 单机 Docker | ¥1,000/月 |
| Staging | < 10,000 | Docker Compose | ¥3,000/月 |
| Prod 1 | < 100,000 | K8s 2-4 节点 | ¥10,000/月 |
| Prod 2 | < 1,000,000 | K8s 10+ 节点 | ¥50,000/月 |
| Prod 3 | < 10,000,000 | 多地域 + CDN | ¥200,000/月 |

---

## 开发环境（单机 Docker）

### 1. 启动后端

```bash
cd backend
docker build -t shunshi-api:latest .
docker run -d \
  --name shunshi-api \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://postgres:password@host.docker.internal:5432/shunshi \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  -e ENV=development \
  shunshi-api:latest
```

### 2. 启动 Flutter App（开发模式）

```bash
cd ios-cn
flutter run
# 或
flutter run -d <device_id>
```

---

## 阿里云 ECS 部署（Staging）

### 服务器规格

| 项目 | 推荐配置 |
|------|---------|
| 实例类型 | ECS u1 (2核4G) |
| 操作系统 | Ubuntu 22.04 LTS |
| 数据盘 | 40GB SSD |
| 带宽 | 5Mbps 按量付费 |

### 1. 服务器初始化

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装 Nginx
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 2. 克隆代码

```bash
git clone https://github.com/shunshi/backend.git /opt/shunshi/backend
git clone https://github.com/shunshi/app.git /opt/shunshi/app

cd /opt/shunshi/backend
```

### 3. 配置环境变量

```bash
# .env.production
ENV=staging
DATABASE_URL=postgresql://shunshi:YourSecurePassword@localhost:5432/shunshi
REDIS_URL=redis://localhost:6379
JWT_SECRET=YourJWTSecretKey123456
ALIYUN_SMS_ACCESS_KEY=YourAccessKey
ALIYUN_SMS_ACCESS_SECRET=YourAccessSecret
ALIYUN_OSS_ENDPOINT=oss-cn-shanghai.aliyuncs.com
```

### 4. Docker Compose 配置

```yaml
# docker-compose.staging.yml
version: '3.8'

services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - ENV=staging
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - db
      - redis
    restart: always

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      POSTGRES_DB: shunshi
      POSTGRES_USER: shunshi
      POSTGRES_PASSWORD: YourSecurePassword
    restart: always

  redis:
    image: redis:7
    volumes:
      - redis_data:/data
    restart: always

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/certs:/etc/nginx/certs
    depends_on:
      - api
    restart: always

volumes:
  postgres_data:
  redis_data:
```

### 5. 启动服务

```bash
docker-compose -f docker-compose.staging.yml up -d

# 查看日志
docker-compose -f docker-compose.staging.yml logs -f api

# 重启
docker-compose -f docker-compose.staging.yml restart api
```

### 6. Nginx 配置

```nginx
# /etc/nginx/sites-available/shunshi-api
server {
    listen 80;
    server_name api.shunshi.app;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

### 7. SSL 证书

```bash
sudo certbot --nginx -d api.shunshi.app
# 自动续期配置在 /etc/cron.d/certbot
```

---

## 数据库初始化

```sql
-- init.sql
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    nickname VARCHAR(100),
    life_stage VARCHAR(50),
    feeling VARCHAR(50),
    style_preference VARCHAR(50),
    hemisphere VARCHAR(10) DEFAULT 'north',
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id),
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wellness_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    mood VARCHAR(50),
    energy VARCHAR(50),
    sleep_quality VARCHAR(50),
    notes TEXT,
    recorded_at DATE DEFAULT CURRENT_DATE
);
```

---

## iOS 发布（App Store）

### 1. 证书配置

在 Apple Developer Console 创建：
- App IDs（com.shunshi.shunshi）
- Distribution Certificate
- Provisioning Profile（App Store Connect）

### 2. 打包

```bash
cd ios-cn/ios
flutter build ipa --release \
  --export-options-plist=ExportOptions.plist
```

### 3. 上传 App Store Connect

使用 Transporter 或 Xcode 直接上传。

---

## Android 发布（应用宝/华为/小米）

### 1. Keystore 配置

在 `android/app/build.gradle` 配置签名：

```groovy
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 2. 构建 APK

```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### 3. 国内应用市场

| 市场 | 上传方式 | 备注 |
|------|---------|------|
| 腾讯应用宝 | Developer Console | 需要软件著作权 |
| 华为应用市场 | AppGallery Connect | 企业开发者 |
| 小米应用商店 | Developer Console | 个人也可 |
| OPPO/vivo | Developer Console | 企业优先 |

---

## 监控与日志

### 日志收集

```yaml
# docker-compose 中添加 Filebeat
filebeat:
  image: elastic/filebeat:8.10.0
  volumes:
    - ./logs:/var/log/shunshi
    - ./filebeat.yml:/usr/share/filebeat/filebeat.yml
  depends_on:
    - api
```

### 健康检查

```bash
# API 健康检查
curl https://api.shunshi.app/health

# 预期响应
{"status": "healthy", "version": "1.0.0", "db": "connected", "redis": "connected"}
```

### 报警规则（推荐）

| 条件 | 动作 |
|------|------|
| API 响应时间 > 5s | 发送钉钉/企业微信通知 |
| 错误率 > 5% | 发送报警 |
| DB 连接失败 | 立即报警 |
| 订阅服务异常 | 立即报警 |
