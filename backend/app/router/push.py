"""
个性化推送 API
Mock模式 — 只返回推送内容，不实际推送
"""
import logging
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/push", tags=["push"])


# ============ 推送偏好模型 ============

class PushPreferences(BaseModel):
    user_id: str
    quiet_hours_start: str = "22:00"
    quiet_hours_end: str = "07:00"
    push_frequency: str = "normal"  # normal / minimal / verbose
    focus_areas: list[str] = []  # e.g. ["睡眠", "运动", "饮食"]
    language: str = "cn"


# ============ Mock 偏好存储 ============

_preferences_store: dict[str, dict] = {}


# ============ API 端点 ============

@router.get("/morning")
async def get_morning_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """早晨推送 (7:00) — 问候+今日饮食建议+晨练"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_morning_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] morning push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/noon")
async def get_noon_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """午间推送 (12:00) — 午餐建议+午休提醒+茶饮"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_noon_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] noon push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/afternoon")
async def get_afternoon_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """下午推送 (15:00) — 运动提醒+穴位按摩"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_afternoon_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] afternoon push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/evening")
async def get_evening_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """晚间推送 (18:00) — 晚餐+泡脚建议"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_evening_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] evening push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/night")
async def get_night_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """睡前推送 (21:30) — 睡眠建议+穴位+情绪"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_night_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] night push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/daily")
async def get_daily_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """完整日推送方案"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_daily_push(user_id, lang)
        return result
    except Exception as e:
        logger.error(f"[Push] daily push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/preferences")
async def set_push_preferences(prefs: PushPreferences):
    """设置推送偏好"""
    _preferences_store[prefs.user_id] = prefs.model_dump()
    return {
        "success": True,
        "message": "Push preferences saved",
        "preferences": prefs.model_dump(),
    }


@router.get("/preferences")
async def get_push_preferences(
    user_id: str = Query(..., description="用户ID"),
):
    """获取推送偏好"""
    prefs = _preferences_store.get(user_id)
    if not prefs:
        return {
            "user_id": user_id,
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "07:00",
            "push_frequency": "normal",
            "focus_areas": [],
            "language": "cn",
        }
    return prefs
