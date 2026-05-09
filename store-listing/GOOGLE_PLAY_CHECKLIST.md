# SEASONS / 顺时 — Google Play 上架准备清单

## 构建产物
| 文件 | 大小 | 路径 |
|------|------|------|
| CN APK | 91MB | android-cn/build/app/outputs/flutter-apk/app-release.apk |
| CN AAB | ~70MB | android-cn/build/app/outputs/bundle/release/app-release.aab |
| Global APK | 80MB | android-global/build/app/outputs/flutter-apk/app-release.apk |
| Global AAB | 70MB | android-global/build/app/outputs/bundle/release/app-release.aab |

## 上架前必须完成

### 1. Google Play 开发者账号
- [ ] 注册 Google Play Developer ($25 一次性费用)
- [ ] 创建应用: `com.shunshi.seasons` (Global) / `com.shunshi.app` (CN)

### 2. 应用截图 (必须)
需要以下尺寸截图:
- 手机: 16:9 (至少 2 张, 最多 8 张)
  - 1080x1920 或 1440x2560
- 7寸平板: 16:9
- 10寸平板: 16:9

建议截图内容:
1. 首页 — 节气卡片 + 每日建议
2. AI 对话 — 养生顾问界面
3. 节气详情 — 谷雨养生
4. 体质测试 — 九种体质
5. 食疗推荐 — 时令食谱
6. 冥想/功法 — 引导练习
7. 家庭养生 — 成员管理
8. 订阅页面 — 会员权益

### 3. 图形素材
- [ ] Feature Graphic: 1024x500 PNG
- [ ] 应用图标: 512x512 PNG (已有 launcher_icon)
- [ ] 宣传视频 (可选, YouTube 链接)

### 4. 内容分级问卷
- IARC 问卷 (App 内容)
- 是否包含暴力: 否
- 是否包含色情: 否
- 是否包含赌博: 否
- 是否共享用户数据: 是 (健康数据, 加密传输)
- 是否包含广告: 否
- 是否包含内购: 是 (会员订阅)

### 5. 数据安全表单
| 数据类型 | 收集 | 共享 | 加密 | 可删除 |
|---------|------|------|------|--------|
| 个人信息 (邮箱/昵称) | ✅ | ❌ | ✅ | ✅ |
| 健康数据 (体质/症状) | ✅ | ❌ | ✅ | ✅ |
| 使用数据 (对话记录) | ✅ | ❌ | ✅ | ✅ |
| 设备信息 | ✅ | ❌ | ✅ | ✅ |

### 6. 目标 API 级别
- targetSdkVersion: 34 (Android 14) — 检查 build.gradle
- minSdkVersion: 21 (Android 5.0)

### 7. 隐私政策
- URL: http://116.62.32.43:4030/privacy (需替换为正式域名)
- 内容: 已完成

### 8. 应用签名
- Keystore: shunshi-release.jks (新生成, 密码: shunshi2026)
- 别名: release
- 有效期: 10000 天 (~27 年)
- ⚠️ 备份 keystore 到安全位置！丢失后无法更新应用

## 上架步骤
1. 创建 Google Play 开发者账号
2. 创建应用 → 填写商店列表信息 (见 google-play-cn.md / google-play-en.md)
3. 上传 AAB (推荐) 或 APK
4. 填写内容分级
5. 填写数据安全
6. 设置定价 (免费 + 应用内订阅)
7. 发布到内部测试轨道
8. 测试通过 → 公开发布
