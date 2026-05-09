# 顺时 Web 部署指南

## 构建

```bash
cd ios-cn
flutter build web --release
```

产物位于 `build/web/` 目录。

---

## 部署方式

### 方式一：Firebase Hosting（推荐国内）

#### 1. 安装 Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

#### 2. 初始化项目

```bash
cd ios-cn
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
| Build command | `cd ios-cn && flutter build web --release` |
| Build output directory | `ios-cn/build/web` |

#### 3. 自定义域名

在 Pages → Custom Domains 中添加你的域名（如 `app.shunshi.com`）。

---

### 方式三：Nginx 静态托管

```nginx
server {
    listen 80;
    server_name app.shunshi.com;
    root /var/www/shunshi/build/web;
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
# 上传构建产物
rsync -avz --delete build/web/ user@app.shunshi.com:/var/www/shunshi/build/web/

# 重载 Nginx
sudo nginx -s reload
```

---

## SEO 优化

### 当前配置（index.html）

已包含以下 SEO meta tags：

- `description`: "顺时 ShunShi - AI 养生陪伴系统，随时随地守护您的健康"
- `keywords`: 中医,养生,AI健康,健康陪伴,二十四节气,顺时养生
- Open Graph tags（og:title, og:description, og:type, og:locale）
- 主题色：`#8B5A2B`（暖棕色，体现中医养生氛围）

### 建议补充

在 `<head>` 中添加：

```html
<!-- 百度站长验证 -->
<meta name="baidu-site-verification" content="{YOUR_CODE}">

<!-- Google Search Console -->
<meta name="google-site-verification" content="{YOUR_CODE}">

<!--  canonical URL -->
<link rel="canonical" href="https://app.shunshi.com/">
```

---

## PWA 配置

当前 `manifest.json` 已配置：

- 应用名：顺时 ShunShi
- 启动 URL：`.`（根路径）
- 显示模式：`standalone`
- 主题色：`#8B5A2B`
- 背景色：`#FAF0E6`（米色）
- 图标：192x192 和 512x512 PNG

### 更新图标

替换 `web/icons/` 目录下的图标文件，保持文件名一致。

---

## 注意事项

### Web 平台限制

以下功能在 Web 上不可用或行为不同：

- **应用内购买**（IAP）- Web 端返回 `false`
- **语音输入**（speech_to_text）- 需用户授权麦克风权限
- **本地通知** - 使用 Web Notification API 替代
- **文件上传**（image_picker）- 使用 Web File API
- **蓝牙设备**（connectivity_plus）- 部分 API 不可用

### 已知警告

```
package:flutter_secure_storage_web - dart:html 不兼容 Wasm
```

这是预期行为，`flutter_secure_storage` 在 Web 上使用 JS 降级方案，不影响功能。

---

## 自动化部署（CI/CD）

### GitHub Actions 示例

```yaml
name: Deploy Web (CN)

on:
  push:
    branches: [main]
    paths: ['ios-cn/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - run: cd ios-cn && flutter pub get
      - run: cd ios-cn && flutter build web --release

      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_SHUNSHI_CN }}
          projectId: shunshi-cn
```

---

## 预览

本地预览：

```bash
cd ios-cn/build/web
python3 -m http.server 8080
# 访问 http://localhost:8080
```

或使用 Flutter 内置服务器：

```bash
cd ios-cn
flutter run -d chrome
```
