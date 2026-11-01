# 资料汇总与优化成果 — 四产品研究摘要（2026-11-01）

- 范围：顺时/SEASONS、见己/TianJi、分发侠/ContentFlow、新能源/Energy-Intelligence
- 检索面：X（线索）、GitHub、Hugging Face、arXiv/学术会议、官方与监管原文
- 执行：Grok Bot（executor）；开发文档依据：`/workspace/dev_docs/DIGEST.md`
- 原始来源清单（机器可读，31 条）：`/workspace/proj_research/sources_20261101_delta.jsonl`；X 线索：`x_leads_20261101.md`

## 0. 读法与证据分级

| 级别 | 含义 | 能否进用户可见内容 |
|---|---|---|
| A | 官方原文全文（政府/监管机构/标准/原始论文），读过正文 | 经人工审核后可以 |
| B | 转载、律所/媒体解读、作者自报的 README | 只有找到第二来源或原文后才可 |
| C | 二手综述 | 不可，仅作线索 |
| D | 社交平台帖子（X 等） | 仅作线索，必须回到官方原文核实 |

- 本轮所有新增条目一律标「待审核」，用户端不可见；上线仍需具名审核人（见己还需心理学审校人）。
- GitHub / Hugging Face 内容只借鉴设计思路；许可证为 NC / SA / 未标注 的一律不复用代码或数据。
- 没有任何专家签字、企业微信审批或 POLICY_REVIEWERS 被伪造或填写。

## 1. 最重要的发现（先看这里）

1. **顺时旧知识库将在 2026-11-30 整体过期**：旧中文库 valid_until=2026-11-30，之后 230 个中文片段中有 224 个会被新鲜度规则丢弃。另一个修复执行器的 B13 已把 4 份旧文档移出运行时、只留 11 个已核实片段 + 待审核文档；旧库只作评测夹具（`SHUNSHI_KB_LEGACY_EVAL=1`）。真正的补救是尽快审核通过一批官方来源（节气表、膳食指南、卫健委食养指南、WHO/CDC 等）。
2. **IRS Notice 2025-42 已被法院撤销**：D.D.C. 于 2026-06-06 在 Oregon Environmental Council v. IRS 中撤销该通知，恢复 5% 安全港（来源：McGuireWoods 提示，B 级；未读到法院原文）。新能源国际版相关条目已改为"已被撤销"，且闸门在读到法院原文之前一律拒绝上线。
3. **顺时 2026 节气表 24/24 与紫金山天文台《2026 年日历资料》一致**（误差 ≤1 分钟，香港天文台同表交叉核对）。已生成待审核条目 ss-lib-s11 和回归测试，防止以后节气数据被改错。
4. **"变好才上线"闸门自检就拦下一个重复条目**（新能源候选与 en-lib-007 重复），说明去重维度有用。
5. **文献共识：混合检索 + 重排的朴素 RAG 不输"记忆系统"**（Memory Tax, arXiv 2610.34073），重排器偏向语义丰富的旧文档（FRESCO, EMNLP 2026 Findings）——所以我们保留来源日期/失效校验，并把"晋升"变成可测量的闸门（SkillSandbox 2610.10088、Skill-V 2610.11781、SkillForge 2610.09832）。
6. **合规新规已核实原文**：分发侠——《多渠道分发（MCN/代运营）服务规定》令第23号、《微短剧管理办法》令第16号，均 2026-09-01 施行；见己——《拟人化互动办法》令第21号（2026-07-15 施行）此前已入内部依据库；欧盟 AI Act 第 50 条自 2026-08-02 适用（第 50(2) 条存量系统宽限至 2026-12-02）。
7. **可能的真实 sk- 密钥**：另一个执行器在 Mac 的 `99_归档/八产品代码层审查报告` 文档里看到一个形似 sk- 的字符串（副本里已涂掉）。未打印、未验证真伪；建议你自行确认并视情况作废该密钥。

## 2. 顺时 / SEASONS（节气 · 情绪记录 · 冥想；非医疗）

