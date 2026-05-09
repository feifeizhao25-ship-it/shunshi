# SEASONS Web 部署指南

## 构建

```bash
cd ios-global
flutter build web --release
```

产物位于 `build/web/` 目录。

---

## 部署方式

### 方式一：Firebase Hosting（推荐）

#### 1. 安装 Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

#### 2. 初始化项目

```bash
cd ios-global
firebase init hosting
# 选择 "build/web" 作为公共目录
# 配置为单页应用 (Yes)
```

#### 3. 部署

```bash
firebase deploy --only hosting
```

#### 自定义域名

```bash
firebase hosting:channel:deploy preview
firebase hosting:disable {channel}
```

---

### 方式二：Cloudflare Pages

#### 1. 连接 GitHub

在 Cloudflare Dashboard → Pages → Create a project → 连接到 GitHub 仓库。

#### 2. 配置构建

| 设置项 | 值 |
|--------|-----|
| Production branch | `main` |
| Build command | `cd ios-global && flutter build web --release` |
| Build output directory | `ios-global/build/web` |

#### 3. 自定义域名

在 Pages → Custom Domains 中添加你的域名（如 `seasons.ai`）。

---

### 方式三：Vercel

```bash
npm i -g vercel
cd ios-global
vercel --prod
```

在 `vercel.json` 中配置：

```json
{
  "buildCommand": "cd ios-global && flutter build web --release",
  "outputDirectory": "ios-global/build/web",
  "framework": "flutter"
}
```

---

### 方式四：Nginx 静态托管

```nginx
server {
    listen 80;
    server_name seasons.app;
    root /var/www/seasons/build/web;
    index index.html;

    # SPA 支持 - 所有路由回落到 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 缓存静态资源
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

```bash
rsync -avz --delete build/web/ user@seasons.app:/var/www/seasons/build/web/
sudo nginx -s reload
```

---

## SEO 优化

### 当前配置（index.html）

已包含以下 SEO meta tags：

- `description`: "SEASONS - Your AI Calm Lifestyle Companion. Find peace, reflection, and mindful living."
- `keywords`: mindfulness, wellness, AI companion, calm, meditation, reflection, lifestyle
- Open Graph tags（og:title, og:description, og:type, og:locale）
- 主题色：`#1A1A2E`（深蓝色，体现宁静氛围）

### 建议补充

在 `<head>` 中添加：

```html
<!-- Google Search Console -->
<meta name="google-site-verification" content="{YOUR_CODE}">

<!-- canonical URL -->
<link rel="canonical" href="https://seasons.ai/">
```

---

## PWA 配置

当前 `manifest.json` 已配置：

- 应用名：SEASONS
- 启动 URL：`.`（根路径）
- 显示模式：`standalone`
- 主题色：`#0175C2`
- 背景色：`#0175C2`
- 图标：192x192 和 512x512 PNG

### 更新图标

替换 `web/icons/` 目录下的图标文件，保持文件名一致。建议使用深色系图标以匹配深蓝色主题。

---

## 注意事项

### Web 平台限制

以下功能在 Web 上不可用或行为不同：

- **应用内购买**（IAP）- Web 端返回 `false`
- **语音输入**（speech_to_text）- 需用户授权麦克风权限
- **Google Sign-In** - 需要配置 Web OAuth Client ID
- **Apple Sign-In** - Web 上需要配置 ASWebAuthenticationPresentationContext
- **In-App Purchase** - StoreService 在 Web 上不可用

### 已知警告

```
package:flutter_secure_storage_web - dart:html 不兼容 Wasm
```

这是预期行为，`flutter_secure_storage` 在 Web 上使用 JS 降级方案，不影响功能。

---

## 自动化部署（CI/CD）

### GitHub Actions 示例

```yaml
name: Deploy Web (Global)

on:
  push:
    branches: [main]
    paths: ['ios-global/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - run: cd ios-global && flutter pub get
      - run: cd ios-global && flutter build web --release

      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_SEASONS_GLOBAL }}
          projectId: seasons-global
```

---

## 预览

本地预览：

```bash
cd ios-global/build/web
python3 -m http.server 8080
# 访问 http://localhost:8080
```

或使用 Flutter 内置服务器：

```bash
cd ios-global
flutter run -d chrome
```

---

## Stripe 集成（Web）

国际版使用 Stripe Checkout 进行订阅支付。Stripe Checkout 是纯 Web 方案，无需 Native SDK。

确保在 `lib/core/config/` 中配置了正确的 Stripe publishable key（Web 用）。
