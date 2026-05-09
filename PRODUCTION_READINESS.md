# 顺时 / SEASONS — 生产上线检查清单

## ✅ 已完成

### 代码层
- [x] 4 个 Flutter 项目 lib/ 零编译错误
- [x] 后端 15+ import/路由参数错误修复
- [x] Android CN + Global Release 构建成功（AAB + APK）
- [x] 后端部署至 ECS 116.62.32.43:4000 并稳定运行

### 功能层
- [x] 5-Tab 路由统一（Chat/Today/Solar/Wellness/Profile）
- [x] 首页 UI 重写（水墨画风格）
- [x] 缺失页面补充（会员、体质报告、节气详情、养生看板、日记）
- [x] SEASONS Global 英文版页面

---

## ❌ 阻碍生产上线的关键问题

### 1. 移动端构建
| 项目 | 状态 | 阻碍 |
|------|------|------|
| Android CN | ⚠️ 构建成功但**未签名** | build.gradle.kts 指向 `../keystore/release.jks`，实际文件在 `app/shunshi-release.jks`，路径不匹配 |
| Android Global | ⚠️ 同上 | 同上 |
| iOS CN | ❌ 未构建 | 需要完整 Xcode |
| iOS Global | ❌ 未构建 | 需要完整 Xcode |

**必须修复：**
- [ ] 统一 Android keystore 路径或创建 `key.properties`
- [ ] 安装 Xcode 后构建 iOS
- [ ] iOS 需要 Apple Developer 账号 + 证书 + Provisioning Profile

### 2. 后端生产配置
| 配置项 | 当前状态 | 生产要求 |
|--------|---------|---------|
| APP_ENV | `development` | `production` |
| APP_DEBUG | `true` | `false` |
| CORS | `allow_origins=["*"]` | 限制为域名白名单 |
| Stripe | 模拟模式 | 配置真实密钥 |
| Redis | 连接失败（内存回退） | 确认 ECS Redis 配置正确 |
| Database | 未知 | 确认使用 PostgreSQL |

**必须修复：**
- [ ] 更新 ECS `.env` 为生产配置
- [ ] 配置 Stripe 生产密钥
- [ ] 修复 Redis 连接配置
- [ ] 限制 CORS 来源

### 3. 网络/安全
| 项目 | 状态 |
|------|------|
| HTTPS/SSL | ❌ 无证书 |
| Nginx 反向代理 | ❌ 未配置 |
| 域名 DNS | ❌ shunshiapp.com 可能未解析 |
| 防火墙/安全组 | 未确认 |

**必须修复：**
- [ ] 申请/配置 SSL 证书（Let's Encrypt）
- [ ] 配置 Nginx（已准备脚本，但未执行）
- [ ] 确认域名 DNS 解析正常

### 4. 商店上架
| 平台 | 状态 |
|------|------|
| Google Play Store | ❌ 未开始 |
| Apple App Store | ❌ 未开始 |

**必须完成：**
- [ ] 隐私政策页面
- [ ] 应用截图（各尺寸）
- [ ] 应用描述、关键词
- [ ] 内容分级问卷
- [ ] 数据安全表单
- [ ] Android: 创建 Google Play 开发者账号（$25）
- [ ] iOS: 创建 Apple Developer 账号（$99/年）

### 5. 测试
- [ ] 单元测试大量过时（接口变更导致）
- [ ] 无端到端测试
- [ ] 无性能测试
- [ ] 无安全审计

### 6. 监控/运维
- [ ] prometheus_client 未安装
- [ ] 无生产级日志收集（ELK/Loki）
- [ ] 无告警配置
- [ ] 无数据库备份策略

---

## 📊 完成度估算

| 阶段 | 完成度 |
|------|--------|
| 代码开发 | ~95% |
| Android 构建 | ~70%（签名问题） |
| iOS 构建 | ~30%（需 Xcode） |
| 后端部署 | ~60%（配置问题） |
| 网络安全 | ~30%（无 SSL） |
| 商店上架 | ~5% |
| **整体** | **~55%** |

---

## 🎯 建议优先顺序

1. **紧急**：修复 Android keystore 路径 → 重签名构建
2. **高**：配置后端生产 `.env`（Stripe、Redis、CORS）
3. **高**：安装 Xcode + 构建 iOS
4. **中**：配置 SSL + Nginx
5. **中**：注册开发者账号
6. **低**：清理测试、配置监控
