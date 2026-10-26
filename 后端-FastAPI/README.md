# 顺时后端骨架（后端-FastAPI）

单 FastAPI 应用 + router 分模块（health / user / memory / chat / subscription /
reflections / feedback / settings / seasons / content），
架构风格裁剪自见己 `backends/svc-user`（FastAPI 分层、fail-closed 配置、健康检查惯例），
数据层用 SQLAlchemy 同时兼容 SQLite（开发）与 PostgreSQL（生产），启动时建表（对齐见己 init_db 惯例）。

> 本骨架取代/对齐 `手机端-Flutter/backend/` 下的单文件原型；接口契约以已出包的
> Flutter 客户端（`手机端-Flutter/lib`）实际调用为准。

## 目录结构

```
app/
├── main.py                 # create_app 工厂 + uvicorn 入口
├── config.py               # pydantic-settings，全部环境变量
├── db.py / models.py       # SQLAlchemy 引擎、模型、启动建表
├── security.py             # JWT(HS256) 签发/校验、scrypt 密码散列
├── deps.py                 # settings / session / current_user 依赖
├── entitlements.py         # 权益注册表加载与 schema 校验
├── entitlements_registry.json  # 会员权益注册表（free/pro/family/enterprise × 六维）
└── routers/
    ├── health.py           # GET /api/health（fail-closed）、GET /healthz
    ├── user.py             # /api/v1/auth/*：登录注册 + 数据导出 + 账号注销
    ├── memory.py           # /api/v1/settings/memory、/api/v1/memory/all、/api/v1/conversations
    ├── chat.py             # /api/v1/chat/send、/api/v1/ai/chat → 模型网关代理
    ├── subscription.py     # /api/v1/entitlements、/api/v1/subscription/status、/api/v1/billing/callback
    ├── reflections.py      # /api/v1/reflections（POST/GET）
    ├── feedback.py         # /api/v1/feedback、/api/v1/feedback/rating
    ├── settings.py         # /api/v1/notifications/settings、/api/v1/settings/quiet-hours
    ├── seasons.py          # /api/v1/seasons/home/dashboard、onboarding/complete、audio/progress
    └── content.py          # /api/v1/contents*、/api/v1/cms/*、/api/v1/seasons/audio/{id}（fail-closed）
tests/                      # pytest，全部 TestClient，不依赖真实外部服务
```

## 端点表（契约以 Flutter 客户端实际调用为准）

| 端点 | 说明 |
|------|------|
| `POST /api/v1/auth/guest-login` `register` `login` `sms/send` `sms/verify` | 认证（sms fail-closed） |
| `POST /api/v1/auth/data/export`（GET 等价别名） | 真实导出该用户全部数据 JSON |
| `DELETE /api/v1/auth/account` | 真实删除全部数据与账号行，返回各表删除条数 |
| `POST /api/v1/auth/account/cancel-delete` | 无软删除态，如实返回 `pending_deletion:false` |
| `POST /api/v1/chat/send`、`POST /api/v1/ai/chat` | 模型网关代理（fail-closed） |
| `GET/POST /api/v1/settings/memory`、`DELETE /api/v1/memory/all`、`DELETE /api/v1/conversations` | 记忆与对话 |
| `POST /api/v1/reflections`、`GET /api/v1/reflections` | 反思记录（{"id","saved":true} / {"items":[...]}） |
| `POST /api/v1/feedback`、`POST /api/v1/feedback/rating` | 反馈与评分（真实落库） |
| `GET/POST /api/v1/notifications/settings` | 通知设置（push_enabled/time_slots/preferences） |
| `GET/POST/PUT /api/v1/settings/quiet-hours` | 免打扰时段（客户端用 POST，PUT 为别名） |
| `GET /api/v1/seasons/home/dashboard?hemisphere=` | 空态结构：daily_insight=null、suggestions=[]，不编造 |
| `POST /api/v1/seasons/onboarding/complete` | onboarding 档案真实落库 |
| `POST /api/v1/seasons/audio/progress` | 播放进度真实落库 |
| `GET /api/v1/contents*`、`/api/v1/cms/content/{id}`、`/api/v1/seasons/audio/{id}` | 内容源未配置 → 503 configured:false |
| `GET /api/v1/entitlements` | 会员权益注册表（无需登录） |
| `GET /api/v1/subscription/status` | tier 由注册表 product_tier_map 与 entitlements 表同源推导 |
| `POST /api/v1/billing/callback` | 支付回调（HMAC 验签，fail-closed） |

## Fail-closed 约定

| 依赖 | 环境变量 | 未配置时行为 |
|------|----------|--------------|
| JWT 密钥 | `SHUNSHI_JWT_SECRET` | 认证接口 503 `configured:false`；生产启动直接报错 |
| 模型网关 | `SHUNSHI_MODEL_ROUTER_URL` | `/api/v1/chat*` 503 `configured:false`，不返回兜底文案冒充 AI |
| 短信服务商 | `SHUNSHI_SMS_PROVIDER_URL/TOKEN` | `/api/v1/auth/sms/*` 503 `configured:false` |
| 支付回调 | `SHUNSHI_PAYMENT_CALLBACK_SECRET` | `/api/v1/billing/callback` 503 `configured:false`，绝不假开通会员 |
| 内容源（CMS/音频） | `SHUNSHI_CONTENT_SOURCE_URL` | `/api/v1/contents*`、`/api/v1/cms/*`、`/api/v1/seasons/audio/{id}` 503 `configured:false`，不编造内容 |
| Redis / 网关 | `SHUNSHI_REDIS_URL` / `SHUNSHI_MODEL_ROUTER_URL` | `/api/health` 对应项 down，整体 503 |

## 本地启动

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # 按需填写
uvicorn app.main:app --reload --port 8000
curl http://localhost:8000/api/health
```

未配置 Redis/模型网关时 `/api/health` 返回 503 且对应组件 `down`，属预期（fail-closed）。

## 测试

```bash
pytest -q
```

## Docker 部署

```bash
export SHUNSHI_JWT_SECRET=$(openssl rand -hex 32)
docker compose up --build
```

compose 编排 app + postgres + redis；app 以 `postgresql+psycopg://` 连接 postgres。
模型网关 / 短信 / 支付密钥通过同名环境变量注入。
