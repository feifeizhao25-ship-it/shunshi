"""
顺时 - 用户生命周期引擎
根据用户出生年份，识别生命阶段，提供个性化的养生建议。

生命阶段定义：
- 青春期 (12-18): 生长发育关键期
- 奋斗期 (19-30): 事业拼搏期
- 稳定期 (31-45): 家庭事业兼顾期
- 成熟期 (46-60): 健康管理重点期
- 银发期 (60+): 养老养生期

作者: Claw 🦅
日期: 2026-03-17
"""

import enum
from datetime import datetime
from typing import Optional, Dict, Any, List


class LifeStage(enum.Enum):
    """生命阶段枚举"""
    ADOLESCENCE = "adolescence"   # 青春期 12-18
    STRIVING = "striving"        # 奋斗期 19-30
    STABLE = "stable"            # 稳定期 31-45
    MATURE = "mature"            # 成熟期 46-60
    SILVER = "silver"            # 银发期 60+


# ==================== 阶段配置 ====================

STAGE_CONFIGS = {
    LifeStage.ADOLESCENCE: {
        "name": "青春期",
        "age_range": "12-18岁",
        "description": "生长发育的关键时期，身体和心理都在快速变化",
        "focus_areas": ["生长发育", "视力保护", "心理调适", "学习压力"],
        "ai_tone": "温暖鼓励，如知心姐姐",
        "recommended_content_types": ["eye_care", "exercise", "nutrition", "sleep"],
        "key_habits": ["规律作息", "户外运动", "均衡营养", "减少屏幕时间"],
        "health_priorities": [
            "保证每天8-9小时睡眠",
            "每天至少1小时户外活动",
            "保护视力，控制电子产品使用",
            "均衡饮食，补充钙质和蛋白质",
        ],
        "avoid": ["熬夜", "过度节食", "久坐不动", "过量咖啡因"],
    },
    LifeStage.STRIVING: {
        "name": "奋斗期",
        "age_range": "19-30岁",
        "description": "事业起步与拼搏的黄金时期，容易忽视健康",
        "focus_areas": ["亚健康调理", "职场压力", "作息管理", "运动习惯"],
        "ai_tone": "理性务实，亦师亦友",
        "recommended_content_types": ["exercise", "sleep", "stress_relief", "nutrition"],
        "key_habits": ["规律运动", "充足睡眠", "健康饮食", "定期体检"],
        "health_priorities": [
            "保持每周3-5次运动习惯",
            "控制熬夜频率，保证7小时睡眠",
            "注意颈椎和腰椎保护",
            "管理压力，预防亚健康",
        ],
        "avoid": ["过度加班", "久坐不动", "外卖依赖", "睡眠不足"],
    },
    LifeStage.STABLE: {
        "name": "稳定期",
        "age_range": "31-45岁",
        "description": "家庭与事业并重，是健康管理的关键转折点",
        "focus_areas": ["慢性病预防", "家庭健康", "压力管理", "体能维持"],
        "ai_tone": "沉稳可靠，健康顾问",
        "recommended_content_types": ["recipe", "exercise", "acupoint", "tips"],
        "key_habits": ["定期体检", "家庭养生", "适度运动", "饮食调理"],
        "health_priorities": [
            "每年全面体检一次",
            "关注血压、血糖、血脂指标",
            "坚持规律运动，控制体重",
            "注意心脑血管健康",
        ],
        "avoid": ["三高饮食", "缺乏运动", "忽视体检", "过度应酬"],
    },
    LifeStage.MATURE: {
        "name": "成熟期",
        "age_range": "46-60岁",
        "description": "健康管理的黄金窗口期，做好养生可以享受高质量晚年",
        "focus_areas": ["慢性病管理", "骨骼关节", "心脑血管", "情志养生"],
        "ai_tone": "关怀体贴，如贴心管家",
        "recommended_content_types": ["recipe", "acupoint", "exercise", "sleep"],
        "key_habits": ["中药调理", "穴位保健", "柔和运动", "规律作息"],
        "health_priorities": [
            "严格管理慢性病指标",
            "保护关节，适量运动",
            "关注心脑血管健康",
            "保持社交活动，预防孤独",
        ],
        "avoid": ["剧烈运动", "高盐高脂饮食", "情绪激动", "过度劳累"],
    },
    LifeStage.SILVER: {
        "name": "银发期",
        "age_range": "60岁以上",
        "description": "养生保健的核心阶段，注重延年益寿和生活品质",
        "focus_areas": ["延年益寿", "慢病管理", "关节保护", "情志调养"],
        "ai_tone": "慈祥温暖，如亲人陪伴",
        "recommended_content_types": ["recipe", "acupoint", "exercise", "tips"],
        "key_habits": ["规律作息", "中药养生", "穴位按摩", "适度运动"],
        "health_priorities": [
            "坚持低盐低脂饮食",
            "每天适度运动30分钟",
            "定期监测血压血糖",
            "保持良好心态和社交",
        ],
        "avoid": ["过度劳累", "独自外出", "暴饮暴食", "情绪波动"],
    },
}

