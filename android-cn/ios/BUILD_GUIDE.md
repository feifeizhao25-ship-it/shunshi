# 顺时 iOS 构建指南

> 更新日期: 2026-03-12

---

## 当前配置

| 项目 | 值 |
|------|-----|
| Bundle ID | com.shunshi.app |
| Display Name | 顺时 |
| Min iOS Version | 12.0 |

---

## 构建前准备

### 1. Apple Developer 账号

需要以下之一：
- **个人账号** ($99/年) - 可发布 TestFlight
- **企业账号** ($299/年) - 可发布 TestFlight 和企业分发

### 2. 必要证书

```
1. 访问 https://developer.apple.com
2. 创建 App IDs
   - Identifier: com.shunshi.app
   - Capabilities: Push Notifications
3. 创建 Certificates
   - Apple Development (开发)
   - Apple Distribution (发布)
4. 创建 Provisioning Profiles
   - ShunShi Dev (开发)
   - ShunShi TestFlight (发布)
```

### 3. 本地配置

```bash
# 安装 Flutter (如果未安装)
brew install flutter

# 检查 Flutter 环境
flutter doctor

# 登录 Apple Developer
flutter doctor -v
# 按照提示执行: flutter ios --enable-bitcode
```

---

## 构建步骤

### 开发构建 (模拟器)

```bash
cd ~/Documents/shunshi-all/shunshi

# 获取依赖
flutter pub get

# 构建模拟器版本
flutter build ios --simulator --no-codesign
```

### TestFlight 构建

```bash
# 设置代码签名
# 方法1: 自动签名
flutter build ios --release

# 方法2: 手动签名
flutter build ios --release \
  --code-sign-identity="Apple Distribution" \
  --provisioning-profile="ShunShi TestFlight"
```

### 企业分发构建

```bash
flutter build ios --release \
  --code-sign-identity="Apple Distribution" \
  --provisioning-profile="ShunShi Enterprise" \
  --export-options-plist=export_options.plist
```

---

## 发布流程

### 1. TestFlight

```
1. 访问 App Store Connect (https://appstoreconnect.apple.com)
2. 创建新应用
3. 上传构建版本 (使用 Transporter 或 xcodebuild)
4. 添加测试员
5. 提交审核
```

### 2. App Store

```
1. 准备应用截图和描述
2. 填写应用信息
3. 提交审核
4. 等待审核 (1-3天)
5. 发布
```

---

## 常见问题

### Q1: 代码签名失败

**解决方案:**
```bash
# 清除签名
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# 重新安装
flutter pub get
cd ios && pod install
```

### Q2: Bundle ID 冲突

**解决方案:**
- 在 Apple Developer 修改 App ID
- 或者修改 Flutter 项目的 bundle identifier

### Q3: 权限被拒绝

**解决方案:**
- 在 Info.plist 添加必要的权限描述
- 在 Apple Developer 开启对应 Capabilities

---

## Info.plist 权限配置

```xml
<!-- 相机 -->
<key>NSCameraUsageDescription</key>
<string>需要相机来扫描二维码</string>

<!-- 照片库 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问照片库来保存图片</string>

<!-- 位置 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要位置信息来提供本地化养生建议</string>

<!-- 通知 -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 下一步

1. **配置 Apple Developer 账号**
2. **运行 flutter build ios --simulator 测试**
3. **上传 TestFlight**

---

## 相关文档

- [Flutter iOS 构建文档](https://docs.flutter.dev/deployment/ios)
- [App Store Connect 指南](https://developer.apple.com/app-store-connect/)