### 2.1 来源（含链接）
| 来源 | 级别 | 用途 |
|---|---|---|
| 紫金山天文台《2026 年日历资料》 https://pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf | A | 节气表权威来源；24/24 与我们的数据一致 |
| 香港天文台 2026 公历农历对照表 https://www.weather.gov.hk/tc/gts/time/calendar/pdf/files/2026.pdf | A | 交叉核对 |
| NCCIH 冥想与正念：效果与安全 https://www.nccih.nih.gov/health/meditation-and-mindfulness-effectiveness-and-safety | A | 国际版冥想内容的风险提示（约 8% 报告负面体验，不能替代常规医疗） |
| WHO 2020 身体活动指南 https://www.who.int/publications/i/item/9789240015128 | A | SEASONS 运动/作息内容候选 |
| CDC 睡眠 https://www.cdc.gov/sleep/about/ | A | 同上 |
| Memory Tax arXiv 2610.34073；TimelyRAG 2609.11572；FRESCO | A | 检索设计 |
| MTCMB 基准（GitHub Apache-2.0 / Zenodo CC-BY-4.0；HF 镜像无许可，不用） https://github.com/Wayyuanyuan/MTCMB | B | 评测思路，含中药/针灸安全题；未入库 |
| X 上"药食同源"盘点（D 级线索） | D | 回到卫健委原文核实；品牌号的功效宣传一律排除 |

### 2.2 采纳了什么、为什么
- **混合检索**（BM25，标题×3，CJK 二元组 + jieba，与原 TF-IDF 用 RRF k=60 融合）+ **口语别名扩展**。原因：旧检索只有 TF-IDF + 标题加权，对"睡不着怎么办"这类口语问法召回弱。有 RAG_HYBRID / RAG_ALIASES 两个关停开关。
- **口语问法评测集**（dev + 留出集分开，留出集从未用于调参）和**棘轮基线**：以后任何改动不得低于 after。
- **晋升闸门 + 版本发布/回滚 + 周任务 promote_gate**（见第 6 节）。
- **节气表待审核条目 ss-lib-s11** + 回归测试（PMO 与 HKO 对照）。
- 评测前后对照（Recall@5 / MRR）：

| 集合 | 指标 | 之前（TF-IDF） | 之后（混合） |
|---|---|---|---|
| 中文 dev（n=48） | R@5 / MRR | 0.6875 / 0.568 | 0.8542 / 0.671 |
| 中文留出（n=24） | R@5 / MRR | 0.5833 / 0.500 | 0.7083 / 0.615 |
| 英文 dev（n=26） | R@5 / MRR | 0.6923 / 0.474 | 0.8462 / 0.603 |
| 英文留出（n=12） | R@5 / MRR | 0.8333 / 0.517 | **0.7500** / 0.544 |

- **如实说明**：英文留出集 R@5 从 0.833 降到 0.750（n=12，只差 1 条问法），R@1/R@3/MRR 仍提升；保留混合检索，棘轮基线记录的是实测的 0.75，不掩盖。
- 全量后端测试：4143 通过、0 失败、155 个 errors（环境：redis/postgres/reportlab 不可用；与修复执行器基线的 156 个同源）。

### 2.3 没采纳 / 为什么
- 中医"功效"类内容、品牌号的药膳宣传：违反"顺时不是健康/医疗/养生产品"的定位（DIGEST §1），且需第二来源。
- VersionRAG（GitHub 89799969/VersionRAG，作者自报指标、许可证未确认）：只借"整版发布与回滚"的设计，不复用代码。

## 3. 见己 / TianJi（国内路径 B：自我觉察；国际：另库）

