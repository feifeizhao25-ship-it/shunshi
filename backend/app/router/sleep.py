"""
顺时 — 睡眠优化 API
提供个性化睡眠建议、睡眠节律计算、季节性睡眠指导。
"""

from fastapi import APIRouter, Query
from typing import Optional
from datetime import datetime, time

router = APIRouter(prefix="/api/v1/sleep", tags=["sleep"])

# ─────────────────────────────────────────────────────────────────────────────
# 季节性睡眠参数
# ─────────────────────────────────────────────────────────────────────────────
SEASONAL_SLEEP = {
    "spring": {
        "bedtime": "22:30",
        "wake_time": "06:00",
        "duration_hours": 7.5,
        "tcm_principle": "春季宜晚卧早起，顺应阳气生发",
        "tip": "春天适合稍晚入睡，与日出同步唤醒，感受生机。",
        "avoid": ["睡前饮酒", "过度兴奋的娱乐", "过晚进食"],
        "recommend": ["睡前散步10分钟", "打开窗户感受春风", "温热牛奶或枸杞茶"],
    },
    "summer": {
        "bedtime": "22:00",
        "wake_time": "05:30",
        "duration_hours": 7.5,
        "tcm_principle": "夏季宜晚卧早起，午休片刻补充精力",
        "tip": "夏季昼长，可适当晚睡，但务必午休 20–30 分钟。",
        "avoid": ["睡前剧烈运动", "过度使用空调直吹", "浓茶咖啡"],
        "recommend": ["温水冲澡", "午休20分钟", "凉爽环境（26-28°C）"],
    },
    "autumn": {
        "bedtime": "22:00",
        "wake_time": "06:30",
        "duration_hours": 8.5,
        "tcm_principle": "秋季宜早卧早起，与天地收敛之气相应",
        "tip": "秋天是储备能量的季节，比夏天早睡、睡足，为冬季养藏做准备。",
        "avoid": ["悲秋情绪扰眠", "秋燥导致口干影响入睡"],
        "recommend": ["睡前蜂蜜水润燥", "加厚被褥防秋凉", "内关穴按摩安神"],
    },
    "winter": {
        "bedtime": "21:30",
        "wake_time": "07:00",
        "duration_hours": 9.5,
        "tcm_principle": "冬季宜早卧晚起，必待日光，顺应阳气潜藏",
        "tip": "冬天最适合多睡，天黑即可准备入眠，等太阳升起后再起床。",
        "avoid": ["过度消耗阳气的夜间活动", "睡前玩手机（蓝光扰褪黑素）"],
        "recommend": ["睡前涌泉穴按摩", "热水泡脚15分钟", "厚实保暖的睡眠环境"],
    },
}

CONSTITUTION_SLEEP = {
    "qi_deficiency": {
        "note": "气虚者容易疲倦，但睡眠质量可能差。建议早睡，睡前避免思虑过多。",
        "acupoint": "足三里（ST36）按摩助气。",
    },
    "yang_deficiency": {
        "note": "阳虚者怕冷，冬天尤其需要充足睡眠，注意保暖。",
        "acupoint": "命门（GV4）和肾俞（BL23）温阳助眠。",
    },
    "yin_deficiency": {
        "note": "阴虚者可能虚火上扰，出现入睡难或多梦。建议睡前1小时放松，避免刺激。",
        "acupoint": "涌泉（KD1）和神门（HT7）滋阴安神。",
    },
    "qi_stagnation": {
        "note": "气郁者容易思虑过重影响入睡。建议睡前进行腹式呼吸或轻柔散步。",
        "acupoint": "内关（PC6）和神门（HT7）疏肝安神。",
    },
    "damp": {
        "note": "痰湿者可能嗜睡但睡眠质量差，白天昏沉。减少晚餐摄入，饭后散步。",
        "acupoint": "足三里（ST36）和三阴交（SP6）健脾化湿。",
    },
    "balanced": {
        "note": "体质平和者按季节睡眠指导即可，保持规律即是最好的养生。",
        "acupoint": "内关（PC6）日常安神保健。",
    },
}


