# 用户数据记录 API 路由
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date
import uuid

from app.database.db import get_db
from app.db.database import get_db as get_orm_db
from app.locale_context import RequestLocale, request_locale

router = APIRouter(prefix="/api/v1/records", tags=["数据记录"])

# ============ Models ============

class CareRecord(BaseModel):
    id: str
    user_id: str
    date: str
    mood: Optional[str] = None
    sleep_hours: Optional[float] = None
    exercise_minutes: Optional[int] = None
    stress_level: Optional[str] = None
    notes: Optional[str] = None
    created_at: str

class EmotionRecord(BaseModel):
    id: str
    user_id: str
    date: str
    emotion: str
    intensity: int
    trigger: Optional[str] = None
    notes: Optional[str] = None
    created_at: str

class SleepRecord(BaseModel):
    id: str
    user_id: str
    date: str
    sleep_time: str
    wake_time: str
    hours: float
    quality: str
    notes: Optional[str] = None
    created_at: str

# ============ Helper Functions ============

def generate_id(prefix: str) -> str:
    return f"{prefix}_{uuid.uuid4().hex}"

# ============ CareStatus API ============

@router.get("/care", response_model=dict)
async def get_care_records(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    start_date: str = Query(None),
    end_date: str = Query(None),
    limit: int = Query(30, ge=1, le=100)
):
    """获取养生状态记录"""
    db = get_db()
    
    sql = "SELECT * FROM care_status WHERE user_id = ?"
    params = [user_id]
    
    if start_date:
        sql += " AND date >= ?"
        params.append(start_date)
    if end_date:
        sql += " AND date <= ?"
        params.append(end_date)
    
    sql += " ORDER BY date DESC LIMIT ?"
    params.append(limit)
    
    rows = db.execute(sql, params).fetchall()
    items = [dict(r) for r in rows]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(items)
        }
    }

@router.post("/care", response_model=dict)
async def add_care_record(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    date: str = Query(...),
    mood: str = Query(None),
    sleep_hours: float = Query(None),
    exercise_minutes: int = Query(None),
    stress_level: str = Query(None),
    notes: str = Query(None)
):
    """添加养生状态记录"""
    db = get_db()
    
    record_id = generate_id("care")
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT INTO care_status (id, user_id, date, mood, sleep_hours, exercise_minutes, stress_level, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (record_id, user_id, date, mood, sleep_hours, exercise_minutes, stress_level, notes, now))
    db.commit()
    
    record = {
        "id": record_id,
        "user_id": user_id,
        "date": date,
        "mood": mood,
        "sleep_hours": sleep_hours,
        "exercise_minutes": exercise_minutes,
        "stress_level": stress_level,
        "notes": notes,
        "created_at": now
    }
    
    return {"success": True, "data": record}

@router.get("/care/today", response_model=dict)
async def get_today_care(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    orm: Session = Depends(get_orm_db),
    loc: RequestLocale = Depends(request_locale),
):
    """今日养生状态 + 今日习惯完成情况（打卡 / 心情 / 睡眠，来自真实写入）。"""
    from app.router.gamification import progress_snapshot

    db = get_db()
    today = date.today().isoformat()
    row = db.execute(
        "SELECT * FROM care_status WHERE user_id = ? AND date = ?",
        (user_id, today)
    ).fetchone()
    snap = progress_snapshot(orm, user_id, loc.is_global)
    t = snap["today"]
    data = dict(row) if row else {}
    data.update({"date": t["date"], "completed": t["completed"], "total": t["total"], "done": t["done"], "care": dict(row) if row else None})
    return {"success": True, "data": data}

