# 用户数据记录 API 路由
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date

from app.database.db import get_db

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
    return f"{prefix}_{datetime.now().strftime('%Y%m%d%H%M%S')}"

# ============ CareStatus API ============

@router.get("/care", response_model=dict)
async def get_care_records(
    user_id: str = Query("user-001"),
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
    user_id: str = Query("user-001"),
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
async def get_today_care(user_id: str = Query("user-001")):
    """获取今日养生状态"""
    db = get_db()
    
    today = date.today().isoformat()
    row = db.execute(
        "SELECT * FROM care_status WHERE user_id = ? AND date = ?",
        (user_id, today)
    ).fetchone()
    
    return {"success": True, "data": dict(row) if row else None}

@router.get("/care/stats", response_model=dict)
async def get_care_stats(
    user_id: str = Query("user-001"),
    period: str = Query("week")
):
    """获取养生统计"""
    db = get_db()
    
    rows = db.execute(
        "SELECT sleep_hours, exercise_minutes FROM care_status WHERE user_id = ?",
        (user_id,)
    ).fetchall()
    
    if not rows:
        return {
            "success": True,
            "data": {
                "period": period,
                "average_sleep": 0,
                "total_exercise": 0,
                "mood_trend": "stable"
            }
        }
    
    sleep_values = [r["sleep_hours"] for r in rows if r["sleep_hours"] is not None]
    exercise_values = [r["exercise_minutes"] for r in rows if r["exercise_minutes"] is not None]
    
    avg_sleep = sum(sleep_values) / len(sleep_values) if sleep_values else 0
    total_exercise = sum(exercise_values)
    
    return {
        "success": True,
        "data": {
            "period": period,
            "average_sleep": round(avg_sleep, 1),
            "total_exercise": total_exercise,
            "mood_trend": "stable",
            "record_count": len(rows)
        }
    }

# ============ Emotion Records API ============

@router.get("/emotion", response_model=dict)
async def get_emotion_records(
    user_id: str = Query("user-001"),
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
    user_id: str = Query("user-001"),
    date: str = Query(...),
    emotion: str = Query(...),
    intensity: int = Query(5, ge=1, le=10),
    trigger: str = Query(None),
    notes: str = Query(None)
):
    """添加情绪记录"""
    emotions = ["开心", "平静", "愉悦", "焦虑", "烦躁", "悲伤", "愤怒", "恐惧", "惊讶", "其他"]
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

@router.get("/emotion/trends", response_model=dict)
async def get_emotion_trends(
    user_id: str = Query("user-001"),
    period: str = Query("week")
):
    """获取情绪趋势"""
    db = get_db()
    
    rows = db.execute(
        "SELECT emotion, intensity FROM emotion_records WHERE user_id = ?",
        (user_id,)
    ).fetchall()
    
    if not rows:
        return {
            "success": True,
            "data": {
                "period": period,
                "dominant_emotion": None,
                "average_intensity": 0,
                "trends": []
            }
        }
    
    emotion_count = {}
    total_intensity = 0
    
    for r in rows:
        e = r["emotion"]
        emotion_count[e] = emotion_count.get(e, 0) + 1
        total_intensity += r["intensity"]
    
    dominant = max(emotion_count, key=emotion_count.get)
    avg_intensity = total_intensity / len(rows) if rows else 0
    
    return {
        "success": True,
        "data": {
            "period": period,
            "dominant_emotion": dominant,
            "average_intensity": round(avg_intensity, 1),
            "trends": []
        }
    }

# ============ Sleep Records API ============

@router.get("/sleep", response_model=dict)
async def get_sleep_records(
    user_id: str = Query("user-001"),
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
    user_id: str = Query("user-001"),
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

@router.get("/sleep/stats", response_model=dict)
async def get_sleep_stats(
    user_id: str = Query("user-001"),
    period: str = Query("week")
):
    """获取睡眠统计"""
    db = get_db()
    
    rows = db.execute(
        "SELECT hours, quality FROM sleep_records WHERE user_id = ?",
        (user_id,)
    ).fetchall()
    
    if not rows:
        return {
            "success": True,
            "data": {
                "period": period,
                "average_hours": 0,
                "average_quality": "normal",
                "trend": "stable"
            }
        }
    
    hours_values = [r["hours"] for r in rows if r["hours"] is not None]
    quality_count = {"good": 0, "normal": 0, "poor": 0}
    
    for r in rows:
        q = r["quality"]
        quality_count[q] = quality_count.get(q, 0) + 1
    
    avg_hours = sum(hours_values) / len(hours_values) if hours_values else 0
    avg_quality = max(quality_count, key=quality_count.get)
    
    return {
        "success": True,
        "data": {
            "period": period,
            "average_hours": round(avg_hours, 1),
            "average_quality": avg_quality,
            "trend": "stable",
            "record_count": len(rows)
        }
    }

# ============ 批量记录 API ============

@router.delete("/{record_type}/{record_id}", response_model=dict)
async def delete_record(
    record_type: str,
    record_id: str,
    user_id: str = Query("user-001")
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
    user_id: str = Query("user-001"),
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
