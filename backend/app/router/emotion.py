"""
顺时 — 情绪追踪与引导 API
提供情绪记录、情绪趋势分析、季节性情绪养护建议。
"""

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/emotion", tags=["emotion"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class EmotionLogRequest(BaseModel):
    user_id: str
    emotion: str = Field(..., description="情绪类型: calm/happy/anxious/sad/tired/irritable/overwhelmed/curious")
    intensity: int = Field(..., ge=1, le=5, description="强度 1-5（1最轻，5最强）")
    note: Optional[str] = Field(None, max_length=500, description="可选的情绪备注")
    context: Optional[str] = Field(None, description="情境: morning/work/relationship/health/other")


# ─────────────────────────────────────────────────────────────────────────────
# 情绪知识库
# ─────────────────────────────────────────────────────────────────────────────

# 情绪的中医五脏对应
EMOTION_ORGAN_MAP = {
    "anxious":     {"organ": "心", "element": "火", "season": "summer"},
    "irritable":   {"organ": "肝", "element": "木", "season": "spring"},
    "sad":         {"organ": "肺", "element": "金", "season": "autumn"},
    "overwhelmed": {"organ": "脾", "element": "土", "season": "changeover"},
    "tired":       {"organ": "肾", "element": "水", "season": "winter"},
    "calm":        {"organ": "心", "element": "火", "season": "all", "positive": True},
    "happy":       {"organ": "心", "element": "火", "season": "all", "positive": True},
    "curious":     {"organ": "肝", "element": "木", "season": "spring", "positive": True},
}

# 季节性情绪规律
SEASONAL_EMOTION = {
    "spring": {
        "common_emotions": ["irritable", "anxious", "curious", "happy"],
        "tcm_insight": "春属木，主肝。春季肝气升发，情绪易波动，忌怒，宜疏泄。",
        "guidance": "春天情绪波动是正常的，顺应生发之气，多做户外活动，让情绪自然流动。",
        "practices": ["郊游踏青", "深呼吸", "合谷穴（LI4）疏肝解郁", "菊花茶"],
    },
    "summer": {
        "common_emotions": ["happy", "anxious", "overwhelmed"],
        "tcm_insight": "夏属火，主心。心主神志，夏季心火旺，喜乐过度亦伤心。",
        "guidance": "夏天保持平和愉悦，但避免过度兴奋。午休很重要，养心神。",
        "practices": ["午休20分钟", "内关穴（PC6）安心", "莲子心茶", "傍晚散步"],
    },
    "autumn": {
        "common_emotions": ["sad", "tired", "calm"],
        "tcm_insight": "秋属金，主肺。肺在志为忧悲，秋季易生悲伤情绪，需滋肺润燥。",
        "guidance": "秋天感到忧郁是自然现象，顺势内省，也是深度休息和整理的好时机。",
        "practices": ["深呼吸练习", "写日记整理思绪", "百合银耳汤润肺", "欣赏秋景"],
    },
    "winter": {
        "common_emotions": ["tired", "calm", "sad"],
        "tcm_insight": "冬属水，主肾。肾在志为恐，冬季阳气内藏，宜静养，勿耗散。",
        "guidance": "冬天放慢节奏，情绪趋于沉静是正常的。充足睡眠和温暖环境是最好的情绪药。",
        "practices": ["早睡晚起", "涌泉穴（KD1）温肾", "核桃黑芝麻养肾", "减少社交活动"],
    },
}