STAGE_CONFIGS_EN = {
    LifeStage.ADOLESCENCE: {
        "name": "Adolescence",
        "age_range": "12-18 years",
        "description": "A critical period of growth and development, with rapid physical and psychological changes",
        "focus_areas": ["Growth & Development", "Vision Protection", "Mental Wellness", "Study Stress"],
        "ai_tone": "Warm and encouraging, like a caring mentor",
        "recommended_content_types": ["eye_care", "exercise", "nutrition", "sleep"],
        "key_habits": ["Regular sleep schedule", "Outdoor activities", "Balanced nutrition", "Reduced screen time"],
        "health_priorities": [
            "Ensure 8-9 hours of sleep daily",
            "At least 1 hour of outdoor activity daily",
            "Protect vision, limit electronic device usage",
            "Balanced diet with adequate calcium and protein",
        ],
        "avoid": ["Staying up late", "Crash dieting", "Prolonged sitting", "Excessive caffeine"],
    },
    LifeStage.STRIVING: {
        "name": "Career Building",
        "age_range": "19-30 years",
        "description": "The golden period for career development, where health is easily overlooked",
        "focus_areas": ["Sub-health Management", "Workplace Stress", "Sleep Management", "Exercise Habits"],
        "ai_tone": "Practical and rational, like a trusted advisor",
        "recommended_content_types": ["exercise", "sleep", "stress_relief", "nutrition"],
        "key_habits": ["Regular exercise", "Adequate sleep", "Healthy eating", "Regular health checkups"],
        "health_priorities": [
            "Maintain 3-5 exercise sessions per week",
            "Limit late nights, ensure 7 hours of sleep",
            "Protect neck and lower back",
            "Manage stress, prevent sub-health conditions",
        ],
        "avoid": ["Excessive overtime", "Prolonged sitting", "Takeout dependency", "Sleep deprivation"],
    },
    LifeStage.STABLE: {
        "name": "Peak Balance",
        "age_range": "31-45 years",
        "description": "Balancing family and career, a key turning point for health management",
        "focus_areas": ["Chronic Disease Prevention", "Family Wellness", "Stress Management", "Fitness Maintenance"],
        "ai_tone": "Steady and reliable, like a health consultant",
        "recommended_content_types": ["recipe", "exercise", "acupoint", "tips"],
        "key_habits": ["Regular health checkups", "Family wellness routines", "Moderate exercise", "Dietary therapy"],
        "health_priorities": [
            "Annual comprehensive health checkup",
            "Monitor blood pressure, blood sugar, and lipids",
            "Maintain regular exercise and healthy weight",
            "Pay attention to cardiovascular and cerebrovascular health",
        ],
        "avoid": ["High sodium, sugar, and fat diet", "Lack of exercise", "Skipping checkups", "Excessive social drinking"],
    },
    LifeStage.MATURE: {
        "name": "Wisdom & Vitality",
        "age_range": "46-60 years",
        "description": "A golden window for health management — proper care ensures a high-quality later life",
        "focus_areas": ["Chronic Disease Management", "Bone & Joint Health", "Cardiovascular Care", "Emotional Wellness"],
        "ai_tone": "Caring and considerate, like a dedicated butler",
        "recommended_content_types": ["recipe", "acupoint", "exercise", "sleep"],
        "key_habits": ["Herbal remedies", "Acupoint self-care", "Gentle exercise", "Regular routine"],
        "health_priorities": [
            "Strictly manage chronic disease indicators",
            "Protect joints with appropriate exercise",
            "Focus on cardiovascular and cerebrovascular health",
            "Stay socially active and prevent loneliness",
        ],
        "avoid": ["Intense exercise", "High salt and fat diet", "Emotional volatility", "Overexertion"],
    },
    LifeStage.SILVER: {
        "name": "Golden Years",
        "age_range": "60+ years",
        "description": "The core stage of wellness care, focusing on longevity and quality of life",
        "focus_areas": ["Longevity", "Chronic Disease Care", "Joint Protection", "Emotional Harmony"],
        "ai_tone": "Warm and affectionate, like family companionship",
        "recommended_content_types": ["recipe", "acupoint", "exercise", "tips"],
        "key_habits": ["Regular daily routine", "Herbal wellness", "Acupoint massage", "Moderate exercise"],
        "health_priorities": [
            "Maintain a low-salt, low-fat diet",
            "30 minutes of moderate exercise daily",
            "Regularly monitor blood pressure and blood sugar",
            "Stay positive and socially connected",
        ],
        "avoid": ["Overexertion", "Going out alone", "Overeating", "Emotional extremes"],
    },
}


