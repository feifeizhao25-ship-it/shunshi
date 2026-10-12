# 家庭设置持久化与提醒开关（2026-10-12）

## 已修复

此前 GET /family/settings 永远返回默认值，PUT 只回显请求、没有保存；关怀提醒不读取开关，并把写入发起者通知列表描述为已发给家人。

新增记录库 family_settings 表，按认证账号保存设置；启动时通过现有幂等 SCHEMA_SQL 初始化，新旧记录库均可创建该表。PUT 只合并显式提交的字段，以 BEGIN IMMEDIATE 序列化读改写，避免两个部分更新互相覆盖。读写错误不返回虚假的默认值或保存成功。新表使用 user_id，可由现有数据导出及注销清理流程识别。

发送关怀提醒与设置保存使用相同记录库写事务边界。开关关闭时返回 409，不创建通知；重新开启后可保存。接口准确返回 delivery=self_inbox 和“已保存到自己的通知列表”，不宣称向家人实际送达。详情分享缺少成员授权流程，show_trend_only 仅接受 true，不把 false 当作已实现的隐私授权。

reminder_frequency 限定 daily/weekly/manual，保存的是偏好；当前没有家庭自动提醒调度。GET/PUT 明确返回 reminder_schedule_active=false，保存提示也说明自动定时提醒尚未启用。

## 测试

backend 下运行：

```sh
/tmp/shunshi-verify-20261008/bin/python -m pytest tests/test_family_settings_persistence.py tests/test_family_status_persistence.py tests/test_account_erasure.py -q
```

20 项通过，5 条警告（已有依赖弃用、模型字段元数据警告），无跳过。覆盖独立应用实例重启读取、部分更新保留其他字段、两个应用实例并发更新、非法频率/未支持的详情分享、开关阻止通知、重新开启、真实通知归属、账号隔离与伪造 user_id、数据导出及注销清理、数据库错误，以及此前成员状态保存回归。日志见 evidence/2026-10-12-family-settings/tests.txt。git diff --check 通过。

本轮未重跑后端全量。最近全量记录（内购绑定提交 8cdf3b18）为 3432 通过 / 387 失败 / 17 跳过；不能将本轮专项通过解读为全量通过。

## 仍未完成

自动提醒调度、向实际家庭成员投递与推送、成员授权的详情分享仍未实现。本轮是后端与 SQLite 集成验证，未完成网页/移动端设置控件的真实 UI 验收，也未部署生产。上线时需按正常服务启动初始化记录库，并保留数据目录；多实例记录库部署方式仍需按既有部署方案验证。四产品全部上线状态不因本轮改变。
