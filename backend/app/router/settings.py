# 用户设置 API 路由
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, time

from app.database.db import get_db

router = APIRouter(prefix="/api/v1/settings", tags=["设置"])

# ============ Models ============

class UserSettings(BaseModel):
    user_id: str
    memory_enabled: bool = True
    quiet_hours_enabled: bool = False
    quiet_hours_start: str = "22:00"
    quiet_hours_end: str = "08:00"
    notifications_enabled: bool = True
    solar_term_reminders: bool = True
    followup_reminders: bool = True
    marketing_notifications: bool = False
    language: str = "zh-CN"
    theme: str = "light"
    updated_at: str

class MemoryRecord(BaseModel):
    id: str
    type: str
    content: str
    metadata: Optional[dict] = None
    created_at: str

# ============ Helper Functions ============

def get_default_settings(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "memory_enabled": 1,
        "quiet_hours_enabled": 0,
        "quiet_hours_start": "22:00",
        "quiet_hours_end": "08:00",
        "notifications_enabled": 1,
        "solar_term_reminders": 1,
        "followup_reminders": 1,
        "marketing_notifications": 0,
        "language": "zh-CN",
        "theme": "light",
        "updated_at": datetime.now().isoformat()
    }

def generate_id(prefix: str) -> str:
    return f"{prefix}_{datetime.now().strftime('%Y%m%d%H%M%S')}"

def _settings_row_to_dict(row) -> dict:
    d = dict(row)
    d["memory_enabled"] = bool(d.get("memory_enabled", 1))
    d["quiet_hours_enabled"] = bool(d.get("quiet_hours_enabled", 0))
    d["notifications_enabled"] = bool(d.get("notifications_enabled", 1))
    d["solar_term_reminders"] = bool(d.get("solar_term_reminders", 1))
    d["followup_reminders"] = bool(d.get("followup_reminders", 1))
    d["marketing_notifications"] = bool(d.get("marketing_notifications", 0))
    return d

def _parse_json(s):
    import json
    try:
        return json.loads(s) if s else {}
    except (json.JSONDecodeError, TypeError):
        return {}

# ============ Settings API ============

@router.get("", response_model=dict)
async def get_settings(user_id: str = Query("user-001")):
    """获取用户设置"""
    db = get_db()
    
    row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
    if row:
        return {"success": True, "data": _settings_row_to_dict(row)}
    
    return {"success": True, "data": get_default_settings(user_id)}

@router.post("", response_model=dict)
async def update_settings(
    user_id: str = Query("user-001"),
    memory_enabled: Optional[bool] = Query(None),
    quiet_hours_enabled: Optional[bool] = Query(None),
    quiet_hours_start: Optional[str] = Query(None),
    quiet_hours_end: Optional[str] = Query(None),
    notifications_enabled: Optional[bool] = Query(None),
    solar_term_reminders: Optional[bool] = Query(None),
    followup_reminders: Optional[bool] = Query(None),
    marketing_notifications: Optional[bool] = Query(None),
    language: Optional[str] = Query(None),
    theme: Optional[str] = Query(None)
):
    """更新用户设置"""
    db = get_db()
    now = datetime.now().isoformat()
    
    # 先确保记录存在
    db.execute("INSERT OR IGNORE INTO user_settings (user_id) VALUES (?)", (user_id,))
    
    updates = []
    params = []
    
    if memory_enabled is not None:
        updates.append("memory_enabled = ?")
        params.append(int(memory_enabled))
    if quiet_hours_enabled is not None:
        updates.append("quiet_hours_enabled = ?")
        params.append(int(quiet_hours_enabled))
    if quiet_hours_start is not None:
        updates.append("quiet_hours_start = ?")
        params.append(quiet_hours_start)
    if quiet_hours_end is not None:
        updates.append("quiet_hours_end = ?")
        params.append(quiet_hours_end)
    if notifications_enabled is not None:
        updates.append("notifications_enabled = ?")
        params.append(int(notifications_enabled))
    if solar_term_reminders is not None:
        updates.append("solar_term_reminders = ?")
        params.append(int(solar_term_reminders))
    if followup_reminders is not None:
        updates.append("followup_reminders = ?")
        params.append(int(followup_reminders))
    if marketing_notifications is not None:
        updates.append("marketing_notifications = ?")
        params.append(int(marketing_notifications))
    if language is not None:
        updates.append("language = ?")
        params.append(language)
    if theme is not None:
        updates.append("theme = ?")
        params.append(theme)
    
    if updates:
        updates.append("updated_at = ?")
        params.append(now)
        params.append(user_id)
        
        db.execute(
            f"UPDATE user_settings SET {', '.join(updates)} WHERE user_id = ?",
            params
        )
        db.commit()
    
    row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
    
    return {
        "success": True,
        "data": _settings_row_to_dict(row) if row else get_default_settings(user_id),
        "message": "设置已更新"
    }

# ============ Memory API ============

@router.get("/memory", response_model=dict)
async def get_memory(
    user_id: str = Query("user-001"),
    type: str = Query(None),
    limit: int = Query(50, ge=1, le=100)
):
    """获取用户记忆"""
    db = get_db()
    
    sql = "SELECT * FROM user_memory WHERE user_id = ?"
    params = [user_id]
    
    if type:
        sql += " AND type = ?"
        params.append(type)
    
    sql += " ORDER BY created_at DESC LIMIT ?"
    params.append(limit)
    
    rows = db.execute(sql, params).fetchall()
    items = []
    for r in rows:
        d = dict(r)
        d["metadata"] = _parse_json(d.get("metadata"))
        items.append(d)
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(items)
        }
    }

