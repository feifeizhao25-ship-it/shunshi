# iOS 首次交易账号绑定与收据兼容（2026-10-12）

## 修复

- 新增认证接口 GET /api/v1/subscription/store-account，为当前账号返回稳定的 UUID。命名空间保持固定，不以登录 token、手机号或邮箱传给商店，也不新增数据库迁移。
- iOS 发起购买前获取该 UUID，通过 PurchaseParam.applicationUserName 传给 StoreKit。请求失败、UUID 格式错误或登录凭证在获取期间变化时不打开付款页，不退回无账号关联购买。
- Apple 验证服务提取所选交易的 app_account_token；恢复和收据验证共用持久化边界，只有平台验证返回的账号关联有效，客户端提交的同名字段不能替代它。首笔交易即使先被其他账号提交，也不会创建该账号的归属或会员。
- 没有关联标识的历史交易，只允许恢复已经建立归属的原账号；尚无归属的旧交易返回 409，需要可信的历史记录核对流程。不会按“谁先提交就归谁”自动认领。
- 现有归属、商品冲突、跨渠道会员保护及数据库事务回滚继续执行。平台标识格式无效或与当前账号冲突时拒绝写入。
- 实际依赖 in_app_purchase_storekit 0.4.8+1 默认使用 StoreKit 2，其 serverVerificationData 是 JWS，原后端使用 verifyReceipt 接口。这轮保留 StoreKit 2：通过 SKReceiptManager 读取原生 app receipt 再发送后端，不把 JWS 冒充收据。读取有 10 秒期限，缺少收据时失败关闭并保持交易待核验。添加直接依赖并锁定当前已经使用的版本，没有升级其余依赖。
- 客户端传递 purchaseID，verify-receipt-v2 转交交易选择条件给 Apple 验证器；交易内容仍以 Apple 返回结果为准。

## 来源核对

2026-10-12 查阅 Apple 官方文档：

- https://developer.apple.com/documentation/appstorereceipts/app_account_token ：关联 UUID 随平台交易返回；原 StoreKit 的 applicationUsername 为 UUID 时对应此字段。
- https://developer.apple.com/documentation/storekit/validating-receipts-with-the-app-store ：app receipt 在安全服务端核验；verifyReceipt 已弃用，应规划迁移 App Store Server API / 签名交易验证。

另核对本机锁定依赖的 in_app_purchase_storekit_platform.dart、sk2_transaction_wrapper.dart、sk_receipt_manager.dart：PurchaseParam.applicationUserName 映射 appAccountToken；StoreKit 2 返回 JWS；原生 app receipt 可以独立读取。没有把本地 JWS 解码当成可信验证。

## 验证记录

专项后端 65 项测试通过（含国内渠道与商店恢复的 SQLite 并发检查）；客户端 46 项测试通过；5 个客户端目标文件静态检查无问题。结果与日志见本目录 evidence/2026-10-12-store-account-binding/。测试覆盖跨账号首次抢占、三个恢复入口、错误/缺失关联、历史归属恢复、事务回滚、续期、国内渠道并发，以及客户端账号切换、失败关闭、JWS 转 app receipt 和读取超时。

后端最终全量结果：387 failed, 3432 passed, 17 skipped, 58 warnings in 186.05s (0:03:06)。与 2026-10-11 membership-consistency 基线逐项比较，新增失败 0，原有失败仍需继续处理。首次全量发现的 5 个旧成功样例已补充真实契约要求的平台账号关联；缺失或跨账号关联拒绝测试保留，未放宽生产校验。

## 部署及外部验收

服务端与新版 iOS 应配套发布。旧客户端新购买未附带关联标识，将被服务端拒绝首次自动认领；发布前需安排版本更新与历史订单核对支持，不能临时放开认领来规避限制。

尚未完成 Apple 真机沙盒、真实付款或退款、App Store 审核及生产部署。StoreKit 2 下 app receipt 的真实可用性、实际产品配置与账号关联字段需要真机验收；若原生收据不可用不会完成交易。长期仍需迁移 Apple 已弃用的 verifyReceipt 接口，实施签名链校验/通知更新，不能把本轮兼容处理称为完成该迁移。

本轮仅修改顺时 iOS 与共用后端的 iOS 内购路径；其他三产品没有变更，Android 商店账号关联不在本轮范围。已有未绑定历史交易的人工迁移工具尚未实现。所有已获原账号凭证发出的请求可能仍在服务端完成，客户端无法撤销既有服务端提交。
