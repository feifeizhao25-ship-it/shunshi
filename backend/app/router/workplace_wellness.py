"""
顺时 — 职场白领 TCM 养生 API
提供久坐、护眼、加班等职场场景的 TCM 养护方案。
"""

from fastapi import APIRouter, Query
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/workplace", tags=["workplace_wellness"])

# ─────────────────────────────────────────────────────────────────────────────
# 久坐解乏动作方案
# ─────────────────────────────────────────────────────────────────────────────
DESK_EXERCISES = {
    "5min": {
        "duration_minutes": 5,
        "title": "5分钟办公室放松操",
        "tcm_theory": "久坐伤肉，久视伤血，推荐每小时进行一次短暂活动以疏通气血",
        "exercises": [
            {
                "name": "颈椎操",
                "steps": ["头向左转30度，停5秒", "头向右转30度，停5秒", "低头按摩颈后大椎穴"],
                "duration_seconds": 90,
                "benefit": "疏通颈部气血，缓解长期低头导致的颈椎压力"
            },
            {
                "name": "腰椎扭转",
                "steps": ["坐直，双手交叉置于胸前", "身体向左扭转，停5秒", "身体向右扭转，停5秒"],
                "duration_seconds": 90,
                "benefit": "促进腰部气血循环，缓解久坐腰部酸痛"
            },
            {
                "name": "眼部放松",
                "steps": ["闭眼深呼吸3次", "睁眼向远处看30秒", "用食指轻按眼周穴位（睛明、四白、太阳穴）"],
                "duration_seconds": 120,
                "benefit": "缓解眼部疲劳，护肝明目"
            }
        ]
    },
    "10min": {
        "duration_minutes": 10,
        "title": "10分钟办公室伸展操",
        "tcm_theory": "配合深呼吸，疏通任督二脉，调理气血",
        "exercises": [
            {
                "name": "肩颈伸展",
                "steps": ["双肩向上耸肩，停2秒后放松", "右手拉住左臂肘部向右后拉伸15秒", "左手拉住右臂肘部向左后拉伸15秒"],
                "duration_seconds": 120,
                "benefit": "缓解肩颈紧张，疏通肩部经络"
            },
            {
                "name": "腰部伸展",
                "steps": ["站立，双腿分开与肩同宽", "身体向左侧弯，左手向下延伸，停15秒", "身体向右侧弯，右手向下延伸，停15秒"],
                "duration_seconds": 150,
                "benefit": "拉伸腰侧肌肉，疏通胆经、脾经"
            },
            {
                "name": "下肢拉伸",
                "steps": ["站立，右腿向前跨步，双手放在右大腿上", "身体向前倾，停20秒", "交换腿部，重复"],
                "duration_seconds": 150,
                "benefit": "激活下肢血液循环，缓解久坐腿部酸胀"
            },
            {
                "name": "穴位按摩（合谷穴）",
                "steps": ["用大拇指按压对侧手的合谷穴（虎口处）", "旋转按摩1分钟，可缓解头痛、疲劳"],
                "duration_seconds": 120,
                "benefit": "合谷穴为万能穴，提神醒脑"
            }
        ]
    },
    "20min": {
        "duration_minutes": 20,
        "title": "20分钟办公室完整养护操",
        "tcm_theory": "午休时段完整的气血调理方案，配合食疗可显著提升下午工作效率",
        "exercises": [
            {
                "name": "全身关节活动",
                "steps": ["颈部环绕8圈（正向）、8圈（反向）", "肩关节环绕各8圈", "腰部环绕各8圈", "膝盖弯曲伸展各15次"],
                "duration_seconds": 300,
                "benefit": "激活全身关节，促进血液循环"
            },
            {
                "name": "经络拍打",
                "steps": ["用手掌拍打双臂内侧（心经、心包经）各2分钟", "拍打双腿外侧（胆经）各2分钟", "拍打腰部两侧（肾经）1分钟"],
                "duration_seconds": 300,
                "benefit": "激活经络气血，增强免疫力"
            },
            {
                "name": "八段锦-简化版",
                "steps": ["两手托天理三焦（30秒）", "左右开弓似射雕（30秒）", "调理脾胃臂下垂（30秒）", "五劳七伤往后瞧（30秒）"],
                "duration_seconds": 240,
                "benefit": "融合中医养生精粹，调理五脏六腑"
            },
            {
                "name": "穴位疗法",
                "steps": ["太阳穴按摩30秒", "内关穴（腕部）按摩30秒", "足三里（膝下3寸）按摩1分钟"],
                "duration_seconds": 180,
                "benefit": "提神醒脑，调理脾胃"
            }
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 护眼完整方案
# ─────────────────────────────────────────────────────────────────────────────
EYE_CARE_PLAN = {
    "diet": [
        {"ingredient": "枸杞", "benefit": "明目补肝血", "usage": "泡水或煲粥，10-15粒/天"},
        {"ingredient": "菊花", "benefit": "清肝热，明目", "usage": "泡水，5-8朵/杯"},
        {"ingredient": "决明子", "benefit": "清肝明目，通便", "usage": "泡水或粥，10克/天"},
        {"ingredient": "黑芝麻", "benefit": "补肝肾，黑目光", "usage": "黑芝麻糊或炒食，每日适量"},
        {"ingredient": "猪肝", "benefit": "补肝血，明目", "usage": "周1-2次，每次50克"},
    ],
    "eye_protection_rule": {
        "name": "20-20-20护眼法则",
        "description": "每20分钟看屏幕，转移目光到20英尺（6米）外的物体，持续看20秒",
        "tcm_correspondence": "中医认为'久视伤血'，该方法通过定期转移目光，让眼睛肌肉放松，缓解气血瘀滞",
        "implementation": [
            "设置手机提醒，每20分钟提醒一次",
            "不看手机，抬头看向窗外或远处",
            "配合眨眼运动（每分钟眨眼15-20次）",
            "可辅以热敷眼睛（湿毛巾敷眼3-5分钟）"
        ]
    },
    "acupoints": [
        {
            "name": "睛明穴",
            "location": "内眼角上方",
            "technique": "轻轻按压或用指腹旋转按摩，1分钟/次",
            "benefit": "明目、消除眼部疲劳",
            "frequency": "每2小时一次"
        },
        {
            "name": "四白穴",
            "location": "眼下方，瞳孔直下，眼眶下缘上方凹陷处",
            "technique": "用拇指指腹垂直按压，维持1分钟",
            "benefit": "缓解眼睛疲劳、迎风流泪",
            "frequency": "早晚各一次"
        },
        {
            "name": "太阳穴",
            "location": "眼角外侧，眉梢后方",
            "technique": "用两手拇指尖按住太阳穴，旋转按摩1分钟",
            "benefit": "缓解眼部酸痛、头痛",
            "frequency": "每天3-5次"
        }
    ],
    "daily_habits": [
        "减少屏幕时间，尤其避免在昏暗环境下使用",
        "保证充足睡眠，肝血在夜间得以恢复",
        "避免熬夜，23:00-03:00为肝经值班时间",
        "每周至少2天户外活动，让眼睛接受自然光",
        "避免过度用眼，适度放松眼睛肌肉"
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# 会议间隙快速恢复方案（15分钟以内）
# ─────────────────────────────────────────────────────────────────────────────
QUICK_RECOVERY = {
    "fatigue_relief": {
        "duration_minutes": 5,
        "title": "快速消疲劳",
        "acupoints": [
            {
                "name": "合谷穴",
                "location": "两手虎口处",
                "technique": "用对侧大拇指用力按压1-2分钟",
                "effect": "快速提神，缓解头痛、疲劳"
            },
            {
                "name": "劳宫穴",
                "location": "手心中央",
                "technique": "用拇指指尖按压，旋转1分钟",
                "effect": "消除焦虑、提神"
            },
            {
                "name": "印堂穴",
                "location": "两眉中间",
                "technique": "用指腹轻轻按摩3-5分钟",
                "effect": "缓解紧张、额头疼痛、改善专注力"
            }
        ]
    },
    "breathing_exercise": {
        "duration_minutes": 3,
        "title": "深呼吸调气",
        "technique": "腹式呼吸（丹田呼吸）",
        "steps": [
            "坐正，放松肩膀",
            "缓缓吸气8秒，腹部扩张（想象将气吸入丹田），屏住呼吸2秒",
            "缓缓呼气8秒，腹部内收",
            "重复6-8次"
        ],
        "benefit": "调理气血，缓解压力，增强专注力",
        "tcm_note": "深呼吸能疏通任脉、调理脾胃，激发人体内在能量"
    },
    "rejuvenating_foods": [
        {"food": "红糖姜茶", "effect": "温阳祛湿，驱散疲劳", "prep_time": "3分钟"},
        {"food": "坚果（杏仁、核桃）", "effect": "补脑，快速补充能量", "prep_time": "即食"},
        {"food": "蜂蜜水", "effect": "补气健脾，快速补充血糖", "prep_time": "1分钟"},
        {"food": "黄芪红枣茶", "effect": "补气增耐力", "prep_time": "5分钟"},
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# 加班养护方案（按加班时段）
# ─────────────────────────────────────────────────────────────────────────────
OVERTIME_CARE = {
    "20_oclock": {
        "time_range": "20:00-22:00",
        "tcm_organ": "心、脾",
        "key_point": "此时段心经当令，应避免过度消耗心阴",
        "care_tips": [
            "避免过于刺激的工作内容，防止心火过旺",
            "每30分钟站起来活动5分钟，疏通气血",
            "饮用温热的花茶（如玫瑰花茶）来疏肝解郁",
            "21:00后避免摄入咖啡因饮料"
        ],
        "food_recommendations": [
            "红枣桂圆茶（补气血）",
            "黑芝麻糊（滋阴补心）",
            "山药粥（健脾益气）"
        ],
        "acupoint_care": "按摩神门穴（腕部）安神，1分钟/次"
    },
    "22_oclock": {
        "time_range": "22:00-00:00",
        "tcm_organ": "胆、肝初期",
        "key_point": "胆经将开启，此时加班最伤阴血，尤其易导致气虚",
        "care_tips": [
            "加班到此时段，身体已明显疲劳，应适当减速",
            "避免过度脑力消耗，转向整理、总结工作",
            "23:00前最好完成工作，准备入睡",
            "如必须继续，需要强化养护措施"
        ],
        "food_recommendations": [
            "黄芪党参鸡汤（补气，增强抵抗力）",
            "冰糖银耳羹（滋阴润肺）",
            "蜂蜜柚子茶（舒缓压力）"
        ],
        "acupoint_care": "按摩内关穴（腕部）缓解压力，1-2分钟/次"
    },
    "midnight_after": {
        "time_range": "00:00之后",
        "tcm_organ": "肝、肾",
        "key_point": "丑时肝经当令，长期在此时段加班严重损伤肝血",
        "care_tips": [
            "此时段加班风险最高，应尽量避免",
            "如必须加班，工作30分钟后需强制休息10分钟",
            "在此时段加班后，次日应特别重视午睡（20-30分钟）",
            "需要在加班结束后的3-5天内进行集中调理"
        ],
        "food_recommendations": [
            "黑鸡汤（大补肝血）",
            "黑色食物（黑米、黑豆、黑芝麻）养肝肾",
            "红糖生姜水（温阳补气）",
            "鹿茸参汤（深度滋补，仅在调理阶段使用）"
        ],
        "acupoint_care": "足三里、三阴交穴位深度按摩，2-3分钟/次，连续3-5天",
        "recovery_protocol": {
            "post_midnight_hours": 3,
            "recovery_days": "3-5天",
            "key_actions": ["充分午睡", "早睡（22:00前）", "食疗调补", "穴位按摩"]
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5个工作阶段的TCM建议
# ─────────────────────────────────────────────────────────────────────────────
WORK_PHASES = {
    "pre_morning_meeting": {
        "phase": "早会前",
        "time_window": "08:00-09:00",
        "tcm_principle": "阳气初生，应唤醒体内阳气，为全天工作蓄势",
        "recommendations": [
            "清晨已进食早餐，此时应摄入温热饮品以激发脾阳",
            "可做5分钟简单拉伸，打开胸腔，为讲话做准备",
            "穴位：按摩足三里穴（膝下3寸），激发阳气"
        ],
        "food_suggestions": [
            "温热黄芪茶（强阳气）",
            "清粥配榨菜（温和健脾）"
        ],
        "avoid": ["冷饮", "油腻食物（会困脾阳）"]
    },
    "morning_focus": {
        "phase": "上午专注期",
        "time_window": "09:00-12:00",
        "tcm_principle": "阳气达到高峰，是一日中工作效率最高的时段",
        "recommendations": [
            "充分利用此时段完成高难度工作",
            "每60分钟站起休息5分钟，做颈肩操",
            "10:00-10:30可摄入清淡点心（坚果、水果），补充脑力能量"
        ],
        "food_suggestions": [
            "坚果类（补脑）",
            "新鲜水果（补充维生素）",
            "黑咖啡或普洱茶（增强专注，避免下午困倦）"
        ],
        "acupoint_care": "按摩风池穴（颈部）维持清醒，2分钟/次"
    },
    "afternoon_fatigue": {
        "phase": "午后困倦期",
        "time_window": "13:00-15:00",
        "tcm_principle": "午餐后脾胃消化需要血液，脑部供血相对减少，午后易困倦",
        "recommendations": [
            "午睡20-30分钟最有效，可显著提升下午工作效率",
            "如无法午睡，可进行10分钟快走或站立工作",
            "13:30-14:00摄入清淡下午茶，避免高糖饮品"
        ],
        "food_suggestions": [
            "红豆薏米粥（健脾祛湿，缓解困倦）",
            "绿茶（清心提神，避免咖啡因过量）",
            "酸梅汤（生津开胃，增强消化）"
        ],
        "acupoint_care": "按摩人中穴（鼻唇沟中点）提神，或耳朵上的神门穴"
    },
    "afternoon_sprint": {
        "phase": "下午冲刺",
        "time_window": "15:00-18:00",
        "tcm_principle": "午后困倦期过后，阳气再次升发，但能量有限，需谨慎分配",
        "recommendations": [
            "15:30摄入营养补充，为最后冲刺蓄力",
            "避免过度消耗，为晚间工作留足精力",
            "每30分钟站起活动一次，维持血液循环"
        ],
        "food_suggestions": [
            "黄芪红枣茶（补气续航）",
            "燕麦饼干配牛奶（补充蛋白、维持血糖）",
            "坚果能量棒（快速补充）"
        ],
        "acupoint_care": "按摩三阴交穴（内踝上3寸）调理脾胃，2分钟/次"
    },
    "evening_closeout": {
        "phase": "晚间收尾",
        "time_window": "18:00-20:00",
        "tcm_principle": "阳气渐收，应逐步放缓工作节奏，为夜间恢复做准备",
        "recommendations": [
            "逐步减少工作强度，转向总结和计划性工作",
            "18:30前应完成核心工作，避免过度压力进入夜间",
            "可做10分钟拉伸或散步，帮助过渡到休息状态",
            "晚餐应清淡易消化，避免过饱或刺激"
        ],
        "food_suggestions": [
            "清汤面或清粥（清淡易消化）",
            "清蒸鱼（补气血，清淡）",
            "蔬菜汤（增加纤维，助消化）"
        ],
        "acupoint_care": "按摩内关穴（腕部）缓解压力，为休息做准备，2分钟/次"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 症状缓解方案
# ─────────────────────────────────────────────────────────────────────────────
SYMPTOM_RELIEF = {
    "neck_shoulder_pain": {
        "symptom": "颈肩疼",
        "tcm_cause": "久坐导致颈肩部气血瘀滞，经络不通",
        "quick_solutions": [
            {
                "name": "颈部穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "用对侧大拇指按压风池穴（颈后发际线上，向外约2厘米）",
                    "旋转按摩1分钟，力度适中至酸胀感",
                    "按摩肩井穴（肩膀最高点），1分钟"
                ],
                "effect": "快速缓解颈肩紧张"
            },
            {
                "name": "热敷疗法",
                "time_minutes": 5,
                "steps": [
                    "用热毛巾或热水袋敷在颈肩部3-5分钟",
                    "温度以舒适不烫伤为准（约40-45℃）"
                ],
                "effect": "温阳活血，放松肌肉"
            },
            {
                "name": "颈部拉伸",
                "time_minutes": 2,
                "steps": [
                    "坐正，右手轻轻拉住头部左侧，头向右倾斜",
                    "停留15秒，可感受左侧颈部拉伸感",
                    "交换方向，重复"
                ],
                "effect": "缓解肌肉紧张"
            }
        ]
    },
    "eye_fatigue": {
        "symptom": "眼疲劳",
        "tcm_cause": "久视伤血，眼睛失去气血滋养",
        "quick_solutions": [
            {
                "name": "眼部穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "用食指指腹轻轻按压睛明穴（内眼角上方），30秒",
                    "按压四白穴（眼下方），30秒",
                    "按摩太阳穴（眼角外侧），1分钟"
                ],
                "effect": "快速缓解眼部疲劳"
            },
            {
                "name": "远眺法",
                "time_minutes": 2,
                "steps": [
                    "闭眼深呼吸3次",
                    "睁眼看向6米外远处30秒（使用20-20-20法则）",
                    "可配合眨眼运动"
                ],
                "effect": "缓解眼部肌肉疲劳"
            },
            {
                "name": "热敷眼睛",
                "time_minutes": 3,
                "steps": [
                    "用温毛巾敷在闭合的眼睛上3-5分钟",
                    "温度约38-40℃，舒适即可"
                ],
                "effect": "促进眼周血液循环"
            }
        ]
    },
    "drowsiness": {
        "symptom": "困倦",
        "tcm_cause": "脾胃虚弱，气血不足，或午餐过饱导致脾胃血液供应过多",
        "quick_solutions": [
            {
                "name": "穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "按压人中穴（鼻唇沟中点），30秒至1分钟（力度较大）",
                    "按压合谷穴（虎口），1分钟",
                    "按压足三里穴（膝下3寸外侧），1分钟"
                ],
                "effect": "快速提神"
            },
            {
                "name": "站立活动",
                "time_minutes": 2,
                "steps": [
                    "站起来，做5个深蹲或跳跃",
                    "原地快走1分钟",
                    "踮起脚尖行走30秒"
                ],
                "effect": "激活神经，提神醒脑"
            },
            {
                "name": "提神饮品",
                "time_minutes": 1,
                "steps": [
                    "饮用温热黄芪水或绿茶",
                    "避免过量咖啡因"
                ],
                "effect": "缓解困倦，补气"
            }
        ]
    },
    "stomach_discomfort": {
        "symptom": "胃痛",
        "tcm_cause": "工作压力导致肝气郁结，脾胃受损；或饮食不节制",
        "quick_solutions": [
            {
                "name": "穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "按压足三里穴（膝下3寸外侧），2分钟",
                    "用掌根温和地按摩腹部（脐周顺时针），1分钟"
                ],
                "effect": "健脾和胃，缓解疼痛"
            },
            {
                "name": "温热疗法",
                "time_minutes": 3,
                "steps": [
                    "用热水杯或热水袋温敷腹部3-5分钟",
                    "温度约40-45℃"
                ],
                "effect": "温阳散寒，缓解胃痛"
            },
            {
                "name": "调理食物",
                "time_minutes": 1,
                "steps": [
                    "饮用温热生姜红糖水",
                    "或清汤"
                ],
                "effect": "温中和胃"
            }
        ]
    },
    "headache": {
        "symptom": "头痛",
        "tcm_cause": "颈椎压力、压力过大导致肝阳上亢或气血不足",
        "quick_solutions": [
            {
                "name": "穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "用大拇指按压太阳穴（眼角外侧），1分钟",
                    "按压合谷穴（虎口），1分钟",
                    "按压风池穴（颈后），1分钟"
                ],
                "effect": "快速缓解头痛"
            },
            {
                "name": "头部拉伸",
                "time_minutes": 2,
                "steps": [
                    "颈部缓慢向左、右、前倾斜各15秒",
                    "避免过度用力"
                ],
                "effect": "缓解颈肩紧张引起的头痛"
            },
            {
                "name": "冷热交替",
                "time_minutes": 3,
                "steps": [
                    "用冷毛巾敷前额1分钟",
                    "用热毛巾敷后颈1分钟",
                    "重复一次"
                ],
                "effect": "缓解头部充血"
            }
        ]
    },
    "anxiety": {
        "symptom": "焦虑",
        "tcm_cause": "肝气郁结，心神不宁，长期压力导致气滞血瘀",
        "quick_solutions": [
            {
                "name": "呼吸调理",
                "time_minutes": 3,
                "steps": [
                    "坐正，进行4-7-8呼吸法：吸气4秒，屏气7秒，呼气8秒",
                    "重复5-8轮"
                ],
                "effect": "快速平复情绪，疏肝解郁"
            },
            {
                "name": "穴位按摩",
                "time_minutes": 3,
                "steps": [
                    "按压内关穴（腕部，掌心向上，距腕纹3厘米），2分钟",
                    "按压神门穴（腕部，小指侧），1分钟"
                ],
                "effect": "安神定志，缓解焦虑"
            },
            {
                "name": "心理建议",
                "time_minutes": 2,
                "steps": [
                    "走到户外或窗边，深呼吸2分钟",
                    "远眺或看向绿色植物",
                    "可冲泡玫瑰花茶，舒缓情绪"
                ],
                "effect": "环境调节，缓解压力"
            }
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/desk-exercises", summary="久坐解乏动作方案")
async def desk_exercises(duration: str = Query("5min", description="5min | 10min | 20min")):
    """根据时长返回办公室放松动作方案。"""
    if duration not in DESK_EXERCISES:
        return {
            "success": False,
            "data": {"error": f"Invalid duration. Supported: {list(DESK_EXERCISES.keys())}"}
        }

    return {
        "success": True,
        "data": DESK_EXERCISES[duration]
    }


@router.get("/eye-care", summary="护眼完整方案")
async def eye_care():
    """返回护眼完整方案（食疗+穴位+习惯）。"""
    return {
        "success": True,
        "data": EYE_CARE_PLAN
    }


@router.get("/quick-recovery", summary="会议间隙快速恢复")
async def quick_recovery():
    """返回15分钟以内的快速恢复方案。"""
    return {
        "success": True,
        "data": QUICK_RECOVERY
    }


@router.get("/overtime-care", summary="加班养护方案")
async def overtime_care(time_segment: str = Query("20_oclock", description="20_oclock | 22_oclock | midnight_after")):
    """根据加班时段返回相应的养护方案。"""
    if time_segment not in OVERTIME_CARE:
        return {
            "success": False,
            "data": {"error": f"Invalid time segment. Supported: {list(OVERTIME_CARE.keys())}"}
        }

    return {
        "success": True,
        "data": OVERTIME_CARE[time_segment]
    }


@router.get("/work-phases", summary="5个工作阶段TCM建议")
async def work_phases():
    """返回5个工作阶段的TCM养护建议。"""
    return {
        "success": True,
        "data": WORK_PHASES
    }


@router.post("/symptom-relief", summary="即时症状缓解方案")
async def symptom_relief(body: dict):
    """
    根据症状返回3分钟内可操作的缓解方案。
    body: {symptom: 颈肩疼/眼疲劳/困倦/胃痛/头痛/焦虑}
    """
    symptom = body.get("symptom", "")

    # 症状映射
    symptom_map = {
        "颈肩疼": "neck_shoulder_pain",
        "眼疲劳": "eye_fatigue",
        "困倦": "drowsiness",
        "胃痛": "stomach_discomfort",
        "头痛": "headache",
        "焦虑": "anxiety"
    }

    mapped_symptom = symptom_map.get(symptom)
    if not mapped_symptom or mapped_symptom not in SYMPTOM_RELIEF:
        return {
            "success": False,
            "data": {"error": f"Unknown symptom. Supported: {list(symptom_map.keys())}"}
        }

    return {
        "success": True,
        "data": SYMPTOM_RELIEF[mapped_symptom]
    }
