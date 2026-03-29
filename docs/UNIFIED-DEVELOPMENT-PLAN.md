# 统一开发提示词体系 - 执行计划

> 四个产品 × 三个平台 × 双版本 = 完整矩阵
> 
> 版本: v1.0 | 2026-03-13

---

## 一、产品矩阵

```
项目位置                                国内版 (CN)          国际版 (Global)
────────────────────────────────────────────────────────────────────
~/Documents/futurex/                  ✅                   ✅
~/Documents/shunshi-all/shunshi/       ✅ (顺时)             
~/Documents/shunshi-all/seasons/                         ✅ (SEASONS)
~/Documents/energy-intelligence/       ✅                   ✅
~/Documents/distributor/               ✅                   ✅
```

---

## 二、开发提示位置

| 产品 | 开发提示 | 位置 |
|------|----------|------|
| FutureX | DEVELOPMENT-PROMPT.md | ~/Documents/futurex/docs/ |
| 顺时 | DEVELOPMENT-PROMPT.md | ~/Documents/shunshi-all/shunshi/docs/ |
| SEASONS | DEVELOPMENT-PROMPT.md | ~/Documents/shunshi-all/seasons/docs/ |
| 新能源智库 | DEVELOPMENT-PROMPT.md | ~/Documents/energy-intelligence/docs/ |
| 分发侠 | DEVELOPMENT-PROMPT.md | ~/Documents/distributor/docs/ |

---

## 三、技术栈

| 产品 | Web | Mobile | Backend |
|------|-----|--------|---------|
| FutureX | Next.js | React Native | PostgreSQL |
| 顺时 | Next.js | Flutter | FastAPI |
| SEASONS | Next.js | Flutter | FastAPI |
| 新能源智库 | Next.js | React Native | PostgreSQL |
| 分发侠 | Next.js | React Native | PostgreSQL |

---

## 四、开发顺序

```
Phase 1: FutureX 平台
    位置: ~/Documents/futurex/
    提示: docs/DEVELOPMENT-PROMPT.md

Phase 2: 新能源智库
    位置: ~/Documents/energy-intelligence/
    提示: docs/DEVELOPMENT-PROMPT.md

Phase 3: 顺时 + SEASONS
    位置: ~/Documents/shunshi-all/shunshi/ (顺时)
    位置: ~/Documents/shunshi-all/seasons/ (SEASONS)
    提示: docs/DEVELOPMENT-PROMPT.md

Phase 4: 分发侠
    位置: ~/Documents/distributor/
    提示: docs/DEVELOPMENT-PROMPT.md
```

---

## 五、使用方法

给 OpenClaw 发送指令:

```
请根据 ~/Documents/futurex/docs/DEVELOPMENT-PROMPT.md 开发 FutureX 平台
```

---

## 六、环境配置

每个项目支持双版本:

```bash
# 国内版
APP_ENV=cn

# 国际版
APP_ENV=global
```

差异包括:
- AI Provider (国内: 通义/开思/DeepSeek | 国际: OpenAI/Claude/Gemini)
- Payment (国内: 支付宝/微信 | 国际: Stripe)
- Push (国内: 极光/华为 | 国际: Firebase)

---

*计划完成*
