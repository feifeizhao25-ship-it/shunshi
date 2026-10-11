# iOS 恢复购买等待与结果修复（2026-10-12）

## 问题与行为

此前恢复购买只等待商店 SDK 发起请求，不能代表恢复已经通过核验；全局回调会被后一次请求覆盖。个人页在异步请求后关闭弹窗，还存在页面切换后误关闭其他页面的风险。

现在恢复请求返回明确结果。并发请求共享一次商店调用；后端确认有效收据才提前返回成功。单条过期或无效收据不会遮住后续有效收据。SDK 发起异常返回请求失败；30 秒尚无确认结果则结束本次等待，提示刷新会员状态或稍后重试，不推断用户没有购买记录。服务释放也会结束等待。

会员页显示返回结果并重新读取会员状态，不在客户端自行授予权益。个人页取消异步关闭路由的逻辑，用中文消息反馈结果并防止重复点击。

## 验证

在 ios-cn 执行：

```sh
flutter test test/restore_attempt_test.dart test/startup_gate_test.dart test/store_connection_test.dart test/purchase_update_processor_test.dart test/membership_page_test.dart
flutter analyze lib/data/services/restore_attempt.dart lib/data/services/store_service.dart lib/presentation/pages/profile_page.dart lib/presentation/pages/subscription/subscription_page_v2.dart test/restore_attempt_test.dart test/membership_page_test.dart
```

32 项测试通过，6 个目标文件静态分析无问题，git diff --check 通过。新增覆盖 SDK 调用完成不等于恢复成功、并发合并、无效后有效收据、SDK 无响应、发起异常后重试、旧请求结果隔离、释放等待以及会员页不确定结果结束等待且不授予会员。

原始日志见 evidence/2026-10-12-restore-wait/tests.txt 和 analyze.txt。

## 边界与未完成项

- 30 秒是恢复等待器的截止时间，不是整个页面刷新流程总时限；超时不会取消商店调用或后端核验。迟到核验仍可能更新会员状态，需再次刷新确认。
- 请求标识在收据处理函数开始时捕获。SDK 事件没有恢复会话标识，不能完全区分在下一轮才开始处理的旧事件。
- 本次为受控 Future、回调和 Flutter 组件测试，未进行 Apple 沙盒、真机真实付款或生产部署验收，也没有新增真实设备截图。
- 账号切换期间在途交易的身份绑定仍需专项审查。本轮未改变另外三个产品，未重跑后端全量测试；上轮后端全量仍有 387 项失败，不能据此宣称四产品全部达到上线要求。
