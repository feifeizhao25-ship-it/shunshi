# 评审结论落地：最低年龄 16 + 热线号码统一（2026-10-31）

> **这些选择是助手在用户全权委托下做的**（"你觉得哪个最好就用哪个，全部你来决定"），
> 不是法务 / 运营 / 专家的结论。所有条目 **待专家复核**；下一次热线复核 2027-01-31（每季度）。
> 法务依据仅作参考（PIPL 14 周岁、GDPR 第 8 条默认 16、COPPA 13）；产品下限 16 比它们都严。

## 1. 最低使用年龄统一为 16 周岁（国内版、国际版、所有产品）
- `backend/app/services/age_policy.py`：新增 `MIN_AGE = 16`；<16 直接拒绝（不调模型），16–17 仍走未成年人模式；
  拒绝文案改为 16 周岁。（后端国内/国际共用，所以国际版用户会看到中文拒绝文案——已知限制，待后续按语言区分。）
- `backend/app/router/subscription_local.py` `REGION_COMPLIANCE`：EU/UK 16、US/AU/SG 13、JP 15、KR 14 → 全部 16。
- `backend/app/static/privacy-policy.html`：14 岁以下 → 16 周岁以下。
- 国内 App（ios-cn / android-cn）：医疗免责声明、隐私政策 14→16；订阅页「年满18周岁」→「年满16周岁；16–17 周岁应在监护人知情同意下使用」。
- 国际 App（ios-global / android-global）：隐私政策新增 "Minimum age"、服务条款新增 "Eligibility"（16+）；
  帮助中心 FAQ 18+ → 16+；医疗免责声明 3.4 改为 16；**ios-global 的医疗免责声明原本是中文，已换成与 android-global 一致的英文版**。
- 未改动：`rag/personalizer.py`、`youth_wellness.py`、`lifecycle_engine.py` 里的年龄区间（内容个性化用，不是准入门槛）。

## 2. 热线号码
- 国内版保持后端单一来源：12356 + 120 / 110（后端已无 12320、988、741741）。`config.py` 注释补全文号
  国卫医政函〔2024〕259号（成文 2024-12-06，网站发布 2024-12-25）与"每天不少于 18 小时，具体以当地为准"。
- 国际版：
  - 删除 400-161-9995（希望24热线，中国号码）与「Emergency: 120」；改为"当地急救电话"。
  - 988 只标 US & Canada；741741 标 US only；去掉写死的 911。
  - UK：「111 NHS Mental Health」→ Samaritans 116 123（NHS 111 是非紧急咨询，不是危机热线）。
  - AU：13 11 14 是 Lifeline Australia，不是 Beyond Blue。
  - 本地化 key `chatpagedart_4001619995_…` 更名为 `chatpagedart_crisis_support_subtitle`。
- 新测试 `backend/tests/test_crisis_numbers_by_edition.py`（6 条）：国际版不得出现中国号码 / 120 / NHS 111 / Beyond Blue 误标；
  988/741741 必须标注国家；国内版不得出现国际号码和 12320。

## 3. 没有改的（需要后续人工决定）
- Flutter 页面无法在这里构建，字符串改动由测试扫描保证，未在模拟器里看过。
- 国内版仍只有 12356（未加入 800-810-1117、希望24 等）：后端单一来源测试明确只允许 12356。
