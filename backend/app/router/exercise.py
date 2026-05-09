"""
顺时 — 运动方案 API
提供基于中医体质和季节的运动养生指导（运动方案）。
包括八段锦、太极拳、五禽戏、易筋经等传统功法。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/exercise", tags=["exercise"])

# ─────────────────────────────────────────────────────────────────────────────
# 强度定义
# ─────────────────────────────────────────────────────────────────────────────
INTENSITY_LEVELS = {
    "very_light": 1,
    "light": 2,
    "medium": 3,
    "high": 4,
}

# ─────────────────────────────────────────────────────────────────────────────
# 运动方案知识库（10 种 TCM 运动）
# ─────────────────────────────────────────────────────────────────────────────
EXERCISES = [
    {
        "id": "ba-duan-jin",
        "name": "八段锦",
        "name_en": "Eight Brocades Qigong",
        "category": "qigong",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["all"],
        "intensity": "light",
        "duration_minutes": 20,
        "benefits": [
            "强身健体",
            "增强免疫力",
            "调理气血",
            "改善睡眠",
            "缓解疲劳",
            "培养气感",
        ],
        "contraindications": ["急性扭伤期间"],
        "steps": [
            "两足分开，与肩同宽，自然站立",
            "双手自然下垂，深呼吸 5-10 次",
            "第一式：两手托天理三焦，五指交叉上举，拉伸脊椎",
            "第二式：左右开弓似射雕，开胸扩肺，强心肺功能",
            "第三式：调理脾胃需单举，左右交替上举一臂，刺激脾胃",
            "第四式：五劳七伤往后瞧，转体向后看，缓解脊椎压力",
            "第五式：摇头摆尾去心火，俯身摆尾动作，清心火降浊气",
            "第六式：两手攀足固肾腰，俯身攀脚，强腰肾",
            "第七式：攥拳怒目增气力，握拳怒视，鼓动气血",
            "第八式：背后七颠百病消，踮脚拍打百会穴，强身健体",
            "缓缓放松，自然呼吸，静站 1-2 分钟后结束",
        ],
        "tcm_principle": "调理阴阳，强身健体，适合各体质四季养生",
        "best_time": "morning",
        "equipment_needed": "无需特殊器材，宽敞平地即可",
    },
    {
        "id": "tai-chi-quan",
        "name": "太极拳",
        "name_en": "Tai Chi",
        "category": "martial_arts",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["all"],
        "intensity": "light",
        "duration_minutes": 30,
        "benefits": [
            "强化心肺功能",
            "改善平衡能力",
            "降低血压",
            "增强肌肉力量",
            "缓解焦虑压力",
            "改善睡眠质量",
        ],
        "contraindications": ["骨质疏松严重者"],
        "steps": [
            "身体放松，两足分开与肩同宽",
            "缓缓吸气，两臂缓缓上升至肩平",
            "呼气，屈膝下坐，两臂缓缓下落",
            "起身，右脚向右迈步，转身右转",
            "左手推出，右手收于胸前，转腰驱动",
            "缓缓后退，重心转移，动作柔和连贯",
            "左右交替，步法稳健，呼吸深长悠远",
            "结束时收势，缓缓站立，静立调息",
        ],
        "tcm_principle": "阴阳相济，刚柔并济，强身健体，适合长期修养",
        "best_time": "morning",
        "equipment_needed": "无需特殊器材，宽敞场地即可",
    },
    {
        "id": "wu-qin-xi",
        "name": "五禽戏",
        "name_en": "Five Animal Frolics",
        "category": "qigong",
        "seasons": ["spring", "summer"],
        "constitution_types": ["qi_deficiency", "yang_deficiency"],
        "intensity": "light",
        "duration_minutes": 25,
        "benefits": [
            "强化脏腑功能",
            "疏通经络",
            "调理气血",
            "增强体质",
            "改善消化",
            "培养气感",
        ],
        "contraindications": ["严重心脏病患者"],
        "steps": [
            "站立放松，调整呼吸",
            "虎戏：四肢着地，爬行运动，强肺气",
            "鹿戏：两肘后拉，转腰摆胯，强肾气",
            "熊戏：身体摇晃，转身挥掌，强脾气",
            "猿戏：双臂交替上举，跳跃轻灵，强心气",
            "鸟戏：双臂展开，转身轻旋，强肝气",
            "逐式进行，每式 3-5 分钟",
            "全部完成后，站立调息，收功",
        ],
        "tcm_principle": "五禽对应五脏，调理脏腑阴阳平衡",
        "best_time": "morning",
        "equipment_needed": "无需特殊器材",
    },
    {
        "id": "yijin-jing",
        "name": "易筋经",
        "name_en": "Yijin Jing (Muscle Change Classic)",
        "category": "qigong",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["blood_stasis", "qi_stagnation"],
        "intensity": "medium",
        "duration_minutes": 35,
        "benefits": [
            "疏通经络",
            "活血化瘀",
            "强化肌肉",
            "改善气血循环",
            "缓解肩颈僵硬",
            "增强体质",
        ],
        "contraindications": ["严重骨伤患者"],
        "steps": [
            "站立调息，两足分开与肩同宽",
            "第一式：韦驮献杵：双臂上举交叉，展开胸腔",
            "第二式：横单鞭：侧身单臂横推，拉伸肋部",
            "第三式：出爪亮翅：两臂展开，身体前倾后仰",
            "第四式：卧虎扑食：俯身拍地，强化腰背",
            "第五式：金鸡独立：单腿站立，强化下肢",
            "第六式：凤凰展翅：两臂展开旋转，拉伸全身",
            "第七式：摘星换斗：侧身转体上举，强化侧腰",
            "第八式：倒拽九牛尾：俯身后拉，强化脊椎",
            "第九式：打躬势：俯身拱背，深度拉伸",
            "第十式：青龙探爪：侧身探爪，拉伸腋下",
            "第十一式：卧虎扑食：重复强化",
            "第十二式：掉尾：转身甩腰，放松脊椎",
            "结束站立调息，收功",
        ],
        "tcm_principle": "通过拉伸疏通经络，活血化瘀，强化肌肉",
        "best_time": "morning",
        "equipment_needed": "垫子（可选）",
    },
    {
        "id": "liu-zi-jue",
        "name": "六字诀",
        "name_en": "Six Healing Sounds",
        "category": "qigong",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["all"],
        "intensity": "light",
        "duration_minutes": 15,
        "benefits": [
            "调理六脏",
            "增强肺功能",
            "缓解情绪压力",
            "改善睡眠",
            "增强免疫力",
            "清热排毒",
        ],
        "contraindications": ["无特殊禁忌"],
        "steps": [
            "站立放松，两足分开与肩同宽",
            "深呼吸调整节奏",
            "肝脏健身法：呼气时发\"嘘\"音，想象绿色之气从肝排出",
            "心脏健身法：呼气时发\"呵\"音，想象红色之气从心排出",
            "脾脏健身法：呼气时发\"呼\"音，想象黄色之气从脾排出",
            "肺脏健身法：呼气时发\"丝\"音，想象白色之气从肺排出",
            "肾脏健身法：呼气时发\"吹\"音，想象蓝黑色之气从肾排出",
            "三焦健身法：呼气时发\"嘻\"音，想象浊气从身体排出",
            "每个音重复 6-10 次",
            "最后调息站立，体验清爽感受",
        ],
        "tcm_principle": "六字对应六脏，调理脏腑功能，排毒强身",
        "best_time": "any",
        "equipment_needed": "无需特殊器材",
    },
    {
        "id": "san-bu-ming-xiang",
        "name": "散步冥想",
        "name_en": "Walking Meditation",
        "category": "walking",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["all"],
        "intensity": "very_light",
        "duration_minutes": 20,
        "benefits": [
            "放松身心",
            "缓解压力",
            "改善睡眠",
            "强化心肺",
            "增进专注力",
            "增强身体平衡",
        ],
        "contraindications": ["无特殊禁忌"],
        "steps": [
            "选择空气清新的环境，散步场地平坦安全",
            "缓缓开始行走，步伐均匀缓慢",
            "放松肩膀，让手臂自然摆动",
            "深长吸气，缓慢呼气，节奏与步伐相配合",
            "专注当下，观察周围环境、植被、天空",
            "如果心神散乱，温和地将注意力带回呼吸",
            "保持此状态继续行走 15-20 分钟",
            "逐渐放慢步伐，深呼吸，结束冥想",
        ],
        "tcm_principle": "结合行走与冥想，调理气血，宁心安神，适合各体质",
        "best_time": "morning",
        "equipment_needed": "舒适的散步环境",
    },
    {
        "id": "ta-qing-cai-feng",
        "name": "踏青采风",
        "name_en": "Spring Walking",
        "category": "walking",
        "seasons": ["spring"],
        "constitution_types": ["qi_stagnation"],
        "intensity": "light",
        "duration_minutes": 45,
        "benefits": [
            "疏肝解郁",
            "升发阳气",
            "增进体力",
            "改善心情",
            "亲近自然",
            "增强免疫",
        ],
        "contraindications": ["无特殊禁忌"],
        "steps": [
            "选择春天生机盎然的户外环境，公园、郊野、山区",
            "穿着轻便，带上舒适的鞋履",
            "缓缓开始散步，边走边观赏春天景色",
            "深呼吸，感受春天的清新之气，升发阳气",
            "如果可能，采集春天的新鲜植物（如艾草、马兰头等）",
            "每 10 分钟可停留观赏，呼吸新鲜空气",
            "保持轻快的步伐，节奏舒适",
            "走 45 分钟左右，感到微微出汗最佳",
            "返回后，缓缓调息，享受身心舒畅",
        ],
        "tcm_principle": "春季升发阳气，疏肝解郁，特别适合气滞体质",
        "best_time": "morning",
        "equipment_needed": "舒适的户外衣着和鞋履",
    },
    {
        "id": "xia-ri-you-yong",
        "name": "夏日游泳",
        "name_en": "Summer Swimming",
        "category": "sports",
        "seasons": ["summer"],
        "constitution_types": ["damp_heat", "yin_deficiency"],
        "intensity": "medium",
        "duration_minutes": 45,
        "benefits": [
            "清热祛湿",
            "强化心肺",
            "全身肌肉锻炼",
            "增进耐力",
            "改善体态",
            "提升免疫",
        ],
        "contraindications": ["感冒期间", "饭后立即游泳", "过度疲劳"],
        "steps": [
            "选择水质清洁、温度适宜的游泳场所",
            "饭后 1-2 小时后方可入水",
            "入水前做充分的热身运动，拉伸肌肉",
            "逐渐适应水温，开始缓慢游动",
            "采用舒适的泳姿（如自由泳、蛙泳、仰泳）",
            "保持匀速节奏，避免过度用力",
            "游泳 30-45 分钟，中途可休息",
            "感到微微疲劳时停止，上岸后缓缓放松",
            "及时擦干身体，穿上衣物保暖",
            "饮水补液，恢复体力",
        ],
        "tcm_principle": "夏季游泳清热祛湿，强心肺，适合热性和湿热体质",
        "best_time": "morning",
        "equipment_needed": "游泳衣、毛巾、泳镜（可选）",
    },
    {
        "id": "qiu-ji-deng-shan",
        "name": "秋季登山",
        "name_en": "Autumn Hiking",
        "category": "sports",
        "seasons": ["autumn"],
        "constitution_types": ["qi_deficiency", "phlegm_dampness"],
        "intensity": "medium",
        "duration_minutes": 90,
        "benefits": [
            "增强心肺功能",
            "强化下肢肌肉",
            "祛湿健脾",
            "调理气血",
            "增强体质",
            "放松身心",
        ],
        "contraindications": ["膝盖严重受损", "心脏病患者"],
        "steps": [
            "选择安全、风景优美的登山路线",
            "穿着防滑登山鞋，带上登山杖",
            "携带足够的水和干粮",
            "做充分热身，拉伸腿部肌肉",
            "开始缓慢上山，保持均匀节奏",
            "每 20 分钟可停留休息，观赏风景",
            "下山时步伐更慢，减轻膝盖负担",
            "下山后缓缓放松，拉伸下肢肌肉",
            "清爽的秋风中调息，感受秋季清肃之气",
        ],
        "tcm_principle": "秋季登山强心肺，祛湿健脾，增强体质",
        "best_time": "morning",
        "equipment_needed": "登山鞋、登山杖、背包、水、干粮",
    },
    {
        "id": "dong-ji-nuan-shen-gong",
        "name": "冬季暖身功",
        "name_en": "Winter Warming Qigong",
        "category": "qigong",
        "seasons": ["winter"],
        "constitution_types": ["yang_deficiency"],
        "intensity": "light",
        "duration_minutes": 30,
        "benefits": [
            "温阳补气",
            "增强抗寒能力",
            "调理阳虚体质",
            "改善手脚冰凉",
            "增强免疫",
            "改善睡眠",
        ],
        "contraindications": ["无特殊禁忌"],
        "steps": [
            "在温暖房间内进行，穿着保暖衣物",
            "站立放松，两足分开与肩同宽",
            "调整呼吸，进行深长的腹式呼吸",
            "双手搓热，按摩腹部丹田穴，温暖下丹田",
            "双臂交叉，拍打腰部、脊柱两侧，温阳气",
            "转腰摆胯，激活腰阳气",
            "踮脚站立，拍打头顶百会穴，升阳气",
            "做简单的太极八式，温和运动",
            "呼吸吐纳，意念温阳",
            "结束站立调息，自然呼吸，体验温暖感",
        ],
        "tcm_principle": "冬季阳气内藏，通过温阳功法，补充阳气",
        "best_time": "morning",
        "equipment_needed": "无需特殊器材",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 7 日锻炼计划模板
# ─────────────────────────────────────────────────────────────────────────────
SEVEN_DAY_PLANS = {
    "qi_deficiency": [
        {"day": "Monday", "exercise_id": "ba-duan-jin", "duration_minutes": 20},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "ba-duan-jin", "duration_minutes": 20},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
    ],
    "yang_deficiency": [
        {"day": "Monday", "exercise_id": "dong-ji-nuan-shen-gong", "duration_minutes": 30},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "ba-duan-jin", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "dong-ji-nuan-shen-gong", "duration_minutes": 30},
        {"day": "Friday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "ba-duan-jin", "duration_minutes": 20},
    ],
    "blood_stasis": [
        {"day": "Monday", "exercise_id": "yijin-jing", "duration_minutes": 35},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "yijin-jing", "duration_minutes": 35},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
    ],
    "qi_stagnation": [
        {"day": "Monday", "exercise_id": "ta-qing-cai-feng", "duration_minutes": 45},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "ta-qing-cai-feng", "duration_minutes": 45},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
    ],
    "damp_heat": [
        {"day": "Monday", "exercise_id": "xia-ri-you-yong", "duration_minutes": 45},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "xia-ri-you-yong", "duration_minutes": 45},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
    ],
    "yin_deficiency": [
        {"day": "Monday", "exercise_id": "xia-ri-you-yong", "duration_minutes": 45},
        {"day": "Tuesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Wednesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Thursday", "exercise_id": "xia-ri-you-yong", "duration_minutes": 45},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Sunday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
    ],
    "phlegm_dampness": [
        {"day": "Monday", "exercise_id": "qiu-ji-deng-shan", "duration_minutes": 90},
        {"day": "Tuesday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Wednesday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
        {"day": "Thursday", "exercise_id": "qiu-ji-deng-shan", "duration_minutes": 90},
        {"day": "Friday", "exercise_id": "liu-zi-jue", "duration_minutes": 15},
        {"day": "Saturday", "exercise_id": "tai-chi-quan", "duration_minutes": 30},
        {"day": "Sunday", "exercise_id": "san-bu-ming-xiang", "duration_minutes": 20},
    ],
}


def _get_current_season() -> str:
    """获取当前季节"""
    month = datetime.now().month
    if month in (3, 4, 5):
        return "spring"
    if month in (6, 7, 8):
        return "summer"
    if month in (9, 10, 11):
        return "autumn"
    return "winter"


def _get_exercise_by_id(exercise_id: str):
    """按 ID 查询运动"""
    return next((e for e in EXERCISES if e["id"] == exercise_id), None)


def _filter_exercises(
    season: Optional[str] = None,
    constitution: Optional[str] = None,
    intensity: Optional[str] = None,
    category: Optional[str] = None,
) -> List[dict]:
    """过滤运动列表"""
    results = EXERCISES.copy()

    if season:
        results = [e for e in results if season in e["seasons"]]

    if constitution:
        results = [e for e in results if "all" in e["constitution_types"] or constitution in e["constitution_types"]]

    if intensity:
        if intensity in INTENSITY_LEVELS:
            intensity_level = INTENSITY_LEVELS[intensity]
            results = [e for e in results if INTENSITY_LEVELS.get(e["intensity"], 0) <= intensity_level]

    if category:
        results = [e for e in results if e["category"] == category]

    return results


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/", summary="获取运动列表")
async def list_exercises(
    season: Optional[str] = Query(None, description="季节筛选: spring/summer/autumn/winter"),
    constitution: Optional[str] = Query(None, description="体质筛选"),
    intensity: Optional[str] = Query(None, description="强度筛选: very_light/light/medium/high"),
    category: Optional[str] = Query(None, description="类别筛选: qigong/martial_arts/walking/sports"),
    limit: int = Query(10, ge=1, le=50),
):
    """
    返回运动列表，支持按季节、体质、强度、类别筛选。
    """
    results = _filter_exercises(
        season=season,
        constitution=constitution,
        intensity=intensity,
        category=category,
    )

    return {
        "success": True,
        "data": {
            "exercises": results[:limit],
            "total": len(results),
            "season": season or _get_current_season(),
            "filters": {
                "season": season,
                "constitution": constitution,
                "intensity": intensity,
                "category": category,
            },
        },
    }


@router.get("/daily", summary="今日推荐运动")
async def daily_exercises(
    constitution: Optional[str] = Query(None, description="体质类型（可选）"),
):
    """
    根据当前季节和体质，返回今日推荐的 2-3 个运动及详细指导。
    """
    current_season = _get_current_season()

    # 获取该季节的所有运动
    seasonal_exercises = [e for e in EXERCISES if current_season in e["seasons"]]

    recommended = []

    if constitution and constitution != "all":
        # 优先推荐与体质匹配的运动
        matched = [
            e
            for e in seasonal_exercises
            if "all" in e["constitution_types"] or constitution in e["constitution_types"]
        ]
        recommended = matched[:3] if matched else seasonal_exercises[:3]
    else:
        # 推荐通用运动
        recommended = [e for e in seasonal_exercises if "all" in e["constitution_types"]][:3]

    if not recommended:
        recommended = seasonal_exercises[:3]

    return {
        "success": True,
        "data": {
            "season": current_season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "constitution": constitution,
            "recommended_exercises": recommended,
            "daily_routine": f"今日推荐运动顺序：{' → '.join(e['name'] for e in recommended)}",
            "tip": "建议选择上午 6-9 点或傍晚 17-19 点进行锻炼，效果最佳。",
        },
    }


@router.get("/seasonal", summary="当前季节特色运动")
async def seasonal_exercises():
    """
    获取当前季节的特色推荐运动及说明。
    """
    current_season = _get_current_season()
    seasonal_exs = [e for e in EXERCISES if current_season in e["seasons"]]

    # 优先显示本季节限定的运动
    season_specific = [
        e for e in seasonal_exs if len(e["seasons"]) == 1 or current_season in e["seasons"]
    ]

    if not season_specific:
        season_specific = seasonal_exs

    return {
        "success": True,
        "data": {
            "season": current_season,
            "season_name": {
                "spring": "春季",
                "summer": "夏季",
                "autumn": "秋季",
                "winter": "冬季",
            }.get(current_season, "当前季节"),
            "featured_exercises": season_specific[:5],
            "season_wisdom": {
                "spring": "春季升发阳气，宜选择升阳疏肝的运动。",
                "summer": "夏季阳气外达，宜选择清热祛湿的运动。",
                "autumn": "秋季收敛阳气，宜选择滋阴润肺的运动。",
                "winter": "冬季阳气内藏，宜选择温阳补气的运动。",
            }.get(current_season, ""),
        },
    }


@router.get("/plan/{constitution}", summary="体质 7 日锻炼计划")
async def seven_day_plan(constitution: str):
    """
    根据体质类型返回一个完整的 7 日个性化运动计划。
    计划包括每日运动项目、时长、重点以及进度追踪建议。
    """
    if constitution not in SEVEN_DAY_PLANS:
        raise HTTPException(
            status_code=404,
            detail=f"Constitution type '{constitution}' not found. Valid types: {', '.join(SEVEN_DAY_PLANS.keys())}",
        )

    plan = SEVEN_DAY_PLANS[constitution]
    detailed_plan = []

    for day_item in plan:
        exercise = _get_exercise_by_id(day_item["exercise_id"])
        if exercise:
            detailed_plan.append(
                {
                    "day": day_item["day"],
                    "exercise_name": exercise["name"],
                    "exercise_id": exercise["id"],
                    "duration_minutes": day_item["duration_minutes"],
                    "intensity": exercise["intensity"],
                    "benefits": exercise["benefits"][:3],
                    "best_time": exercise["best_time"],
                }
            )

    return {
        "success": True,
        "data": {
            "constitution": constitution,
            "plan_duration": "7 days",
            "weekly_plan": detailed_plan,
            "total_weekly_minutes": sum(d["duration_minutes"] for d in detailed_plan),
            "tips": [
                "建议固定时间进行，坚持 4 周观察效果",
                "每周至少进行 5 天以上，才能取得显著成效",
                "如感到过度疲劳，可减少次数或时长",
                "季节变化时，可相应调整运动类型",
            ],
        },
    }


@router.get("/{exercise_id}", summary="运动详情")
async def get_exercise_detail(exercise_id: str):
    """
    获取指定运动的完整详情，包括分步骤说明、益处、禁忌等。
    """
    exercise = _get_exercise_by_id(exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=404,
            detail=f"Exercise '{exercise_id}' not found",
        )

    return {
        "success": True,
        "data": exercise,
    }
