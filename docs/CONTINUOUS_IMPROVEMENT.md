# 持续改进：评测集、陈旧检测、雷达暂存、月度报告（顺时）

全部默认关闭（`SIL_ENABLED=0`）。开关没开时，所有任务只返回 `{"status": "disabled"}`，不建目录、不联网。
`--force` 只用于人工手动跑一次，不改开关。所有任务只写 `SIL_DATA_DIR`（默认 `var/self_improve/shunshi`），**不改资料库条目、不改知识库、不发消息、不自动通过任何候选**。

## 跑什么、什么时候跑（`python -m app.self_improve.run serve` 里同一个调度循环，上海时间）

| 任务 | 命令 | 时间 | 做什么 | 产物 |
|---|---|---|---|---|
| 陈旧扫描 | `run stale` | 每日 02:30 | 扫资料库 + 暂存区 + RAG 来源清单 + 金标准出处：过期 / 45 天内到期 / 超 180 天没复核 / 待审核超 45 天 / 征求意见稿超 30 天 / 缺出处 | `stale_report.json`；新出现的“高”级项进 `worklist.jsonl` |
| 金标准评测 | `run golden` | 每周日 03:30 | 跑 `data/golden_shunshi_zh.jsonl`（46 题，每题带出处），对比上次；上次过、这次不过 = 退步 | `golden/golden_YYYY-MM-DD.json`、`golden/last.json`；退步题进 `worklist.jsonl` |
| 研究雷达 | `run radar` | 每周三 05:00 | 只访问白名单（arXiv / GitHub / Hugging Face），只写摘要和结构化线索 | `radar/digest_*.md`、`radar/items_*.json` |
| 雷达暂存 | `run radar-stage` | 每周三 06:00 | 把相关线索写成“待审核”的**线索**（不是条目），去重、丢弃注入、标许可证类别 | `library_staged.jsonl` |
| 月度报告 | `run monthly-report [--month YYYY-MM]` | 每月 1 日 05:00 | 汇总上月：改了什么、评测分数、陈旧项、等人审核的候选、建议 | `reports/monthly-YYYY-MM.{md,json,pdf}` |

## 金标准评测集

- 每个技能至少 2 题（`coverage()` 检查；缺技能 = 报告里红字提示）：10 个增长技能（`app/growth/skills`）+ 6 个领域主题（食药同源、运动睡眠、节气、体质、已核验基础知识、医疗边界）。
- 每题：问题、必须包含的要点（`must_include`）、不得出现的词（`must_not_include`）、出处（官方来源 + URL + 检索日期）、`valid_until`（会过期的题）。拒答题（`expect: refuse`）没有“出处”，依据是 `app/safety/config.py` 的医疗边界规则。
- **所有题的 `review_status` 都是“待审核”**：题和答案是研究员根据已打开的官方页面写的，没有任何专家签字。要升级必须有真人审核。
- 它是**监测**，不是上线门禁：结果进报告和工作清单，不阻止任何发布，也不会自动改任何东西。
- 有 `valid_until` 的题（例如“食药物质现在多少种”“现行体质国标”）到期后会在陈旧扫描里被点名，避免旧答案当成对的。

## 暂存区（资料库自动供给）

- `app/library/data/staged_entries_*.json`：已整理好的候选条目（现有 3 条：GB/T 46939-2025、食药物质 106 种与三批增补、2026 三项食养指南）。**用户永远看不到**（`annotated()/find()` 不读它）。
- `library_staged.jsonl`：雷达线索，`kind: lead`，`ingest_allowed=false` 的许可证类别（GPL / 非商用 / 不明）只能当线索读，不能抄正文或代码。
- 要采用：人工读原文 → `python -m app.library.review_cli promote ss-lib-s01 --reviewer 姓名`（复制进工作文档，**仍是“待审核”**）→ 再 `approve`。审核人必须是真人，系统不会代签。

## 体质问卷的诚实说明

`/api/constitution/submit` 现在多返回 `standard_note`：本问卷是自编简化版（25 题），不是国家标准 GB/T 46939-2025 的量表（27 条）和判定方法。`_determine_levels` 的注释同步改正（原注释写成了“转化分”公式，但代码并没有按它算）。

## 需要人做的事

1. 审核暂存区条目（promote → approve），每条要读原文。
2. 审核金标准题（把“待审核”改为已审核需要真人名字和日期）。
3. 看月报里的“陈旧项”和“退步题”，决定改哪条。
4. 旧知识库（`顺时知识库_中文版.md` 等）`valid_until=2026-11-30`，到期前要么复核要么下线；陈旧扫描已提前提示。

## 已知限制

- 评测是离线、确定性的字符串/召回检查，不是大模型评审；它能发现“条目被改坏/被删/过期”，不能判断表达好不好。
- 资料库答案用 2 字组合匹配，不是线上检索；知识库题（`channel: kb`）用线上检索器。
- PDF 用 reportlab；没有中文字体时只出 md + json（报告里会写明）。
