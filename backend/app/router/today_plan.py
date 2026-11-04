# 今日计划 API 端点

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime, timedelta
import hashlib
import random
import logging

from app.locale_context import RequestLocale, request_locale

router = APIRouter(prefix="/api/v1/today-plan", tags=["今日计划"])

# ============ Models ============

class TodayInsight(BaseModel):
    id: str
    title: str
    content: str
    icon: str
    type: str = "general"

class FollowUpTask(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    status: str = "pending"
    priority: str = "normal"
    category: Optional[str] = None
    time_slot: str = "morning"  # morning / afternoon / evening

class ContentRecommendation(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    type: str = "article"
    image_url: Optional[str] = None

class SolarTermCard(BaseModel):
    name: str
    emoji: str
    description: str
    suggestions: List[str]
    date: str

class TodayPlan(BaseModel):
    id: str
    date: str
    locale: str = "zh"
    personalization: Optional[dict] = None
    insights: List[TodayInsight]
    tasks: List[FollowUpTask]
    recommendations: List[ContentRecommendation]
    solar_term: Optional[SolarTermCard] = None

# ============ Solar Terms Data ============

SOLAR_TERMS = [
    {"name": "立春", "emoji": "🌱", "description": "万物复苏，宜养肝护肝"},
    {"name": "雨水", "emoji": "💧", "description": "春雨润物，宜祛湿健脾"},
    {"name": "惊蛰", "emoji": "⚡", "description": "春雷惊醒，宜养心安神"},
    {"name": "春分", "emoji": "🌸", "description": "阴阳平衡，宜调理气血"},
    {"name": "清明", "emoji": "🌿", "description": "气清景明，宜养肺润燥"},
    {"name": "谷雨", "emoji": "🌧️", "description": "雨生百谷，宜健脾祛湿"},
    {"name": "立夏", "emoji": "☀️", "description": "夏日至始，宜养心安神"},
    {"name": "小满", "emoji": "🌾", "description": "物至于此，宜清热利湿"},
    {"name": "芒种", "emoji": "🌾", "description": "忙种时节，宜补气养血"},
    {"name": "夏至", "emoji": "🌞", "description": "阳气最旺，宜养阴清热"},
    {"name": "小暑", "emoji": "🔥", "description": "暑热初起，宜消暑健脾"},
    {"name": "大暑", "emoji": "🌡️", "description": "炎热至极，宜清热解毒"},
    {"name": "立秋", "emoji": "🍂", "description": "秋意渐起，宜润燥养肺"},
    {"name": "处暑", "emoji": "🍃", "description": "暑热渐退，宜滋阴润肺"},
    {"name": "白露", "emoji": "💧", "description": "露凝而白，宜补脾养肺"},
    {"name": "秋分", "emoji": "🍁", "description": "阴阳平衡，宜养阴润燥"},
    {"name": "寒露", "emoji": "🍂", "description": "露寒风凉，宜滋补肝肾"},
    {"name": "霜降", "emoji": "❄️", "description": "霜降始寒，宜温补脾肾"},
    {"name": "立冬", "emoji": "❄️", "description": "冬藏开始，宜温补肾阳"},
    {"name": "小雪", "emoji": "🌨️", "description": "雪未大，宜温肾助阳"},
    {"name": "大雪", "emoji": "⛄", "description": "雪盛时节，宜补肾温阳"},
    {"name": "冬至", "emoji": "☀️", "description": "阴阳交替，宜养肾藏精"},
    {"name": "小寒", "emoji": "🥶", "description": "寒气渐盛，宜温阳散寒"},
    {"name": "大寒", "emoji": "🥶", "description": "寒至极点，宜温肾健脾"},
]

# ============ Insights Templates ============

INSIGHTS_TEMPLATES = [
    {"title": "早安", "content": "新的一天开始了，记得喝一杯温水", "icon": "🌅"},
    {"title": "养生提示", "content": "今日宜清淡饮食，少食辛辣", "icon": "🥗"},
    {"title": "运动建议", "content": "适合散步30分钟，促进气血运行", "icon": "🚶"},
    {"title": "睡眠养生", "content": "睡前可用温水泡脚，有助睡眠", "icon": "😴"},
    {"title": "情绪调节", "content": "保持心情愉悦，听听舒缓的音乐", "icon": "🎵"},
    {"title": "饮食养生", "content": "宜多食绿色蔬菜，养肝明目", "icon": "🥬"},
]

# ============ Task Templates ============

TASK_TEMPLATES = [
    # ── 早晨 (morning) ──
    {"title": "晨起一杯温水", "description": "唤醒身体，促进代谢", "category": "health", "priority": "high", "time_slot": "morning"},
    {"title": "5分钟拉伸运动", "description": "舒展肩颈，活动筋骨", "category": "exercise", "priority": "normal", "time_slot": "morning"},
    {"title": "营养早餐", "description": "温热的粥类+鸡蛋，养胃暖身", "category": "diet", "priority": "high", "time_slot": "morning"},
    {"title": "深呼吸练习", "description": "腹式呼吸5分钟，提神醒脑", "category": "mental", "priority": "low", "time_slot": "morning"},
    {"title": "按揉迎香穴", "description": "预防感冒，通鼻窍", "category": "health", "priority": "low", "time_slot": "morning"},
    # ── 下午 (afternoon) ──
    {"title": "午后散步15分钟", "description": "促进消化，缓解久坐", "category": "exercise", "priority": "normal", "time_slot": "afternoon"},
    {"title": "午后小憩20分钟", "description": "养心安神，恢复精力", "category": "rest", "priority": "normal", "time_slot": "afternoon"},
    {"title": "喝一杯养生茶", "description": "枸杞菊花茶，清肝明目", "category": "diet", "priority": "normal", "time_slot": "afternoon"},
    {"title": "晒太阳10分钟", "description": "补充阳气，促进钙吸收", "category": "health", "priority": "normal", "time_slot": "afternoon"},
    {"title": "办公室颈部操", "description": "缓解颈椎疲劳", "category": "exercise", "priority": "low", "time_slot": "afternoon"},
    # ── 晚上 (evening) ──
    {"title": "晚餐七分饱", "description": "清淡饮食，减轻肠胃负担", "category": "diet", "priority": "high", "time_slot": "evening"},
    {"title": "温水泡脚15分钟", "description": "促进血液循环，助眠", "category": "health", "priority": "normal", "time_slot": "evening"},
    {"title": "23:00前入睡", "description": "子时养肝，保证7-8小时睡眠", "category": "rest", "priority": "high", "time_slot": "evening"},
    {"title": "睡前冥想放松", "description": "清空思绪，帮助入眠", "category": "mental", "priority": "low", "time_slot": "evening"},
    {"title": "按揉涌泉穴", "description": "滋阴降火，改善睡眠", "category": "health", "priority": "low", "time_slot": "evening"},
]

# 按时间段分组
TASKS_BY_SLOT = {
    "morning": [t for t in TASK_TEMPLATES if t["time_slot"] == "morning"],
    "afternoon": [t for t in TASK_TEMPLATES if t["time_slot"] == "afternoon"],
    "evening": [t for t in TASK_TEMPLATES if t["time_slot"] == "evening"],
}

# ============ English content (international edition) ============
# 国际版（SEASONS）今日计划用英文，不含中文、不含中医用语；都是日常生活建议，不是医疗建议。

INSIGHTS_EN = [
    {"title": "Good morning", "content": "A new day. Start it with a glass of water.", "icon": "🌅", "cat": "general"},
    {"title": "Eat light", "content": "Today, favour simple meals with plenty of vegetables.", "icon": "🥗", "cat": "diet"},
    {"title": "Move a little", "content": "A 30-minute walk is a gentle way to get moving.", "icon": "🚶", "cat": "exercise"},
    {"title": "Wind down", "content": "A warm bath and screens off before bed make it easier to switch off.", "icon": "😴", "cat": "sleep"},
    {"title": "Make room for calm", "content": "Put on something soothing and take a few slow breaths.", "icon": "🎵", "cat": "mental"},
    {"title": "Eat the rainbow", "content": "Add one extra colourful vegetable or fruit to a meal today.", "icon": "🥬", "cat": "diet"},
]

TASKS_EN = [
    {"title": "A glass of water on waking", "description": "Start the day hydrated", "category": "health", "priority": "high", "time_slot": "morning"},
    {"title": "5-minute stretch", "description": "Loosen your neck, shoulders and back", "category": "exercise", "priority": "normal", "time_slot": "morning"},
    {"title": "A proper breakfast", "description": "Something warm, with some protein", "category": "diet", "priority": "high", "time_slot": "morning"},
    {"title": "Slow breathing", "description": "Five minutes of slow belly breathing", "category": "mental", "priority": "low", "time_slot": "morning"},
    {"title": "Open a window", "description": "Fresh air for a couple of minutes", "category": "health", "priority": "low", "time_slot": "morning"},
    {"title": "15-minute walk", "description": "Break up a long stretch of sitting", "category": "exercise", "priority": "normal", "time_slot": "afternoon"},
    {"title": "20-minute rest", "description": "A short break to recharge", "category": "rest", "priority": "normal", "time_slot": "afternoon"},
    {"title": "A cup of herbal tea", "description": "Caffeine-free, unhurried", "category": "diet", "priority": "normal", "time_slot": "afternoon"},
    {"title": "10 minutes of daylight", "description": "Step outside if you can", "category": "health", "priority": "normal", "time_slot": "afternoon"},
    {"title": "Desk neck stretches", "description": "Ease tension from screen time", "category": "exercise", "priority": "low", "time_slot": "afternoon"},
    {"title": "Stop eating when you are comfortably full", "description": "A lighter dinner sits easier", "category": "diet", "priority": "high", "time_slot": "evening"},
    {"title": "Warm shower or bath", "description": "A relaxing step before bed", "category": "health", "priority": "normal", "time_slot": "evening"},
    {"title": "Lights out at a regular time", "description": "Aim for a consistent bedtime", "category": "rest", "priority": "high", "time_slot": "evening"},
    {"title": "Five-minute wind-down", "description": "Write down tomorrow's top three things, then put the phone away", "category": "mental", "priority": "low", "time_slot": "evening"},
    {"title": "Gentle evening stretch", "description": "Slow stretches for legs and back", "category": "exercise", "priority": "low", "time_slot": "evening"},
]

RECS_EN = [
    {"id": "rec_1", "title": "{season} seasonal recipes", "description": "Home cooking that fits the season", "type": "recipe"},
    {"id": "rec_2", "title": "Gentle morning movement", "description": "A short, easy routine", "type": "video"},
    {"id": "rec_3", "title": "Sleep wind-down guide", "description": "Small habits for better evenings", "type": "article"},
]

SEASON_EN = {"春": "Spring", "夏": "Summer", "秋": "Autumn", "冬": "Winter"}

# 需要关注 → 优先的任务类别 / 洞察类别
NEED_CATEGORIES = {
    "sleep_low": ("rest", "sleep"),
    "stress_high": ("mental",),
    "move_low": ("exercise",),
}

log = logging.getLogger(__name__)

# ============ Helper Functions ============

def get_current_solar_term(is_global: bool = False):
    """获取当前节气：查天文计算的节气表（北京时间），见 app/utils/solar_term_calendar.py。"""
    from app.utils import solar_term_calendar

    today = solar_term_calendar.beijing_today()
    current_name = solar_term_calendar.term_on(today)
    current_emoji, current_desc = "🍃", ""
    for t in SOLAR_TERMS:
        if t["name"] == current_name:
            current_emoji, current_desc = t["emoji"], t["description"]
            break
    if is_global:
        # 国际版：只用英文节气名；说明是季节性的日常提示，不含中医用语
        from app.services.solar_term_enhanced import SOLAR_TERMS_2026
        name_en = next((t["name_en"] for t in SOLAR_TERMS_2026 if t["name"] == current_name), "Seasonal change")
        return {
            "name": name_en,
            "emoji": current_emoji,
            "description": "One of the 24 traditional East Asian solar terms, marking the turning of the season.",
            "suggestions": ["Keep a gentle routine", "Make time to rest", "Eat with the season"],
            "date": today.isoformat(),
        }
    return {
        "name": current_name,
        "emoji": current_emoji,
        "description": current_desc,
        "suggestions": ["适当运动", "注意休息", "调理饮食"],
        "date": today.isoformat(),
    }


def _seed(user_key: str, day: str, market: str, variant: int = 0) -> random.Random:
    """同一用户、同一天、同一市场 → 同一个随机序列：同日反复刷新结果不变，隔天才换（I-08）。"""
    digest = hashlib.sha256(f"{user_key}|{day}|{market}|{variant}".encode()).digest()
    return random.Random(int.from_bytes(digest[:8], "big"))


def read_signals(user_id: Optional[str], today: date) -> dict:
    """只读用户自己最近 3 天写入的记录（打卡 / 睡眠 / 情绪），得出需要关注的方向；没有记录就不猜。"""
    if not user_id:
        return {"needs": [], "basis": None}
    try:
        from app.database.db import get_db
        db = get_db()
        since = (today - timedelta(days=3)).isoformat()
        sleeps = [r["hours"] for r in db.execute("SELECT hours FROM sleep_records WHERE user_id = ? AND date >= ?", (user_id, since)).fetchall() if r["hours"] is not None]
        care = db.execute("SELECT sleep_hours, exercise_minutes, stress_level FROM care_status WHERE user_id = ? AND date >= ?", (user_id, since)).fetchall()
        sleeps += [r["sleep_hours"] for r in care if r["sleep_hours"] is not None]
        moves = [r["exercise_minutes"] for r in care if r["exercise_minutes"] is not None]
        emotions = [r["intensity"] for r in db.execute("SELECT intensity FROM emotion_records WHERE user_id = ? AND date >= ?", (user_id, since)).fetchall() if r["intensity"] is not None]
        stress = [r["stress_level"] for r in care if r["stress_level"]]
    except Exception:  # 读不到就当没有信号，不影响今日计划本身
        log.warning("today-plan: could not read signals", exc_info=True)
        return {"needs": [], "basis": None}
    needs = []
    if sleeps and sum(sleeps) / len(sleeps) < 6.5:
        needs.append("sleep_low")
    if (emotions and max(emotions) >= 7) or any(str(x).lower() in ("high", "高", "较高") for x in stress):
        needs.append("stress_high")
    if moves and sum(moves) / len(moves) < 20:
        needs.append("move_low")
    n = len(sleeps) + len(moves) + len(emotions) + len(stress)
    return {"needs": needs, "basis": {"records_used": n, "window_days": 3} if n else None}


def _prefer(pool: list, needs: list, rng: random.Random, count: int, key: str) -> list:
    """先放符合需要的，再用同一个随机序列补足；顺序也由随机序列决定，所以同一天稳定。"""
    wanted = {c for n in needs for c in NEED_CATEGORIES.get(n, ())}
    shuffled = pool[:]
    rng.shuffle(shuffled)
    first = [x for x in shuffled if x.get(key) in wanted]
    rest = [x for x in shuffled if x.get(key) not in wanted]
    return (first + rest)[:count]


def generate_insights(rng: Optional[random.Random] = None, needs: Optional[list] = None, is_global: bool = False):
    """生成今日洞察"""
    rng = rng or random.Random()
    pool = INSIGHTS_EN if is_global else INSIGHTS_TEMPLATES
    if not is_global:
        pool = [dict(t, cat={"睡眠养生": "sleep", "情绪调节": "mental", "运动建议": "exercise"}.get(t["title"], "general")) for t in pool]
    selected = _prefer(pool, needs or [], rng, min(3, len(pool)), "cat")
    return [
        TodayInsight(
            id=f"insight_{i+1}",
            title=item["title"],
            content=item["content"],
            icon=item["icon"],
            type="general"
        )
        for i, item in enumerate(selected)
    ]

def generate_tasks(rng: Optional[random.Random] = None, needs: Optional[list] = None, is_global: bool = False):
    """生成今日任务（每个时间段2-3个任务）"""
    rng = rng or random.Random()
    templates = TASKS_EN if is_global else TASK_TEMPLATES
    # 国内版任务类别：rest/mental/exercise 与国际版同名，可共用
    tasks = []
    for slot in ["morning", "afternoon", "evening"]:
        pool = [t for t in templates if t["time_slot"] == slot]
        count = min(rng.randint(2, 3), len(pool))
        selected = _prefer(pool, needs or [], rng, count, "category")
        for i, item in enumerate(selected):
            tasks.append(FollowUpTask(
                id=f"task_{slot[0]}{i+1}",
                title=item["title"],
                description=item.get("description"),
                status="pending",
                priority=item.get("priority", "normal"),
                category=item.get("category"),
                time_slot=slot,
            ))
    return tasks

def generate_recommendations(is_global: bool = False):
    """生成内容推荐"""
    from app.utils import solar_term_calendar

    season = solar_term_calendar.season_of(solar_term_calendar.current_term())
    if is_global:
        season_en = SEASON_EN.get(season[:1], "Seasonal")
        return [ContentRecommendation(**dict(r, title=r["title"].format(season=season_en))) for r in RECS_EN]
    recommendations = [
        {
            "id": "rec_1",
            "title": f"{season}季养生食谱",
            "description": f"适合{season}季的家常饮食",
            "type": "recipe",
        },
        {
            "id": "rec_2",
            "title": "八段锦教学",
            "description": "传统养生功法",
            "type": "video",
        },
        {
            "id": "rec_3",
            "title": "穴位按摩指南",
            "description": "常用养生穴位",
            "type": "article",
        },
    ]
    return [ContentRecommendation(**r) for r in recommendations]


def _optional_user(request: Request) -> Optional[str]:
    """今日计划对游客也开放；带了有效令牌就按本人个性化，没带 / 无效就给通用版（不报错）。"""
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        return None
    try:
        from app.security import verify_token
        return verify_token(request.app.state.settings, auth[7:].strip())
    except Exception:
        return None


def build_plan(user_id: Optional[str], loc: RequestLocale, variant: int = 0) -> TodayPlan:
    now = datetime.now()
    day = now.strftime("%Y-%m-%d")
    sig = read_signals(user_id, now.date())
    rng = _seed(user_id or "anonymous", day, loc.market, variant)
    needs = sig["needs"]
    return TodayPlan(
        id=f"plan_{now.strftime('%Y%m%d')}",
        date=day,
        locale=loc.lang,
        personalization={"signals": needs, "basis": sig["basis"], "stable_for_day": True} if user_id else {"signals": [], "basis": None, "stable_for_day": True},
        insights=generate_insights(rng, needs, loc.is_global),
        tasks=generate_tasks(rng, needs, loc.is_global),
        recommendations=generate_recommendations(loc.is_global),
        solar_term=get_current_solar_term(loc.is_global),
    )


# ============ API Endpoints ============

@router.get("", response_model=TodayPlan)
async def get_today_plan(request: Request, loc: RequestLocale = Depends(request_locale)):
    """获取今日计划：同一用户同一天内容固定，隔天更新；有最近记录时按记录调整重点。"""
    return build_plan(_optional_user(request), loc)

@router.post("/refresh", response_model=TodayPlan)
async def refresh_today_plan(request: Request, loc: RequestLocale = Depends(request_locale), variant: int = Query(0, ge=0, le=20, description="想换一组时传 1、2…；不传就是今天固定的这一组")):
    """刷新今日计划：默认返回与 GET 相同的稳定内容（不会无故“乱跳”）；传 variant 才换一组。"""
    return build_plan(_optional_user(request), loc, variant)

@router.patch("/tasks/{task_id}")
async def update_task_status(task_id: str, status: str):
    """更新任务状态"""
    return {"success": True, "task_id": task_id, "status": status}