### 3.1 来源
| 来源 | 级别 | 用途 |
|---|---|---|
| 《人工智能拟人化互动服务管理暂行办法》令第21号 https://www.cac.gov.cn/2026-04/10/c_1777558395078289.htm | A | 已在内部合规依据库（internal，不展示给用户） |
| EC 第 50 条 FAQ https://digital-strategy.ec.europa.eu/en/faqs/transparency-obligations-under-article-50-ai-act | A | 国际版 TianJi 透明度义务（AI 披露、内容标记；2026-08-02 起，50(2) 存量宽限至 2026-12-02） |
| California SB 243（leginfo） https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260SB243 | B | 陪伴型聊天机器人：AI 披露、自伤危机转介、未成年人休息提醒；法条原文本轮未读，故 B 级 |
| GitHub Renhuai123/ziwei-doushu（代码 MIT；数据集 CC BY 4.0；"倪师原话"部分 CC BY-NC-SA 不可商用） https://github.com/Renhuai123/ziwei-doushu | B | 仅作排盘引擎的边界用例参考（真太阳时/夏令时/闰月/立春）；解读数据批量生成，不入库 |
| SylarLong/iztro（MIT）、6tail/lunar-javascript（MIT） | B | 排盘库参考，见己国内栈不含命理，故不引入 |
| X 上"AI 连玄学都 Skill 化"（D 级） | D | 仅趋势；与国内栈"不含命理代码与语料"冲突，不采纳 |

### 3.2 采纳了什么、为什么
- 把**晋升闸门、版本发布/回滚、promote_gate 周任务**移植到 svc-growth（PR #93 已合并）；**内部合规依据（internal=true）永远不过闸门、不进用户库**；审核仍要"审核人 + 心理学审校人"两个不同的人。
- 没有新增国内条目：本轮没有新的官方心理类原文通过读取校验，宁缺毋滥。没有新增国际英文条目：见己目前只有国内中文库，英文内容不混入。

### 3.3 没采纳 / 为什么
- SB 243 条目：条文未读，B 级，闸门要求第二来源 —— 留在研究摘要里，等读到原文再入库。
- 任何命理语料与代码：国内栈 D4/D7 明确不得含命理（主体级风险）。

## 4. 分发侠 / ContentFlow（内容创作 · 多平台分发 · 合规）

### 4.1 来源
| 来源 | 级别 | 用途 |
|---|---|---|
| 《多渠道分发（MCN/代运营）服务规定》令第23号 https://www.cac.gov.cn/2026-05/29/c_1781795864412597.htm | A | 条目 cf-rule-s01（待审核） |
| 《微短剧管理办法》令第16号 https://www.nrta.gov.cn/art/2026/7/31/art_1588_73827.html | A | 条目 cf-rule-s02（待审核） |
| GitHub dreammis/social-auto-upload（MIT，抖音/小红书/视频号自动发布） https://github.com/dreammis/social-auto-upload | B | 仅作设计参考；自动化登录各平台有 ToS 风险，**不采纳** |
| TimelyRAG（arXiv 2609.11572） | A | 对"重叠、演化的法规"做语义 + 时间重排 |

### 4.2 采纳了什么、为什么
- 2 条新规待审核条目（各带 4 条口语问法，如"MCN 机构要备案吗""微短剧片头要标什么"），来源白名单补入 cac.gov.cn / nrta.gov.cn。适用边界仍需律师意见（DIGEST：多渠道分发规定需法务判断）。
- BM25（标题×3）与原关键词法 RRF 融合 + 晋升闸门 + 发布链/回滚 + promote_gate 周任务（PR #65 已合并）。
- 保留：国内库只在国内版开放（DomesticOnlyGuard），不建境外分发库。

## 5. 新能源 / Energy-Intelligence（政策 · 电价 · 储能 · 光伏 · 碳）