def _current_season(hemisphere: str = "north") -> str:
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

@router.get("/guide", summary="今日睡眠指南")
async def sleep_guide(
    hemisphere: str = Query("north", description="north | south"),
    constitution: Optional[str] = Query(None, description="体质类型"),
):
    """根据当前季节和体质，返回今日睡眠建议。"""
    season = _current_season(hemisphere)
    seasonal = SEASONAL_SLEEP[season]
    constitution_info = CONSTITUTION_SLEEP.get(constitution, CONSTITUTION_SLEEP["balanced"])

    return {
        "success": True,
        "data": {
            "season": season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "recommended_bedtime": seasonal["bedtime"],
            "recommended_wake_time": seasonal["wake_time"],
            "recommended_duration_hours": seasonal["duration_hours"],
            "tcm_principle": seasonal["tcm_principle"],
            "seasonal_tip": seasonal["tip"],
            "avoid": seasonal["avoid"],
            "recommend": seasonal["recommend"],
            "constitution_note": constitution_info["note"],
            "acupoint_suggestion": constitution_info["acupoint"],
        },
    }


@router.get("/schedule", summary="个性化睡眠时间表")
async def sleep_schedule(
    wake_time: str = Query("07:00", description="期望起床时间 HH:MM"),
    hemisphere: str = Query("north", description="north | south"),
):
    """根据起床时间反推推荐入睡时间（90分钟睡眠周期计算）。"""
    season = _current_season(hemisphere)
    seasonal = SEASONAL_SLEEP[season]

    # 解析起床时间
    try:
        h, m = map(int, wake_time.split(":"))
        wake_total_minutes = h * 60 + m
    except Exception:
        wake_total_minutes = 7 * 60

    # 90 分钟 × 周期 = 推荐睡眠时长
    cycles = [5, 6]  # 7.5h 或 9h
    options = []
    for c in cycles:
        sleep_duration = c * 90  # minutes
        bedtime_minutes = wake_total_minutes - sleep_duration
        if bedtime_minutes < 0:
            bedtime_minutes += 24 * 60
        bh = bedtime_minutes // 60
        bm = bedtime_minutes % 60
        options.append({
            "bedtime": f"{bh:02d}:{bm:02d}",
            "cycles": c,
            "duration_hours": round(sleep_duration / 60, 1),
            "label": f"{c} 个睡眠周期（{round(sleep_duration/60,1)} 小时）",
        })

    return {
        "success": True,
        "data": {
            "wake_time": wake_time,
            "season": season,
            "seasonal_recommendation": seasonal["bedtime"],
            "sleep_cycle_options": options,
            "tip": "入睡后约 20 分钟才进入第一个完整睡眠周期，建议比计划时间提前 20 分钟上床放松。",
        },
    }


@router.get("/checkin", summary="睡眠质量自评")
async def sleep_checkin_guide():
    """返回睡眠质量自评维度，供前端展示。"""
    return {
        "success": True,
        "data": {
            "dimensions": [
                {"key": "sleep_onset", "label": "入睡速度", "options": ["5分钟内", "5-15分钟", "15-30分钟", "30分钟以上"]},
                {"key": "sleep_quality", "label": "睡眠深度", "options": ["很深，不易被吵醒", "较深", "较浅，偶尔醒", "很浅，频繁醒"]},
                {"key": "dreams", "label": "梦境", "options": ["几乎无梦", "偶有梦", "梦多但不影响休息", "多梦且疲惫"]},
                {"key": "morning_energy", "label": "起床状态", "options": ["精力充沛", "尚可", "略感疲惫", "十分疲惫"]},
            ],
            "tip": "连续记录 7 天，可以帮助发现睡眠规律，找到最适合你的作息时间。",
        },
    }
