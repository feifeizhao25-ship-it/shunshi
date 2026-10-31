# SIL v1.1（持续自改进内核增量）— 2026-10-31

在已合并的 SIL（默认关闭）上**增量**补的内核能力。**默认关闭不变**：`SIL_ENABLED=0`；`POLICY_REVIEWERS` 为空；`expert_signed` 不由任何自动流程设置；用户可见改动仍须企业微信批准。

| 新增 | 作用 | 位置 |
|---|---|---|
| 效用账本 `UtilityLedger` | 每条技能/条目记录 EMA 效用（α 默认 0.4，**须用本产品评测集离线校准**，论文数值只是起点）；`rank` 做效用感知重排；`retire_candidates`、`prune_plan` 只给建议名单，不删任何东西 | `backend/app/self_improve/utility.py` |
| 名字级退役名单 | 退役的名字（NFKC、去空白/标点后匹配）不能被同名提案复活；移出名单只有 `POLICY_REVIEWERS` 内的人可以，名单为空则无人可移出 | `loop.retire / unretire` |
| 自引用拦截 | 提案证据若指向本系统自己的输出（`file://`、`var/self_improve`、数据目录）→ 拒绝 `self_citation` | `loop` |
| 状态字段 | 条目可带 `status`：`in_force / draft_consultation / superseded / expired`。征求意见稿可检索、**绝不能当现行规则回答**（`fact_allowed=false`，回答必须带固定提示 `DRAFT_NOTICE_ZH`）；`resolve_conflict` 给出中英文/多来源冲突的取舍规则（状态 > 来源层级 > 中文优先 > 交人工） | `freshness` |
| 零英文门 | `zh_only_rate` 评测指标 + 白名单缩写；可作为 `extra_floors` 的一项接入产品门禁 | `zhgate` |
| 评审去偏 | 提示词变体、多评审员（异源）去偏投票、季度 ≥30 条真人标注的 kappa 校准（不达标即停用该评审员） | `judge` |
| `extra_floors` 同步 | 各产品可声明额外下限（缺失即不通过，fail-closed）；默认为空，不影响现有行为 | `gates` |
| 周报指标 | `CycleReport.metrics`：来源/提案/拒绝原因分布/退役名单规模，不含任何用户数据 | `loop` |

晋升后 7 天观察期：线上指标不退步记 `utility=1`，回滚记 `0`（EMA 更新）。

## 来源与边界
- 思路来自 Selm（arXiv 2610.24630，全文已读；论文基准上的数值未在本产品验证）。
- 评审去偏：评审偏差相关论文仅到元数据级，这里只落地「交换顺序 + 长度归一 + 多评审员 + 真人校准」这些不依赖论文数值的做法。
- 不新增任何运行时依赖，不调用任何模型，不联网。