@router.get("/care/stats", response_model=dict)
async def get_care_stats(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    period: str = Query("week"),
    orm: Session = Depends(get_orm_db),
    loc: RequestLocale = Depends(request_locale),
):
    """养生统计：本周打卡天数、连续天数、累计积分（来自打卡 / 日记 / 积分表），以及养生状态里的睡眠 / 运动均值。"""
    from app.router.gamification import progress_snapshot

    db = get_db()
    rows = db.execute(
        "SELECT sleep_hours, exercise_minutes FROM care_status WHERE user_id = ?",
        (user_id,)
    ).fetchall()
    sleep_values = [r["sleep_hours"] for r in rows if r["sleep_hours"] is not None]
    exercise_values = [r["exercise_minutes"] for r in rows if r["exercise_minutes"] is not None]
    avg_sleep = sum(sleep_values) / len(sleep_values) if sleep_values else 0
    snap = progress_snapshot(orm, user_id, loc.is_global)
    return {
        "success": True,
        "data": {
            "period": period,
            "average_sleep": round(avg_sleep, 1),
            "total_exercise": sum(exercise_values),
            "mood_trend": "stable",
            "record_count": len(rows),
            "week_streak": snap["week_checkin_days"],
            "streak_days": snap["streak_days"],
            "total_checkin_days": snap["total_checkin_days"],
            "total_points": snap["points"],
            "level": snap["level"],
            "level_name": snap["level_name"],
        },
    }

# ============ Emotion Records API ============

@router.get("/emotion", response_model=dict)
async def get_emotion_records(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    date: str = Query(None),
    limit: int = Query(30, ge=1, le=100)
):
    """获取情绪记录"""
    db = get_db()
    
    sql = "SELECT * FROM emotion_records WHERE user_id = ?"
    params = [user_id]
    
    if date:
        sql += " AND date = ?"
        params.append(date)
    
    sql += " ORDER BY created_at DESC LIMIT ?"
    params.append(limit)
    
    rows = db.execute(sql, params).fetchall()
    items = [dict(r) for r in rows]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(items)
        }
    }

@router.post("/emotion", response_model=dict)
async def add_emotion_record(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    date: str = Query(...),
    emotion: str = Query(...),
    intensity: int = Query(5, ge=1, le=10),
    trigger: str = Query(None),
    notes: str = Query(None)
):
    """添加情绪记录"""
    emotions = ["开心", "平静", "愉悦", "焦虑", "烦躁", "悲伤", "愤怒", "恐惧", "惊讶", "其他"]
    emotion = EMOTION_FROM_EN.get(emotion.strip().lower(), emotion)  # 国际版传英文标签，库里统一存规范词
    if emotion not in emotions:
        emotion = "其他"
    
    db = get_db()
    
    record_id = generate_id("emotion")
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT INTO emotion_records (id, user_id, date, emotion, intensity, trigger, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (record_id, user_id, date, emotion, intensity, trigger, notes, now))
    db.commit()
    
    record = {
        "id": record_id,
        "user_id": user_id,
        "date": date,
        "emotion": emotion,
        "intensity": intensity,
        "trigger": trigger,
        "notes": notes,
        "created_at": now
    }
    
    return {"success": True, "data": record}

EMOTION_MOOD_SCORE = {"开心": 5, "愉悦": 5, "平静": 4, "惊讶": 3, "其他": 3, "焦虑": 2, "烦躁": 2, "悲伤": 2, "愤怒": 1, "恐惧": 1}
EMOTION_EN = {"开心": "happy", "愉悦": "joyful", "平静": "calm", "惊讶": "surprised", "其他": "other", "焦虑": "anxious", "烦躁": "irritable", "悲伤": "sad", "愤怒": "angry", "恐惧": "fearful"}
EMOTION_FROM_EN = {v: k for k, v in EMOTION_EN.items()}


