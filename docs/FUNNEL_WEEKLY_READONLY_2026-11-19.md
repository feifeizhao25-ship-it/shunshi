# 每周漏斗汇总（只读，国内版）

`GET /api/v1/admin/growth/funnel/weekly`：按上海时间的自然周出聚合数，给运营每周复盘用。
只做 SELECT、不写任何表，响应里没有用户 id、手机号、订单号或任何用户级数据。

## 谁能调

| 凭证 | 能调什么 |
|---|---|
| 管理后台登录令牌（`X-Admin-Token` / `Authorization: Bearer`） | 本接口和其他全部后台接口（不变） |
| 运营中枢令牌 `OPENCLAW_SHUNSHI_ADMIN_TOKEN`（Bearer） | 同上，全权限（不变） |
| **只读漏斗令牌 `SHUNSHI_FUNNEL_READONLY_TOKEN`**（Bearer） | **只有**本接口的 `GET`。其他后台接口、任何写操作、普通用户接口一律拒绝 |

- 环境变量名：`SHUNSHI_FUNNEL_READONLY_TOKEN`。**默认不设 = 只读入口关闭**（带任何值都是 403）。
- 值由主人自己生成并配置（建议 ≥32 位随机串），不要和 `OPENCLAW_SHUNSHI_ADMIN_TOKEN`、管理后台口令复用。
- 只认 `Authorization: Bearer <令牌>`；比较的是 SHA-256 摘要（`hmac.compare_digest`），常量时间、不因长度不同而短路。
- 门禁在 `backend/app/product_access.py` 的 `_readonly_funnel_allowed`：方法必须是 `GET`、路径必须完全等于上面这条，才放行。
- 没带凭证：401；带了但不对（含只读令牌去调别的后台接口）：403。

## 参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `week_start` | 本周 | 最后一周的周日，`YYYY-MM-DD`（上海时间）。不是周日、或晚于本周，返回 422 |
| `weeks` | 4 | 从 `week_start` 往前共几周，1–26，超出返回 422 |

## 周的定义

上海时间（Asia/Shanghai，UTC+8，无夏令时）**周日 00:00:00 至周六 23:59:59**，即左闭右开
`[周日 00:00, 下周日 00:00)`。数据库里存的 UTC 时间先换成上海时间再归周：
例如 UTC 周六 16:00 已是上海周日 00:00，归下一周。`complete=false` 表示这周还没过完。

## 字段

金额单位一律是**分（人民币）**，整数。付款类只统计国内渠道：`payment_orders.currency='CNY'`
且 `platform IN ('alipay','wechat')`。

| 字段 | 定义 | 数据来源 |
|---|---|---|
| `week_start` / `week_end` | 本周第一秒 / 最后一秒，带 `+08:00` | — |
| `complete` | 此刻是否已过完这一周 | — |
| `new_signups` | 非游客账号，注册时间落在本周 | 产品库 `users`（`is_guest=false`，`created_at`）。已注销（行被删）的账号不再计入历史周 |
| `new_paid` | 本周付款、且此前从没付过款的**人数**（按用户去重） | 记录库 `payment_orders`，`status IN ('paid','refunded')` 且 `paid_at` 非空，按 `paid_at` 归周 |
| `renewals` | 本周付款的**订单数**中，付款人此前已有付款记录的那些 | 同上。同一人同一周付两次：第一单算新付费，第二单算续费 |
| `order_amount_cents` | 本周付款订单的金额合计 | 同上，`amount_cents`。之后被退款的订单仍算在付款那周（退款另在 `refund_amount_cents` 里体现） |
| `refund_amount_cents` | 本周结算成功的退款金额合计 | 记录库 `domestic_refund_events`，只算 `outcome='settled'`，按事件时间归周。`deferred`（部分退款，目前不结算）、`rejected`、`already_settled` 不计 |
| `expirations` | 会员到期**人数**：每位用户仍为 `active` 的国内会员（`subscriptions.platform IN ('alipay','wechat')`）里最晚的到期时间落在本周、且已经过去 | 记录库 `subscriptions`。已续费的人旧那条到期不算；`status='refunded'` 的不算；当前周只算到此刻 |
| `signups_by_source` | 注册来源题各选项的计数，加 `unanswered`（本周 signup 事件里没答的） | 产品库 `growth_signup_source` ⋈ `growth_event`（`event_type='signup'`，按事件时间归周）。**表不存在时为 `null`**，并附 `signups_by_source_note` |

说明：

- 注册来源题在 PR #153（`grok/signup-source`）里，还没合入 main。本接口不依赖那个分支：表不在就返回
  `null` 加说明，**`null` 不代表 0**。#153 合入并打开 `SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED` 后，
  这里会自动出各选项计数，选项顺序取 `app.growth.signup_source.SIGNUP_SOURCES`。
- `new_signups` 来自账号表，`signups_by_source` 来自增长事件，两者口径不同，合计不一定相等。
- 退款只接了支付宝回调；微信退款、部分退款目前不会出现在 `refund_amount_cents` 里。
- 付款、退款、会员在记录库（SQLite `data/shunshi_records.db`）里，读的时候用 `query_only` 只读连接、2 秒忙等。
  现在没有业务数据，汇总在内存里按周归并；数据量大了再改成按时间范围在 SQL 里过滤。

## 响应示例

下面是测试用造数据（`tests/growth/test_weekly_funnel.py` 的场景）跑出来的真实响应，不是线上数据：

```json
{
  "success": true,
  "data": {
    "timezone": "Asia/Shanghai",
    "week_definition": "周日 00:00:00 至周六 23:59:59（上海时间）",
    "currency": "CNY",
    "money_unit": "分",
    "generated_at": "2026-11-19T02:48:52+08:00",
    "weeks": [
      {
        "week_start": "2026-11-01T00:00:00+08:00",
        "week_end": "2026-11-07T23:59:59+08:00",
        "complete": true,
        "new_signups": 1,
        "new_paid": 1,
        "renewals": 0,
        "order_amount_cents": 39900,
        "refund_amount_cents": 1000,
        "expirations": 1,
        "signups_by_source": null,
        "signups_by_source_note": "注册来源表 growth_signup_source 不存在（注册来源题尚未上线或未合入），本项为空，不代表 0。"
      },
      {
        "week_start": "2026-11-08T00:00:00+08:00",
        "week_end": "2026-11-14T23:59:59+08:00",
        "complete": true,
        "new_signups": 2,
        "new_paid": 2,
        "renewals": 1,
        "order_amount_cents": 81790,
        "refund_amount_cents": 39900,
        "expirations": 2,
        "signups_by_source": null,
        "signups_by_source_note": "注册来源表 growth_signup_source 不存在（注册来源题尚未上线或未合入），本项为空，不代表 0。"
      }
    ]
  }
}
```

## 调用示例

```bash
curl -s -H "Authorization: Bearer $SHUNSHI_FUNNEL_READONLY_TOKEN" \
  "https://<后端域名>/api/v1/admin/growth/funnel/weekly?weeks=4"
```

## 测试

`backend/tests/growth/test_weekly_funnel.py`：周边界（周六 23:59:59 / 周日 00:00、UTC 偏移）、每个字段的计入与排除、
来源表缺失与存在、只读令牌不能调其他后台接口或写操作、管理员令牌照常可用、缺令牌 401 / 错令牌 403 / 未配置即关闭、
响应里没有用户级字段。