### 5.1 来源
| 来源 | 级别 | 用途 |
|---|---|---|
| 国家能源局 2026 年 1–9 月电力统计（装机 41.3 亿 kW +11.2%；太阳能 13.1 亿；风电 7.0 亿） https://www.nea.gov.cn/20261026/7e48f52542c94c0f99c166262453627d/c.html | A | 已有同类条目 en-lib-007，闸门判重复，未重复入库 |
| 国家能源局 9 月绿证核发/交易 https://www.nea.gov.cn/20261029/07750da8d7d641d0a50071cdccd3c7e5/c.html | A | en-lib-s04 |
| 国家发改委《电力现货市场基本规则（公开征求意见稿）》公告 https://yyglxxbsgw.ndrc.gov.cn/htmls/article/article.html?articleId=2c97d16c-9ff00a63-01a1-524711ba-002f | A（仅公告页，附件未读） | en-lib-s05（征求意见 2026-10-19 至 11-18，拟 2027-01-01 施行） |
| IEA Global Energy Review 2026 https://www.iea.org/reports/global-energy-review-2026/key-findings | A | en-intl-s01（2025 光伏 +600TWh；储能新增 108GW） |
| EU CBAM 正式期 https://taxation-customs.ec.europa.eu/carbon-border-adjustment-mechanism/cbam-definitive-regime_en | A | en-intl-s02（2026-01-01 起；证书 2027-02 起销售） |
| IRS Notice 2025-42 https://www.irs.gov/pub/irs-drop/n-25-42.pdf + McGuireWoods 撤销提示 | A + B | en-intl-s03（B 级，闸门拒绝，需法院原文） |
| Ember Global Electricity Review 2026（电池成本 −45%） | B | 暂不入库，需第二来源 |
| 生态环境部 2025 年第 47 号公告 | A | 碳市场线索，本轮未生成条目 |
| X 帖（装机、绿证、现货规则等） | D | 仅线索，全部回到官方页核实；A 股题材/投资炒作类全部排除 |

### 5.2 采纳了什么、为什么
- 国内 2 条 + 国际 3 条待审核条目；所有条目的"读取范围"如实标注（例如附件未读）。
- 晋升闸门（证据/安全/对照/去重）、版本发布与回滚、promote_gate 周任务、BM25 融合（PR #81 已合并，**仅合并到 fixes/energy-p0-2026-10-15，没有碰 main**）。
- 金标准评测的"库问答器"改成 gram + BM25 的 RRF 融合：单用 BM25 会让新条目抢答已有用例（en-g-002 回退），融合后金标准恢复。
- 三条底线（不荐股/不承诺收益/不做评级）在闸门安全分里对应词族。

### 5.3 测试
- 新增 `test_research_c_20261101.py`；全量 pytest 1258 通过，2 个失败为环境问题（live smoke HTTP 402、public_ingestion fixtures），基线同样失败。

## 6. 持续自我改进机制（四产品共用的设计）

### 6.1 一周怎么跑
| 任务 | 时间（Asia/Shanghai） | 做什么 |
|---|---|---|
| library-check | 每天 02:00 | 资料库健康/过期检查 |
| stale 扫描 | 每天 02:30 | 陈旧条目 |
| 金标准评测 | 周日 03:30 | 自动评测，回归即告警 |
| library-discover | 周日 03:00 | 发现候选来源 |
| radar | 周三 05:00 | 抓取官方来源线索 |
| radar_stage | 周三 06:00 | 把线索暂存为候选 |
| **promote_gate（本轮新增）** | 周三 07:00 | 对暂存候选逐条跑闸门，写 promote_gate_report，对新的 keep 写待办 |
| 月报 | 每月 1 日 05:00 | 汇总评测、候选、审核、陈旧 |

### 6.2 "变好才上线"闸门（只出结论，不自动上线）
- 证据分 ≥ 0.85：A=1.0；B 最多 0.9 且需第二来源；D=0；还要求 https、来源标题与出版方、读取范围、发布日期与检索日期、白名单域名、距今 ≤120 天。
- 安全分 ≥ 0.85：词族（医学/收益/命定论/绝对化等）命中即拒；"不能替代医生"之类否定式免责不误伤；必须有 caution。
- 对照：候选自带 ≥2 条口语问法，Top3 命中 ≥2/3，已有条目的问法零回退。
- 去重：id / url / 文号。
- 人工：keep 之后仍需具名审核人 approve（见己 + 心理学审校人）；`LIBRARY_PROMOTE_GATE=1` 时 approve 必须先过闸门（出厂关闭）。

### 6.3 发布与回滚
- 每次审核动作写完整快照 + 哈希链（releases/NNNN.json + index.jsonl）；`verify` 校验链；`rollback` 追加一条回滚记录，需审核人和原因，链断裂拒绝回滚。

