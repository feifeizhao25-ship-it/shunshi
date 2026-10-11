# 商店交易队列账号隔离（2026-10-12）

## 修复范围

原流程在商店事件进入队列后，直到收据处理开始才读取当前登录凭证。前一个交易等待期间切换账号，后续排队事件可能携带新账号凭证提交。

本轮在事件送达时捕获凭证，并在每条购买或恢复事件开始核验前检查凭证仍一致且非空。核验成功后再次检查；会话变化时保留交易待处理，不完成商店交易。异常、取消事件仍按原逻辑清理，不授予会员。

收据请求显式接收处理开始时捕获的凭证，不替换成随后登录的凭证。未登录不发起购买或恢复；恢复等待期间登录状态改变，返回中文账号变化提示，而非向当前账号报告旧请求成功。恢复异常不再向用户拼接底层异常文本。

## 验证

在 ios-cn 运行：

```sh
flutter test test/restore_attempt_test.dart test/startup_gate_test.dart test/store_connection_test.dart test/purchase_update_processor_test.dart test/membership_page_test.dart
flutter analyze lib/data/services/store_service.dart lib/data/services/purchase_update_processor.dart test/purchase_update_processor_test.dart
```

37 项测试通过；静态检查无问题。新增 5 项交易处理器测试覆盖购买和恢复的跨批次排队切换、同批次中途退出、未登录收据保持待处理及取消事件清理。测试使用受控会话判断和核验回调，不是原生商店或真实 HTTP 端到端验收。日志位于 evidence/2026-10-12-store-account-queue/。

## 仍须处理的边界

1. 本轮捕获的是事件送达时的凭证，不是购买发起时的账号。SDK 延迟事件在账号切换后才首次送达、跨进程恢复和首次交易归属仍需服务端购买意图/平台账号关联方案；不能仅靠客户端判断完整解决。
2. 已发出的 HTTP 请求不会因退出而撤销；原账号的服务端核验可能已经成功。客户端拒绝把迟到结果作为新会话成功，保留交易供后续核对。
3. 凭证刷新也会保守地使旧事件失效，需后续重新投递或恢复；使用完全相同凭证退出后再登录的过程不是本轮凭证比对能识别的会话版本变化。
4. backend/app/services/store_restore.py 的 persist_restore 已检查 StorePurchaseOwner：已有归属不允许转给其他用户；归属为空时按本次认证用户建立归属，因此不能据已有交易保护推断首次归属风险已解决。本轮只阅读该逻辑，未修改后端。
5. 未重跑后端全量、未进行 Apple 沙盒、真实付款或生产部署；上次后端全量仍有 387 项失败。其余三个产品本轮未改变。