# ==================== 节气调整建议 ====================

SEASONAL_ADJUSTMENTS: Dict[str, Dict[str, List[Dict[str, Any]]]] = {
    # 春季节气
    "立春": {
        "focus": "养肝护肝，疏肝理气",
        "by_stage": {
            "adolescence": [
                {"suggestion": "多吃绿色蔬菜，养肝明目", "type": "diet"},
                {"suggestion": "户外踏青，舒展筋骨", "type": "exercise"},
            ],
            "striving": [
                {"suggestion": "少熬夜，春季养肝最佳时间23点前入睡", "type": "sleep"},
                {"suggestion": "每天10分钟拉伸，疏肝理气", "type": "exercise"},
            ],
            "stable": [
                {"suggestion": "枸杞菊花茶养肝", "type": "diet"},
                {"suggestion": "太冲穴按摩疏肝", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "饮食清淡，保护肝脏", "type": "diet"},
                {"suggestion": "太极拳调畅气血", "type": "exercise"},
            ],
            "silver": [
                {"suggestion": "注意倒春寒，及时添衣", "type": "care"},
                {"suggestion": "散步调畅气血", "type": "exercise"},
            ],
        },
    },
    "清明": {
        "focus": "养肺润燥，调畅情志",
        "by_stage": {
            "adolescence": [
                {"suggestion": "春游踏青，调节情绪", "type": "exercise"},
                {"suggestion": "多食梨和银耳润肺", "type": "diet"},
            ],
            "striving": [
                {"suggestion": "利用假期充分休息", "type": "care"},
                {"suggestion": "踏青运动缓解工作压力", "type": "exercise"},
            ],
            "stable": [
                {"suggestion": "注意过敏防护", "type": "care"},
                {"suggestion": "百合银耳羹润肺", "type": "diet"},
            ],
            "mature": [
                {"suggestion": "注意花粉过敏", "type": "care"},
                {"suggestion": "散步养心", "type": "exercise"},
            ],
            "silver": [
                {"suggestion": "出行注意安全", "type": "care"},
                {"suggestion": "在家也可做呼吸练习", "type": "exercise"},
            ],
        },
    },
    "谷雨": {
        "focus": "健脾祛湿，强健脾胃",
        "by_stage": {
            "adolescence": [
                {"suggestion": "薏米红豆粥祛湿", "type": "diet"},
                {"suggestion": "注意防潮，保持衣物干燥", "type": "care"},
            ],
            "striving": [
                {"suggestion": "减少生冷食物，保护脾胃", "type": "diet"},
                {"suggestion": "避免久坐潮湿环境", "type": "care"},
            ],
            "stable": [
                {"suggestion": "山药薏米粥健脾", "type": "diet"},
                {"suggestion": "三阴交穴健脾祛湿", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "饮食温热，少吃寒凉", "type": "diet"},
                {"suggestion": "足三里艾灸强脾胃", "type": "acupoint"},
            ],
            "silver": [
                {"suggestion": "防潮保暖，预防风湿", "type": "care"},
                {"suggestion": "温水泡脚祛湿", "type": "care"},
            ],
        },
    },
    # 夏季节气
    "立夏": {
        "focus": "养心安神，清热解暑",
        "by_stage": {
            "adolescence": [
                {"suggestion": "多喝水，注意防暑降温", "type": "care"},
                {"suggestion": "避免午后剧烈运动", "type": "exercise"},
            ],
            "striving": [
                {"suggestion": "莲子百合粥养心", "type": "diet"},
                {"suggestion": "内关穴按摩安神", "type": "acupoint"},
            ],
            "stable": [
                {"suggestion": "绿豆汤消暑", "type": "diet"},
                {"suggestion": "调整作息，适当午休", "type": "sleep"},
            ],
            "mature": [
                {"suggestion": "注意心脑血管，避免高温", "type": "care"},
                {"suggestion": "清淡饮食，少油少盐", "type": "diet"},
            ],
            "silver": [
                {"suggestion": "避免中午外出", "type": "care"},
                {"suggestion": "及时补充水分", "type": "care"},
            ],
        },
    },
    "小满": {
        "focus": "清热利湿，注意皮肤病",
        "by_stage": {
            "adolescence": [
                {"suggestion": "注意皮肤清洁", "type": "care"},
                {"suggestion": "吃苦味蔬菜清心火", "type": "diet"},
            ],
            "striving": [
                {"suggestion": "空调温度不要太低", "type": "care"},
                {"suggestion": "冬瓜汤清热利湿", "type": "diet"},
            ],
            "stable": [
                {"suggestion": "饮食清淡，避免上火", "type": "diet"},
                {"suggestion": "适量运动排汗祛湿", "type": "exercise"},
            ],
            "mature": [
                {"suggestion": "注意湿疹和皮肤病", "type": "care"},
                {"suggestion": "保持皮肤干燥清洁", "type": "care"},
            ],
            "silver": [
                {"suggestion": "防暑降温", "type": "care"},
                {"suggestion": "衣物透气舒适", "type": "care"},
            ],
        },
    },
    "芒种": {
        "focus": "养心健脾，注意补水",
        "by_stage": {
            "adolescence": [
                {"suggestion": "注意劳逸结合", "type": "care"},
                {"suggestion": "补充水分和电解质", "type": "diet"},
            ],
            "striving": [
                {"suggestion": "避免暴晒", "type": "care"},
                {"suggestion": "适当午休，养心气", "type": "sleep"},
            ],
            "stable": [
                {"suggestion": "苦瓜清热解暑", "type": "diet"},
                {"suggestion": "神门穴安神助眠", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "控制血压，注意心脏健康", "type": "care"},
                {"suggestion": "减少盐分摄入", "type": "diet"},
            ],
            "silver": [
                {"suggestion": "注意防暑", "type": "care"},
                {"suggestion": "少食多餐，易消化", "type": "diet"},
            ],
        },
    },
    "夏至": {
        "focus": "养阳固本，冬病夏治",
        "by_stage": {
            "adolescence": [
                {"suggestion": "避免贪凉过度", "type": "care"},
                {"suggestion": "适当运动增强体质", "type": "exercise"},
            ],
            "striving": [
                {"suggestion": "三伏天注意冬病夏治", "type": "care"},
                {"suggestion": "温水淋浴，避免冷水澡", "type": "care"},
            ],
            "stable": [
                {"suggestion": "姜枣茶温阳散寒", "type": "diet"},
                {"suggestion": "三伏贴冬病夏治", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "保护关节，避免空调直吹", "type": "care"},
                {"suggestion": "艾灸督脉养阳", "type": "acupoint"},
            ],
            "silver": [
                {"suggestion": "避免冷热交替过大", "type": "care"},
                {"suggestion": "室内保持通风", "type": "care"},
            ],
        },
    },
    # 秋季节气
    "立秋": {
        "focus": "润肺养阴，防止秋燥",
        "by_stage": {
            "adolescence": [
                {"suggestion": "防止秋燥，多喝温水", "type": "diet"},
                {"suggestion": "开始调整作息，早睡早起", "type": "sleep"},
            ],
            "striving": [
                {"suggestion": "梨子银耳润肺", "type": "diet"},
                {"suggestion": "减少空调使用", "type": "care"},
            ],
            "stable": [
                {"suggestion": "沙参麦冬汤养阴润肺", "type": "diet"},
                {"suggestion": "尺泽穴清肺热", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "注意呼吸道保护", "type": "care"},
                {"suggestion": "滋阴润燥为主", "type": "diet"},
            ],
            "silver": [
                {"suggestion": "注意秋季腹泻", "type": "care"},
                {"suggestion": "适当增减衣物", "type": "care"},
            ],
        },
    },
    "白露": {
        "focus": "滋阴润燥，注意保暖",
        "by_stage": {
            "adolescence": [
                {"suggestion": "注意早晚温差", "type": "care"},
                {"suggestion": "防止感冒", "type": "care"},
            ],
            "striving": [
                {"suggestion": "早睡早起与秋同步", "type": "sleep"},
                {"suggestion": "防止秋乏", "type": "care"},
            ],
            "stable": [
                {"suggestion": "白露身不露，注意保暖", "type": "care"},
                {"suggestion": "百合粥润肺", "type": "diet"},
            ],
            "mature": [
                {"suggestion": "保护关节防寒", "type": "care"},
                {"suggestion": "泡脚养生开始", "type": "care"},
            ],
            "silver": [
                {"suggestion": "注意保暖防寒", "type": "care"},
                {"suggestion": "泡脚温阳", "type": "care"},
            ],
        },
    },
    "秋分": {
        "focus": "阴阳平衡，平和养生",
        "by_stage": {
            "adolescence": [
                {"suggestion": "平衡饮食，不偏食", "type": "diet"},
                {"suggestion": "秋季运动适中", "type": "exercise"},
            ],
            "striving": [
                {"suggestion": "饮食阴阳平衡", "type": "diet"},
                {"suggestion": "运动不宜大汗淋漓", "type": "exercise"},
            ],
            "stable": [
                {"suggestion": "秋天适合登山赏景", "type": "exercise"},
                {"suggestion": "保持情绪平和", "type": "care"},
            ],
            "mature": [
                {"suggestion": "注意血压波动", "type": "care"},
                {"suggestion": "保持心态平和", "type": "care"},
            ],
            "silver": [
                {"suggestion": "注意秋燥便秘", "type": "care"},
                {"suggestion": "多食蜂蜜润肠", "type": "diet"},
            ],
        },
    },
    # 冬季节气
    "立冬": {
        "focus": "养藏固本，温补阳气",
        "by_stage": {
            "adolescence": [
                {"suggestion": "注意保暖，预防感冒", "type": "care"},
                {"suggestion": "适当进补", "type": "diet"},
            ],
            "striving": [
                {"suggestion": "冬天早睡晚起", "type": "sleep"},
                {"suggestion": "羊肉汤温补", "type": "diet"},
            ],
            "stable": [
                {"suggestion": "冬季进补好时机", "type": "diet"},
                {"suggestion": "关元穴艾灸温阳", "type": "acupoint"},
            ],
            "mature": [
                {"suggestion": "注意心脑血管保护", "type": "care"},
                {"suggestion": "冬至进补膏方", "type": "diet"},
            ],
            "silver": [
                {"suggestion": "注意防滑保暖", "type": "care"},
                {"suggestion": "减少外出频率", "type": "care"},
            ],
        },
    },
    "冬至": {
        "focus": "冬至大如年，进补养藏",
        "by_stage": {
            "adolescence": [
                {"suggestion": "冬至吃饺子汤圆", "type": "diet"},
                {"suggestion": "注意保暖", "type": "care"},
            ],
            "striving": [
                {"suggestion": "冬至开始数九", "type": "care"},
                {"suggestion": "当归羊肉汤温补", "type": "diet"},
            ],
            "stable": [
                {"suggestion": "冬至是进补的最佳时机", "type": "diet"},
                {"suggestion": "膏方调理", "type": "diet"},
            ],
            "mature": [
                {"suggestion": "冬至养生重中之重", "type": "care"},
                {"suggestion": "涌泉穴按摩补肾", "type": "acupoint"},
            ],
            "silver": [
                {"suggestion": "注意室内保暖", "type": "care"},
                {"suggestion": "汤水进补", "type": "diet"},
            ],
        },
    },
    "大寒": {
        "focus": "防寒保暖，迎接春天",
        "by_stage": {
            "adolescence": [
                {"suggestion": "寒假注意作息规律", "type": "sleep"},
                {"suggestion": "预防流感", "type": "care"},
            ],
            "striving": [
                {"suggestion": "春节前注意休息", "type": "care"},
                {"suggestion": "准备迎接春暖花开", "type": "care"},
            ],
            "stable": [
                {"suggestion": "大寒养生最后冲刺", "type": "diet"},
                {"suggestion": "为春季养生做准备", "type": "care"},
            ],
            "mature": [
                {"suggestion": "防寒保暖第一位", "type": "care"},
                {"suggestion": "监测血压血糖", "type": "care"},
            ],
            "silver": [
                {"suggestion": "减少外出，注意保暖", "type": "care"},
                {"suggestion": "居家养生", "type": "care"},
            ],
        },
    },
}


