# 注册来源题「从哪知道我们」（国内版，默认关闭）

## 开关

| 项 | 值 |
|---|---|
| 环境变量 | `SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED` |
| Settings 字段 | `growth_signup_source_enabled`（`backend/app/config.py`） |
| 默认值 | `false`（关闭） |

关闭时：`GET /api/v1/growth/signup-source` 返回 `{"enabled": false, "options": []}`，
App 里不显示题目、不占位；提交的任何值都被丢弃，不落库。

打开：在后端环境里设 `SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED=true` 后重启。客户端不用发版。

## 题目与选项

单选、可跳过，放在首次资料填写（`/profile-setup`）最后一步的选填区，
android-cn、ios-cn 两个包（国内 Web 用同一套 Flutter 代码构建）都有。

| 代码 | 显示 |
|---|---|
| `xiaohongshu` | 小红书 |
| `douyin` | 抖音 |
| `shipinhao` | 视频号 |
| `gongzhonghao` | 公众号 |
| `zhihu` | 知乎 |
| `bilibili` | 哔哩哔哩 |
| `search` | 搜索 |
| `friend` | 朋友推荐 |
| `other` | 其他 |

代码只能追加，不要改名。

## 接口

- `GET /api/v1/growth/signup-source`：公开，返回开关状态和选项，不含任何用户数据。
- `POST /api/v1/growth/signup-source`，body `{"source": "<代码>"}`：要登录。
  返回只有 `{"recorded": true|false}`，不回显来源、不带任何身份字段。
  只记一次；游客、找不到账号、注册超过 72 小时的账号不记。
- `POST /api/v1/growth/events` 的 `signup` 事件可带 `signup_source`，规则同上；响应不回显。

## 数据怎么存

- 新表 `growth_signup_source(event_id, source, created_at)`，由启动时的 `create_all` 建出，
  不改旧表结构，不需要单独迁移。
- `event_id` 关联 `growth_event` 里这位用户的 `signup` 事件；表里没有用户 id、手机号、昵称、
  自由文本。
- 服务端只认上表 9 个代码，其余（中文显示名、大小写不符、自由文本）直接丢弃，不报错。

## 不和身份信息一起输出

- 提交接口、事件接口的响应都不回显来源；本功能不写日志。
- 后台只出聚合：`GET /api/v1/admin/growth/funnel` 新增 `signup_sources`，
  是各代码的计数加 `unanswered`，没有任何用户级数据。
- 用户数据导出（`/api/v1/auth/data/export`）不读这张表。

## 测试

- 后端：`backend/tests/growth/test_signup_source.py`
- App：`android-cn/test/signup_source_card_test.dart`、`ios-cn/test/signup_source_card_test.dart`