### 6.4 个性化推送
- 已有：顺时 feed、新能源 library feed、分发侠 library feed（按用户偏好选内容）；本轮没有改动，也没有新增个性化逻辑。

### 6.5 出厂开关（全部保持关闭）
SIL_ENABLED=0；POLICY_REVIEWERS 为空；LIBRARY_FRESHNESS_ENABLED 关；LIBRARY_PROMOTE_GATE 关；expert_signed=false。机制已完整并在测试里打开验证，但出厂不启用，需要人来开。

## 7. 合并情况
| 仓库 | PR | 目标 | 合并提交 | 状态 |
|---|---|---|---|---|
| contentflow | #65 | main | 75a2a32f | 已合并（merge，锁定 head sha 965fb572，祖先校验通过） |
| energy-intelligence | #81 | fixes/energy-p0-2026-10-15 | cac9c116 | 已合并（main 未动，仍为 b0243bb） |
| jianji-tianji | #93 | main | c44c4a31 | 已合并（锁定 head sha c72ef95d） |
| shunshi | （见下） | main | — | 修复执行器的 PR #74（B03/B20/B13…）已先合并（72d343cf）；我在其之上 rebase 后提交本 PR，合并后在此补上编号与合并提交 |

- contentflow 的 GitHub CI 在 main 上本来就红（Production dependency audit、Validate deployed runtime、CN/INT language isolation），本 PR 的失败步骤与 main 完全相同，没有新增失败；本地 jest 全绿。

## 8. 与开发文档的偏离及原因
1. **只合并，不上线**：所有新内容为"待审核"；DIGEST 要求"知识发布需具名审核人 + 分数 ≥0.85 + 回滚目标"——闸门分数与回滚都已做，但审核人由你指定，我没有填 POLICY_REVIEWERS，也没有伪造签字。
2. **B 级内容未入库**：DIGEST"高风险来源 ≥2 个"——SB 243、Ember、IRS 撤销相关只有单一二手来源，我没有降低门槛，B 级条目留在待审核且闸门拒绝（只有 IRS 条目作为"已被撤销"的提示入暂存）。
3. **见己不新增国际英文条目**：见己目前只有国内中文库，国际版需单独的英文库（国内全中文、国际全英文），本轮未建，避免语言混用。
4. **分发侠不建境外分发库**：DIGEST 规定国内合规库仅国内；多渠道分发规定的适用边界仍要律师意见。
5. **顺时定位**：不是健康/医疗/养生产品——节气表条目 caution 里显式写明"不含养生功效承诺"；药食同源/药膳类社交内容全部排除。
6. **个性化**：DIGEST 要求"每张卡有 why / 不再推荐"——本轮没有改动个性化代码，保持现状，未新增。
7. **评测的 legacy 夹具**：另一执行器的 PR #74（B13）把旧库移出运行时，只留作评测夹具（`SHUNSHI_KB_LEGACY_EVAL=1` / `include_legacy=True`）；我的口语问法评测集在其之上改为显式 `include_legacy=True`，所以评测数字是在旧库夹具上测的检索质量，不代表线上运行时（线上现在只有 11 个已核实片段 + 待审核文档）。
8. **只借思路、不复用代码**：VersionRAG 许可证未确认；ziwei-doushu 含 CC BY-NC-SA 部分；social-auto-upload 涉及自动登录各平台——均不复用。

## 9. 需要人来做的事
1. 指定 POLICY_REVIEWERS 并逐条审核待审核条目（节气表、绿证、现货规则征求稿、CBAM、IEA、两条分发新规）。
2. 见己：心理学审校人签字；顺时：营养/中医专家对食养类内容签字（expert_signed 目前 false）。
3. 分发侠：请律师就《多渠道分发规定》对我们产品的适用范围出意见。
4. 新能源：读取发改委现货规则征求稿附件、IRS 撤销的法院原文，再让对应条目过闸门。
5. 确认疑似 sk- 密钥是否有效并视情况作废。
6. 在需要启用时，由你决定是否打开 SIL_ENABLED / LIBRARY_PROMOTE_GATE（均需先配好审核人）。