# ==================== 作息建议 ====================

DAILY_RHYTHMS: Dict[LifeStage, Dict[str, Any]] = {
    LifeStage.ADOLESCENCE: {
        "sleep": {
            "bedtime": "22:00",
            "wake_time": "06:30",
            "hours": 8.5,
            "note": "青春期需要充足睡眠促进生长发育",
        },
        "meals": {
            "breakfast": "07:00",
            "lunch": "12:00",
            "dinner": "18:00",
            "note": "三餐规律，补充钙质和蛋白质",
        },
        "exercise": {
            "best_time": "16:00-18:00",
            "duration": "30-60分钟",
            "types": ["跑步", "篮球", "游泳", "骑车"],
            "note": "青春期是骨骼发育关键期，多做户外运动",
        },
        "study_work": {
            "best_time": "08:00-11:30, 14:00-17:00",
            "note": "利用大脑高效时段学习",
        },
    },
    LifeStage.STRIVING: {
        "sleep": {
            "bedtime": "23:00",
            "wake_time": "07:00",
            "hours": 8.0,
            "note": "尽量保证7-8小时睡眠，减少熬夜",
        },
        "meals": {
            "breakfast": "07:30",
            "lunch": "12:00",
            "dinner": "18:30",
            "note": "按时吃饭，减少外卖频率",
        },
        "exercise": {
            "best_time": "18:00-20:00",
            "duration": "30-45分钟",
            "types": ["跑步", "健身", "瑜伽", "游泳"],
            "note": "下班后运动，释放工作压力",
        },
        "study_work": {
            "best_time": "09:00-12:00, 14:00-18:00",
            "note": "劳逸结合，每工作1小时休息10分钟",
        },
    },
    LifeStage.STABLE: {
        "sleep": {
            "bedtime": "22:30",
            "wake_time": "06:30",
            "hours": 8.0,
            "note": "规律作息，养生从睡眠开始",
        },
        "meals": {
            "breakfast": "07:00",
            "lunch": "12:00",
            "dinner": "18:00",
            "note": "控制饮食量，注意营养均衡",
        },
        "exercise": {
            "best_time": "06:30-07:30 或 18:00-19:00",
            "duration": "30-45分钟",
            "types": ["快走", "慢跑", "太极拳", "游泳"],
            "note": "坚持规律运动，每周至少3次",
        },
        "study_work": {
            "best_time": "09:00-12:00, 14:00-17:30",
            "note": "注意久坐，每50分钟活动一下",
        },
    },
    LifeStage.MATURE: {
        "sleep": {
            "bedtime": "22:00",
            "wake_time": "06:00",
            "hours": 8.0,
            "note": "充足睡眠是健康的基础",
        },
        "meals": {
            "breakfast": "07:00",
            "lunch": "11:30",
            "dinner": "17:30",
            "note": "少食多餐，控制油盐糖",
        },
        "exercise": {
            "best_time": "07:00-08:00 或 16:00-17:00",
            "duration": "20-40分钟",
            "types": ["散步", "太极拳", "八段锦", "游泳"],
            "note": "运动量适中，避免剧烈运动",
        },
        "study_work": {
            "best_time": "09:00-11:30, 14:00-16:30",
            "note": "量力而行，注意休息",
        },
    },
    LifeStage.SILVER: {
        "sleep": {
            "bedtime": "21:30",
            "wake_time": "06:00",
            "hours": 8.5,
            "note": "早睡早起，午休30-60分钟",
        },
        "meals": {
            "breakfast": "07:00",
            "lunch": "11:30",
            "dinner": "17:00",
            "note": "少量多餐，易于消化",
        },
        "exercise": {
            "best_time": "07:00-08:00",
            "duration": "20-30分钟",
            "types": ["散步", "太极拳", "八段锦", "站桩"],
            "note": "动作柔和，量力而行，最好结伴",
        },
        "study_work": {
            "best_time": "09:00-11:00, 15:00-16:30",
            "note": "活动量适中，培养兴趣爱好",
        },
    },
}