@router.post("/memory", response_model=dict)
async def add_memory(
    user_id: str = Query("user-001"),
    type: str = Query(...),
    content: str = Query(...),
    metadata: str = Query(None)
):
    """添加记忆"""
    db = get_db()
    
    import json
    meta = {}
    if metadata:
        try:
            meta = json.loads(metadata)
        except:
            pass
    
    record_id = generate_id("mem")
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT INTO user_memory (id, user_id, type, content, metadata, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (record_id, user_id, type, content, json.dumps(meta, ensure_ascii=False), now))
    db.commit()
    
    record = {
        "id": record_id,
        "type": type,
        "content": content,
        "metadata": meta,
        "created_at": now
    }
    
    return {"success": True, "data": record}

@router.delete("/memory/{memory_id}", response_model=dict)
async def delete_memory(
    memory_id: str,
    user_id: str = Query("user-001")
):
    """删除单条记忆"""
    db = get_db()
    db.execute("DELETE FROM user_memory WHERE id = ? AND user_id = ?",
               (memory_id, user_id))
    db.commit()
    
    return {"success": True, "message": "记忆已删除"}

@router.delete("/memory", response_model=dict)
async def clear_memory(
    user_id: str = Query("user-001"),
    confirm: str = Query(..., description="必须输入 'confirm' 确认")
):
    """清空所有记忆"""
    if confirm != "confirm":
        raise HTTPException(status_code=400, detail="请输入 confirm 确认清空记忆")
    
    db = get_db()
    now = datetime.now().isoformat()
    
    db.execute("DELETE FROM user_memory WHERE user_id = ?", (user_id,))
    
    # 同时禁用记忆功能
    db.execute("""
        INSERT OR REPLACE INTO user_settings (user_id, memory_enabled, updated_at)
        VALUES (?, 0, ?)
    """, (user_id, now))
    
    db.commit()
    
    return {"success": True, "message": "所有记忆已清空，记忆功能已关闭"}

@router.post("/memory/enable", response_model=dict)
async def enable_memory(
    user_id: str = Query("user-001"),
    enabled: bool = Query(True)
):
    """开启/关闭记忆"""
    db = get_db()
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT OR REPLACE INTO user_settings (user_id, memory_enabled, updated_at)
        VALUES (?, ?, ?)
    """, (user_id, int(enabled), now))
    db.commit()
    
    message = "记忆功能已开启" if enabled else "记忆功能已关闭"
    return {"success": True, "message": message}

# ============ Quiet Hours API ============

@router.get("/quiet-hours", response_model=dict)
async def get_quiet_hours(user_id: str = Query("user-001")):
    """获取静默时段设置"""
    db = get_db()
    
    row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
    if row:
        r = dict(row)
        return {
            "success": True,
            "data": {
                "enabled": bool(r.get("quiet_hours_enabled", 0)),
                "start": r.get("quiet_hours_start", "22:00"),
                "end": r.get("quiet_hours_end", "08:00")
            }
        }
    
    return {
        "success": True,
        "data": {"enabled": False, "start": "22:00", "end": "08:00"}
    }

@router.post("/quiet-hours", response_model=dict)
async def set_quiet_hours(
    user_id: str = Query("user-001"),
    enabled: bool = Query(True),
    start: str = Query("22:00"),
    end: str = Query("08:00")
):
    """设置静默时段"""
    db = get_db()
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT OR REPLACE INTO user_settings (user_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end, updated_at)
        VALUES (?, ?, ?, ?, ?)
    """, (user_id, int(enabled), start, end, now))
    db.commit()
    
    message = f"静默时段已设置: {start} - {end}" if enabled else "静默时段已关闭"
    
    return {
        "success": True,
        "message": message,
        "data": {"enabled": enabled, "start": start, "end": end}
    }

@router.get("/quiet-hours/check", response_model=dict)
async def check_quiet_hours(user_id: str = Query("user-001")):
    """检查当前是否在静默时段"""
    db = get_db()
    
    row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
    
    if not row or not row.get("quiet_hours_enabled", 0):
        return {
            "success": True,
            "data": {"is_quiet": False, "reason": "静默时段未开启"}
        }
    
    now = datetime.now()
    current_time = now.strftime("%H:%M")
    start = row.get("quiet_hours_start", "22:00")
    end = row.get("quiet_hours_end", "08:00")
    
    if start > end:
        is_quiet = current_time >= start or current_time <= end
    else:
        is_quiet = start <= current_time <= end
    
    return {
        "success": True,
        "data": {
            "is_quiet": is_quiet,
            "reason": "在静默时段" if is_quiet else "不在静默时段"
        }
    }

# ============ 导出/导入设置 ============

@router.get("/export", response_model=dict)
async def export_settings(user_id: str = Query("user-001")):
    """导出所有设置和记忆"""
    db = get_db()
    
    row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
    settings = _settings_row_to_dict(row) if row else get_default_settings(user_id)
    
    memory_rows = db.execute(
        "SELECT * FROM user_memory WHERE user_id = ? ORDER BY created_at DESC",
        (user_id,)
    ).fetchall()
    memory = []
    for r in memory_rows:
        d = dict(r)
        d["metadata"] = _parse_json(d.get("metadata"))
        memory.append(d)
    
    return {
        "success": True,
        "data": {
            "settings": settings,
            "memory": memory,
            "exported_at": datetime.now().isoformat()
        }
    }
