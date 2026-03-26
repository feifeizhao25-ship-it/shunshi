"""
安全守卫配置
SafeGuard Configuration
"""

SAFETY_CONFIG = {
    # 开关
    "enable_input_check": True,
    "enable_output_check": True,
    "log_all_checks": True,

    # 危机热线
    "crisis_hotline_cn": "400-161-9995",       # 全国24小时心理援助热线
    "crisis_hotline_life": "010-82951332",      # 生命热线
    "crisis_hotline_hope": "400-161-9995",      # 希望24热线
    "crisis_hotline_lifeline": "400-821-1215",  # 生命热线(全国)
    "crisis_emergency": "120",                   # 医疗急救
    "crisis_police": "110",                      # 报警

    # 告警阈值
    "max_sensitive_streak": 5,    # 连续N次敏感输入触发告警
    "max_crisis_streak": 3,       # 连续N次危机输入立即告警

    # 医疗边界关键词
    "medical_block_keywords": [
        "吃什么药", "推荐药物", "该吃什么药", "给我开药",
        "帮我诊断", "帮我看看", "是什么病", "得了什么病",
        "怎么治", "怎么治疗", "如何治疗", "需要手术吗",
        "要不要手术", "病情严重吗", "还能活多久",
        "处方", "开处方", "剂量", "服用剂量",
        "药物副作用", "药量", "用药量",
    ],

    # 医疗边界正则
    "medical_block_patterns": [
        r"帮我?(看看|分析|解读|检查).{0,6}(体检|报告|化验|CT|B超|核磁|X光)",
        r"(头疼|头痛|胃痛|胸痛|腹痛).{0,4}该吃什么",
        r"(血压|血糖|心率).{0,4}(正常|偏高|偏低|异常)",
        r"(癌症|肿瘤|恶性肿瘤).{0,4}(能治|怎么治|严重|晚期)",
    ],

    # 危机关键词
    "crisis_keywords": [
        "想死", "不想活", "活着没意思", "想自杀", "自杀",
        "跳楼", "割腕", "吃药自杀", "结束生命",
        "从楼上跳", "不想醒来", "消失算了",
        "死了算了", "不如死", "去死", "寻死",
        "想伤害自己", "伤害自己", "自残", "自尽",
        "撑不下去", "活不下去", "没有活下去的意义",
        "想离开这个世界", "再也不想醒来",
        "让我死", "杀死自己",
        # English crisis keywords (SEASONS Global)
        "want to die", "wanna die", "kill myself", "end my life",
        "suicide", "suicidal", "kill me", "hurt myself",
        "don't want to live", "nothing to live for",
        "better off dead", "self harm", "cutting myself",
        "overdose", "hang myself", "tired of living", "done with life",
        "life is not worth living", "no reason to live",
        "wish i were dead", "wish i was never born",
        "harm myself", "ending it all", "my life is worthless",
        "better dead than alive", "if i died", "when i die",
    ],

    # 情绪困扰关键词
    "distress_keywords": [
        "崩溃", "绝望", "痛苦", "折磨", "窒息",
        "受不了", "扛不住", "撑不住", "太累了",
        "快疯了", "要疯了", "抑郁", "重度抑郁",
        "每天都很痛苦", "不想出门", "害怕出门",
        "没人理解", "没有人关心", "孤独",
        "被抛弃", "被伤害", "被欺负", "被羞辱",
        "无能为力", "无力感", "空虚", "麻木",
        "每天都哭", "控制不住哭", "哭不出来",
        "严重焦虑", "恐慌", "惊恐",
        # English distress keywords (SEASONS Global)
        "lonely", "hopeless", "worthless", "helpless",
        "depressed", "anxious", "overwhelmed", "exhausted",
        "can't cope", "falling apart", "numb", "empty",
        "crying every day", "panic", "miserable",
        "nobody cares", "no one understands", "isolated",
        "giving up", "broken", "out of control",
        "don't want to be here", "want to disappear",
        "feel like nothing", "feeling everything and nothing",
        "heavy heart", "weighed down", "drowning",
        "falling into darkness", "can't breathe",
        "losing my mind", "going insane", "losing control",
        "self-harm", "cutting", "burned out", "at the end of my rope",
    ],

    # 儿童保护关键词
    "child_protection_keywords": [
        "孩子不想活", "小孩自杀", "儿童自残",
        "虐待孩子", "打孩子", "家暴",
    ],

    # 依赖检测关键词
    "dependency_keywords": [
        "你是我的全部", "只有你能帮我", "没人能理解我",
        "不想跟任何人说", "除了你我谁都不信",
    ],

    # 输出违规关键词 — 防止AI生成危险内容
    "output_violation_patterns": [
        r"建议.{0,6}(服用|吃|使用).{0,6}(药|胶囊|片|针|阿莫西林|布洛芬|头孢)",
        r"(你|您)(应该|可以|需要).{0,6}(吃药|服药|用药|服用)",
        r"(诊断|确诊|患病).{0,6}(为|是).{0,6}(病|症)",
        r"(剂量|每日|每次).{0,6}(服用|吃|口服)",
    ],

    # 响应语言
    "default_lang": "cn",
}
