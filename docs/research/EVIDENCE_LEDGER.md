# 证据账本（顺时）— 2026-10-31

本目录是「持续自改进」计划第 1 步的产物：把本轮检索（X、GitHub、HuggingFace、arXiv、政府/平台公告）里和**顺时**相关的来源登记成可审计的账本。
它是**登记册，不是语料**：账本里的条目不会自动进入任何检索索引或回答。

## 使用规则
1. **只有 A 级来源可以驱动内容改动**（政策条目、事实数据点、评测期望答案）。A = 本轮已读到官方/平台原文或论文全文。
2. B 级（只读到元数据、搜索摘录或媒体转述）和 lead 级（X 帖子等线索）只能作**发现线索**，要升级为 A 才能入库。
3. 带「待核」标记的条目必须回到原文复核后才能使用；复核前不得写进任何用户可见回答。
4. 许可证：`do_not_ingest`（非商用/相同方式共享）不入库、不训练、不拷贝题目；`do_not_introduce`（GPL/自定义许可证）不引入依赖或代码；`permissive_reference` 仅作思路参考，若拷贝代码须保留许可证声明。
5. 所有新条目走既有流程：来源 → 隔离区 → 离线评测 → 合规门 → 企业微信批准 → 发布。SIL 默认关闭（`SIL_ENABLED=0`），审批人名单为空，`expert_signed` 保持 false。
6. 本账本不含国内社交平台抓取结果；X 内容只当线索，不含任何投资类内容。

## 待核清单（本产品相关）
- `nhc-2643-2025` — 待核：盒子直连 HTTP 412，正文仅由搜索工具读取

## 条目（23 条；A 级 5 条）
| 等级 | id | 类型 | 标题 | 许可证 | 许可分类 | 链接 | 备注 |
|---|---|---|---|---|---|---|---|
| A | `2609.15482` | arxiv | When AI Companions Disappear (China anthropomorphic AI rules) | n/a | n/a | https://arxiv.org/abs/2609.15482 | 全文已读；设计与政策考量表→导出/终止通知/申诉 |
| A | `2609.33014` | arxiv | TCMQA 38K 中医基准+执业者对照 | 数据集 CC-BY-NC-SA-4.0 | do_not_ingest | https://arxiv.org/abs/2609.33014 | 全文已读；模型与执业者难题几乎不相关；数据非商用 |
| A | `2610.14705` | arxiv | Lingdan-V2 TCM LLM family | 代码 Apache-2.0 | permissive_reference | https://arxiv.org/abs/2610.14705 | 全文已读；处方F1仅37.0；不采用处方生成 |
| A | `2610.24630` | arxiv | Selm: Self-Evolving Library Management for Multi-Skill Agent Optimization | n/a | n/a | https://arxiv.org/abs/2610.24630 | 全文已读：效用检索+验证门+退役名单；容量30、α=0.4（论文基准，需自测校准） |
| A | `samr-03459-2026` | policy | 市场监管总局政协提案答复（食药物质106种、复方配伍试点36种） | 政府公开 | gov_public | https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/tssps/art/2026/art_fcdb8ed8982e45ed8250cdb0adcdb586.html | 正文已读 |
| B | `2604.27306` | arxiv | NuggetIndex: Governed Atomic Retrieval | n/a | n/a | https://arxiv.org/abs/2604.27306 | 元数据 |
| B | `2606.12903` | arxiv | X-MADAM-RAG 中英证据冲突 | n/a | n/a | https://arxiv.org/abs/2606.12903 | 元数据 |
| B | `2607.24760` | arxiv | CHaystack 中文文档检索 | n/a | n/a | https://arxiv.org/abs/2607.24760 | 元数据 |
| B | `2610.04215` | arxiv | TCMClinicalReason-Bench | n/a | n/a | https://arxiv.org/abs/2610.04215 | 元数据，仅线索 |
| B | `2610.24320` | arxiv | The Judge Can Debias Itself | n/a | n/a | https://arxiv.org/abs/2610.24320 | 元数据 |
| B | `2610.24601` | arxiv | TCMScience | n/a | n/a | https://arxiv.org/abs/2610.24601 | 元数据，仅线索 |
| B | `2610.25126` | arxiv | Trackable Skill Library Lifecycle Management | n/a | n/a | https://arxiv.org/abs/2610.25126 | 元数据 |
| B | `2610.36188` | arxiv | Skill Dreaming | n/a | n/a | https://arxiv.org/abs/2610.36188 | 元数据 |
| B | `2610.38333` | arxiv | Fu-TCM | n/a | n/a | https://arxiv.org/abs/2610.38333 | 元数据，仅线索 |
| B | `Qwen/Qwen3-Embedding-4B` | hf-model | Qwen3-Embedding-4B | apache-2.0 | permissive_reference | https://huggingface.co/Qwen/Qwen3-Embedding-4B | 嵌入/重排 A/B 本期暂缓（用户决定 2026-10-31） |
| B | `Qwen/Qwen3Guard-Gen-4B` | hf-model | Qwen3Guard-Gen-4B | apache-2.0 | permissive_reference | https://huggingface.co/Qwen/Qwen3Guard-Gen-4B | 离线对照分类器 |
| B | `TCMAI-BJTU/Lingdan-V2` | github | Lingdan-V2 repo | Apache-2.0 | permissive_reference | https://github.com/TCMAI-BJTU/Lingdan-V2 | API |
| B | `TechTCM/TCMQA` | hf-dataset | TCMQA dataset | cc-by-nc-sa-4.0 | do_not_ingest | https://huggingface.co/datasets/TechTCM/TCMQA | HF API 取许可证；禁入语料 |
| B | `nhc-2643-2025` | policy | 卫健委对2643号建议答复（食药物质106种，20项国标） | 政府公开 | gov_public | https://www.nhc.gov.cn/wjw/jiany/202508/6141c788fa794723afb4e71af48b3d93.shtml | 待核：盒子直连 HTTP 412，正文仅由搜索工具读取 |
| B | `pariskang/CMLM-ZhongJing` | github | CMLM-ZhongJing | MIT | permissive_reference | https://github.com/pariskang/CMLM-ZhongJing | API；不进运行时 |
| B | `tyang816/Awesome-TCM-LLM` | github | Awesome-TCM-LLM | MIT | permissive_reference | https://github.com/tyang816/Awesome-TCM-LLM | API；索引用 |
| lead | `x-2111993577081614838` | x | 药食同源资讯早报（以官方原文为准） | 线索 | unknown | https://x.com/ValenutritionX/status/2111993577081614838 | 线索 |
| lead | `x-2114496716036833457` | x | 中医体质自测：固定评分规则、不靠大模型猜 | 线索 | unknown | https://x.com/SuiYuanQi/status/2114496716036833457 | 线索 |

数据文件：`evidence_ledger_20261031.jsonl`（同内容的机器可读版，字段：id/type/title/url/date/license/license_class/products/grade/url_status/flag/takeaway_zh/retrieved）。
