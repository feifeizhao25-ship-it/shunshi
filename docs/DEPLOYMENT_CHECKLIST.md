# 顺时 App 部署清单

> 最后更新: 2026-03-09

---

## 一、本地构建状态 ✅

### iOS
| 项目 | 状态 | 路径 |
|------|------|------|
| 模拟器构建 | ✅ 完成 | `build/ios/iphonesimulator/Runner.app` |
| App Name | ✅ 已修改 | "顺时" |
| Bundle ID | ✅ 已修改 | com.shunshi.app |

### Android
| 项目 | 状态 | 路径 |
|------|------|------|
| Debug APK | ✅ 完成 | `build/app/outputs/flutter-apk/app-debug.apk` (146MB) |
| App Name | ✅ 已修改 | "顺时" |
| Package Name | ✅ 已修改 | com.shunshi.app |

---

## 二、部署前检查清单

### 2.1 应用配置

| 项目 | 当前值 | 目标值 | 状态 |
|------|--------|--------|------|
| App Name | 顺时 | 顺时 | ✅ |
| Bundle ID | com.shunshi.app | com.shunshi.app | ✅ |
| Version | 1.0.0 | 1.0.0 | ✅ |
| Build Number | 1 | 1 | ✅ |

### 2.2 图标配置

| 项目 | 状态 |
|------|------|
| iOS 图标 | ⚠️ 需配置 |
| Android 图标 | ⚠️ 需配置 |
| 启动屏 | ⚠️ 需配置 |

### 2.3 权限配置

| 权限 | iOS | Android |
|------|-----|---------|
| 网络 | ✅ | ✅ |
| 存储 | ✅ | ⚠️ 需确认 |
| 通知 | ⚠️ 需配置 | ⚠️ 需配置 |

---

## 三、账号准备 (需要手动)

### 3.1 Apple Developer
- [ ] Apple Developer 账号 (年费 $99)
- [ ] Bundle ID 注册: `com.shunshi.app`
- [ ] App Store Connect 应用创建

### 3.2 Google Play
- [ ] Google Play 开发者账号 (一次性 $25)
- [ ] 应用包名: `com.shunshi.app`
- [ ] 应用商店配置

### 3.3 后端服务器
- [ ] 服务器 (阿里云/腾讯云/AWS)
- [ ] 域名 + HTTPS 证书
- [ ] 数据库 (MySQL/PostgreSQL)

---

## 四、本地可完成项

### 4.1 修改 App 名称
```bash
# iOS
open ios/Runner.xcworkspace
# 在 Runner -> General -> Display Name 改为 "顺时"

# Android
# 修改 android/app/src/main/AndroidManifest.xml
android:label="顺时"
```

### 4.2 修改 Bundle ID
```bash
# Flutter
flutter pub global activate rename
rename --bundleId com.shunshi.app
```

---

## 五、发布构建命令

### 5.1 iOS 发布 (需要 Mac + Xcode)
```bash
# 1. 更新版本
flutter build ios --release --build-name=1.0.0 --build-number=1

# 2. 用 Xcode 打开
open ios/Runner.xcworkspace

# 3. Xcode 中:
# - 选择 Generic iOS Device
# - Product -> Archive
# - Window -> Organizer -> 导出
```

### 5.2 Android 发布
```bash
# 1. 生成签名密钥
keytool -genkey -v -keystore ~/shunshi.keystore -alias shunshi -keyalg RSA -keysize 2048 -validity 10000

# 2. 配置签名
# android/app/build.gradle 添加签名配置

# 3. 构建 Release
flutter build apk --release

# 4. 构建 AAB (Play Store)
flutter build appbundle --release
```

---

## 六、后端部署

### 6.1 服务器要求
- 系统: Ubuntu 22.04 / CentOS 8
- 配置: 2核4G起步
- 数据库: MySQL 8.0+

### 6.2 部署步骤
```bash
# 1. 克隆后端
cd /var/www
git clone https://github.com/shunshi/backend.git
cd backend

# 2. 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 3. 安装依赖
pip install -r requirements.txt

# 4. 配置环境变量
cp .env.example .env
# 编辑 .env 填入 API 密钥

# 5. 启动服务
# 使用 systemd 或 docker
docker-compose up -d

# 6. Nginx 配置
sudo cp nginx.conf /etc/nginx/sites-available/shunshi
sudo ln -s /etc/nginx/sites-available/shunshi /etc/nginx/sites-enabled/
sudo nginx -t && sudo nginx -s reload
```

---

## 七、第三方服务

| 服务 | 用途 | 账号 |
|------|------|------|
| SiliconFlow | AI API | 需要申请 |
| Sentry | 崩溃监控 | 需要创建项目 |
| Firebase | 推送/分析 | 需要创建项目 |
| 短信服务 | 验证码 | 阿里云/腾讯云 |

---

## 八、手动操作指南

### 步骤 1: 修改 App 名称和 Bundle ID
1. 打开 Xcode: `open ios/Runner.xcworkspace`
2. Runner -> General
3. Display Name 改为 "顺时"
4. Bundle Identifier 改为 "com.shunshi.app"

### 步骤 2: 配置图标
1. 使用 App Icon Generator 生成图标
2. 替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
3. 替换 `android/app/src/main/res/mipmap-*/`

### 步骤 3: 申请 Apple Developer
1. 访问 https://developer.apple.com
2. 注册账号 ($99/年)
3. 创建 App ID: com.shunshi.app

### 步骤 4: 申请 Google Play
1. 访问 https://play.google.com/console
2. 创建开发者账号 ($25)
3. 创建应用

### 步骤 5: 部署后端
1. 购买服务器
2. 配置域名
3. 部署后端代码

---

## 九、完成后可提交的应用

| 平台 | 文件 | 提交方式 |
|------|------|----------|
| iOS TestFlight | Runner.app (Export) | Xcode / Transporter |
| iOS App Store | Runner.app (Archive) | Xcode / Transporter |
| Android Play | app-release.apk / .aab | Play Console |
| Android 第三方 | app-release.apk | 直接分发 |

---

## 十、紧急联系方式

- Apple Developer 支持: https://developer.apple.com/contact
- Google Play 支持: https://support.google.com/googleplay/android-developer
- Flutter 文档: https://flutter.dev/docs

---

*此文档包含部署所需的全部信息和手动操作步骤*