# 即时情绪应对建议
EMOTION_RESPONSES = {
    "anxious": {
        "immediate": "先做4-7-8呼吸：吸气4秒，屏息7秒，呼气8秒，重复4次。",
        "acupoint": "按压内关穴（PC6）1-2分钟，可立即缓解心跳加速和焦虑感。",
        "longer_term": "检查最近睡眠和饮食，焦虑常常是身体在提醒你需要休息。",
    },
    "sad": {
        "immediate": "允许自己感受悲伤，不必压抑。找一个安静的空间，让情绪流动。",
        "acupoint": "轻按神门穴（HT7）安抚情绪，膻中穴（CV17）宽胸理气。",
        "longer_term": "增加户外光照时间，运动有助于提升血清素，温暖的食物和社交连接。",
    },
    "irritable": {
        "immediate": "暂时离开触发点，冷水洗脸或手腕处降温，有助于快速冷静。",
        "acupoint": "合谷穴（LI4）和太冲穴（LV3）——'四关'组合，疏肝解郁效果显著。",
        "longer_term": "检查是否睡眠不足或血糖不稳定，两者都是易怒的常见原因。",
    },
    "tired": {
        "immediate": "如果条件允许，20分钟的小睡效果远超咖啡。闭眼放松也有帮助。",
        "acupoint": "按压足三里（ST36）提振精神，百会穴（GV20）提神醒脑。",
        "longer_term": "持续疲劳需要关注：检查睡眠质量、铁和B12水平，以及是否过度消耗。",
    },
    "overwhelmed": {
        "immediate": "列出所有让你感到压力的事情，写在纸上。大脑外化负担后通常会感到轻松。",
        "acupoint": "太阳穴（EX-HN5）轻揉，配合内关穴（PC6）缓解压力。",
        "longer_term": "练习说'不'，检查哪些事情可以推迟或委托他人，保护自己的能量边界。",
    },
    "calm": {
        "immediate": "记录这个状态——是什么让你感到平静？可以成为以后的参考。",
        "acupoint": "维持现状，可以用神门穴（HT7）或内关穴（PC6）巩固宁静感。",
        "longer_term": "平静时是做重要决策和深度工作的最佳时机。",
    },
    "happy": {
        "immediate": "享受这种感觉，但中医提示：喜乐过极亦伤心，保持平和愉悦即可。",
        "acupoint": "无需特别按摩，保持即可。",
        "longer_term": "记录是什么让你快乐，建立属于你的'快乐清单'供低落时参考。",
    },
    "curious": {
        "immediate": "顺应这份好奇心，给自己一些探索的时间和空间。",
        "acupoint": "百会穴（GV20）激活思维，帮助好奇心的清晰表达。",
        "longer_term": "好奇是春天的能量，趁势学习新事物或探索新领域。",
    },
}


def _get_season(hemisphere: str = "north") -> str:
    month = datetime.now().month
    if hemisphere == "south":
        month = (month + 6 - 1) % 12 + 1
    if month in (3, 4, 5):   return "spring"
    if month in (6, 7, 8):   return "summer"
    if month in (9, 10, 11): return "autumn"
    return "winter"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/log", summary="记录情绪")
async def log_emotion(request: EmotionLogRequest):
    """记录用户的即时情绪，并返回个性化应对建议。"""
    emotion = request.emotion.lower()

    if emotion not in EMOTION_RESPONSES:
        raise HTTPException(
            status_code=422,
            detail=f"Unknown emotion '{emotion}'. Valid values: {list(EMOTION_RESPONSES.keys())}",
        )

    response_data = EMOTION_RESPONSES[emotion]
    organ_info = EMOTION_ORGAN_MAP.get(emotion, {})

    return {
        "success": True,
        "data": {
            "logged": True,
            "emotion": emotion,
            "intensity": request.intensity,
            "timestamp": datetime.now().isoformat(),
            "guidance": {
                "immediate_action": response_data["immediate"],
                "acupoint_suggestion": response_data["acupoint"],
                "longer_term": response_data["longer_term"],
            },
            "tcm_insight": {
                "organ": organ_info.get("organ"),
                "element": organ_info.get("element"),
                "note": f"此情绪与{organ_info.get('organ', '内脏')}功能相关，可通过调节{organ_info.get('organ', '对应脏腑')}来缓解。" if organ_info else None,
            },
            "message": "已记录。情绪如天气，会来也会走。" if request.intensity <= 2 else
                       "已记录。感谢你诚实地面对自己的感受。" if request.intensity <= 4 else
                       "已记录。强烈的情绪需要更多关注——记得给自己一些空间和温柔。",
        },
    }