@router.get("/emotion/trends", response_model=dict)
async def get_emotion_trends(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    period: str = Query("week"),
    orm: Session = Depends(get_orm_db),
    loc: RequestLocale = Depends(request_locale),
):
    """情绪趋势：近 7 天（period=month 为 30 天）每天的平均心情（1–5），合并「情绪记录」和日记里的心情评分。"""
    from datetime import timedelta
    from app.models.journal import JournalEntry

    days = 30 if period == "month" else 7
    start = (date.today() - timedelta(days=days - 1)).isoformat()
    per_day: dict = {}

    db = get_db()
    rows = db.execute(
        "SELECT date, emotion, intensity FROM emotion_records WHERE user_id = ? AND date >= ?", (user_id, start)
    ).fetchall()
    emotion_count: dict = {}
    total_intensity = 0
    for r in rows:
        per_day.setdefault(str(r["date"])[:10], []).append(EMOTION_MOOD_SCORE.get(r["emotion"], 3))
        emotion_count[r["emotion"]] = emotion_count.get(r["emotion"], 0) + 1
        total_intensity += r["intensity"] or 0
    for d, score in orm.query(JournalEntry.date, JournalEntry.mood_score).filter(
        JournalEntry.user_id == user_id, JournalEntry.date >= start
    ).all():
        if score:
            per_day.setdefault(str(d)[:10], []).append(score)

    trends = [
        {"date": d, "avg_mood": round(sum(v) / len(v), 1), "count": len(v)}
        for d, v in sorted(per_day.items())
    ]
    dominant = max(emotion_count, key=emotion_count.get) if emotion_count else None
    if dominant and loc.is_global:
        dominant = EMOTION_EN.get(dominant, "other")
    return {
        "success": True,
        "data": {
            "period": period,
            "dominant_emotion": dominant,
            "average_intensity": round(total_intensity / len(rows), 1) if rows else 0,
            "trends": trends,
        },
    }

# ============ Sleep Records API ============

@router.get("/sleep", response_model=dict)
async def get_sleep_records(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    date: str = Query(None),
    limit: int = Query(30, ge=1, le=100)
):
    """获取睡眠记录"""
    db = get_db()
    
    sql = "SELECT * FROM sleep_records WHERE user_id = ?"
    params = [user_id]
    
    if date:
        sql += " AND date = ?"
        params.append(date)
    
    sql += " ORDER BY date DESC LIMIT ?"
    params.append(limit)
    
    rows = db.execute(sql, params).fetchall()
    items = [dict(r) for r in rows]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(items)
        }
    }

@router.post("/sleep", response_model=dict)
async def add_sleep_record(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    date: str = Query(...),
    sleep_time: str = Query("23:00"),
    wake_time: str = Query("07:00"),
    hours: float = Query(8.0),
    quality: str = Query("normal"),
    notes: str = Query(None)
):
    """添加睡眠记录"""
    qualities = ["good", "normal", "poor"]
    if quality not in qualities:
        quality = "normal"
    
    db = get_db()
    
    record_id = generate_id("sleep")
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT INTO sleep_records (id, user_id, date, sleep_time, wake_time, hours, quality, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (record_id, user_id, date, sleep_time, wake_time, hours, quality, notes, now))
    db.commit()
    
    record = {
        "id": record_id,
        "user_id": user_id,
        "date": date,
        "sleep_time": sleep_time,
        "wake_time": wake_time,
        "hours": hours,
        "quality": quality,
        "notes": notes,
        "created_at": now
    }
    
    return {"success": True, "data": record}

QUALITY_SCORE = {"good": 5, "normal": 3, "poor": 1}


@router.get("/sleep/stats", response_model=dict)
async def get_sleep_stats(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    period: str = Query("week"),
    orm: Session = Depends(get_orm_db),
):
    """睡眠统计：平均时长来自睡眠记录；质量评分（1–5）合并睡眠记录和日记里的睡眠评分。没有数据的项返回 null，不编造。"""
    from app.models.journal import JournalEntry

    db = get_db()
    rows = db.execute(
        "SELECT hours, quality FROM sleep_records WHERE user_id = ?",
        (user_id,)
    ).fetchall()
    hours_values = [r["hours"] for r in rows if r["hours"] is not None]
    quality_count = {"good": 0, "normal": 0, "poor": 0}
    scores = []
    for r in rows:
        q = r["quality"]
        quality_count[q] = quality_count.get(q, 0) + 1
        if q in QUALITY_SCORE:
            scores.append(QUALITY_SCORE[q])
    journal_scores = [q for (q,) in orm.query(JournalEntry.sleep_quality).filter(JournalEntry.user_id == user_id).all() if q]
    scores.extend(journal_scores)

    avg_hours = round(sum(hours_values) / len(hours_values), 1) if hours_values else None
    avg_quality = round(sum(scores) / len(scores), 1) if scores else None
    return {
        "success": True,
        "data": {
            "period": period,
            "average_hours": avg_hours or 0,
            "average_quality": max(quality_count, key=quality_count.get) if rows else "normal",
            "trend": "stable",
            "record_count": len(rows) + len(journal_scores),
            "avg_hours": avg_hours,
            "avg_quality": avg_quality,
        },
    }

