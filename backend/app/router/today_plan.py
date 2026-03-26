# 今日计划 API 端点

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import random

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

# ============ Helper Functions ============

def get_current_solar_term():
    """获取当前节气（2026年精确日期）"""
    month = datetime.now().month
    day = datetime.now().day
    md = (month, day)

    TERMS = [
        ((1, 5), "小寒", "🥶"), ((1, 20), "大寒", "🥶"),
        ((2, 4), "立春", "🌱"), ((2, 19), "雨水", "💧"),
        ((3, 5), "惊蛰", "⚡"), ((3, 20), "春分", "🌸"),
        ((4, 5), "清明", "🌿"), ((4, 20), "谷雨", "🌧️"),
        ((5, 6), "立夏", "☀️"), ((5, 21), "小满", "🌾"),
        ((6, 6), "芒种", "🌾"), ((6, 21), "夏至", "🌞"),
        ((7, 7), "小暑", "🔥"), ((7, 23), "大暑", "🌡️"),
        ((8, 7), "立秋", "🍂"), ((8, 23), "处暑", "🍃"),
        ((9, 7), "白露", "💧"), ((9, 23), "秋分", "🍁"),
        ((10, 8), "寒露", "🍂"), ((10, 23), "霜降", "❄️"),
        ((11, 7), "立冬", "❄️"), ((11, 22), "小雪", "🌨️"),
        ((12, 7), "大雪", "⛄"), ((12, 22), "冬至", "☀️"),
    ]

    current_name, current_emoji = "春分", "🌸"
    current_desc = "阴阳平衡，宜调理气血"
    for (m, d), name, emoji in TERMS:
        if md >= (m, d):
            current_name, current_emoji = name, emoji
    # 查描述
    for t in SOLAR_TERMS:
        if t["name"] == current_name:
            current_desc = t["description"]
            break

    return {
        "name": current_name,
        "emoji": current_emoji,
        "description": current_desc,
        "suggestions": ["适当运动", "注意休息", "调理饮食"],
        "date": datetime.now().strftime("%Y-%m-%d"),
    }

def generate_insights():
    """生成今日洞察"""
    selected = random.sample(INSIGHTS_TEMPLATES, min(3, len(INSIGHTS_TEMPLATES)))
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

def generate_tasks():
    """生成今日任务（每个时间段2-3个任务）"""
    tasks = []
    for slot in ["morning", "afternoon", "evening"]:
        pool = TASKS_BY_SLOT.get(slot, [])
        count = min(random.randint(2, 3), len(pool))
        selected = random.sample(pool, count) if len(pool) >= count else pool
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

def generate_recommendations():
    """生成内容推荐"""
    recommendations = [
        {
            "id": "rec_1",
            "title": "春季养生食谱",
            "description": "适合春季的养生美食",
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

# ============ API Endpoints ============

@router.get("", response_model=TodayPlan)
async def get_today_plan():
    """获取今日计划"""
    return TodayPlan(
        id=f"plan_{datetime.now().strftime('%Y%m%d')}",
        date=datetime.now().strftime("%Y-%m-%d"),
        insights=generate_insights(),
        tasks=generate_tasks(),
        recommendations=generate_recommendations(),
        solar_term=get_current_solar_term()
    )

@router.post("/refresh", response_model=TodayPlan)
async def refresh_today_plan():
    """刷新今日计划"""
    return TodayPlan(
        id=f"plan_{datetime.now().strftime('%Y%m%d')}",
        date=datetime.now().strftime("%Y-%m-%d"),
        insights=generate_insights(),
        tasks=generate_tasks(),
        recommendations=generate_recommendations(),
        solar_term=get_current_solar_term()
    )

@router.patch("/tasks/{task_id}")
async def update_task_status(task_id: str, status: str):
    """更新任务状态"""
    return {"success": True, "task_id": task_id, "status": status}
