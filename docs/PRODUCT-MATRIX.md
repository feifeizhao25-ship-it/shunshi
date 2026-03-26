# 四个产品 - 国内外版本矩阵

## 一、FutureX 平台

| 版本 | Web | App (iOS/Android) | 位置 |
|------|-----|-------------------|------|
| 国内版 | Next.js | React Native | ~/Documents/futurex/ |
| 国际版 | Next.js | React Native | ~/Documents/futurex/ |

### 环境差异
- 国内版: 通义千问/Kimi/DeepSeek + 支付宝/微信 + 极光/华为
- 国际版: OpenAI/Claude/Gemini + Stripe + Firebase

---

## 二、新能源智库

| 版本 | Web | App (iOS/Android) | 位置 |
|------|-----|-------------------|------|
| 国内版 | Next.js | React Native | ~/Documents/energy-intelligence/ |
| 国际版 | Next.js | React Native | ~/Documents/energy-intelligence/ |

### 环境差异
- 国内版: 中文 + 国内市场数据 + 通义/Kimi
- 国际版: English + Bloomberg/IEA + OpenAI/Claude

---

## 三、分发侠

| 版本 | Web | App (iOS/Android) | 位置 |
|------|-----|-------------------|------|
| 国内版 | Next.js | React Native | ~/Documents/distributor/ |
| 国际版 | Next.js | React Native | ~/Documents/distributor/ |

### 环境差异
- 国内版: 小红书/微信/微博/抖音 + 支付宝/微信
- 国际版: Twitter/LinkedIn/Instagram + Stripe

---

## 四、顺时 (特殊)

| 版本 | Web | App | 位置 |
|------|-----|-----|------|
| 国内版 (顺时) | Next.js | Flutter | ~/Documents/shunshi-all/shunshi/ |
| 国际版 (SEASONS) | Next.js | Flutter | ~/Documents/shunshi-all/seasons/ |

---

## 五、技术栈总结

| 产品 | Web | App | Backend |
|------|-----|-----|---------|
| FutureX | Next.js | React Native | PostgreSQL |
| 新能源智库 | Next.js | React Native | PostgreSQL |
| 分发侠 | Next.js | React Native | PostgreSQL |
| 顺时 | Next.js | Flutter | FastAPI |
| SEASONS | Next.js | Flutter | FastAPI |

---

## 六、代码组织

每个项目使用 **环境变量** 切换版本:

```bash
# 国内版
APP_ENV=cn

# 国际版
APP_ENV=global
```

一套代码，通过配置区分国内/国际。
