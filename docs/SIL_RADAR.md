# 研究雷达（SIL 的线索发现，2026-10-31）

每周（建议周三 05:00 Asia/Shanghai，常量见 `RADAR_SCHEDULE`/`RADAR_CRON`）去白名单站点找新的论文、仓库、模型和数据集，只写一份摘要文件。

## 它做什么
- 只访问 `export.arxiv.org`、`api.github.com`、`huggingface.co`；只用 https；不跟随重定向；限大小、限超时。
- 产出只有 `<data_dir>/radar/digest_YYYYMMDD.md` 和去重用的 `seen.json`。
- 每条线索标「线索（未核）」，附许可证类别：`permissive_reference`、`do_not_ingest`（CC-BY-NC/SA）、`do_not_introduce`（GPL 等）、`unknown_do_not_introduce`。类别只是提醒，不是法律意见。
- 抓回的文字当数据：去控制字符、截断，含提示注入特征的条目直接丢弃；带实体声明的 XML 拒绝解析。
- 查询词默认见 `DEFAULT_QUERIES`，可用 `SIL_RADAR_QUERIES`（分号分隔，最多 6 个）覆盖。

## 它不做什么
不入库、不改技能、不发企业微信或任何消息、不抓国内社交平台、不下载模型权重、不自动采用任何内容。`SIL_ENABLED=0`（默认）时 `run_if_enabled` 什么都不做。源码里不引用审批或发送函数，测试会检查。

## 还没做（需要人决定）
- 还没有接进 `run.py` / 定时服务，现在只是可被调用的库；接入前先让人读一遍摘要格式。
- 摘要里的线索要采用，仍须有人读原文，再走原有的提案、评测、审批流程。
