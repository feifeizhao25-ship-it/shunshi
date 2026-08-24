"""
顺时 — 时区感知的昼夜节律养生系统
基于十二时辰理论，提供时间优化的健康作息建议。
"""

from fastapi import APIRouter, HTTPException, Path, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta, timezone
import math

router = APIRouter(prefix="/api/v1/timezone", tags=["timezone_circadian"])


# ─────────────────────────────────────────────────────────────────────────────
# 十二时辰数据结构
# ─────────────────────────────────────────────────────────────────────────────

SHICHEN_MAP = {
    "子": {
        "name": "子时",
        "hours_24": [23, 0],
        "organ": "胆",
        "organ_pair": "肝",
        "optimal_activity": "深睡眠，开始修复",
        "avoid": "熬夜，过度思考",
        "tcm_principle": "阴气最盛，阳气始生，是身体深度修复的黄金时段",
        "circadian_science": "褪黑素分泌高峰，核心体温最低，适合深睡眠",
    },
    "丑": {
        "name": "丑时",
        "hours_24": [1, 2],
        "organ": "肝",
        "organ_pair": "胆",
        "optimal_activity": "深度睡眠，勿扰",
        "avoid": "工作，激烈活动",
        "tcm_principle": "肝经当令，肝藏魂，此时睡眠最宝贵",
        "circadian_science": "深度睡眠N3阶段，体温最低，生长激素分泌最高",
    },
    "寅": {
        "name": "寅时",
        "hours_24": [3, 4],
        "organ": "肺",
        "organ_pair": "大肠",
        "optimal_activity": "自然醒前的静卧，酝酿",
        "avoid": "突然惊醒，急躁",
        "tcm_principle": "肺经当令，阳气萌生，身体开始苏醒准备",
        "circadian_science": "即将进入REM睡眠，体温开始上升，激素调整",
    },
    "卯": {
        "name": "卯时",
        "hours_24": [5, 6],
        "organ": "大肠",
        "organ_pair": "肺",
        "optimal_activity": "排便，晨间呼吸功法",
        "avoid": "憋尿，进食油腻",
        "tcm_principle": "大肠经当令，是排毒的最佳时间，晨起排便很重要",
        "circadian_science": "皮质醇上升，体温回升，肠道蠕动增强",
    },
    "辰": {
        "name": "辰时",
        "hours_24": [7, 8],
        "organ": "胃",
        "organ_pair": "脾",
        "optimal_activity": "吃早餐，温和散步",
        "avoid": "空腹，过饱",
        "tcm_principle": "胃经当令，脾胃开始工作，早餐是一日中最重要的一餐",
        "circadian_science": "胃酸分泌最高，消化能力最强，最佳进食时间",
    },
    "巳": {
        "name": "巳时",
        "hours_24": [9, 10],
        "organ": "脾",
        "organ_pair": "胃",
        "optimal_activity": "专注工作，思维清晰",
        "avoid": "剧烈运动，过度思考",
        "tcm_principle": "脾经当令，脾主运化，此时工作效率最高，学习能力最强",
        "circadian_science": "脑部清醒度达高峰，专注力和学习能力最优",
    },
    "午": {
        "name": "午时",
        "hours_24": [11, 12],
        "organ": "心",
        "organ_pair": "小肠",
        "optimal_activity": "午餐，午休小憩20分钟",
        "avoid": "过量进食，剧烈运动",
        "tcm_principle": "心经当令，阳气最盛，午时一刻钟睡眠胜过晚上一小时",
        "circadian_science": "体温高峰后开始下降，产生午睡压力，20分钟小睡很有益",
    },
    "未": {
        "name": "未时",
        "hours_24": [13, 14],
        "organ": "小肠",
        "organ_pair": "心",
        "optimal_activity": "消化吸收，温和活动",
        "avoid": "重体力劳动，冷饮",
        "tcm_principle": "小肠经当令，分清浊，此时消化功能最强",
        "circadian_science": "体温继续下降，消化酶活性最高，是吸收营养的黄金时段",
    },
    "申": {
        "name": "申时",
        "hours_24": [15, 16],
        "organ": "膀胱",
        "organ_pair": "肾",
        "optimal_activity": "运动锻炼的最佳时段",
        "avoid": "久坐，憋尿",
        "tcm_principle": "膀胱经当令，是一日中运动最合适的时间，阳气逐渐内收",
        "circadian_science": "体温最高，肌肉力量最强，运动表现和耐受力最佳",
    },
    "酉": {
        "name": "酉时",
        "hours_24": [17, 18],
        "organ": "肾",
        "organ_pair": "膀胱",
        "optimal_activity": "轻松活动，散步，反思",
        "avoid": "激烈运动，过度消耗",
        "tcm_principle": "肾经当令，肾为先天之本，此时开始进入阴长阳消的过程",
        "circadian_science": "运动表现开始下降，体温开始下降，准备进入休息模式",
    },
    "戌": {
        "name": "戌时",
        "hours_24": [19, 20],
        "organ": "心包",
        "organ_pair": "三焦",
        "optimal_activity": "社交放松，准备晚餐",
        "avoid": "激烈工作，过度刺激",
        "tcm_principle": "心包经当令，护心阳，晚餐应清淡，为睡眠做准备",
        "circadian_science": "褪黑素开始分泌，体温继续下降，进入休息模式",
    },
    "亥": {
        "name": "亥时",
        "hours_24": [21, 22],
        "organ": "三焦",
        "organ_pair": "心包",
        "optimal_activity": "放松冥想，准备入睡，温水沐浴",
        "avoid": "剧烈运动，过度思考，蓝光刺激",
        "tcm_principle": "三焦经当令，准备入睡的最佳时间，此时睡眠效率最高",
        "circadian_science": "褪黑素分泌上升，体温最低，进入睡眠准备阶段",
    },
}