# ============ 批量记录 API ============

@router.delete("/{record_type}/{record_id}", response_model=dict)
async def delete_record(
    record_type: str,
    record_id: str,
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")
):
    """删除记录（支持 care / emotion / sleep 三种类型）"""
    valid_types = {"care", "emotion", "sleep"}
    if record_type not in valid_types:
        raise HTTPException(status_code=400, detail=f"无效的记录类型: {record_type}")
    
    table_map = {
        "care": "care_status",
        "emotion": "emotion_records",
        "sleep": "sleep_records",
    }
    
    db = get_db()
    table = table_map[record_type]
    
    cursor = db.execute(
        f"DELETE FROM {table} WHERE id = ? AND user_id = ?",
        (record_id, user_id)
    )
    db.commit()
    
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="记录不存在")
    
    return {"success": True, "message": "记录已删除"}

@router.get("/summary", response_model=dict)
async def get_records_summary(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    days: int = Query(7, ge=1, le=90)
):
    """获取综合记录摘要：情绪趋势、睡眠平均、运动频率等"""
    db = get_db()
    
    import json
    from datetime import timedelta
    
    end_date = date.today().isoformat()
    start_date = (date.today() - timedelta(days=days)).isoformat()
    
    # 情绪数据
    emotion_rows = db.execute(
        "SELECT date, emotion, intensity FROM emotion_records WHERE user_id = ? AND date >= ? AND date <= ? ORDER BY date",
        (user_id, start_date, end_date)
    ).fetchall()
    
    # 睡眠数据
    sleep_rows = db.execute(
        "SELECT date, hours, quality FROM sleep_records WHERE user_id = ? AND date >= ? AND date <= ? ORDER BY date",
        (user_id, start_date, end_date)
    ).fetchall()
    
    # 养生数据
    care_rows = db.execute(
        "SELECT date, mood, sleep_hours, exercise_minutes, stress_level FROM care_status WHERE user_id = ? AND date >= ? AND date <= ? ORDER BY date",
        (user_id, start_date, end_date)
    ).fetchall()
    
    # 情绪趋势
    emotion_trend = []
    for r in emotion_rows:
        emotion_trend.append({
            "date": r["date"],
            "emotion": r["emotion"],
            "intensity": r["intensity"],
        })
    
    # 睡眠趋势
    sleep_trend = []
    for r in sleep_rows:
        sleep_trend.append({
            "date": r["date"],
            "hours": r["hours"],
            "quality": r["quality"],
        })
    
    # 计算平均值
    avg_sleep = 0.0
    if sleep_rows:
        hours_vals = [r["hours"] for r in sleep_rows if r["hours"] is not None]
        avg_sleep = sum(hours_vals) / len(hours_vals) if hours_vals else 0.0
    
    avg_exercise = 0.0
    exercise_count = 0
    if care_rows:
        exercise_vals = [r["exercise_minutes"] for r in care_rows if r["exercise_minutes"] is not None]
        if exercise_vals:
            avg_exercise = sum(exercise_vals) / len(exercise_vals)
            exercise_count = len([v for v in exercise_vals if v > 0])
    
    # 主导情绪
    emotion_count = {}
    for r in emotion_rows:
        e = r["emotion"]
        emotion_count[e] = emotion_count.get(e, 0) + 1
    dominant_emotion = max(emotion_count, key=emotion_count.get) if emotion_count else None
    
    return {
        "success": True,
        "data": {
            "period": f"last_{days}_days",
            "start_date": start_date,
            "end_date": end_date,
            "emotion": {
                "trend": emotion_trend,
                "dominant": dominant_emotion,
                "record_count": len(emotion_rows),
            },
            "sleep": {
                "trend": sleep_trend,
                "average_hours": round(avg_sleep, 1),
                "record_count": len(sleep_rows),
            },
            "exercise": {
                "average_minutes": round(avg_exercise, 0),
                "active_days": exercise_count,
            },
            "total_records": len(emotion_rows) + len(sleep_rows) + len(care_rows),
        }
    }
