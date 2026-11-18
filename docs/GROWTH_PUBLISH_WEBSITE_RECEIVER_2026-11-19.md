# 自有网站发布接收口（POST /api/v1/growth/publish/website）

运营中枢（contentflow 仓库 `ops/airui_ops/publish.py`）的 A 档渠道 `website_seo` 会调产品侧的 `{api_base}/growth/publish/website`。这个接口就是产品侧的接收口：**核对通过就把内容存进顺时后台，不上线，不转发到任何外部平台。**

## 开关和令牌

| 项 | 名字 | 默认 |
|---|---|---|
| 开关 | `SHUNSHI_GROWTH_PUBLISH_RECEIVER_ENABLED`（Settings 字段 `growth_publish_receiver_enabled`） | `false`：一律返回 503 `disabled` |
| 令牌 | `OPENCLAW_SHUNSHI_PUBLISH_TOKEN` | 不设：503 `token_not_configured` |

- 只认 `Authorization: Bearer <令牌>`，比较 SHA-256 摘要（`hmac.compare_digest`）。
- **不认**管理员登录态、`X-Admin-Token`、运营中枢后台令牌 `OPENCLAW_SHUNSHI_ADMIN_TOKEN`。令牌的值如果和下面这些变量相同，按"未配置"处理：`OPENCLAW_SHUNSHI_ADMIN_TOKEN`、`SHUNSHI_FUNNEL_READONLY_TOKEN`、`SHUNSHI_JWT_SECRET`、`ADMIN_JWT_SECRET`、`ADMIN_PASSWORD_HASH`、`SHUNSHI_ADMIN_TOKEN`。
- 这个令牌也打不开任何后台接口（测试里核过：带它调 `/api/v1/admin/growth/audit` 返回 403）。
- 产品门禁 `product_access.py` 把这条路径列为"由处理函数自己核身份"（同支付回调），所以不需要用户登录。

运营中枢的 `api_base` 填 `https://<顺时域名>/api/v1`。

## 请求格式

照 `Publisher._deliver`：

```
POST /api/v1/growth/publish/website
Authorization: Bearer <OPENCLAW_SHUNSHI_PUBLISH_TOKEN>
Content-Type: application/json
X-Airui-Contract: live
```

```json
{
  "content": {
    "product": "shunshi",
    "channel": "website_seo",
    "title": "小雪：名字的来历",
    "body": "小雪是二十四节气里的第二十个。\n\n本内容由人工智能生成。\n仅供作息安排参考，不是医疗诊断或治疗建议。",
    "url": "https://preview.invalid/website_seo"
  },
  "stub": false,
  "note": "",
  "approval": {
    "id": "ap_test0001",
    "status": "approved",
    "content_sha256": "9f089a21cff2a800a27581b1a6206e7c5c51a42232eca5325d300e64a72b89c6",
    "channel": "template_card",
    "detail_checked": false
  }
}
```

`content` 是运营中枢 `daily.py` 生成的 A 档内容：`product`、`channel`、`title`、`body`、`url`。

**`approval` 是这里新增的要求**：运营中枢现在的请求体只有 `content`、`stub`、`note`，没有批准单。产品侧没有办法凭空知道这份内容批没批，所以要求运营中枢把它手上的批准单（`ApprovalService` 的记录）里这几项一起带来：`id`、`status`、`content_sha256`、`channel`、`detail_checked`。**在运营中枢改好之前，每一次调用都会被拒（`approval_missing`）。** 这是有意的：宁可不收，也不收没有批准单的内容。

## 接收条件（四项同时满足）

