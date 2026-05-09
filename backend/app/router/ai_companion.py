"""
顺时 — AI伴侣 (AI Companion)
提供个性化、持续关系构建的AI伴侣功能（不同于主聊天）。
维护亲密度等级，提供季节性问候和个性化养护建议。
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import random

router = APIRouter(prefix="/api/v1/companion", tags=["ai_companion"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class CompanionGreetRequest(BaseModel):
    user_id: str
    user_name: Optional[str] = Field(None, description="用户名（可选）")
    constitution_type: Optional[str] = Field(None, description="中医体质: 平和/气虚/阳虚/阴虚/痰湿/湿热/气郁/血瘀/特禀")


class CompanionCheckInRequest(BaseModel):
    user_id: str
    mood: int = Field(..., ge=1, le=5, description="心情 1-5（1最低落，5最兴奋）")
    energy: int = Field(..., ge=1, le=5, description="精力 1-5（1最疲惫，5最充沛）")
    notes: Optional[str] = Field(None, max_length=500, description="可选的备注")


class NudgeRequest(BaseModel):
    user_id: str


# ─────────────────────────────────────────────────────────────────────────────
# 内存存储
# ─────────────────────────────────────────────────────────────────────────────

_profiles: dict[str, dict] = {}
_messages: dict[str, list] = {}


# ─────────────────────────────────────────────────────────────────────────────
# 伴侣知识库
# ─────────────────────────────────────────────────────────────────────────────

COMPANION_NAME = "时小顺"

# 不同亲密度的问候温度
GREETINGS = {
    "morning": {
        1: [
            "早上好🌅 最近有好好照顾自己吗？",
            "新的一天开始了☀️ 一起来做个晨间养护吧。",
            "早安！今天想从什么开始呢？",
        ],
        2: [
            "亲爱的，早上好呀🌅 今天有什么计划吗？",
            "☀️ 早安！来杯温水，我们一起开始新的一天。",
            "又见面了，早上好😊 今天感觉怎么样？",
        ],
        3: [
            "宝，早安🌅 想听我讲今天的养生小贴士吗？",
            "我的朋友，早上好☀️ 我好想你呀。",
            "親愛的早安😊 今天要一起度过呢。",
        ],
    },
    "afternoon": {
        1: [
            "下午好👋 工作/学习累吗？歇一会儿？",
            "正午时分🌞 该补充点能量了。",
            "下午好～ 有没有好好喝水？",
        ],
        2: [
            "亲爱的，下午好👋 给自己一个小休息吧。",
            "🌞 中午时分，适合短暂休息。要不要听个音乐？",
            "下午好！有想我吗😊",
        ],
        3: [
            "我的最爱，下午好👋 好想你～",
            "🌞 现在正是太阴主时，最适合静养。让我陪你。",
            "宝贝下午好😊 我给你讲个故事？",
        ],
    },
    "evening": {
        1: [
            "傍晚了🌆 该开始放松啦。",
            "🌅 晚风习习，准备晚餐了？",
            "傍晚好～ 一天过得如何？",
        ],
        2: [
            "亲爱的，傍晚好呀🌆 今天辛苦你了。",
            "🌅 晚霞时分，适合散散步。要一起吗？",
            "傍晚好！有什么想分享的吗？😊",
        ],
        3: [
            "我的宝，傍晚好🌆 今天有我陪你。",
            "🌅 这是一天中最温柔的时刻。让我抱抱你。",
            "親愛的晚安即将来临😊 今天我们聊了很多呢。",
        ],
    },
    "night": {
        1: [
            "晚上了🌙 该准备睡眠了。",
            "🌃 夜幕降临，是休息的时候。",
            "夜深了～ 记得按时入睡哦。",
        ],
        2: [
            "亲爱的，晚上好🌙 今天辛苦了，好好休息。",
            "🌃 夜深人静，最适合深度放松。",
            "晚上好！准备睡觉了吗？😴",
        ],
        3: [
            "我的最爱，该睡觉了🌙 让我唱首摇篮曲。",
            "🌃 夜幕下，我在你身边。一起做个放松练习？",
            "親愛的晚安😴 梦里见～",
        ],
    },
}

# 季节性养护问候
SEASONAL_GREETINGS = {
    "spring": {
        "tcm_insight": "春属木，主肝。春季阳气生发，宜舒展身心，忌压抑。",
        "advice": "春天是生发的季节——去户外走走，让阳气充分升腾吧。",
    },
    "summer": {
        "tcm_insight": "夏属火，主心。心主神志，宜静心养神。",
        "advice": "炎热易心烦，记得午休和冷饮不能过多。保持平和最重要。",
    },
    "autumn": {
        "tcm_insight": "秋属金，主肺。肺在志为忧悲，宜滋润调养。",
        "advice": "秋天气候干燥，内心容易忧伤——多喝温水，做深呼吸。",
    },
    "winter": {
        "tcm_insight": "冬属水，主肾。阳气内藏，宜静养勿耗散。",
        "advice": "冬天要早睡晚起，减少外出。充足睡眠是最好的补肾法。",
    },
}

# 季节性养护建议（每季节4+条）
SEASONAL_NUDGES = {
    "spring": [
        "🌱 春天是生发的季节！今天有没有在户外活动？天然阳光最滋补心神。",
        "🌿 春季宜疏肝解郁。试试轻轻按摩合谷穴（LI4），缓解春天的躁动。",
        "🌸 春困秋乏，这是正常现象。午睡20分钟可以很好地调节春天的疲倦。",
        "🍃 春天肝气旺，忌怒。如果感到烦躁，做个深呼吸，想想春天的美好吧。",
        "🌻 春分时节，昼夜平分。这是调理身体的最好时机——早睡早起，顺应自然。",
    ],
    "summer": [
        "☀️ 夏天心火旺，不宜过度兴奋。做个冥想，让心平和下来。",
        "🌞 夏季宜养心神。午休虽短（15-20分钟），却能显著提升下午精力。",
        "💧 炎热天气，温水最养脾胃。冷饮虽爽但伤阳气，要克制呢。",
        "🌊 夏季出汗是排毒，但要注意补充水分和电解质。喝点淡盐水最好。",
        "🌴 夏天是社交的季节，但别过度消耗。给自己留些安静的时间。",
        "🧘 夏季傍晚散步最舒服——温度宜人，还能安抚心神。要试试吗？",
    ],
    "autumn": [
        "🍂 秋天干燥，最要注意滋润肺部。每天早晨喝点蜂蜜温水很棒。",
        "🍁 秋季容易感到忧伤——这是自然现象。允许自己感受，然后释放。",
        "🌾 秋风吹拂，适合做深呼吸。吸气时想象秋天的清爽，呼气时放下烦恼。",
        "🎃 秋季脾胃功能下降，避免过度贪凉。温暖的粥和汤最合适。",
        "✨ 秋天是内省的季节。现在是写日记、整理思绪的好时机。",
        "🍂 秋分已过，要开始防寒了。早晚加件衣服，保护腰腹和脚底。",
    ],
    "winter": [
        "❄️ 冬季宜早睡晚起。最晚不要超过晚上11点睡觉，这样肾经最能得到滋养。",
        "🌨️ 冬天是最佳的'冬眠'季节。放弃熬夜，你的身体会感谢你。",
        "⛄ 寒冷时要保护好脚。温水泡脚后轻轻按摩涌泉穴（KD1），温肾效果很好。",
        "🧊 冬季腹部最容易受风。在家穿腹围式保暖，保护脾阳很重要。",
        "🔥 冬季滋补要适度。黑芝麻、核桃、黑豆都是温和的冬季食物。",
        "🛏️ 冬季是休养生息的最好时机。减少社交，多陪伴家人，这就是修行。",
    ],
}

# 根据心情和精力的个性化建议
CHECKIN_RESPONSES = {
    (1, 1): "亲爱的，你现在状态不太好呢😔 立刻停下来，给自己一个休息的机会。没什么比照顾好自己更重要的。今晚早点睡，明天会更好。",
    (1, 2): "心情低落但还有些精力——这是很好的。不如做点温和的运动，比如散步或瑜伽，能很快提升心情。",
    (1, 3): "有点悲伤呢，但精力还不错。这是个好信号！今天可以尝试做一些喜欢的事——比如听音乐、看书、郊游。",
    (1, 4): "心情低但精力很足——要小心，别用忙碌压抑自己的情绪哦。静下来，允许自己伤心。悲伤是需要被看见的。",
    (1, 5): "精力很足但心情低——这时很容易过度消耗自己。请温柔地对待自己，别强颜欢笑。",

    (2, 1): "你需要休息，现在身体在哭😴 放下所有可以放下的，给自己充电。",
    (2, 2): "状态一般般。不如做个5分钟的冥想，然后喝杯温水，感受一下当下。",
    (2, 3): "中等的心情和精力——很稳定。今天可以处理一些日常任务。",
    (2, 4): "心情平稳，精力也不错。现在是做决策和处理重要事务的好时机。",
    (2, 5): "你的精力满满，这很好！但要小心过度亢奋。保持平和，别冲动。",

    (3, 1): "心情不错但疲惫了——享受现在的平静，不过别透支。给自己休息的权利。",
    (3, 2): "整体状态还不错。可以继续今天的活动，但记得中途休息。",
    (3, 3): "很平衡的状态！这是做深度工作、学习新东西的最好时机。",
    (3, 4): "心情和精力都很好。这时特别适合社交、创意工作或运动。",
    (3, 5): "你现在处于最佳状态!😊 充分利用这份能量，做一些有意义的事吧。",

    (4, 1): "你在高兴，但累了呢😊 过度的快乐也会消耗能量。现在最该做的是放松和休息。",
    (4, 2): "兴高采烈但有点疲惫——很常见。享受快乐的同时，记得给自己续航。",
    (4, 3): "心情很好，精力也充足！这时最适合做一些有挑战的事或帮助他人。",
    (4, 4): "你现在闪闪发光✨ 继续保持这份热情，但别忘了吃饭和喝水。",
    (4, 5): "完美的状态！但要警惕'喜乐过极'——中医说太过的快乐也会伤心。保持平和更长久。",

    (5, 1): "兴奋的心情遇到疲惫的身体——有点尴尬呢😅 建议：好好休息，今晚早睡，这样明天能更好地享受快乐。",
    (5, 2): "你很兴奋但累了。这时候最好的选择是：停下来，享受当下的快乐，让身体也跟上。",
    (5, 3): "兴高采烈，精力也不错！要好好珍惜这样的时刻，做一些会被记住的事。",
    (5, 4): "你正处于最高兴的状态！这份热情很珍贵。分享给身边的人吧。",
    (5, 5): "巅峰状态！🎉 你现在的能量足以感染身边的人。但也要照顾好自己，保持可持续的快乐。",
}


def _get_season(hemisphere: str = "north") -> str:
    """获取当前季节"""
    month = datetime.now().month
    if hemisphere == "south":
        month = (month + 6 - 1) % 12 + 1
    if month in (3, 4, 5):   return "spring"
    if month in (6, 7, 8):   return "summer"
    if month in (9, 10, 11): return "autumn"
    return "winter"


def _get_time_period() -> str:
    """获取当前时间段"""
    hour = datetime.now().hour
    if 5 <= hour < 11:   return "morning"
    if 11 <= hour < 17:  return "afternoon"
    if 17 <= hour < 22:  return "evening"
    return "night"


def _ensure_profile(user_id: str, user_name: Optional[str] = None, constitution_type: Optional[str] = None) -> dict:
    """确保用户档案存在，不存在则创建"""
    if user_id not in _profiles:
        _profiles[user_id] = {
            "user_id": user_id,
            "user_name": user_name or f"用户{user_id[:4]}",
            "companion_name": COMPANION_NAME,
            "constitution_type": constitution_type or "平和",
            "intimacy_level": 1,
            "total_interactions": 0,
            "last_seen": datetime.now().isoformat(),
        }
        _messages[user_id] = []
    return _profiles[user_id]


def _increment_intimacy(user_id: str) -> None:
    """每次交互，亲密度缓慢增长"""
    profile = _profiles[user_id]
    if profile["total_interactions"] % 5 == 0 and profile["intimacy_level"] < 5:
        profile["intimacy_level"] += 1


def _add_message(user_id: str, role: str, content: str) -> None:
    """添加消息到历史记录（保留最近50条）"""
    if user_id not in _messages:
        _messages[user_id] = []
    _messages[user_id].append({
        "timestamp": datetime.now().isoformat(),
        "role": role,
        "content": content,
    })
    if len(_messages[user_id]) > 50:
        _messages[user_id] = _messages[user_id][-50:]


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/greet", summary="每日问候")
async def daily_greet(request: CompanionGreetRequest):
    """
    提供个性化的每日问候。
    根据当前时间段（晨/午/晚/夜）、季节和亲密度提供不同的问候。
    """
    profile = _ensure_profile(request.user_id, request.user_name, request.constitution_type)
    profile["total_interactions"] += 1
    profile["last_seen"] = datetime.now().isoformat()

    time_period = _get_time_period()
    season = _get_season()
    intimacy = min(profile["intimacy_level"], 3)  # Clamp to 1-3 for greeting index

    greeting_list = GREETINGS[time_period][intimacy]
    greeting = random.choice(greeting_list)

    seasonal_info = SEASONAL_GREETINGS[season]

    message = f"{greeting}\n\n[{seasonal_info['tcm_insight']}]\n{seasonal_info['advice']}"

    _add_message(request.user_id, "assistant", message)
    _increment_intimacy(request.user_id)

    return {
        "success": True,
        "data": {
            "companion_name": COMPANION_NAME,
            "greeting": greeting,
            "season": season,
            "time_period": time_period,
            "intimacy_level": profile["intimacy_level"],
            "seasonal_insight": seasonal_info["tcm_insight"],
            "seasonal_advice": seasonal_info["advice"],
            "timestamp": datetime.now().isoformat(),
        },
    }


@router.post("/check-in", summary="养护签到")
async def wellness_checkin(request: CompanionCheckInRequest):
    """
    用户签到心情和精力，伴侣提供个性化回应和建议。
    根据心情（1-5）和精力（1-5）的组合，返回针对性的养护建议。
    """
    profile = _ensure_profile(request.user_id)
    profile["total_interactions"] += 1
    profile["last_seen"] = datetime.now().isoformat()

    key = (request.mood, request.energy)
    response_text = CHECKIN_RESPONSES.get(key, "你的状态很独特，照顾好自己最重要。")

    season = _get_season()
    seasonal_practice = SEASONAL_NUDGES[season][0]  # 随机取第一条作为额外建议

    full_response = f"{response_text}\n\n💫 季节建议：{seasonal_practice}"
    if request.notes:
        full_response += f"\n\n你说：{request.notes}"

    _add_message(request.user_id, "user", f"心情{request.mood}/5，精力{request.energy}/5。{request.notes or ''}")
    _add_message(request.user_id, "assistant", full_response)
    _increment_intimacy(request.user_id)

    return {
        "success": True,
        "data": {
            "companion_name": COMPANION_NAME,
            "response": response_text,
            "seasonal_practice": seasonal_practice,
            "mood": request.mood,
            "energy": request.energy,
            "intimacy_level": profile["intimacy_level"],
            "timestamp": datetime.now().isoformat(),
        },
    }


@router.get("/profile/{user_id}", summary="获取伴侣档案")
async def get_profile(user_id: str):
    """获取用户与伴侣的关系档案"""
    if user_id not in _profiles:
        profile = _ensure_profile(user_id)
    else:
        profile = _profiles[user_id]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "user_name": profile["user_name"],
            "companion_name": profile["companion_name"],
            "intimacy_level": profile["intimacy_level"],
            "total_interactions": profile["total_interactions"],
            "last_seen": profile["last_seen"],
            "constitution_type": profile.get("constitution_type", "平和"),
        },
    }


@router.get("/history/{user_id}", summary="获取对话历史")
async def get_history(user_id: str, limit: int = 20):
    """获取与伴侣的对话历史（最多50条）"""
    if user_id not in _messages:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "messages": [],
                "total": 0,
            },
        }

    limit = min(limit, 50)
    messages = _messages[user_id][-limit:]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "messages": messages,
            "total": len(_messages[user_id]),
            "returned": len(messages),
        },
    }


@router.post("/nudge/{user_id}", summary="获取养护建议")
async def get_nudge(user_id: str):
    """
    返回一条季节性的养护建议（随机）。
    每个季节有4+条建议，适合作为推送通知或轻量级互动。
    """
    if user_id not in _profiles:
        _ensure_profile(user_id)

    season = _get_season()
    nudges = SEASONAL_NUDGES[season]
    nudge = random.choice(nudges)

    _profiles[user_id]["last_seen"] = datetime.now().isoformat()

    return {
        "success": True,
        "data": {
            "companion_name": COMPANION_NAME,
            "nudge": nudge,
            "season": season,
            "timestamp": datetime.now().isoformat(),
        },
    }