# 时差恢复方案
JET_LAG_RECOVERY = {
    (1, 3): {
        "severity": "轻度时差",
        "recovery_days": 1,
        "measures": [
            "适应当地作息（特别是光照和进食时间）",
            "到达后立即采用当地时间，第一夜可能睡眠不足但要坚持",
            "早晨日光浴15-20分钟加速调整",
        ],
    },
    (4, 6): {
        "severity": "中度时差",
        "recovery_days": 2,
        "measures": [
            "分阶段调整作息，每天提前或延后1-2小时",
            "根据方向选择是否提前调整：向东飞（日程缩短）建议提前睡；向西飞建议延迟睡眠",
            "使用褪黑素辅助（晚间0.5-3mg）",
            "避免白天长时间睡眠，但第一夜可小睡1-2小时",
        ],
    },
    (7, 12): {
        "severity": "重度时差",
        "recovery_days": 3,
        "measures": [
            "到达后3天内严格执行当地作息，即使白天困顿也不要睡眠超过2小时",
            "前两天多进行户外活动，特别是早晨阳光照射",
            "第一天尽量禁食或只吃清粥清汤，帮助肠道调整",
            "从第二天开始逐步恢复正常进食，使用传统中医调理：黄芪红枣粥、生姜茶",
            "可考虑中医针灸三阴交穴（脾经）调整脾胃功能",
        ],
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class PersonalizedScheduleRequest(BaseModel):
    wake_time: str = Field(..., description="起床时间 HH:MM 格式，如 07:00")
    sleep_target: str = Field(..., description="目标入睡时间 HH:MM 格式，如 23:00")
    timezone_offset: str = Field(default="+8", description="时区偏移，如 +8, -5 等")
    constitution_type: Optional[str] = Field(None, description="体质类型: qi_deficiency/yin_deficiency/damp_heat 等")


# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _hour_to_shichen(hour: int) -> str:
    """将 24 小时制转换为十二时辰名称"""
    if hour == 0:
        return "子"
    elif hour in (1, 2):
        return "丑"
    elif hour in (3, 4):
        return "寅"
    elif hour in (5, 6):
        return "卯"
    elif hour in (7, 8):
        return "辰"
    elif hour in (9, 10):
        return "巳"
    elif hour in (11, 12):
        return "午"
    elif hour in (13, 14):
        return "未"
    elif hour in (15, 16):
        return "申"
    elif hour in (17, 18):
        return "酉"
    elif hour in (19, 20):
        return "戌"
    elif hour in (21, 22):
        return "亥"
    else:
        return "子"


def _get_shichen_info(hour: int) -> Dict[str, Any]:
    """获取某小时对应的时辰详细信息"""
    shichen_key = _hour_to_shichen(hour)
    info = SHICHEN_MAP[shichen_key].copy()
    info["hour"] = hour
    info["shichen"] = shichen_key
    return info


def _parse_time(time_str: str) -> tuple:
    """解析 HH:MM 格式的时间，返回 (hour, minute)"""
    try:
        h, m = map(int, time_str.split(":"))
        if not (0 <= h < 24 and 0 <= m < 60):
            raise ValueError
        return h, m
    except (ValueError, IndexError):
        raise HTTPException(status_code=422, detail="时间格式错误，应为 HH:MM")


def _calculate_tz_offset_hours(tz_str: str) -> int:
    """解析时区字符串，返回小时偏移"""
    try:
        tz_str = tz_str.strip()
        if tz_str.startswith("+"):
            return int(tz_str[1:])
        else:
            return int(tz_str)
    except ValueError:
        raise HTTPException(status_code=422, detail="时区格式错误，如 +8, -5")


def _parse_utc_offset(value: str, field_name: str) -> int:
    """Parse UTC offsets, including '+' decoded as a query-string space."""
    raw = value.strip()
    if not raw.upper().startswith("UTC"):
        raise HTTPException(status_code=422, detail=f"{field_name} 格式错误")
    offset = raw[3:]
    if not offset:
        return 0
    if offset.startswith(" "):
        offset = f"+{offset.strip()}"
    try:
        parsed = int(offset)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=f"{field_name} 格式错误") from exc
    if not -12 <= parsed <= 14:
        raise HTTPException(status_code=422, detail=f"{field_name} 超出有效范围")
    return parsed


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/current-shichen", summary="当前时辰")
async def get_current_shichen(timezone_offset: str = Query("+8", description="时区偏移")):
    """
    获取当前时辰（按 UTC 时间和时区偏移计算），
    返回时辰信息、对应器官、活动建议和禁忌。
    """
    try:
        offset_hours = _calculate_tz_offset_hours(timezone_offset)
    except HTTPException as e:
        raise e

    now_utc = datetime.now(timezone.utc)
    now_local = now_utc + timedelta(hours=offset_hours)
    hour = now_local.hour

    shichen_info = _get_shichen_info(hour)

    return {
        "success": True,
        "data": {
            "current_time": now_local.strftime("%H:%M"),
            "timezone_offset": f"{offset_hours:+d}",
            "shichen": shichen_info["shichen"],
            "shichen_name": shichen_info["name"],
            "hour": hour,
            "organ": shichen_info["organ"],
            "organ_pair": shichen_info["organ_pair"],
            "optimal_activity": shichen_info["optimal_activity"],
            "avoid": shichen_info["avoid"],
            "tcm_principle": shichen_info["tcm_principle"],
            "circadian_science": shichen_info["circadian_science"],
        },
    }


@router.get("/shichen/{hour}", summary="指定小时的时辰信息")
async def get_shichen_by_hour(hour: int = Path(..., ge=0, le=23)):
    """
    获取指定小时（0-23）对应的十二时辰详细信息。
    """
    if not (0 <= hour < 24):
        raise HTTPException(status_code=422, detail="hour 必须在 0-23 之间")

    shichen_info = _get_shichen_info(hour)

    return {
        "success": True,
        "data": shichen_info,
    }


@router.get("/daily-schedule", summary="完整一日作息建议")
async def get_daily_schedule(timezone_offset: str = Query("+8", description="时区偏移")):
    """
    返回完整一日（24小时）按十二时辰排列的作息和养生建议。
    """
    try:
        _calculate_tz_offset_hours(timezone_offset)
    except HTTPException as e:
        raise e

    schedule = []
    for hour in range(24):
        info = _get_shichen_info(hour)
        schedule.append({
            "hour": hour,
            "time_range": f"{hour:02d}:00-{hour+1:02d}:00",
            "shichen": info["shichen"],
            "shichen_name": info["name"],
            "organ": info["organ"],
            "optimal_activity": info["optimal_activity"],
            "avoid": info["avoid"],
            "tcm_principle": info["tcm_principle"],
        })

    return {
        "success": True,
        "data": {
            "timezone_offset": timezone_offset,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "schedule": schedule,
            "summary": "遵循十二时辰作息，顺应自然昼夜节律，是中医养生的核心原则",
        },
    }


@router.get("/jet-lag", summary="时差调节方案")
async def get_jet_lag_recovery(
    from_tz: str = Query("UTC+8", description="出发地时区，如 UTC+8"),
    to_tz: str = Query("UTC-5", description="目的地时区，如 UTC-5"),
):
    """
    根据两个时区计算时差，返回详细的调节方案和中医调理建议。
    """
    from_offset = _parse_utc_offset(from_tz, "from_tz")
    to_offset = _parse_utc_offset(to_tz, "to_tz")

    time_diff = abs(to_offset - from_offset)
    direction = "向东" if to_offset > from_offset else "向西"

    # 查找恢复方案
    recovery_key = None
    for key in sorted(JET_LAG_RECOVERY.keys()):
        if key[0] <= time_diff <= key[1]:
            recovery_key = key
            break

    if recovery_key is None:
        recovery_key = (7, 12) if time_diff > 6 else (1, 3)

    recovery_plan = JET_LAG_RECOVERY[recovery_key]

    return {
        "success": True,
        "data": {
            "from_timezone": from_tz,
            "to_timezone": to_tz,
            "time_difference_hours": time_diff,
            "direction": direction,
            "severity": recovery_plan["severity"],
            "estimated_recovery_days": recovery_plan["recovery_days"],
            "adjustment_measures": recovery_plan["measures"],
            "tcm_supplement": "黄芪红枣粥可增强体质，生姜茶温阳助消化，三阴交穴按摩调脾胃" if time_diff > 6 else "简单调整，保证睡眠和日光照射即可",
        },
    }


@router.get("/optimal-activity/{activity}", summary="最佳活动时辰")
async def get_optimal_activity_time(activity: str):
    """
    获取某项活动（sleep/exercise/meditation/eating/work）的最佳时辰和时间。
    """
    activity = activity.lower()

    activity_shichen_map = {
        "sleep": {
            "best_shichen": ["亥", "子", "丑"],
            "best_hours": [21, 22, 23, 0, 1, 2],
            "explanation": "夜间 21:00-3:00 是睡眠的黄金时段，特别是 23:00-3:00",
            "tips": "晚上 21:00 开始准备入睡，23:00 前最好已入睡",
        },
        "exercise": {
            "best_shichen": ["申"],
            "best_hours": [15, 16],
            "explanation": "申时（15-17点）是一日中运动能力最强的时段，肌肉力量和耐受力最佳",
            "tips": "此时运动效率高，且不会影响晚间睡眠，是运动锻炼的最优选择",
        },
        "meditation": {
            "best_shichen": ["巳", "午"],
            "best_hours": [9, 10, 11, 12],
            "explanation": "早上 9-12 点阳气升发，是冥想和内观的好时间，特别是午时（11-13点）",
            "tips": "早晨冥想帮助整理思绪，午间冥想有助于心神调理",
        },
        "eating": {
            "best_shichen": ["辰", "午"],
            "best_hours": [7, 8, 11, 12],
            "explanation": "早餐最佳在辰时（7-9点），午餐最佳在午时（11-13点），此时脾胃功能最强",
            "tips": "避免晚上进食过饱，晚餐应在戌时（19-21点）前完成",
        },
        "work": {
            "best_shichen": ["巳", "午"],
            "best_hours": [9, 10, 11, 12],
            "explanation": "上午 9-12 点大脑清醒度最高，专注力和学习能力最强，是工作的黄金时段",
            "tips": "建议在此时间段处理重要工作和学习任务",
        },
    }

    if activity not in activity_shichen_map:
        raise HTTPException(
            status_code=404,
            detail=f"未知活动类型 '{activity}'。支持: sleep, exercise, meditation, eating, work",
        )

    info = activity_shichen_map[activity]

    return {
        "success": True,
        "data": {
            "activity": activity,
            "best_shichen": info["best_shichen"],
            "best_hours": info["best_hours"],
            "explanation": info["explanation"],
            "tips": info["tips"],
        },
    }


@router.post("/personalized-schedule", summary="个性化作息建议")
async def get_personalized_schedule(request: PersonalizedScheduleRequest):
    """
    根据用户的起床时间、目标睡眠时间和体质类型，
    生成优化的一日作息表，融合十二时辰养生原则。
    """
    wake_h, wake_m = _parse_time(request.wake_time)
    sleep_h, sleep_m = _parse_time(request.sleep_target)

    try:
        _calculate_tz_offset_hours(request.timezone_offset)
    except HTTPException as e:
        raise e

    # 构建个性化建议
    schedule = []

    # 入睡时段建议
    sleep_shichen = _get_shichen_info(sleep_h)
    schedule.append({
        "time": request.sleep_target,
        "activity": "准备入睡",
        "shichen": sleep_shichen["shichen"],
        "recommendation": f"{sleep_shichen['optimal_activity']}，{sleep_shichen['tcm_principle']}",
    })

    # 起床时段
    wake_shichen = _get_shichen_info(wake_h)
    schedule.append({
        "time": request.wake_time,
        "activity": "起床",
        "shichen": wake_shichen["shichen"],
        "recommendation": f"{wake_shichen['optimal_activity']}，漱口后可做深呼吸",
    })

    # 早餐时段
    breakfast_hour = min(wake_h + 1, 8)
    breakfast_shichen = _get_shichen_info(breakfast_hour)
    schedule.append({
        "time": f"{breakfast_hour:02d}:00",
        "activity": "早餐",
        "shichen": breakfast_shichen["shichen"],
        "recommendation": f"温暖营养的早餐，{breakfast_shichen['tcm_principle']}",
    })

    # 午餐时段
    lunch_shichen = _get_shichen_info(12)
    schedule.append({
        "time": "12:00",
        "activity": "午餐",
        "note": "餐后建议午休 20 分钟",
        "shichen": lunch_shichen["shichen"],
        "recommendation": f"午时进食，并午休 20 分钟，{lunch_shichen['tcm_principle']}",
    })

    # 运动时段
    exercise_shichen = _get_shichen_info(16)
    schedule.append({
        "time": "16:00",
        "activity": "运动锻炼",
        "shichen": exercise_shichen["shichen"],
        "recommendation": f"申时运动效果最佳，{exercise_shichen['tcm_principle']}",
    })

    # 晚餐时段
    dinner_shichen = _get_shichen_info(19)
    schedule.append({
        "time": "19:00",
        "activity": "晚餐",
        "shichen": dinner_shichen["shichen"],
        "recommendation": f"清淡晚餐，避免过饱，{dinner_shichen['tcm_principle']}",
    })

    # 放松时段
    relax_shichen = _get_shichen_info(21)
    schedule.append({
        "time": "21:00",
        "activity": "放松冥想",
        "shichen": relax_shichen["shichen"],
        "recommendation": f"温水沐浴，冥想放松，{relax_shichen['tcm_principle']}",
    })

    # 体质特异性建议
    constitution_advice = ""
    if request.constitution_type == "qi_deficiency":
        constitution_advice = "气虚体质建议：午餐增加黄芪、红枣；运动选择八段锦；避免过度消耗"
    elif request.constitution_type == "yin_deficiency":
        constitution_advice = "阴虚体质建议：多食滋阴食物（银耳、麦冬、百合）；避免过度运动；保证充足睡眠"
    elif request.constitution_type == "damp_heat":
        constitution_advice = "湿热体质建议：清淡饮食，避免油腻；多进行有氧运动；可用薏米、绿豆调理"
    else:
        constitution_advice = "遵循十二时辰作息，顺应自然节律，定期调整以适应季节变化"

    return {
        "success": True,
        "data": {
            "wake_time": request.wake_time,
            "sleep_target": request.sleep_target,
            "timezone_offset": request.timezone_offset,
            "constitution_type": request.constitution_type or "default",
            "personalized_schedule": schedule,
            "constitution_advice": constitution_advice,
            "sleep_duration_hours": "约 8 小时（建议最优）",
            "message": "遵循此作息，可显著改善睡眠质量和白天精力",
        },
    }