class LifecycleEngine:
    """用户生命周期引擎"""

    def detect_life_stage(self, birth_year: int) -> LifeStage:
        """根据出生年份检测生命阶段"""
        current_year = datetime.now().year
        age = current_year - birth_year

        if age < 12:
            # 未到青春期，归为青春期(即将进入)
            return LifeStage.ADOLESCENCE
        elif age <= 18:
            return LifeStage.ADOLESCENCE
        elif age <= 30:
            return LifeStage.STRIVING
        elif age <= 45:
            return LifeStage.STABLE
        elif age <= 60:
            return LifeStage.MATURE
        else:
            return LifeStage.SILVER

    def get_age(self, birth_year: int) -> int:
        """根据出生年份计算年龄"""
        return datetime.now().year - birth_year

    def get_stage_config(self, stage: LifeStage) -> Dict[str, Any]:
        """获取生命阶段配置"""
        return STAGE_CONFIGS.get(stage, STAGE_CONFIGS[LifeStage.STABLE])

    def get_seasonal_adjustment(
        self, stage: LifeStage, solar_term: str
    ) -> Dict[str, Any]:
        """
        获取节气调整建议

        Args:
            stage: 生命阶段
            solar_term: 节气名称（如"立春"）

        Returns:
            包含 focus 和 suggestions 的字典
        """
        term_data = SEASONAL_ADJUSTMENTS.get(solar_term)
        if not term_data:
            return {
                "solar_term": solar_term,
                "focus": "顺时养生，因时制宜",
                "suggestions": [],
            }

        stage_key = stage.value
        stage_suggestions = term_data.get("by_stage", {}).get(stage_key, [])

        return {
            "solar_term": solar_term,
            "focus": term_data.get("focus", ""),
            "suggestions": stage_suggestions,
        }

    def get_daily_rhythm(self, stage: LifeStage) -> Dict[str, Any]:
        """获取日常作息建议"""
        return DAILY_RHYTHMS.get(stage, DAILY_RHYTHMS[LifeStage.STABLE])

    def get_all_seasonal_adjustments(self, stage: LifeStage) -> List[Dict[str, Any]]:
        """获取所有节气的调整建议"""
        results = []
        for term_name, term_data in SEASONAL_ADJUSTMENTS.items():
            stage_key = stage.value
            stage_suggestions = term_data.get("by_stage", {}).get(stage_key, [])
            results.append({
                "solar_term": term_name,
                "focus": term_data.get("focus", ""),
                "suggestions": stage_suggestions,
            })
        return results

    def get_user_profile_summary(
        self, birth_year: int, solar_term: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        获取用户画像摘要（综合生命阶段 + 当前节气）

        Args:
            birth_year: 出生年份
            solar_term: 当前节气名称（可选）

        Returns:
            包含阶段信息、推荐、作息、节气建议的综合摘要
        """
        stage = self.detect_life_stage(birth_year)
        age = self.get_age(birth_year)
        config = self.get_stage_config(stage)
        rhythm = self.get_daily_rhythm(stage)

        result = {
            "age": age,
            "birth_year": birth_year,
            "life_stage": stage.value,
            "stage_name": config["name"],
            "description": config["description"],
            "focus_areas": config["focus_areas"],
            "ai_tone": config["ai_tone"],
            "health_priorities": config["health_priorities"],
            "key_habits": config["key_habits"],
            "avoid": config["avoid"],
            "daily_rhythm": rhythm,
        }

        if solar_term:
            seasonal = self.get_seasonal_adjustment(stage, solar_term)
            result["seasonal"] = seasonal

        return result


# 全局实例
lifecycle_engine = LifecycleEngine()