@router.get("/guide", summary="今日情绪养护指南")
async def emotion_guide(
    hemisphere: str = Query("north", description="north | south"),
    current_emotion: Optional[str] = Query(None, description="当前情绪"),
):
    """根据当前季节返回情绪养护指南，可结合当前情绪个性化。"""
    season = _get_season(hemisphere)
    seasonal = SEASONAL_EMOTION[season]

    data = {
        "season": season,
        "date": datetime.now().strftime("%Y-%m-%d"),
        "seasonal_pattern": seasonal["common_emotions"],
        "tcm_insight": seasonal["tcm_insight"],
        "seasonal_guidance": seasonal["guidance"],
        "recommended_practices": seasonal["practices"],
    }

    if current_emotion and current_emotion.lower() in EMOTION_RESPONSES:
        e = current_emotion.lower()
        data["personalized_response"] = EMOTION_RESPONSES[e]
        data["personalized_for"] = e

    return {"success": True, "data": data}


@router.get("/check-in", summary="情绪签到选项")
async def emotion_checkin_options():
    """返回情绪签到的选项列表，供前端展示选择器。"""
    emotions = [
        {"key": "calm",        "label": "平静",   "emoji": "😌", "color": "#8FBCB9"},
        {"key": "happy",       "label": "愉悦",   "emoji": "😊", "color": "#F4A261"},
        {"key": "curious",     "label": "好奇",   "emoji": "🤔", "color": "#74C69D"},
        {"key": "tired",       "label": "疲惫",   "emoji": "😴", "color": "#ADB5BD"},
        {"key": "anxious",     "label": "焦虑",   "emoji": "😰", "color": "#E9C46A"},
        {"key": "sad",         "label": "忧伤",   "emoji": "😢", "color": "#6C91C2"},
        {"key": "irritable",   "label": "烦躁",   "emoji": "😤", "color": "#E76F51"},
        {"key": "overwhelmed", "label": "不堪负重", "emoji": "😩", "color": "#9B5DE5"},
    ]
    return {
        "success": True,
        "data": {
            "emotions": emotions,
            "prompt": "此刻，你感觉怎么样？",
            "intensity_label": "强度（1=轻微，5=强烈）",
        },
    }


@router.get("/insights/{emotion}", summary="情绪深度解读")
async def emotion_insight(emotion: str):
    """获取特定情绪的深度 TCM 解读和调养方案。"""
    emotion = emotion.lower()
    if emotion not in EMOTION_RESPONSES:
        raise HTTPException(
            status_code=404,
            detail=f"Emotion '{emotion}' not found. Valid: {list(EMOTION_RESPONSES.keys())}",
        )

    organ = EMOTION_ORGAN_MAP.get(emotion, {})
    seasonal_connections = [
        s for s, data in SEASONAL_EMOTION.items()
        if emotion in data["common_emotions"]
    ]

    return {
        "success": True,
        "data": {
            "emotion": emotion,
            "tcm_organ": organ.get("organ"),
            "tcm_element": organ.get("element"),
            "seasonal_connection": seasonal_connections,
            "is_positive": organ.get("positive", False),
            "guidance": EMOTION_RESPONSES[emotion],
            "affirmation": {
                "anxious":     "你的神经系统正在保护你。焦虑是信号，不是缺陷。",
                "sad":         "悲伤是爱的证明——你在乎过，所以会难过。这很正常。",
                "irritable":   "烦躁背后通常有疲惫或委屈。先照顾好自己。",
                "tired":       "休息不是懒惰，是身体最诚实的需求。",
                "overwhelmed": "你不必独自承担一切。一次只做一件事。",
                "calm":        "这份平静是你努力来的，值得好好品味。",
                "happy":       "快乐值得被记住和感谢。",
                "curious":     "好奇心是最美好的年轻状态，保持它。",
            }.get(emotion, "每一种情绪都有它存在的意义。"),
        },
    }