| # | 条件 | 怎么核 | 不满足时 |
|---|---|---|---|
| 1 | 有一张哈希对得上的批准单 | `approval.status == "approved"`；`approval.content_sha256` 等于对 `content` 重新计算的哈希（和运营中枢 `content_sha256` 同一算法：`json.dumps(sort_keys=True, ensure_ascii=False, separators=(",", ":"))` 后 SHA-256）；企业微信审批（`channel == "oa"`）还要 `detail_checked == true` | 409 `approval_missing` / `approval_not_approved` / `sha_mismatch` / `approval_detail_not_checked` |
| 2 | 上海时间 08:00–21:30 | 用**服务器时钟**换算成 Asia/Shanghai，含两端整分（08:00:00 到 21:30:59），和运营中枢 `in_window` 一致；不看请求里带的任何时间 | 403 `outside_window` |
| 3 | 带人工智能生成标识 | 正文里同时有"本内容由人工智能生成。"和"仅供作息安排参考，不是医疗诊断或治疗建议。"（运营中枢 `AIGC_TEXT['shunshi']` 和 `SHUNSHI_DISCLAIMER`） | 422 `aigc_missing` |
| 4 | 写进只增不改的审计记录 | 在同一个事务里写 `growth_audit_log`（action=`website_receive`，decision=`accept`）。这张表在 ORM 层拒绝更新和删除。审计写不进去，整笔回滚，内容不留下 | 503 `audit_unavailable` |

另外三条（不在四项里，但沿用已有规矩）：

- 全局急停（`SHUNSHI_KILL_SWITCH` 或 Settings `kill_switch`）打开时：423 `kill_switch`。
- 内容要过已有的合规门 `violation_codes`：422 `compliance_failed`。
- 请求体格式不对、`stub: true`、`product` 不是 shunshi、`channel` 不是 website_seo：422 `bad_request`。

响应里的 `failed` 列出所有没满足的项，`reason` 是第一项，`message` 是中文说明。

## 存在哪里

- 表 `growth_website_submission`（随 `init_db` 的 `create_all` 建表，和其他增长表一样；没有 alembic 迁移）：`content_sha256`（唯一）、`approval_id`、`title`、`body`、`url`、`content_json`、`status=received`、`received_at`。只追加：同一份内容重复推送返回 200、`duplicate: true`，不覆盖；ORM 层拒绝更新和删除。
- 审计：通过身份核对以后的每一次请求（接收、重复、拒绝）都写一条 `growth_audit_log`，detail 里有原因代码和内容哈希。身份核对之前的拒绝（开关关、令牌不对）不写审计，免得任何人都能刷审计表。
- 不上线：没有任何代码把这张表的内容渲染到网站上，也没有任何外部请求。上线方式由主人另定。

## 响应示例

接收（201）：

```json
{
  "success": true,
  "accepted": true,
  "id": "63036140b43a45a085ca1350805552d9",
  "url": null,
  "content_sha256": "9f089a21cff2a800a27581b1a6206e7c5c51a42232eca5325d300e64a72b89c6",
  "stored": true,
  "published": false,
  "duplicate": false,
  "note": "已存进顺时后台，未上线、未转发到任何外部平台"
}
```

运营中枢现在的请求体（没有 `approval`）（409）：

```json
{
  "success": false,
  "accepted": false,
  "reason": "approval_missing",
  "message": "没有批准单",
  "failed": [
    "approval_missing"
  ],
  "content_sha256": "6af01eacb28528db18ec0376df81b8693eb441d618276bc6b651f4e05556d811"
}
```

批准以后内容被改过（409）：

```json
{
  "success": false,
  "accepted": false,
  "reason": "sha_mismatch",
  "message": "批准单哈希与内容不一致",
  "failed": [
    "sha_mismatch"
  ],
  "content_sha256": "6af01eacb28528db18ec0376df81b8693eb441d618276bc6b651f4e05556d811"
}
```

## 和运营中枢对接还差什么（要主人定）

1. 运营中枢的请求体要加 `approval`（见上）。
2. 运营中枢给顺时发的是 `OPENCLAW_SHUNSHI_ADMIN_TOKEN`（后台令牌）。这个接收口不认它，要运营中枢改成发 `OPENCLAW_SHUNSHI_PUBLISH_TOKEN`；或者在运营中枢那边把这个渠道单独配一个令牌。
3. 运营中枢把任何 2xx 都记成 `published: true`。这里返回的是"已存、未上线"（`published: false`），运营中枢那边要按这个字段记账，否则台账会把"已收到"当成"已发布"。
