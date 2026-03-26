# 顺时 App 构建配置

## iOS

### 开发构建 (模拟器)
```bash
flutter build ios --simulator --no-codesign
```

### 生产构建 (App Store)
```bash
# 1. 更新版本号
flutter build ios --build-name=1.0.0 --build-number=1

# 2. 或使用 Xcode 打开
open ios/Runner.xcworkspace
```

### Bundle ID
- 开发: `com.example.shunshi`
- 生产: `com.shunshi.app` (需要 Apple Developer)

---

## Android

### APK 构建 (调试)
```bash
flutter build apk --debug
```

### APK 构建 (发布)
```bash
flutter build apk --release
```

### AAB 构建 (Play Store)
```bash
flutter build appbundle --release
```

---

## 版本管理

| 版本 | 构建号 | 日期 | 说明 |
|------|--------|------|------|
| 1.0.0 | 1 | 2026-03-09 | 初始版本 |

---

## 构建检查清单

- [ ] 版本号已更新
- [ ] Bundle ID 正确
- [ ] 应用图标已设置
- [ ] 启动页已配置
- [ ] 权限已配置 (iOS Info.plist)
- [ ] 证书已配置 (如需要)
