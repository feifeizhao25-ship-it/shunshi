# SEASONS — 生产构建与部署指南
> 2026-03-20

---

## 构建产物现状

| 平台 | 当前状态 | 备注 |
|------|---------|------|
| Android APK | ✅ 54.3MB release | 开发证书，需正式签名 |
| iOS Simulator | ✅ Runner.app (debug) | 需 macOS + Apple 账号才能打生产包 |

---

## Android 生产构建

### 1. 生成正式签名密钥

```bash
# 在终端运行（只需一次）
cd ~/Documents/Shunshi/android-global/android/app

keytool -genkey \
  -v -keystore seasons-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -alias seasons \
  -dname "CN=SEASONS, OU=SEASONS, O=SEASONS, L=San Francisco, ST=CA, C=US"
```

### 2. 配置 `android/app/build.gradle` (release)

```groovy
android {
    ...
    signingConfigs {
        release {
            storeFile file("seasons-release.jks")
            storePassword "YOUR_STORE_PASSWORD"
            keyAlias "seasons"
            keyPassword "YOUR_KEY_PASSWORD"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3. 构建生产 APK

```bash
cd ~/Documents/Shunshi/android-global

flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### 4. 验证签名

```bash
keytool -list -v -keystore android/app/seasons-release.jks
```

---

## iOS 生产构建（需 macOS）

### 环境要求
- macOS (Xcode)
- Apple Developer Account ($99/year)
- Bundle ID: `com.seasons.seasons`
- App Store Connect 中的应用记录

### 步骤

#### 1. 配置 App ID 和 Provisioning Profile
在 Apple Developer Console:
- 创建 App ID: `com.seasons.seasons`
- 启用 Push Notifications, Sign in with Apple
- 创建 Distribution Provisioning Profile (App Store)

#### 2. 配置 Xcode 项目
```bash
cd ios
open Runner.xcworkspace
```

在 Xcode 中:
- Signing & Capabilities → Team → 你的开发者账号
- Bundle Identifier: `com.seasons.seasons`
- Version: 1.0.0
- Build: 1

#### 3. 构建生产包

```bash
# 在 macOS 终端运行
cd ~/Documents/Shunshi/ios-global

flutter build ios --release --no-codesign

# 或使用 xcodebuild（带签名）
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

#### 4. 上传到 App Store Connect

```bash
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

或在 Xcode Organizer 中手动选择 Archive → Distribute

---

## 后端生产部署 (AWS)

### 环境要求
- AWS Account
- RDS PostgreSQL 14+
- ElastiCache Redis 7+
- ECS Fargate (或 EC2)
- S3 (静态资源)
- CloudFront (CDN)
- ACM (SSL 证书)
- Route 53 (DNS)

### Docker 配置

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/"]
      interval: 30s
      timeout: 10s
      retries: 3

  celery:
    build: .
    command: celery -A app.celery_app worker --loglevel=info
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    restart: always
```

### 环境变量 (.env.production)

```bash
# 数据库
DATABASE_URL=postgresql://user:pass@rds.amazonaws.com:5432/seasons
REDIS_URL=rediss://elasticache.amazonaws.com:6379/0

# AI API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_live_...

# AWS
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-west-2
S3_BUCKET=seasons-static

# App
ENVIRONMENT=production
LOG_LEVEL=INFO
CORS_ORIGINS=https://seasons.app,https://www.seasons.app
```

### 数据库迁移

```bash
# 运行迁移
alembic upgrade head

# 种子数据
python -m app.scripts.seed_seasons_data
```

### Nginx 配置

```nginx
server {
    listen 443 ssl http2;
    server_name api.seasons.app;

    ssl_certificate /etc/ssl/seasons.pem;
    ssl_certificate_key /etc/ssl/seasons.key;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## App Store 配置

### App Store Connect

1. **基本信息**
   - Name: SEASONS
   - Bundle ID: com.seasons.seasons
   - Category: Health & Fitness / Lifestyle
   - Content Rating: 4+ (all ages)

2. **隐私政策 URL** (必需)
   - https://seasons.app/privacy

3. **支持 URL**
   - https://seasons.app/support

4. **App 描述** (英文)

```
SEASONS — Your AI Calm Lifestyle Companion

Live in rhythm with nature. SEASONS is a gentle AI companion 
designed to help you slow down, breathe, and find calm in 
your everyday life.

FEATURES:
• Daily personalized insights
• Breathing exercises & audio guides
• Evening wind-down rituals
• Self-reflection journaling
• Seasonal living guidance

Download SEASONS today and discover a gentler way to live.
```

5. **关键词** (100字符)
```
calm,meditation,breathing,relaxation,sleep,wellness,mindfulness,gentle,self-care,daily
```

6. **截图要求**
   - iPhone 6.5" (1284×2778): 3张
   - iPhone 5.5" (1242×2208): 3张
   - iPad Pro 12.9" (2048×2732): 3张

---

## Google Play 配置

### Play Console

1. **应用签名**
   - 使用 Google 生成的签名密钥
   - 或上传自己的密钥

2. **商店列表**
   - 简短描述 (80字符)
   - 完整描述 (4000字符)
   - 截图 (手机 + 平板)

3. **内容分级**
   - 问卷: 所有年龄 / 无暴力 / 无毒品

---

## 第三方服务配置

### AI Providers

**OpenAI**
- Platform: https://platform.openai.com
- API Key: sk-...
- Model: gpt-4o

**Anthropic**
- Platform: https://console.anthropic.com
- API Key: sk-ant-...
- Model: claude-sonnet-4-6

### Stripe

1. 创建产品 (Serenity/Harmony/Family)
2. 配置 Webhook: `https://api.seasons.app/api/v1/webhooks/stripe`
3. 添加支付方式: Visa, Mastercard, Amex

### 推送通知

**iOS (APNs)**
- APNs Auth Key (p8): Apple Push Notifications service
- Key ID + Team ID

**Android (FCM)**
- google-services.json
- FCM Server Key

---

## 监控与告警

### CloudWatch 告警
- API 错误率 > 1%
- p95 延迟 > 2s
- Redis 连接失败
- 数据库 CPU > 80%

### 日志
- CloudWatch Logs
- 结构化 JSON 日志
- 保留 30 天

---

## 部署检查清单

### 前置
- [ ] Apple Developer Account 激活
- [ ] Stripe 账户验证
- [ ] OpenAI/Anthropic API 额度充足
- [ ] 域名 DNS 配置
- [ ] SSL 证书申请

### 构建
- [ ] Android keystore 生成并备份
- [ ] Android release APK 签名成功
- [ ] iOS archive 构建成功 (macOS)
- [ ] 后端 Docker 镜像构建成功

### 部署
- [ ] RDS 数据库创建
- [ ] ElastiCache Redis 创建
- [ ] S3 bucket 配置
- [ ] ECS 任务定义创建
- [ ] ECS Service 部署
- [ ] ALB 目标组健康检查通过
- [ ] 域名 SSL 证书生效
- [ ] Stripe Webhook 验证

### 验证
- [ ] 健康检查: `GET /`
- [ ] API 测试: `/api/v1/seasons/home/dashboard`
- [ ] AI Chat 测试: `/ai/chat`
- [ ] Stripe 支付测试 (test mode)
- [ ] 推送通知测试

### 上线
- [ ] App Store 提交审核
- [ ] Google Play 提交审核
- [ ] 监控仪表盘配置
- [ ] 告警规则配置
- [ ] Rollback 方案测试
