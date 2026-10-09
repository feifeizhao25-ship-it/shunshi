# 生产数据库测试修复（2026-10-08）

## 本次修复

- 国内付款恢复任务的生产生命周期测试原来使用 SQLite，触发生产启动保护而失败。改为独立真实 PostgreSQL 数据库，验证恢复任务启动、结束以及实际数据库版本与权益表存在。
- 新增每次运行自动执行的 PostgreSQL 支付跨渠道竞争测试，覆盖尚无权益与已有过期权益两种状态，复用同样的 SQLite 回归断言。
- 原先依赖 SHUNSHI_TEST_POSTGRES_URL、默认跳过的生产启动测试，改为同一独立数据库夹具。验证仅使用文档中的配置、镜像式目录布局时实际启动和 /healthz 响应。
- CI 增加 PostgreSQL 17 服务和健康等待；测试的 JWT_SECRET 与 SHUNSHI_JWT_SECRET 使用相同夹具值，避免合法登录因密钥不一致失败；补齐 PyYAML，让部署配置检查不会因为缺少解析库而跳过。
- 没有修改生产认证、验签、SQLite 拒绝规则或付款成功标准。

## 本地复现

安装 backend/requirements.txt 与 PyYAML==6.0.3 后，从 backend 运行：

```sh
python -m pytest tests/test_domestic_payment_jobs.py tests/test_payment_postgres.py tests/test_production_boot_contract.py tests/test_settings_env_prefix_contract.py -q
```

PostgreSQL 服务端的 pg_config、initdb、pg_ctl 必须可通过 pg_config 的 bindir 找到。macOS Homebrew 可先把对应 PostgreSQL 的 bin 目录加入 PATH。测试自动启动仅监听 127.0.0.1 的临时实例、使用随机端口，并在结束后停止实例、移除临时目录。

也可显式配置 TEST_POSTGRES_ADMIN_URL，指向专用测试服务器的 postgres 维护库。每个测试创建随机名称 shunshi_test_<uuid> 数据库，结束后只删除自己创建的库。不使用应用的生产连接配置，不清空共享应用表。缺少 PostgreSQL 时明确失败，不静默跳过。CI 服务中的密码仅为公开测试夹具。

## 边界

真实本地 PostgreSQL 测试不是阿里云部署验收，也不是支付宝、微信或商店的真实交易。其余既有失败及产品功能缺口仍需继续处理。本轮生产恢复任务生命周期测试使用受控 worker 验证启动与停止；真实恢复逻辑由其他支付恢复测试覆盖。

## 2026-10-09 验证结果

- Python 3.12 的临时测试环境重建成功，PostgreSQL 为本地 17.9。前期依赖下载中断，恢复后才运行下列测试。
- 专项 32 项全部通过：domestic_payment_jobs、payment_postgres、production_boot_contract、settings_env_prefix_contract。
- 后端全库：3352 通过、411 失败、17 跳过、58 条警告，用时 165.13 秒。未使用忽略列表，未关闭认证或生产数据库保护。
- 与 2026-09-29 存档比较，失败测试标识没有新增；此前生产恢复任务生命周期失败已修复。新增的自动 PostgreSQL 支付测试通过，原先跳过的真实生产启动测试已实际通过。旧版本对照不等同于生产验收。
- 仓库完整性、后端部署配置检查、CI YAML 配置校验和 git diff --check 通过。
- 依赖版本与原始专项、全库日志保存在 evidence/2026-10-08-postgres-regression/，文件日期为实际运行日期 2026-10-09。
- GitHub Actions 的云端执行本轮尚未验收；工作流仍按已有 main/develop push 与 main PR 触发。修复保留在集成分支，未将存在 411 项失败的代码合入 main。

当前仍不能确认顺时后端全部通过，更不能据此确认国内四产品具备生产上线条件。后续需逐项区分旧测试契约与真实功能缺陷，继续完成 UI、会员权益、内容准确性等验证，以及服务器和真实支付的外部验收。
